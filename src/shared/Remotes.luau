--!strict
--[[
	Remotes — central registry. Server creates instances on first access,
	client just reads them. Avoids stringly-typed lookups scattered across
	the codebase.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteNames = {
	-- Events (fire-and-forget)
	Notify = "Notify",                -- server -> client (toasts)
	HudUpdate = "HudUpdate",          -- server -> client (cash, rebirth, multipliers)
	InventoryUpdate = "InventoryUpdate",
	OutbreakUpdate = "OutbreakUpdate",
	BattlePassUpdate = "BattlePassUpdate",
	DailyRewardUpdate = "DailyRewardUpdate",
	LeaderboardUpdate = "LeaderboardUpdate",
	AchievementUpdate = "AchievementUpdate",
	QuestUpdate = "QuestUpdate",
	TradeInvite = "TradeInvite",
	TradeUpdate = "TradeUpdate",
	GlobalLeaderboardUpdate = "GlobalLeaderboardUpdate",
	BossUpdate = "BossUpdate",
	AnnouncementShow = "AnnouncementShow",
	PetUpdate = "PetUpdate",
	LevelUpdate = "LevelUpdate",
	SeasonUpdate = "SeasonUpdate",
	PlayInfectionAnim = "PlayInfectionAnim",

	-- Client -> server actions
	RequestCapture = "RequestCapture",
	RequestPlaceBrainrot = "RequestPlaceBrainrot",
	RequestUnplaceBrainrot = "RequestUnplaceBrainrot",
	RequestSellBrainrot = "RequestSellBrainrot",
	RequestRebirth = "RequestRebirth",
	RequestSteal = "RequestSteal",
	RequestInfect = "RequestInfect",
	RequestClaimDaily = "RequestClaimDaily",
	RequestClaimBattlePassTier = "RequestClaimBattlePassTier",
	RequestPromptPurchase = "RequestPromptPurchase",
	RequestRedeemCode = "RequestRedeemCode",
	RequestRecheckGroup = "RequestRecheckGroup",
	RequestClaimAchievement = "RequestClaimAchievement",
	RequestClaimQuest = "RequestClaimQuest",
	RequestTradeInvite = "RequestTradeInvite",
	RequestTradeAccept = "RequestTradeAccept",
	RequestTradeDecline = "RequestTradeDecline",
	RequestTradeAddBrainrot = "RequestTradeAddBrainrot",
	RequestTradeRemoveBrainrot = "RequestTradeRemoveBrainrot",
	RequestTradeSetCash = "RequestTradeSetCash",
	RequestTradeConfirm = "RequestTradeConfirm",
	RequestTradeCancel = "RequestTradeCancel",
	RequestEquipPet = "RequestEquipPet",
	RequestUnequipPet = "RequestUnequipPet",
	RequestClaimLevelReward = "RequestClaimLevelReward",
}

local Remotes = {}

local folder: Folder

local function ensureFolder(): Folder
	if folder and folder.Parent then return folder end
	if RunService:IsServer() then
		local existing = ReplicatedStorage:FindFirstChild("Remotes")
		if existing then
			folder = existing :: Folder
		else
			folder = Instance.new("Folder")
			folder.Name = "Remotes"
			folder.Parent = ReplicatedStorage
		end
	else
		folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	end
	return folder
end

function Remotes.Event(name: string): RemoteEvent
	local f = ensureFolder()
	if RunService:IsServer() then
		local r = f:FindFirstChild(name)
		if r then return r :: RemoteEvent end
		local ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = f
		return ev
	end
	return f:WaitForChild(name) :: RemoteEvent
end

function Remotes.Function(name: string): RemoteFunction
	local f = ensureFolder()
	if RunService:IsServer() then
		local r = f:FindFirstChild(name)
		if r then return r :: RemoteFunction end
		local fn = Instance.new("RemoteFunction")
		fn.Name = name
		fn.Parent = f
		return fn
	end
	return f:WaitForChild(name) :: RemoteFunction
end

-- Eagerly create all remotes on the server so clients don't race.
function Remotes.InitServer()
	assert(RunService:IsServer(), "InitServer called on client")
	for _, n in pairs(RemoteNames) do
		Remotes.Event(n)
	end
end

Remotes.Names = RemoteNames

return Remotes
