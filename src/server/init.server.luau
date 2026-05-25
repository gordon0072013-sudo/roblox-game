--!strict

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared  = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Log     = require(Shared.Log)

Remotes.InitServer()

local AntiCheat               = require(script.AntiCheat)
local DataService             = require(script.DataService)
local EconomyService          = require(script.EconomyService)
local LabService              = require(script.LabService)
local CaptureService          = require(script.CaptureService)
local MutationService         = require(script.MutationService)
local StealService            = require(script.StealService)
local InfectionService        = require(script.InfectionService)
local OutbreakService         = require(script.OutbreakService)
local MonetizationService     = require(script.MonetizationService)
local BattlePassService       = require(script.BattlePassService)
local DailyRewardService      = require(script.DailyRewardService)
local LeaderboardService      = require(script.LeaderboardService)
local AnalyticsService        = require(script.AnalyticsService)
local CodeService             = require(script.CodeService)
local GroupRewardService      = require(script.GroupRewardService)
local TrailService            = require(script.TrailService)
local AchievementService      = require(script.AchievementService)
local QuestService            = require(script.QuestService)
local TradeService            = require(script.TradeService)
local BadgeService            = require(script.BadgeService)
local GlobalLeaderboardService= require(script.GlobalLeaderboardService)
local AfkService              = require(script.AfkService)
local BossEventService        = require(script.BossEventService)
local AnnouncementService     = require(script.AnnouncementService)
local PetService              = require(script.PetService)
local PlayerLevelService      = require(script.PlayerLevelService)
local SeasonService           = require(script.SeasonService)
local DecorationService       = require(script.DecorationService)
local InviteService           = require(script.InviteService)
local WebhookService          = require(script.WebhookService)
local AdminService            = require(script.AdminService)
local OfflineCashService      = require(script.OfflineCashService)
local WelcomeOfferService     = require(script.WelcomeOfferService)
local LuckyWheelService       = require(script.LuckyWheelService)
local SocialInviteService     = require(script.SocialInviteService)
local HotStreakService        = require(script.HotStreakService)
local PresenceService         = require(script.PresenceService)
local EventService            = require(script.EventService)
local CinematicService        = require(script.CinematicService)
local MilestoneAnnounceService= require(script.MilestoneAnnounceService)
local VipServerService        = require(script.VipServerService)
local AutoSellService         = require(script.AutoSellService)
local PerformanceService      = require(script.PerformanceService)
local CrossServerShoutService = require(script.CrossServerShoutService)
local FusionService           = require(script.FusionService)
local TopOfHourService        = require(script.TopOfHourService)
local DailyDealService        = require(script.DailyDealService)
local LoginStreakService      = require(script.LoginStreakService)

-- Boot order is significant: persistence first, content domain next,
-- monetization and observability last so they can observe domain state.
local bootOrder = {
	{ "AntiCheat",            AntiCheat.Init             },
	{ "DataService",          DataService.Init           },
	{ "EconomyService",       EconomyService.Init        },
	{ "LabService",           LabService.Init            },
	{ "CaptureService",       CaptureService.Init        },
	{ "BattlePassService",    BattlePassService.Init     },
	{ "DailyRewardService",   DailyRewardService.Init    },
	{ "PetService",           PetService.Init            },
	{ "MutationService",      MutationService.Init       },
	{ "InfectionService",     InfectionService.Init      },
	{ "StealService",         StealService.Init          },
	{ "OutbreakService",      OutbreakService.Init       },
	{ "BossEventService",     BossEventService.Init      },
	{ "MonetizationService",  MonetizationService.Init   },
	{ "LeaderboardService",   LeaderboardService.Init    },
	{ "GlobalLeaderboardService", GlobalLeaderboardService.Init },
	{ "AnalyticsService",     AnalyticsService.Init      },
	{ "CodeService",          CodeService.Init           },
	{ "GroupRewardService",   GroupRewardService.Init    },
	{ "TrailService",         TrailService.Init          },
	{ "AchievementService",   AchievementService.Init    },
	{ "QuestService",         QuestService.Init          },
	{ "TradeService",         TradeService.Init          },
	{ "BadgeService",         BadgeService.Init          },
	{ "AfkService",           AfkService.Init            },
	{ "AnnouncementService",  AnnouncementService.Init   },
	{ "PlayerLevelService",   PlayerLevelService.Init    },
	{ "SeasonService",        SeasonService.Init         },
	{ "DecorationService",    DecorationService.Init     },
	{ "InviteService",        InviteService.Init         },
	{ "WebhookService",       WebhookService.Init        },
	{ "AdminService",         AdminService.Init          },
	{ "OfflineCashService",   OfflineCashService.Init    },
	{ "WelcomeOfferService",  WelcomeOfferService.Init   },
	{ "LuckyWheelService",    LuckyWheelService.Init     },
	{ "SocialInviteService",  SocialInviteService.Init   },
	{ "HotStreakService",     HotStreakService.Init      },
	{ "PresenceService",      PresenceService.Init       },
	{ "EventService",         EventService.Init          },
	{ "CinematicService",     CinematicService.Init      },
	{ "MilestoneAnnounceService", MilestoneAnnounceService.Init },
	{ "VipServerService",     VipServerService.Init      },
	{ "AutoSellService",      AutoSellService.Init       },
	{ "PerformanceService",   PerformanceService.Init    },
	{ "CrossServerShoutService", CrossServerShoutService.Init },
	{ "FusionService",        FusionService.Init         },
	{ "TopOfHourService",     TopOfHourService.Init      },
	{ "DailyDealService",     DailyDealService.Init      },
	{ "LoginStreakService",   LoginStreakService.Init    },
}

