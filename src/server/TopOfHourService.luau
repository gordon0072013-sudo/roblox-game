--!strict

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared.Log)

local AnnouncementService -- forward

local TopOfHourService = {}

-- Predictable 5-minute event every hour on the hour (HH:00 - HH:05 UTC).
-- Players know exactly when to log in. Combined with daily reward and
-- HotStreak this creates 24 daily engagement windows / day.

local EVENT_DURATION = 300

local activeUntil = 0
local currentMult = 1

local EVENT_TYPES = {
	{ label = "💰 GOLDEN HOUR — 3x cash for 5 minutes!",     color = { 255, 215, 80 },  cashMult = 3.0 },
	{ label = "🧬 MUTATION RUSH — 4x mutation speed for 5 minutes!", color = { 255, 100, 220 }, cashMult = 1.5, mutationMult = 4.0 },
	{ label = "🎰 SPIN HOUR — every player gets 1 free wheel spin!",  color = { 120, 220, 255 }, cashMult = 1.5, freeSpins = 1 },
}

local currentEvent: any = nil

local function startEvent()
	currentEvent = EVENT_TYPES[math.random(1, #EVENT_TYPES)]
	activeUntil = os.time() + EVENT_DURATION
	currentMult = currentEvent.cashMult or 1
	if AnnouncementService then
		AnnouncementService.Push(currentEvent.label, currentEvent.color, EVENT_DURATION)
	end

	-- Grant any one-time perks declared by this event
	if currentEvent.freeSpins then
		local ok, LuckyWheelService = pcall(require, script.Parent.LuckyWheelService)
		if ok then
			for _, p in ipairs(Players:GetPlayers()) do
				LuckyWheelService.GrantSpins(p, currentEvent.freeSpins)
			end
		end
	end

	Log.Info("TopOfHour", "%s for %ds", currentEvent.label, EVENT_DURATION)
end

local function endEvent()
	currentEvent = nil
	currentMult = 1
	activeUntil = 0
end

function TopOfHourService.GetCashMult(): number
	if os.time() < activeUntil then return currentMult end
	return 1
end

function TopOfHourService.GetMutationMult(): number
	if os.time() < activeUntil and currentEvent and currentEvent.mutationMult then
		return currentEvent.mutationMult
	end
	return 1
end

function TopOfHourService.GetActive(): any?
	if os.time() < activeUntil then return currentEvent end
	return nil
end

function TopOfHourService.Init()
	AnnouncementService = require(script.Parent.AnnouncementService)
	task.spawn(function()
		while true do
			task.wait(5)
			local now = os.time()
			local minute = math.floor(now / 60) % 60
			local second = now % 60
			if activeUntil > 0 and now >= activeUntil then
				endEvent()
			elseif activeUntil == 0 and minute == 0 and second < 6 then
				startEvent()
				task.wait(10) -- avoid double-trigger within the same minute
			end
		end
	end)
end

return TopOfHourService
