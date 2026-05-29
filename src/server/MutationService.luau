--!strict
--[[
	MutationService — the novel mechanic. Every placed brainrot rolls for a
	mutation tier-up on a per-brainrot interval. Each successful roll picks
	a mutation from MutationData, appends it to the chain, and rebuilds the
	visual so the player SEES the change.

	The interval is gated by the 2x Mutation Speed gamepass.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(Shared.Config)
local MutationData = require(Shared.MutationData)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local LabService = require(script.Parent.LabService)
local BattlePassService -- forward
local BadgeService -- forward

local MutationService = {}

local rng = Random.new()

local function intervalForPlayer(player: Player): number
	local data = DataService.Get(player)
	if not data then return Config.MUTATION_INTERVAL end
	local interval = Config.MUTATION_INTERVAL
	if data.gamepasses["MutationSpeed2x"] then
		interval = interval / Config.MUTATION_GAMEPASS_SPEED_MULT
	end
	local okPet, PetService = pcall(require, script.Parent.PetService)
	if okPet then
		local petMult = PetService.GetMutationSpeedMult(player)
		if petMult > 1 then interval = interval / petMult end
	end
	local okHour, TopOfHourService = pcall(require, script.Parent.TopOfHourService)
	if okHour then
		local hourMult = TopOfHourService.GetMutationMult()
		if hourMult > 1 then interval = interval / hourMult end
	end
	local okEvt, EventService = pcall(require, script.Parent.EventService)
	if okEvt then
		local eventMult = EventService.GetMutationSpeedMult()
		if eventMult > 1 then interval = interval / eventMult end
	end
	local okBf, BuffService = pcall(require, script.Parent.BuffService)
	if okBf then
		local buffMult = BuffService.GetMutationMult(player)
		if buffMult > 1 then interval = interval / buffMult end
	end
	return interval
end

local function rollOne(player: Player, brainrotUid: string)
	local data = DataService.Get(player)
	if not data then return end
	for _, b in ipairs(data.inventory) do
		if b.uid == brainrotUid then
			if b.mutationTier >= Config.MUTATION_MAX_TIER then return end
			local luckyBias = if data.gamepasses["LuckyMutations"] then Config.MUTATION_LUCKY_RARITY_BIAS else 0
			local mutation = MutationData.RollMutation(rng, luckyBias)
			b.mutationTier += 1
			table.insert(b.mutations, mutation.id)
			b.lastMutationAt = os.time()
			data.stats.totalMutations += 1
			LabService.RebuildBrainrotVisual(player, b.uid)
			LabService.PushInventory(player)
			Remotes.Event(Remotes.Names.Notify):FireClient(player, {
				kind = "mutation",
				text = `${mutation.suffix}! T${b.mutationTier}`,
			})
			if BattlePassService then
				BattlePassService.AwardXp(player, "mutation")
			end
			local okL, PlayerLevelService = pcall(require, script.Parent.PlayerLevelService)
			if okL then PlayerLevelService.AwardXp(player, "mutation") end
			if BadgeService then
				if data.stats.totalMutations == 1 then
					BadgeService.Fire(player, "first_mutation")
				end
				if b.mutationTier >= Config.MUTATION_MAX_TIER then
					BadgeService.Fire(player, "apex_mutation")
				end
			end
			if b.mutationTier >= Config.MUTATION_MAX_TIER then
				local okC, CinematicService = pcall(require, script.Parent.CinematicService)
				if okC then
					CinematicService.Play(player, {
						kind = "apex_mutation",
						title = "APEX MUTATION",
						subtitle = mutation.suffix .. " achieved",
						color = { 255, 60, 60 },
						durationSeconds = 4,
					})
				end
			end
			return
		end
	end
end

function MutationService.ForceInstantMutation(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	-- Pick a placed brainrot still below max tier; prefer the one with the highest tier (rarity climb)
	local target
	for _, b in ipairs(data.inventory) do
		if b.placed and b.mutationTier < Config.MUTATION_MAX_TIER then
			if not target or b.mutationTier > target.mutationTier then
				target = b
			end
		end
	end
	if target then
		rollOne(player, target.uid)
	end
end

function MutationService.Init()
	BattlePassService = require(script.Parent.BattlePassService)
	BadgeService = require(script.Parent.BadgeService)
	task.spawn(function()
		while true do
			for _, player in ipairs(Players:GetPlayers()) do
				local data = DataService.Get(player)
				if data then
					local interval = intervalForPlayer(player)
					for _, b in ipairs(data.inventory) do
						if b.placed and b.mutationTier < Config.MUTATION_MAX_TIER then
							if os.time() - b.lastMutationAt >= interval then
								rollOne(player, b.uid)
							end
						end
					end
				end
			end
			task.wait(1)
		end
	end)
end

return MutationService
