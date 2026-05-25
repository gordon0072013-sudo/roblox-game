--!strict
-- BrainrotLab post-install verifier — auto-generated.
-- Paste into Studio Command Bar AFTER running BrainrotLab_Installer.luau.
-- Prints PASS/FAIL for every expected Folder, Script, ModuleScript,
-- LocalScript. Returns the number of failures to the command bar.

local function resolveContainer(path)
	local cur = game
	for part in string.gmatch(path, "[^%.]+") do
		local nxt = cur:FindFirstChild(part)
		if not nxt and cur == game then
			local ok, svc = pcall(function() return game:GetService(part) end)
			if ok then nxt = svc end
		end
		if not nxt then return nil end
		cur = nxt
	end
	return cur
end

local function resolveChild(root, path)
	if path == "" then return root end
	local cur = root
	for seg in string.gmatch(path, "[^/]+") do
		cur = cur and cur:FindFirstChild(seg)
		if not cur then return nil end
	end
	return cur
end

local fails = 0
local total = 0
local function check(label, ok)
	total = total + 1
	if ok then
		print(string.format("  PASS  %s", label))
	else
		fails = fails + 1
		warn(string.format("  FAIL  %s", label))
	end
end

print("[BrainrotLab Verifier] starting…")
do
	local container = resolveContainer("ReplicatedStorage")
	check("ReplicatedStorage", container ~= nil)
	local root = container and container:FindFirstChild("Shared")
	check("ReplicatedStorage/Shared", root ~= nil)
end
do
	local container = resolveContainer("ServerScriptService")
	check("ServerScriptService", container ~= nil)
	local root = container and container:FindFirstChild("Server")
	check("ServerScriptService/Server", root ~= nil)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	check("StarterPlayer.StarterPlayerScripts", container ~= nil)
	local root = container and container:FindFirstChild("Client")
	check("StarterPlayer.StarterPlayerScripts/Client", root ~= nil)
end

