--!strict
--[[
	GroupRewardService — checks if the player is a member of Config.GROUP_ID
	on join and on demand (after they click "Join Group" in the banner).
	Group members get a permanent +25% cash income mult, which encourages
	join → encourages Premium-eligible community → encourages Premium Payouts.
]]

local GroupService = game:GetService("GroupService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local GroupRewardService = {}

local function isInGroup(player: Player): boolean
	if Config.GROUP_ID <= 0 then return false end
	local ok, inGroup = pcall(function()
		return player:IsInGroup(Config.GROUP_ID)
	end)
	return ok and inGroup
end

function GroupRewardService.Check(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	local prev = (data :: any)._inGroup == true
	local now = isInGroup(player)
	;(data :: any)._inGroup = now
	if now and not prev then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, {
			kind = "capture",
			text = `Group member +${math.floor((Config.GROUP_REWARD_MULT - 1) * 100)}% cash unlocked!`,
		})
	end
	EconomyService.PushHud(player)
end

function GroupRewardService.OnPlayerAdded(player: Player)
	task.delay(2, GroupRewardService.Check, player)
end

function GroupRewardService.Init()
	-- Re-check every 3 minutes so newly-joined members get rewarded without
	-- needing to rejoin the server.
	task.spawn(function()
		while true do
			task.wait(180)
			for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
				GroupRewardService.Check(p)
			end
		end
	end)

	-- Suppress unused-import lint
	local _ = GroupService
end

return GroupRewardService
