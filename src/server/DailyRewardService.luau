--!strict
--[[
	DailyRewardService — 7-day cycle, Premium players get bonus on day 7.
	Streak resets if a day is skipped.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(Shared.Config)
local Util = require(Shared.Util)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local InfectionService -- forward
local CaptureService -- forward

local DailyRewardService = {}

local function pushUpdate(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	local today = Util.DayIndex()
	local canClaim = data.dailyReward.lastClaimDay < today
	Remotes.Event(Remotes.Names.DailyRewardUpdate):FireClient(player, {
		streak = data.dailyReward.streak,
		canClaim = canClaim,
		rewards = Config.DAILY_REWARDS,
		isPremium = player.MembershipType == Enum.MembershipType.Premium,
	})
end

function DailyRewardService.Claim(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	local today = Util.DayIndex()
	if data.dailyReward.lastClaimDay >= today then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text="Already claimed today." })
		return
	end
	local streak = data.dailyReward.streak
	if data.dailyReward.lastClaimDay == today - 1 then
		streak += 1
	else
		streak = 1
	end
	if streak > #Config.DAILY_REWARDS then streak = 1 end
	data.dailyReward.streak = streak
	data.dailyReward.lastClaimDay = today
	local r = Config.DAILY_REWARDS[streak]
	if r.kind == "cash" then
		EconomyService.AwardCash(player, r.amount, `daily reward day ${streak}`)
		if r.premium_bonus and player.MembershipType == Enum.MembershipType.Premium then
			EconomyService.AwardCash(player, r.premium_bonus, "Premium bonus")
		end
	elseif r.kind == "infection_bomb" then
		InfectionService.AddBombs(player, r.amount)
	elseif r.kind == "rare_egg" then
		CaptureService.AttemptCapture(player, { freeRare = true, count = r.amount or 1 })
	end
	pushUpdate(player)
end

function DailyRewardService.OnPlayerAdded(player: Player)
	task.delay(1.5, pushUpdate, player)
end

function DailyRewardService.Init()
	InfectionService = require(script.Parent.InfectionService)
	CaptureService = require(script.Parent.CaptureService)
end

return DailyRewardService
