--!strict
--[[
	EconomyService — cash, rebirths, income calculation, multipliers.

	Income tick is driven from LabService (which owns placed brainrots), but
	the math lives here so MonetizationService and BattlePassService can
	consult it for previews and bonus calculations.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(Shared.Config)
local Types = require(Shared.Types)
local BrainrotData = require(Shared.BrainrotData)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)

local EconomyService = {}

-- Compute income/sec for a single brainrot considering tier, mutations, and global multipliers.
function EconomyService.ComputeBrainrotIncome(player: Player, brainrot: Types.OwnedBrainrot): number
	local def = BrainrotData.Get(brainrot.speciesId)
	if not def then return 0 end
	local data = DataService.Get(player)
	if not data then return 0 end

	local base = def.baseIncomePerSecond
	local tierMult = 1 + brainrot.mutationTier * Config.MUTATION_INCOME_MULT_PER_TIER
	local rebirthMult = Config.REBIRTH_INCOME_MULT(data.rebirths)
	local gamepassMult = if data.gamepasses["Cash2x"] then 2 else 1
	local groupMult = if (data :: any)._inGroup then Config.GROUP_REWARD_MULT else 1
	local premiumMult = if player.MembershipType == Enum.MembershipType.Premium then 1.10 else 1
	local petMult = 1
	local okPet, PetService = pcall(require, script.Parent.PetService)
	if okPet then petMult = PetService.GetCashMult(player) end
	local infectionMult = 1
	if data.infectedUntil > os.time() then
		local penalty = Config.INFECTION_INCOME_MULT
		if data.gamepasses["InfectionShield"] then
			-- shield reduces the penalty severity
			penalty = penalty + (1 - penalty) * Config.INFECTION_SHIELD_GAMEPASS_REDUCTION
		end
		infectionMult = penalty
	end
	return base * tierMult * rebirthMult * gamepassMult * groupMult * premiumMult * petMult * infectionMult
end

function EconomyService.AwardCash(player: Player, amount: number, reason: string?)
	local data = DataService.Get(player)
	if not data then return end
	local prevEarned = data.stats.totalCashEarned
	data.cash += amount
	data.stats.totalCashEarned += math.max(0, amount)
	EconomyService.PushHud(player)
	if reason then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, {
			kind = "cash",
			text = `+${amount} cash (${reason})`,
		})
	end
	-- Badge triggers cross the 100k and 1m thresholds
	if amount > 0 then
		local ok, BadgeService = pcall(require, script.Parent.BadgeService)
		if ok then
			if prevEarned < 100000 and data.stats.totalCashEarned >= 100000 then
				BadgeService.Fire(player, "cash_100k")
			end
			if prevEarned < 1000000 and data.stats.totalCashEarned >= 1000000 then
				BadgeService.Fire(player, "cash_1m")
			end
		end
	end
end

function EconomyService.SpendCash(player: Player, amount: number): boolean
	local data = DataService.Get(player)
	if not data then return false end
	if data.cash < amount then return false end
	data.cash -= amount
	EconomyService.PushHud(player)
	return true
end

function EconomyService.TryRebirth(player: Player): boolean
	local data = DataService.Get(player)
	if not data then return false end
	local cost = Config.REBIRTH_CASH_REQUIREMENT(data.rebirths)
	if data.cash < cost then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, {
			kind = "error",
			text = `Need ${cost} cash to rebirth.`,
		})
		return false
	end
	data.cash -= cost
	data.rebirths += 1
	-- Inventory persists across rebirths in this design (player-friendly)
	Remotes.Event(Remotes.Names.Notify):FireClient(player, {
		kind = "rebirth",
		text = `Rebirth ${data.rebirths}! Income multiplier ${string.format("%.2fx", Config.REBIRTH_INCOME_MULT(data.rebirths))}`,
	})
	EconomyService.PushHud(player)
	if data.rebirths == 1 then
		local ok, BadgeService = pcall(require, script.Parent.BadgeService)
		if ok then BadgeService.Fire(player, "first_rebirth") end
	end
	local okL, PlayerLevelService = pcall(require, script.Parent.PlayerLevelService)
	if okL then PlayerLevelService.AwardXp(player, "rebirth") end
	return true
end

function EconomyService.SkipRebirth(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	data.rebirths += 1
	data.cash = math.max(data.cash, Config.STARTING_CASH)
	EconomyService.PushHud(player)
	Remotes.Event(Remotes.Names.Notify):FireClient(player, {
		kind = "rebirth",
		text = `Skipped to Rebirth ${data.rebirths}!`,
	})
end

function EconomyService.PushHud(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	local nextRebirthCost = Config.REBIRTH_CASH_REQUIREMENT(data.rebirths)
	local cashMult = if data.gamepasses["Cash2x"] then 2 else 1
	local infected = data.infectedUntil > os.time()
	Remotes.Event(Remotes.Names.HudUpdate):FireClient(player, {
		cash = data.cash,
		rebirths = data.rebirths,
		nextRebirthCost = nextRebirthCost,
		cashMult = cashMult,
		rebirthMult = Config.REBIRTH_INCOME_MULT(data.rebirths),
		infected = infected,
		infectedSecondsLeft = if infected then data.infectedUntil - os.time() else 0,
		infectionBombs = data.infectionBombs,
	})
end

function EconomyService.Init() end

return EconomyService