for _, entry in ipairs(bootOrder) do
	local ok, err = pcall(entry[2])
	if not ok then Log.Error("Boot", "%s.Init failed: %s", entry[1], tostring(err)) end
end

local function onPlayerAdded(player: Player)
	AntiCheat.OnPlayerAdded(player)
	if AdminService.IsBanned(player.UserId) then
		player:Kick("You are banned from this experience.")
		return
	end
	DataService.LoadProfile(player)
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
		QuestService.OnPlayerAdded(player)
		BadgeService.OnPlayerAdded(player)
		GlobalLeaderboardService.OnPlayerAdded(player)
		AfkService.OnPlayerAdded(player)
		BossEventService.OnPlayerAdded(player)
		AnnouncementService.OnPlayerAdded(player)
		PetService.OnPlayerAdded(player)
		PlayerLevelService.OnPlayerAdded(player)
		SeasonService.OnPlayerAdded(player)
		DecorationService.OnPlayerAdded(player)
		InviteService.OnPlayerAdded(player)
		AdminService.OnPlayerAdded(player)
		OfflineCashService.OnPlayerAdded(player)
		WelcomeOfferService.OnPlayerAdded(player)
		LuckyWheelService.OnPlayerAdded(player)
		HotStreakService.OnPlayerAdded(player)
		PresenceService.OnPlayerAdded(player)
		EventService.OnPlayerAdded(player)
		CinematicService.OnPlayerAdded(player)
		MilestoneAnnounceService.OnPlayerAdded(player)
		VipServerService.OnPlayerAdded(player)
		AutoSellService.OnPlayerAdded(player)
		DailyDealService.OnPlayerAdded(player)
		LoginStreakService.OnPlayerAdded(player)
		EconomyService.PushHud(player)
	end)
end

local function onPlayerRemoving(player: Player)
	LabService.OnPlayerRemoving(player)
	StealService.OnPlayerRemoving(player)
	TradeService.OnPlayerRemoving(player)
	GlobalLeaderboardService.OnPlayerRemoving(player)
	AfkService.OnPlayerRemoving(player)
	DecorationService.OnPlayerRemoving(player)
	AntiCheat.OnPlayerRemoving(player)
	OfflineCashService.OnPlayerRemoving(player)
	HotStreakService.OnPlayerRemoving(player)
	MilestoneAnnounceService.OnPlayerRemoving(player)
	DataService.ReleaseProfile(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, p)
end

-- Remote handlers. Every handler is rate-limited and sanitized via AntiCheat
-- before reaching the service layer; services trust their inputs.

local function bind(name: string, fn: (Player, ...any) -> ())
	AntiCheat.WrapRemote(Remotes.Event(name), name, fn)
end

local function asUid(player: Player, value: any, context: string): string?
	return AntiCheat.SanitizeUid(player, value, context)
end

local function asString(player: Player, value: any, context: string): string?
	return AntiCheat.SanitizeString(player, value, context)
end

local function asNumber(player: Player, value: any, context: string): number?
	return AntiCheat.SanitizeNumber(player, value, context)
end

bind(Remotes.Names.RequestCapture, function(player)
	CaptureService.AttemptCapture(player)
end)

bind(Remotes.Names.RequestPlaceBrainrot, function(player, uid)
	local u = asUid(player, uid, "PlaceBrainrot.uid")
	if u then LabService.PlaceBrainrot(player, u) end
end)

bind(Remotes.Names.RequestUnplaceBrainrot, function(player, uid)
	local u = asUid(player, uid, "UnplaceBrainrot.uid")
	if u then LabService.UnplaceBrainrot(player, u) end
end)

bind(Remotes.Names.RequestSellBrainrot, function(player, uid)
	local u = asUid(player, uid, "SellBrainrot.uid")
	if u then LabService.SellBrainrot(player, u) end
end)

bind(Remotes.Names.RequestRebirth, function(player)
	EconomyService.TryRebirth(player)
end)

bind(Remotes.Names.RequestSteal, function(player, victimUserId, uid)
	local v = asNumber(player, victimUserId, "Steal.victimUserId")
	local u = asUid(player, uid, "Steal.uid")
	if v and u then StealService.AttemptSteal(player, v, u) end
end)