do
	local container = resolveContainer("ReplicatedStorage")
	local root = container and container:FindFirstChild("Shared")
	local inst = root and resolveChild(root, "AchievementData")
	check("ReplicatedStorage/Shared/AchievementData :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ReplicatedStorage")
	local root = container and container:FindFirstChild("Shared")
	local inst = root and resolveChild(root, "BrainrotData")
	check("ReplicatedStorage/Shared/BrainrotData :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ReplicatedStorage")
	local root = container and container:FindFirstChild("Shared")
	local inst = root and resolveChild(root, "Config")
	check("ReplicatedStorage/Shared/Config :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ReplicatedStorage")
	local root = container and container:FindFirstChild("Shared")
	local inst = root and resolveChild(root, "DecorationData")
	check("ReplicatedStorage/Shared/DecorationData :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ReplicatedStorage")
	local root = container and container:FindFirstChild("Shared")
	local inst = root and resolveChild(root, "LocalizationService")
	check("ReplicatedStorage/Shared/LocalizationService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ReplicatedStorage")
	local root = container and container:FindFirstChild("Shared")
	local inst = root and resolveChild(root, "Log")
	check("ReplicatedStorage/Shared/Log :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ReplicatedStorage")
	local root = container and container:FindFirstChild("Shared")
	local inst = root and resolveChild(root, "MutationData")
	check("ReplicatedStorage/Shared/MutationData :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ReplicatedStorage")
	local root = container and container:FindFirstChild("Shared")
	local inst = root and resolveChild(root, "PatchNotes")
	check("ReplicatedStorage/Shared/PatchNotes :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ReplicatedStorage")
	local root = container and container:FindFirstChild("Shared")
	local inst = root and resolveChild(root, "PetData")
	check("ReplicatedStorage/Shared/PetData :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ReplicatedStorage")
	local root = container and container:FindFirstChild("Shared")
	local inst = root and resolveChild(root, "Remotes")
	check("ReplicatedStorage/Shared/Remotes :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ReplicatedStorage")
	local root = container and container:FindFirstChild("Shared")
	local inst = root and resolveChild(root, "Types")
	check("ReplicatedStorage/Shared/Types :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ReplicatedStorage")
	local root = container and container:FindFirstChild("Shared")
	local inst = root and resolveChild(root, "Util")
	check("ReplicatedStorage/Shared/Util :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "AchievementService")
	check("ServerScriptService/Server/AchievementService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "AdminService")
	check("ServerScriptService/Server/AdminService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "AfkService")
	check("ServerScriptService/Server/AfkService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "AnalyticsService")
	check("ServerScriptService/Server/AnalyticsService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "AnnouncementService")
	check("ServerScriptService/Server/AnnouncementService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "AntiCheat")
	check("ServerScriptService/Server/AntiCheat :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "AutoSellService")
	check("ServerScriptService/Server/AutoSellService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "BadgeService")
	check("ServerScriptService/Server/BadgeService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "BattlePassService")
	check("ServerScriptService/Server/BattlePassService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "BossEventService")
	check("ServerScriptService/Server/BossEventService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "CaptureService")
	check("ServerScriptService/Server/CaptureService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "CinematicService")
	check("ServerScriptService/Server/CinematicService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "CodeService")
	check("ServerScriptService/Server/CodeService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "CrossServerShoutService")
	check("ServerScriptService/Server/CrossServerShoutService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "DailyDealService")
	check("ServerScriptService/Server/DailyDealService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "DailyRewardService")
	check("ServerScriptService/Server/DailyRewardService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "DataService")
	check("ServerScriptService/Server/DataService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "DecorationService")
	check("ServerScriptService/Server/DecorationService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "EconomyService")
	check("ServerScriptService/Server/EconomyService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "EventService")
	check("ServerScriptService/Server/EventService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "FusionService")
	check("ServerScriptService/Server/FusionService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "GlobalLeaderboardService")
	check("ServerScriptService/Server/GlobalLeaderboardService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "GroupRewardService")
	check("ServerScriptService/Server/GroupRewardService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "HotStreakService")
	check("ServerScriptService/Server/HotStreakService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "InfectionService")
	check("ServerScriptService/Server/InfectionService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "InviteService")
	check("ServerScriptService/Server/InviteService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "LabService")
	check("ServerScriptService/Server/LabService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "LeaderboardService")
	check("ServerScriptService/Server/LeaderboardService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "LoginStreakService")
	check("ServerScriptService/Server/LoginStreakService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "LuckyWheelService")
	check("ServerScriptService/Server/LuckyWheelService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "MilestoneAnnounceService")
	check("ServerScriptService/Server/MilestoneAnnounceService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "MonetizationService")
	check("ServerScriptService/Server/MonetizationService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "MutationService")
	check("ServerScriptService/Server/MutationService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "OfflineCashService")
	check("ServerScriptService/Server/OfflineCashService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "OutbreakService")
	check("ServerScriptService/Server/OutbreakService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "PerformanceService")
	check("ServerScriptService/Server/PerformanceService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "PetService")
	check("ServerScriptService/Server/PetService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "PlayerLevelService")
	check("ServerScriptService/Server/PlayerLevelService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "PresenceService")
	check("ServerScriptService/Server/PresenceService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "QuestService")
	check("ServerScriptService/Server/QuestService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "SeasonService")
	check("ServerScriptService/Server/SeasonService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "SocialInviteService")
	check("ServerScriptService/Server/SocialInviteService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "StealService")
	check("ServerScriptService/Server/StealService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "TopOfHourService")
	check("ServerScriptService/Server/TopOfHourService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "TradeService")
	check("ServerScriptService/Server/TradeService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "TrailService")
	check("ServerScriptService/Server/TrailService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "VipServerService")
	check("ServerScriptService/Server/VipServerService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "WebhookService")
	check("ServerScriptService/Server/WebhookService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	local inst = root and resolveChild(root, "WelcomeOfferService")
	check("ServerScriptService/Server/WelcomeOfferService :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("ServerScriptService")
	local root = container and container:FindFirstChild("Server")
	check("ServerScriptService/Server :: Script", root and root.ClassName == "Script" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "AchievementUI")
	check("StarterPlayer.StarterPlayerScripts/Client/AchievementUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "AdminPanelUI")
	check("StarterPlayer.StarterPlayerScripts/Client/AdminPanelUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "AnnouncementUI")
	check("StarterPlayer.StarterPlayerScripts/Client/AnnouncementUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "AutoSellUI")
	check("StarterPlayer.StarterPlayerScripts/Client/AutoSellUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "BattlePassUI")
	check("StarterPlayer.StarterPlayerScripts/Client/BattlePassUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "BossUI")
	check("StarterPlayer.StarterPlayerScripts/Client/BossUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "CinematicUI")
	check("StarterPlayer.StarterPlayerScripts/Client/CinematicUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "CodeRedeemUI")
	check("StarterPlayer.StarterPlayerScripts/Client/CodeRedeemUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "DailyRewardUI")
	check("StarterPlayer.StarterPlayerScripts/Client/DailyRewardUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "DecorationUI")
	check("StarterPlayer.StarterPlayerScripts/Client/DecorationUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "GlobalLeaderboardUI")
	check("StarterPlayer.StarterPlayerScripts/Client/GlobalLeaderboardUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "GroupBannerUI")
	check("StarterPlayer.StarterPlayerScripts/Client/GroupBannerUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "HUD")
	check("StarterPlayer.StarterPlayerScripts/Client/HUD :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "InventoryUI")
	check("StarterPlayer.StarterPlayerScripts/Client/InventoryUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "InviteUI")
	check("StarterPlayer.StarterPlayerScripts/Client/InviteUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "LeaderboardUI")
	check("StarterPlayer.StarterPlayerScripts/Client/LeaderboardUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "LevelUI")
	check("StarterPlayer.StarterPlayerScripts/Client/LevelUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "LoadingScreen")
	check("StarterPlayer.StarterPlayerScripts/Client/LoadingScreen :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "LuckyWheelUI")
	check("StarterPlayer.StarterPlayerScripts/Client/LuckyWheelUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "NotificationUI")
	check("StarterPlayer.StarterPlayerScripts/Client/NotificationUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "OutbreakUI")
	check("StarterPlayer.StarterPlayerScripts/Client/OutbreakUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "PatchNotesUI")
	check("StarterPlayer.StarterPlayerScripts/Client/PatchNotesUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "PetUI")
	check("StarterPlayer.StarterPlayerScripts/Client/PetUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "PlotUI")
	check("StarterPlayer.StarterPlayerScripts/Client/PlotUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "QuestUI")
	check("StarterPlayer.StarterPlayerScripts/Client/QuestUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "ShopUI")
	check("StarterPlayer.StarterPlayerScripts/Client/ShopUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "SoundController")
	check("StarterPlayer.StarterPlayerScripts/Client/SoundController :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "TradeUI")
	check("StarterPlayer.StarterPlayerScripts/Client/TradeUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "TutorialUI")
	check("StarterPlayer.StarterPlayerScripts/Client/TutorialUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "UIController")
	check("StarterPlayer.StarterPlayerScripts/Client/UIController :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	local inst = root and resolveChild(root, "WelcomeOfferUI")
	check("StarterPlayer.StarterPlayerScripts/Client/WelcomeOfferUI :: ModuleScript", inst and inst.ClassName == "ModuleScript" or false)
end
do
	local container = resolveContainer("StarterPlayer.StarterPlayerScripts")
	local root = container and container:FindFirstChild("Client")
	check("StarterPlayer.StarterPlayerScripts/Client :: LocalScript", root and root.ClassName == "LocalScript" or false)
end

do  -- Remotes folder presence
	local rs = game:GetService('ReplicatedStorage')
	check('ReplicatedStorage/Remotes', rs:FindFirstChild('Remotes') ~= nil)
end

print(string.format("[BrainrotLab Verifier] %d / %d checks passed (%d failures)", total - fails, total, fails))
if fails > 0 then warn("Re-run BrainrotLab_Installer.luau to repair.") end
