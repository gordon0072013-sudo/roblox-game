--!strict
--[[
	MonetizationService — the revenue plumbing. Three flows:

	  1. Gamepass purchases — PromptPurchaseFinished -> set gamepasses[key] = true
	     and recompute multipliers. On every join we ALSO re-check ownership in
	     case the player bought the pass off-experience.

	  2. Developer products — ProcessReceipt callback. Order matters: we
	     deliver the goods, save the profile, THEN return PurchaseGranted.
	     Returning Granted before save risks lost purchases (which trigger
	     refund requests = revenue loss + store violation flags).

	  3. Premium payouts — Roblox does this automatically when the experience
	     is enrolled. We don't do anything in code, but we log analytics so
	     the user can see how much Premium playtime is generated.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local LabService = require(script.Parent.LabService)
local CaptureService = require(script.Parent.CaptureService)
local MutationService = require(script.Parent.MutationService)
local InfectionService = require(script.Parent.InfectionService)
local PetService = require(script.Parent.PetService)
local LuckyWheelService -- forward
local BattlePassService -- forward
local AnalyticsService -- forward
local TrailService -- forward

local MonetizationService = {}

-- Indexes: id -> {key, def}
local gamepassById: { [number]: { key: string, def: any } } = {}
local productById: { [number]: { key: string, def: any } } = {}

local function rebuildIndexes()
	gamepassById = {}
	productById = {}
	for key, gp in pairs(Config.GAMEPASSES) do
		if gp.id and gp.id > 0 then
			gamepassById[gp.id] = { key = key, def = gp }
		end
	end
	for key, dp in pairs(Config.DEV_PRODUCTS) do
		if dp.id and dp.id > 0 then
			productById[dp.id] = { key = key, def = dp }
		end
	end
end

local function checkGamepasses(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	for key, gp in pairs(Config.GAMEPASSES) do
		if gp.id and gp.id > 0 then
			local ok, owned = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, gp.id)
			if ok and owned then
				data.gamepasses[key] = true
			end
		end
	end
	EconomyService.PushHud(player)
end

local function grantGamepass(player: Player, key: string)
	local data = DataService.Get(player)
	if not data then return end
	data.gamepasses[key] = true
	EconomyService.PushHud(player)
	Remotes.Event(Remotes.Names.Notify):FireClient(player, {
		kind = "info", text = `Gamepass unlocked: ${(Config.GAMEPASSES[key] or {name=key}).name}`,
	})
	if TrailService then
		TrailService.OnGamepassGranted(player, key)
	end
	if key == "GoldenPlot" then
		LabService.RefreshPlotCosmetics(player)
	end
	local okDD, DailyDealService = pcall(require, script.Parent.DailyDealService)
	if okDD then DailyDealService.OnGamepassPurchased(player, key) end
	if AnalyticsService then
		AnalyticsService.LogPurchase(player, "gamepass", key, (Config.GAMEPASSES[key] or {}).price or 0)
	end
end

local function deliverProduct(player: Player, key: string): boolean
	local def = Config.DEV_PRODUCTS[key]
	if not def then return false end
	if def.kind == "cash" then
		EconomyService.AwardCash(player, def.amount or 0, "purchase")
	elseif def.kind == "instant_mutation" then
		MutationService.ForceInstantMutation(player)
	elseif def.kind == "skip_rebirth" then
		EconomyService.SkipRebirth(player)
	elseif def.kind == "rare_egg" then
		CaptureService.AttemptCapture(player, { freeRare = true, count = 1 })
	elseif def.kind == "infection_bomb" then
		InfectionService.AddBombs(player, def.amount or 1)
	elseif def.kind == "battle_pass" then
		if BattlePassService then BattlePassService.GrantPremium(player) end
	elseif def.kind == "pet_egg" then
		PetService.Hatch(player, false)
	elseif def.kind == "pet_egg_lucky" then
		PetService.Hatch(player, true)
	elseif def.kind == "wheel_spins" then
		if LuckyWheelService then LuckyWheelService.GrantSpins(player, def.amount or 1) end
	elseif def.kind == "tip" then
		-- Tips deliver nothing tangible — that's the point. Mark the profile
		-- so chat tags / leaderboard recognize the tipper, and award a small
		-- cash thank-you so it's not entirely empty.
		local data = DataService.Get(player)
		if data then
			(data :: any)._totalTipped = ((data :: any)._totalTipped or 0) + (def.amount or 0)
		end
		EconomyService.AwardCash(player, (def.amount or 0) * 100, "tip thank-you")
		Remotes.Event(Remotes.Names.Notify):FireClient(player, {
			kind = "capture",
			text = string.format("💖 Thank you for the %d R$ tip! You're amazing.", def.amount or 0),
		})
	else
		warn(`[Monetization] Unknown product kind: ${tostring(def.kind)}`)
		return false
	end
	if AnalyticsService then
		AnalyticsService.LogPurchase(player, "product", key, def.price or 0)
	end
	return true
end

function MonetizationService.PromptPurchase(player: Player, kind: string, key: string)
	if kind == "gamepass" then
		local gp = Config.GAMEPASSES[key]
		if gp and gp.id and gp.id > 0 then
			MarketplaceService:PromptGamePassPurchase(player, gp.id)
		else
			Remotes.Event(Remotes.Names.Notify):FireClient(player, {
				kind="error",
				text=`${(gp and gp.name) or key}: gamepass not configured (set ID in Config.luau).`,
			})
			warn(`[Monetization] PromptPurchase requested for unconfigured gamepass ${key}`)
		end
	elseif kind == "product" then
		local dp = Config.DEV_PRODUCTS[key]
		if dp and dp.id and dp.id > 0 then
			MarketplaceService:PromptProductPurchase(player, dp.id)
		else
			Remotes.Event(Remotes.Names.Notify):FireClient(player, {
				kind="error",
				text=`${(dp and dp.name) or key}: dev product not configured (set ID in Config.luau).`,
			})
			warn(`[Monetization] PromptPurchase requested for unconfigured product ${key}`)
		end
	end
end

function MonetizationService.OnPlayerAdded(player: Player)
	checkGamepasses(player)
end

function MonetizationService.Init()
	BattlePassService = require(script.Parent.BattlePassService)
	LuckyWheelService = require(script.Parent.LuckyWheelService)
	AnalyticsService = require(script.Parent.AnalyticsService)
	TrailService = require(script.Parent.TrailService)
	rebuildIndexes()

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if not wasPurchased then return end
		local entry = gamepassById[gamePassId]
		if not entry then return end
		grantGamepass(player, entry.key)
	end)

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
		local entry = productById[receiptInfo.ProductId]
		if not entry then
			warn(`[Monetization] ProcessReceipt: unknown product ${receiptInfo.ProductId}`)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		-- Idempotency: keep a small ring buffer of granted PurchaseIds on the profile.
		local data = DataService.Get(player)
		if not data then return Enum.ProductPurchaseDecision.NotProcessedYet end
		(data :: any)._purchaseLog = (data :: any)._purchaseLog or {}
		local log = (data :: any)._purchaseLog :: { string }
		for _, id in ipairs(log) do
			if id == receiptInfo.PurchaseId then
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end

		local ok, delivered = pcall(deliverProduct, player, entry.key)
		if not ok or not delivered then
			warn(`[Monetization] Delivery failed for ${entry.key}: ${tostring(delivered)}`)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		table.insert(log, receiptInfo.PurchaseId)
		if #log > Config.PURCHASE_LOG_RING_SIZE then
			table.remove(log, 1)
		end

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return MonetizationService