bind(Remotes.Names.RequestInfect, function(player, victimUserId)
	local v = asNumber(player, victimUserId, "Infect.victimUserId")
	if v then InfectionService.AttemptInfect(player, v) end
end)

bind(Remotes.Names.RequestClaimDaily, function(player)
	DailyRewardService.Claim(player)
end)

bind(Remotes.Names.RequestClaimBattlePassTier, function(player, tier)
	local t = asNumber(player, tier, "ClaimBattlePassTier.tier")
	if t then BattlePassService.ClaimTier(player, math.floor(t)) end
end)

bind(Remotes.Names.RequestPromptPurchase, function(player, kind, key)
	local k = asString(player, kind, "Purchase.kind")
	local kk = asString(player, key, "Purchase.key")
	if k and kk then MonetizationService.PromptPurchase(player, k, kk) end
end)

bind(Remotes.Names.RequestRedeemCode, function(player, code)
	local c = asString(player, code, "RedeemCode.code")
	if c then CodeService.Redeem(player, c) end
end)

bind(Remotes.Names.RequestRecheckGroup, function(player)
	GroupRewardService.Check(player)
end)

bind(Remotes.Names.RequestClaimAchievement, function(player, id)
	local i = asString(player, id, "ClaimAchievement.id")
	if i then AchievementService.Claim(player, i) end
end)

bind(Remotes.Names.RequestClaimQuest, function(player, id)
	local i = asString(player, id, "ClaimQuest.id")
	if i then QuestService.Claim(player, i) end
end)

bind(Remotes.Names.RequestTradeInvite, function(player, targetUserId)
	local v = asNumber(player, targetUserId, "TradeInvite.targetUserId")
	if v then TradeService.Invite(player, v) end
end)

bind(Remotes.Names.RequestTradeAccept, function(player) TradeService.Accept(player) end)
bind(Remotes.Names.RequestTradeDecline, function(player) TradeService.Decline(player) end)

bind(Remotes.Names.RequestTradeAddBrainrot, function(player, uid)
	local u = asUid(player, uid, "TradeAdd.uid")
	if u then TradeService.AddBrainrot(player, u) end
end)

bind(Remotes.Names.RequestTradeRemoveBrainrot, function(player, uid)
	local u = asUid(player, uid, "TradeRemove.uid")
	if u then TradeService.RemoveBrainrot(player, u) end
end)

bind(Remotes.Names.RequestTradeSetCash, function(player, n)
	local v = asNumber(player, n, "TradeSetCash.amount")
	if v then TradeService.SetCash(player, math.max(0, math.floor(v))) end
end)

bind(Remotes.Names.RequestTradeConfirm, function(player) TradeService.Confirm(player) end)
bind(Remotes.Names.RequestTradeCancel, function(player) TradeService.Cancel(player) end)

bind(Remotes.Names.RequestEquipPet, function(player, uid)
	local u = asUid(player, uid, "EquipPet.uid")
	if u then PetService.Equip(player, u) end
end)

bind(Remotes.Names.RequestUnequipPet, function(player)
	PetService.Unequip(player)
end)

bind(Remotes.Names.RequestClaimLevelReward, function(player, lvl)
	local v = asNumber(player, lvl, "ClaimLevelReward.level")
	if v then PlayerLevelService.ClaimLevelReward(player, math.floor(v)) end
end)

bind(Remotes.Names.RequestBuyDecoration, function(player, id)
	local i = asString(player, id, "BuyDecoration.id")
	if i then DecorationService.Buy(player, i) end
end)

bind(Remotes.Names.RequestSellDecoration, function(player, uid)
	local u = asUid(player, uid, "SellDecoration.uid")
	if u then DecorationService.Sell(player, u) end
end)

bind(Remotes.Names.RequestRedeemInvite, function(player, code)
	local c = asString(player, code, "RedeemInvite.code")
	if c then InviteService.Redeem(player, c) end
end)

bind(Remotes.Names.RequestWheelSpin, function(player, kind)
	local k = asString(player, kind, "WheelSpin.kind")
	if k then LuckyWheelService.Spin(player, k) end
end)

bind(Remotes.Names.RequestSocialInvite, function(player)
	SocialInviteService.Prompt(player)
end)

bind(Remotes.Names.RequestSetAutoSell, function(player, enabled, threshold, excludeMutated)
	local t = asString(player, threshold, "AutoSell.threshold")
	if t and typeof(enabled) == "boolean" and typeof(excludeMutated) == "boolean" then
		AutoSellService.SetConfig(player, enabled, t, excludeMutated)
	end
end)

bind(Remotes.Names.RequestFuse, function(player, uids)
	if typeof(uids) ~= "table" then return end
	local cleaned: { string } = {}
	for _, u in ipairs(uids) do
		local s = asUid(player, u, "Fuse.uid")
		if s then table.insert(cleaned, s) end
	end
	if #cleaned == 3 then FusionService.Attempt(player, cleaned) end
end)

Log.Info("Boot", "BrainrotLab server ready (%d services).", #bootOrder)
