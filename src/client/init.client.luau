--!strict
--[[
	Client bootstrap — instantiates ScreenGui hierarchy, then hands off to
	individual UI controllers.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

local screen = Instance.new("ScreenGui")
screen.Name = "BrainrotLabUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.Parent = playerGui

local UIController = require(script.UIController)
UIController.Init(screen)

local HUD = require(script.HUD)
HUD.Init(screen)

local ShopUI = require(script.ShopUI)
ShopUI.Init(screen, UIController)

local InventoryUI = require(script.InventoryUI)
InventoryUI.Init(screen, UIController)

local LeaderboardUI = require(script.LeaderboardUI)
LeaderboardUI.Init(screen, UIController)

local OutbreakUI = require(script.OutbreakUI)
OutbreakUI.Init(screen)

local BattlePassUI = require(script.BattlePassUI)
BattlePassUI.Init(screen, UIController)

local DailyRewardUI = require(script.DailyRewardUI)
DailyRewardUI.Init(screen, UIController)

local NotificationUI = require(script.NotificationUI)
NotificationUI.Init(screen)

local PlotUI = require(script.PlotUI)
PlotUI.Init(screen)

local CodeRedeemUI = require(script.CodeRedeemUI)
CodeRedeemUI.Init(screen, UIController)

local GroupBannerUI = require(script.GroupBannerUI)
GroupBannerUI.Init(screen)

local TutorialUI = require(script.TutorialUI)
TutorialUI.Init(screen)

local AchievementUI = require(script.AchievementUI)
AchievementUI.Init(screen, UIController)

local QuestUI = require(script.QuestUI)
QuestUI.Init(screen, UIController)

local TradeUI = require(script.TradeUI)
TradeUI.Init(screen, UIController)

local GlobalLeaderboardUI = require(script.GlobalLeaderboardUI)
GlobalLeaderboardUI.Init(screen, UIController)

local BossUI = require(script.BossUI)
BossUI.Init(screen)

local AnnouncementUI = require(script.AnnouncementUI)
AnnouncementUI.Init(screen)

local PetUI = require(script.PetUI)
PetUI.Init(screen, UIController)

local LevelUI = require(script.LevelUI)
LevelUI.Init(screen, UIController)

local PatchNotesUI = require(script.PatchNotesUI)
PatchNotesUI.Init(screen, UIController)

local DecorationUI = require(script.DecorationUI)
DecorationUI.Init(screen, UIController)

local InviteUI = require(script.InviteUI)
InviteUI.Init(screen, UIController)

local AdminPanelUI = require(script.AdminPanelUI)
AdminPanelUI.Init(screen)

local WelcomeOfferUI = require(script.WelcomeOfferUI)
WelcomeOfferUI.Init(screen)

local LuckyWheelUI = require(script.LuckyWheelUI)
LuckyWheelUI.Init(screen, UIController)

local CinematicUI = require(script.CinematicUI)
CinematicUI.Init(screen)

local AutoSellUI = require(script.AutoSellUI)
AutoSellUI.Init(screen, UIController)

local NextEventUI = require(script.NextEventUI)
NextEventUI.Init(screen)

local SpectateController = require(script.SpectateController)
SpectateController.Init(screen)

local LoadingScreen = require(script.LoadingScreen)
LoadingScreen.Init()

local SoundController = require(script.SoundController)
SoundController.Init()

print("[BrainrotLab] Client ready.")
