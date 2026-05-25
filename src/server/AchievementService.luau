--!strict
--[[
	AchievementService — tracks progress (read from profile.stats and
	profile.rebirths), delivers rewards on claim. Pushes an update to the
	client whenever progress crosses a threshold or a claim is made.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)
local AchievementData = require(Shared.AchievementData)

local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local InfectionService -- forward
local CaptureService -- forward
local MutationService -- forward

local AchievementService = {}

local function statValue(data: any, key: string): number
	if key == "rebirths" then return data.rebirths or 0 end
	return (data.stats and data.stats[key]) or 0
end

local function deliver(player: Player, reward: any)
	if reward.kind == "cash" then
		EconomyService.AwardCash(player, reward.amount or 0, "achievement")
	elseif reward.kind == "infection_bomb" then
		InfectionService.AddBombs(player, reward.amount or 1)
	elseif reward.kind == "rare_egg" then
		CaptureService.AttemptCapture(player, { freeRare = true, count = reward.amount or 1 })
	elseif reward.kind == "instant_mutation" then
		for _ = 1, (reward.amount or 1) do
			MutationService.ForceInstantMutation(player)
		end
	end
end

function AchievementService.Push(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	local list = AchievementData.GetAll()
	;(data :: any)._achievements = (data :: any)._achievements or {}
	local claimed = (data :: any)._achievements :: { [string]: boolean }
	local payload = {}
	for _, a in ipairs(list) do
		local progress = statValue(data, a.statKey)
		table.insert(payload, {
			id = a.id,
			name = a.name,
			description = a.description,
			target = a.target,
			progress = progress,
			complete = progress >= a.target,
			claimed = claimed[a.id] == true,
			rewardKind = a.reward.kind,
			rewardAmount = a.reward.amount,
		})
	end
	Remotes.Event(Remotes.Names.AchievementUpdate):FireClient(player, payload)
end

function AchievementService.Claim(player: Player, id: string)
	local data = DataService.Get(player)
	if not data then return end
	local a = AchievementData.Get(id)
	if not a then return end
	;(data :: any)._achievements = (data :: any)._achievements or {}
	local claimed = (data :: any)._achievements :: { [string]: boolean }
	if claimed[id] then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text="Already claimed." })
		return
	end
	if statValue(data, a.statKey) < a.target then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text="Not finished yet." })
		return
	end
	claimed[id] = true
	deliver(player, a.reward)
	Remotes.Event(Remotes.Names.Notify):FireClient(player, {
		kind = "capture",
		text = `🏅 Achievement: ${a.name}`,
	})
	AchievementService.Push(player)
end

function AchievementService.OnPlayerAdded(player: Player)
	task.delay(2, AchievementService.Push, player)
end

function AchievementService.Init()
	InfectionService = require(script.Parent.InfectionService)
	CaptureService = require(script.Parent.CaptureService)
	MutationService = require(script.Parent.MutationService)

	-- periodic push so progress bars update without manual triggers
	task.spawn(function()
		while true do
			task.wait(8)
			for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
				AchievementService.Push(p)
			end
		end
	end)
end

return AchievementService
