--!strict
--[[
	Server bootstrap — orders the service Init calls so dependencies are
	satisfied before they're used, then wires PlayerAdded/Removing fanout.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

-- Create remote folder up-front so clients don't race.
Remotes.InitServer()

local DataService = require(script.DataService)
local EconomyService = require(script.EconomyService)
local LabService = require(script.LabService)
local CaptureService = require(script.CaptureService)
local MutationService = require(script.MutationService)
local StealService = require(script.StealService)
local InfectionService = require(script.InfectionService)
local OutbreakService = require(script.OutbreakService)
local MonetizationService = require(script.MonetizationService)
local BattlePassService = require(script.BattlePassService)
local DailyRewardService = require(script.DailyRewardService)
local LeaderboardService = require(script.LeaderboardService)
local AnalyticsService = require(script.AnalyticsService)
local CodeService = require(script.CodeService)
local GroupRewardService = require(script.GroupRewardService)
local TrailService = require(script.TrailService)
local AchievementService = require(script.AchievementService)

-- Init order: data first, content next, monetization/UI services last.
DataService.Init()
EconomyService.Init()
LabService.Init()
CaptureService.Init()
BattlePassService.Init()
DailyRewardService.Init()
MutationService.Init()
InfectionService.Init()
StealService.Init()
OutbreakService.Init()
MonetizationService.Init()
LeaderboardService.Init()
AnalyticsService.Init()
CodeService.Init()
GroupRewardService.Init()
TrailService.Init()
AchievementService.Init()

local function onPlayerAdded(player: Player)
	DataService.LoadProfile(player)
	-- Profile loaded callbacks already wired; downstream services need the data.
	DataService.OnProfileLoaded(player, function()
		LabService.OnPlayerAdded(player)
		StealService.OnPlayerAdded(player)
		MonetizationService.OnPlayerAdded(player)
		OutbreakService.OnPlayerAdded(player)
		BattlePassService.OnPlayerAdded(player)
		DailyRewardService.OnPlayerAdded(player)
		GroupRewardService.OnPlayerAdded(player)
		TrailService.OnPlayerAdded(player)
		AchievementService.OnPlayerAdded(player)
		EconomyService.PushHud(player)
	end)
end

local function onPlayerRemoving(player: Player)
	LabService.OnPlayerRemoving(player)
	StealService.OnPlayerRemoving(player)
	DataService.ReleaseProfile(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, p)
end

-- ============================================================
-- Remote request handlers
-- ============================================================
local function handler(name: string, fn: (Player, ...any) -> ())
	Remotes.Event(name).OnServerEvent:Connect(function(player, ...)
		local ok, err = pcall(fn, player, ...)
		if not ok then warn(`[Remote ${name}] ${err}`) end
	end)
end

handler(Remotes.Names.RequestCapture, function(player)
	CaptureService.AttemptCapture(player)
end)

handler(Remotes.Names.RequestPlaceBrainrot, function(player, uid)
	if typeof(uid) == "string" then LabService.PlaceBrainrot(player, uid) end
end)

handler(Remotes.Names.RequestUnplaceBrainrot, function(player, uid)
	if typeof(uid) == "string" then LabService.UnplaceBrainrot(player, uid) end
end)

handler(Remotes.Names.RequestSellBrainrot, function(player, uid)
	if typeof(uid) == "string" then LabService.SellBrainrot(player, uid) end
end)

handler(Remotes.Names.RequestRebirth, function(player)
	EconomyService.TryRebirth(player)
end)

handler(Remotes.Names.RequestSteal, function(player, victimUserId, uid)
	if typeof(victimUserId) == "number" and typeof(uid) == "string" then
		StealService.AttemptSteal(player, victimUserId, uid)
	end
end)

handler(Remotes.Names.RequestInfect, function(player, victimUserId)
	if typeof(victimUserId) == "number" then
		InfectionService.AttemptInfect(player, victimUserId)
	end
end)

handler(Remotes.Names.RequestClaimDaily, function(player)
	DailyRewardService.Claim(player)
end)

handler(Remotes.Names.RequestClaimBattlePassTier, function(player, tier)
	if typeof(tier) == "number" then
		BattlePassService.ClaimTier(player, tier)
	end
end)

handler(Remotes.Names.RequestPromptPurchase, function(player, kind, key)
	if typeof(kind) == "string" and typeof(key) == "string" then
		MonetizationService.PromptPurchase(player, kind, key)
	end
end)

handler(Remotes.Names.RequestRedeemCode, function(player, code)
	if typeof(code) == "string" then CodeService.Redeem(player, code) end
end)

handler(Remotes.Names.RequestRecheckGroup, function(player)
	GroupRewardService.Check(player)
end)

handler(Remotes.Names.RequestClaimAchievement, function(player, id)
	if typeof(id) == "string" then AchievementService.Claim(player, id) end
end)

print("[BrainrotLab] Server boot complete.")
