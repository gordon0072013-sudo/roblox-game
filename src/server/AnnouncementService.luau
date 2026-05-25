--!strict
--[[
	AnnouncementService — broadcasts a rotating banner to all players. Add
	entries to the ANNOUNCEMENTS table for live-ops (codes drop, event
	starting, sale on a gamepass, milestone celebration). The client cycles
	through them in the top-bar ticker.

	Two ways to schedule: static list (recompiled into server) and runtime
	pushes via AnnouncementService.Push(text, color) from any service.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local AnnouncementService = {}

type Announcement = {
	text: string,
	color: { number },     -- {r,g,b} 0-255
	durationSeconds: number?,
}

local STATIC_ANNOUNCEMENTS: { Announcement } = {
	{ text = "🎟 New code: LAUNCH for 2,500 cash — type in 🎟 Codes tab", color = { 120, 220, 120 } },
	{ text = "🧠 Watch your brainrots MUTATE every ~90s for stronger forms", color = { 255, 100, 200 } },
	{ text = "🥷 Walk near a rival's lab and press E to STEAL their brainrots", color = { 255, 80, 80 } },
	{ text = "💣 Press Q near a rival to throw an INFECTION BOMB", color = { 80, 200, 100 } },
	{ text = "🌍 Climb the WEEKLY GLOBAL leaderboard — resets Sun 00:00 UTC", color = { 255, 215, 80 } },
	{ text = "🤝 Trade brainrots with other players in the 🤝 Trade tab", color = { 255, 180, 80 } },
	{ text = "👥 Join the group for permanent +25% cash income", color = { 200, 200, 255 } },
	{ text = "🔥 MEGA BOSS spawns every 45 min — coop kill for huge cash payout", color = { 255, 80, 80 } },
}

local runtimePushes: { Announcement } = {}

local function getRotation(): { Announcement }
	local combined = table.clone(STATIC_ANNOUNCEMENTS) :: { Announcement }
	for _, a in ipairs(runtimePushes) do
		table.insert(combined, 1, a)  -- runtime pushes go to the front
	end
	return combined
end

function AnnouncementService.Push(text: string, color: { number }?, durationSeconds: number?)
	local entry: Announcement = {
		text = text,
		color = color or { 255, 215, 80 },
		durationSeconds = durationSeconds or 60,
	}
	table.insert(runtimePushes, entry)
	-- Auto-expire
	if durationSeconds then
		task.delay(durationSeconds, function()
			for i, e in ipairs(runtimePushes) do
				if e == entry then table.remove(runtimePushes, i); break end
			end
		end)
	end
end

local idx = 1
local function broadcastNext()
	local rotation = getRotation()
	if #rotation == 0 then return end
	idx = ((idx) % #rotation) + 1
	local a = rotation[idx]
	for _, p in ipairs(Players:GetPlayers()) do
		Remotes.Event(Remotes.Names.AnnouncementShow):FireClient(p, a)
	end
end

function AnnouncementService.OnPlayerAdded(player: Player)
	local rotation = getRotation()
	if rotation[1] then
		Remotes.Event(Remotes.Names.AnnouncementShow):FireClient(player, rotation[1])
	end
end

function AnnouncementService.Init()
	task.spawn(function()
		while true do
			task.wait(20)
			broadcastNext()
		end
	end)
end

return AnnouncementService
