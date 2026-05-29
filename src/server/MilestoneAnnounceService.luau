--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Log     = require(Shared.Log)

local AnnouncementService -- forward

local MilestoneAnnounceService = {}

-- Watches the same hook points that fire badges, but instead of awarding
-- the badge to the achieving player, it shouts to the *whole server* so
-- everyone sees the social proof. Compounding effect: seeing "Mark just
-- hit Rebirth 5" is the cheapest in-game motivator there is.

local REBIRTH_TIERS = { 1, 3, 5, 10, 25, 50 }
local CAPTURE_TIERS = { 100, 500, 1000 }

local lastFiredFor: { [string]: { [number]: boolean } } = {}

local function fire(player: Player, kind: string, milestone: number, text: string, color: { number })
	lastFiredFor[kind] = lastFiredFor[kind] or {}
	if lastFiredFor[kind][player.UserId] == nil then
		lastFiredFor[kind][player.UserId] = true
	end
	if not AnnouncementService then return end
	AnnouncementService.Push(text, color, 12)
	-- Also fire a Notify to the achieving player so they get a personal toast
	Remotes.Event(Remotes.Names.Notify):FireClient(player, {
		kind = "capture",
		text = `🎉 Server-wide shoutout: {text}`,
	})
	Log.Info("Milestone", "%s %s %d", player.Name, kind, milestone)
end

local watchedProfiles: { [Player]: { rebirths: number, captures: number } } = {}

local function snapshot(player: Player)
	local DataService = require(script.Parent.DataService)
	local data = DataService.Get(player)
	if not data then return end
	local snap = watchedProfiles[player] or { rebirths = 0, captures = 0 }
	watchedProfiles[player] = snap

	for _, tier in ipairs(REBIRTH_TIERS) do
		if data.rebirths == tier and snap.rebirths < tier then
			fire(player, "rebirth", tier,
				string.format("🚀 %s reached Rebirth %d!", player.DisplayName, tier),
				{ 255, 100, 220 })
		end
	end
	for _, tier in ipairs(CAPTURE_TIERS) do
		if data.stats.totalCaptured >= tier and snap.captures < tier then
			fire(player, "captures", tier,
				string.format("🧠 %s has captured %d brainrots!", player.DisplayName, tier),
				{ 120, 220, 255 })
		end
	end
	snap.rebirths = data.rebirths
	snap.captures = data.stats.totalCaptured
end

function MilestoneAnnounceService.OnPlayerAdded(player: Player)
	watchedProfiles[player] = { rebirths = 0, captures = 0 }
end

function MilestoneAnnounceService.OnPlayerRemoving(player: Player)
	watchedProfiles[player] = nil
end

function MilestoneAnnounceService.Init()
	AnnouncementService = require(script.Parent.AnnouncementService)
	task.spawn(function()
		while true do
			task.wait(5)
			for _, p in ipairs(Players:GetPlayers()) do
				snapshot(p)
			end
		end
	end)
end

return MilestoneAnnounceService
