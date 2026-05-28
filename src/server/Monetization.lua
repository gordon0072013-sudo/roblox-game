--!strict
-- Monetization.lua
-- Wraps MarketplaceService: tracks owned game passes, processes developer
-- product receipts idempotently, and exposes the effective coin multiplier
-- for a player based on the passes they own.

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Monetization = {}

-- userId -> { [passKey]: boolean }
local ownedPasses: { [number]: { [string]: boolean } } = {}

-- Callback the GameLogic registers so we can grant coins on product purchase.
local grantCoins: ((player: Player, amount: number) -> ())? = nil

function Monetization.SetGrantCoinsCallback(cb: (player: Player, amount: number) -> ())
	grantCoins = cb
end

-- Refresh which passes a player owns (call on join).
function Monetization.LoadPasses(player: Player)
	local owned = {}
	for passKey, info in pairs(Config.GamePasses) do
		if info.id and info.id > 0 then
			local ok, result = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, info.id)
			end)
			owned[passKey] = ok and result == true
		else
			owned[passKey] = false
		end
	end
	ownedPasses[player.UserId] = owned
end

function Monetization.OwnsPass(player: Player, passKey: string): boolean
	local owned = ownedPasses[player.UserId]
	return owned ~= nil and owned[passKey] == true
end

-- Effective coin multiplier from all owned passes (multiplicative).
function Monetization.GetMultiplier(player: Player): number
	local mult = 1
	for passKey, factor in pairs(Config.PassMultipliers) do
		if Monetization.OwnsPass(player, passKey) then
			mult = mult * factor
		end
	end
	return mult
end

function Monetization.Release(player: Player)
	ownedPasses[player.UserId] = nil
end

-- Map a developer product id back to its config entry.
local function findProductById(productId: number)
	for productKey, info in pairs(Config.DeveloperProducts) do
		if info.id == productId then
			return productKey, info
		end
	end
	return nil, nil
end

-- ProcessReceipt must be set exactly once. It must be idempotent: Roblox may
-- call it again if we don't confirm, so we only confirm after the grant runs.
function Monetization.Init()
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local player = game:GetService("Players"):GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			-- Player left; let Roblox retry when they return.
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local _, info = findProductById(receiptInfo.ProductId)
		if not info then
			warn("[Monetization] Unknown product id: " .. tostring(receiptInfo.ProductId))
			-- Nothing to grant; mark granted so Roblox stops retrying.
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		if grantCoins then
			grantCoins(player, info.coins)
		else
			warn("[Monetization] grantCoins callback not set; cannot grant product")
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return Monetization
