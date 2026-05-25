--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Util    = require(Shared.Util)
local Remotes = require(Shared.Remotes)
local Log     = require(Shared.Log)

local DataService    = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local LoginStreakService = {}

-- Distinct from DailyRewardService (which is a 7-day chest cycle the
-- player claims). LoginStreak is silent compounding: just by logging in
-- on consecutive UTC days the player accumulates a streak that is *also*
-- displayed in the HUD. Every 7-day streak milestone (7/14/30/60/100)
-- awards a notable cash bonus.

local MILESTONES = { [7] = 5000, [14] = 15000, [30] = 50000, [60] = 150000, [100] = 500000 }

local function ensure(data: any)
	data._streak = data._streak or {
		count = 0,
		lastDay = 0,
		highest = 0,
	}
end

function LoginStreakService.GetStreak(player: Player): number
	local data = DataService.Get(player)
	if not data then return 0 end
	ensure(data)
	return data._streak.count
end

function LoginStreakService.OnPlayerAdded(player: Player)
	DataService.OnProfileLoaded(player, function()
		local data = DataService.Get(player)
		if not data then return end
		ensure(data)
		local today = Util.DayIndex()
		if data._streak.lastDay == today then return end
		if data._streak.lastDay == today - 1 then
			data._streak.count += 1
		else
			data._streak.count = 1
		end
		data._streak.lastDay = today
		if data._streak.count > data._streak.highest then
			data._streak.highest = data._streak.count
		end
		local bonus = MILESTONES[data._streak.count]
		if bonus then
			EconomyService.AwardCash(player, bonus, `${data._streak.count}-day streak`)
			Remotes.Event(Remotes.Names.Notify):FireClient(player, {
				kind = "capture",
				text = string.format("🔥 %d-day streak — bonus +%s cash!",
					data._streak.count, Util.FormatShortNumber(bonus)),
			})
		else
			Remotes.Event(Remotes.Names.Notify):FireClient(player, {
				kind = "info",
				text = string.format("🔥 Day %d streak — keep it going!", data._streak.count),
			})
		end
		Log.Info("Streak", "%s day=%d (highest=%d)", player.Name, data._streak.count, data._streak.highest)
	end)
end

function LoginStreakService.Init() end

return LoginStreakService
