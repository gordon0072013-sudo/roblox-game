--!strict
--[[
	BattlePassService — XP, tier progression, reward claim.
	Free tier gives small cash + bombs. Premium tier (sold via Battle Pass
	dev product) gives 10x rewards. Season resets every BATTLE_PASS_DURATION_DAYS.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local InfectionService -- forward
local CaptureService -- forward

local BattlePassService = {}

local function tierReward(tier: number, premium: boolean): { kind: string, amount: number }
	-- Free vs premium reward magnitudes
	local cash = (tier + 1) * 300
	local mult = if premium then 10 else 1
	if tier % 5 == 4 then
		-- Bonus tier: rare egg (premium) or bomb (free)
		if premium then
			return { kind = "rare_egg", amount = 1 }
		else
			return { kind = "infection_bomb", amount = 1 }
		end
	end
	return { kind = "cash", amount = cash * mult }
end

local function pushUpdate(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	Remotes.Event(Remotes.Names.BattlePassUpdate):FireClient(player, {
		xp = data.battlePass.xp,
		tier = data.battlePass.tier,
		xpPerTier = Config.BATTLE_PASS_XP_PER_TIER,
		maxTier = Config.BATTLE_PASS_TIERS,
		premium = data.battlePass.premium,
		claimed = data.battlePass.claimed,
		seasonId = data.battlePass.seasonId,
	})
end

function BattlePassService.AwardXp(player: Player, kind: string)
	local data = DataService.Get(player)
	if not data then return end
	local amount = Config.BATTLE_PASS_XP_SOURCES[kind] or 0
	if amount == 0 then return end
	data.battlePass.xp += amount
	-- tier ups
	while data.battlePass.tier < Config.BATTLE_PASS_TIERS
		and data.battlePass.xp >= (data.battlePass.tier + 1) * Config.BATTLE_PASS_XP_PER_TIER do
		data.battlePass.tier += 1
		Remotes.Event(Remotes.Names.Notify):FireClient(player, {
			kind = "info",
			text = `Battle Pass Tier {data.battlePass.tier}! Claim your reward.`,
		})
	end
	pushUpdate(player)
end

function BattlePassService.ClaimTier(player: Player, tier: number)
	local data = DataService.Get(player)
	if not data then return end
	if tier < 1 or tier > data.battlePass.tier then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text="Tier not earned yet." })
		return
	end
	local keyFree = `f:{tier}`
	local keyPrem = `p:{tier}`
	if not data.battlePass.claimed[keyFree] then
		local r = tierReward(tier, false)
		if r.kind == "cash" then EconomyService.AwardCash(player, r.amount, "battle pass")
		elseif r.kind == "infection_bomb" then InfectionService.AddBombs(player, r.amount)
		elseif r.kind == "rare_egg" then CaptureService.AttemptCapture(player, { freeRare = true, count = r.amount or 1 })
		end
		data.battlePass.claimed[keyFree] = true
	end
	if data.battlePass.premium and not data.battlePass.claimed[keyPrem] then
		local r = tierReward(tier, true)
		if r.kind == "cash" then EconomyService.AwardCash(player, r.amount, "BP premium")
		elseif r.kind == "infection_bomb" then InfectionService.AddBombs(player, r.amount)
		elseif r.kind == "rare_egg" then CaptureService.AttemptCapture(player, { freeRare = true, count = r.amount or 1 })
		end
		data.battlePass.claimed[keyPrem] = true
	end
	pushUpdate(player)
end

function BattlePassService.GrantPremium(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	data.battlePass.premium = true
	Remotes.Event(Remotes.Names.Notify):FireClient(player, {
		kind = "info", text = "Premium Battle Pass unlocked — claim previous tiers for premium rewards!",
	})
	pushUpdate(player)
end

function BattlePassService.OnPlayerAdded(player: Player)
	task.delay(1, pushUpdate, player)
end

function BattlePassService.Init()
	InfectionService = require(script.Parent.InfectionService)
	CaptureService = require(script.Parent.CaptureService)
end

return BattlePassService
