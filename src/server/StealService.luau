--!strict
--[[
	StealService — the PvP "raid" mechanic. An attacker standing within
	STEAL_DETECTION_RADIUS of a rival's placed brainrot can fire a
	RequestSteal remote with the brainrot uid. If cooldown + tier-delta
	checks pass, the brainrot transfers to the attacker's inventory.

	Defensive constraints (revenue-protecting):
	  * Grace period for new joiners
	  * Per-attacker per-victim cooldown
	  * Tier delta cap (can't steal mythic with a fresh account)
	  * VIP / InfectionShield gamepass holders get partial steal protection
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local BrainrotData = require(Shared.BrainrotData)

local DataService = require(script.Parent.DataService)
local LabService = require(script.Parent.LabService)
local BattlePassService -- forward

local StealService = {}

-- attacker userId -> victim userId -> last steal time (os.clock)
local cooldowns: { [number]: { [number]: number } } = {}
local joinTimes: { [Player]: number } = {}

local function bestTier(player: Player): number
	local data = DataService.Get(player)
	if not data then return 0 end
	local best = 0
	for _, b in ipairs(data.inventory) do
		if b.mutationTier > best then best = b.mutationTier end
	end
	return best
end

local function playerNear(attacker: Player, brainrotModel: Model): boolean
	local char = attacker.Character
	if not char then return false end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return false end
	local body = brainrotModel.PrimaryPart
	if not body then return false end
	local d = (hrp.Position - body.Position).Magnitude
	return d <= Config.STEAL_DETECTION_RADIUS
end

function StealService.AttemptSteal(attacker: Player, victimUserId: number, brainrotUid: string)
	if attacker.UserId == victimUserId then return end
	local victim = Players:GetPlayerByUserId(victimUserId)
	if not victim then
		Remotes.Event(Remotes.Names.Notify):FireClient(attacker, { kind="error", text="Target left the server." })
		return
	end

	-- Grace period
	if joinTimes[victim] and os.clock() - joinTimes[victim] < Config.STEAL_GRACE_PERIOD_AFTER_JOIN then
		Remotes.Event(Remotes.Names.Notify):FireClient(attacker, { kind="error", text="Target is in grace period." })
		return
	end

	-- Cooldown
	local atk = cooldowns[attacker.UserId]
	if atk and atk[victimUserId] and os.clock() - atk[victimUserId] < Config.STEAL_COOLDOWN then
		local rem = Config.STEAL_COOLDOWN - (os.clock() - atk[victimUserId])
		Remotes.Event(Remotes.Names.Notify):FireClient(attacker, { kind="error", text=`Cooldown: {math.ceil(rem)}s` })
		return
	end

	-- VIP / InfectionShield partial protection — 50% chance to fully resist
	local victimData = DataService.Get(victim)
	if victimData and (victimData.gamepasses["InfectionShield"] or victimData.gamepasses["VIPLab"]) then
		if math.random() < 0.5 then
			Remotes.Event(Remotes.Names.Notify):FireClient(attacker, { kind="error", text="Their security blocked you." })
			Remotes.Event(Remotes.Names.Notify):FireClient(victim, { kind="info", text=`{attacker.DisplayName} tried to raid you — blocked!` })
			cooldowns[attacker.UserId] = cooldowns[attacker.UserId] or {}
			cooldowns[attacker.UserId][victimUserId] = os.clock()
			return
		end
	end

	-- Find the brainrot and its placed model
	local models = LabService.GetPlacedModels(victim)
	local model = models[brainrotUid]
	if not model then
		Remotes.Event(Remotes.Names.Notify):FireClient(attacker, { kind="error", text="Brainrot not on plot." })
		return
	end

	-- Proximity
	if not playerNear(attacker, model) then
		Remotes.Event(Remotes.Names.Notify):FireClient(attacker, { kind="error", text="Get closer to it." })
		return
	end

	-- Tier delta check
	if not victimData then return end
	local target
	for _, b in ipairs(victimData.inventory) do
		if b.uid == brainrotUid then target = b; break end
	end
	if not target then return end
	local myBest = bestTier(attacker)
	if target.mutationTier > myBest + Config.STEAL_MAX_TIER_DELTA then
		Remotes.Event(Remotes.Names.Notify):FireClient(attacker, { kind="error", text="Too high tier — mutate yours first." })
		return
	end

	-- Execute
	cooldowns[attacker.UserId] = cooldowns[attacker.UserId] or {}
	cooldowns[attacker.UserId][victimUserId] = os.clock()
	if LabService.TransferBrainrot(victim, attacker, brainrotUid) then
		local atkData = DataService.Get(attacker)
		if atkData then atkData.stats.totalSteals += 1 end
		local def = BrainrotData.Get(target.speciesId)
		Remotes.Event(Remotes.Names.Notify):FireClient(attacker, {
			kind="capture",
			text=`STOLE {def and def.displayName or "brainrot"}!`,
		})
		Remotes.Event(Remotes.Names.Notify):FireClient(victim, {
			kind="error",
			text=`{attacker.DisplayName} stole your {def and def.displayName or "brainrot"}!`,
		})
		if BattlePassService then
			BattlePassService.AwardXp(attacker, "steal")
		end
		local ok, BadgeService = pcall(require, script.Parent.BadgeService)
		if ok and atkData and atkData.stats.totalSteals == 1 then
			BadgeService.Fire(attacker, "first_steal")
		end
		local okL, PlayerLevelService = pcall(require, script.Parent.PlayerLevelService)
		if okL then PlayerLevelService.AwardXp(attacker, "steal") end
	end
end

function StealService.OnPlayerAdded(player: Player)
	joinTimes[player] = os.clock()
end

function StealService.OnPlayerRemoving(player: Player)
	joinTimes[player] = nil
	cooldowns[player.UserId] = nil
	for _, t in pairs(cooldowns) do
		t[player.UserId] = nil
	end
end

function StealService.Init()
	BattlePassService = require(script.Parent.BattlePassService)
end

return StealService
