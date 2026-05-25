--!strict

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Util    = require(Shared.Util)
local Log     = require(Shared.Log)

local EventService = {}

-- Limited-time events are the strongest FOMO lever in the Roblox tycoon
-- meta. We schedule them by absolute timestamps so all servers see the
-- same window simultaneously. Add entries here when you want to push a
-- live-ops moment; the client auto-picks up state via the EventUpdate remote.

type EventDefinition = {
	id: string,
	name: string,
	bannerColor: { number },     -- {r,g,b}
	startTs: number,             -- unix time
	endTs: number,
	cashMult: number?,            -- global cash mult for participants
	mutationSpeedMult: number?,   -- multiplier on mutation cadence
	luckyBoost: number?,          -- biases capture/pet rolls
}

local EVENTS: { EventDefinition } = {}

local function nowSec(): number return os.time() end

local function buildDefaults()
	-- Default rolling event: a 48-hour "Launch Hype" double-cash window
	-- starting at the moment the server boots. Replace with hardcoded
	-- timestamps to lock specific events to wall-clock weekends.
	local now = nowSec()
	table.insert(EVENTS, {
		id = "launch_hype",
		name = "🚀 LAUNCH HYPE — 2x cash for everyone",
		bannerColor = { 255, 100, 200 },
		startTs = now,
		endTs   = now + 48 * 3600,
		cashMult = 2.0,
	})
	table.insert(EVENTS, {
		id = "weekend_mutation",
		name = "🧬 WEEKEND MUTATION — 3x mutation speed",
		bannerColor = { 120, 220, 255 },
		startTs = now + 7 * 86400,
		endTs   = now + 9 * 86400,
		mutationSpeedMult = 3.0,
	})
end

local function activeEvents(): { EventDefinition }
	local out: { EventDefinition } = {}
	local now = nowSec()
	for _, e in ipairs(EVENTS) do
		if now >= e.startTs and now < e.endTs then
			table.insert(out, e)
		end
	end
	return out
end

function EventService.GetCashMult(): number
	local m = 1
	for _, e in ipairs(activeEvents()) do
		if e.cashMult then m *= e.cashMult end
	end
	return m
end

function EventService.GetMutationSpeedMult(): number
	local m = 1
	for _, e in ipairs(activeEvents()) do
		if e.mutationSpeedMult then m *= e.mutationSpeedMult end
	end
	return m
end

function EventService.GetLuckyBoost(): number
	local b = 0
	for _, e in ipairs(activeEvents()) do
		if e.luckyBoost then b += e.luckyBoost end
	end
	return b
end

local function broadcast()
	local payload = {
		active = activeEvents(),
		upcoming = nil :: any,
	}
	-- Pick next-upcoming event for the "coming soon" banner.
	local now = nowSec()
	local nearest
	for _, e in ipairs(EVENTS) do
		if e.startTs > now then
			if not nearest or e.startTs < nearest.startTs then
				nearest = e
			end
		end
	end
	payload.upcoming = nearest

	for _, p in ipairs(Players:GetPlayers()) do
		Remotes.Event(Remotes.Names.EventUpdate):FireClient(p, payload)
	end
end

function EventService.OnPlayerAdded(_: Player)
	task.delay(2, broadcast)
end

function EventService.Init()
	buildDefaults()
	Remotes.Event(Remotes.Names.EventUpdate)
	task.spawn(function()
		while true do
			task.wait(20)
			broadcast()
		end
	end)
	Log.Info("Events", "%d events scheduled", #EVENTS)
	local _ = Util
end

return EventService
