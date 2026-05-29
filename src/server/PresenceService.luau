--!strict

local Players           = game:GetService("Players")
local TextChatService   = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Util = require(Shared.Util)

local DataService   = require(script.Parent.DataService)
local AdminService  = require(script.Parent.AdminService)

local PresenceService = {}

local LEADERSTATS_REFRESH = 2 -- seconds

-- ============================================================
-- Roblox default player-list leaderstats
-- ============================================================
local function ensureLeaderstats(player: Player)
	local existing = player:FindFirstChild("leaderstats")
	if existing then return existing :: Folder end
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	folder.Parent = player

	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Value = "0"
	cash.Parent = folder

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = folder

	return folder
end

local function updateLeaderstats(player: Player)
	local folder = player:FindFirstChild("leaderstats")
	if not folder then return end
	local data = DataService.Get(player)
	if not data then return end
	local cash = folder:FindFirstChild("Cash") :: StringValue?
	local rebirths = folder:FindFirstChild("Rebirths") :: IntValue?
	if cash then cash.Value = Util.FormatShortNumber(data.cash) end
	if rebirths then rebirths.Value = data.rebirths end
end

-- ============================================================
-- Owner / admin chat tag (new TextChatService)
-- ============================================================
local function applyChatTags()
	if TextChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then return end
	TextChatService.OnIncomingMessage = function(message: TextChatMessage)
		local props = Instance.new("TextChatMessageProperties")
		local src = message.TextSource
		if not src then return props end
		local player = Players:GetPlayerByUserId(src.UserId)
		if not player then return props end
		if AdminService.IsOwner(player) then
			props.PrefixText = `<font color="rgb(255,215,80)">[OWNER]</font> {message.PrefixText}`
		elseif AdminService.IsAdmin(player) then
			props.PrefixText = `<font color="rgb(120,220,120)">[ADMIN]</font> {message.PrefixText}`
		else
			local d = DataService.Get(player)
			if d and (d :: any)._totalTipped and (d :: any)._totalTipped >= 200 then
				props.PrefixText = `<font color="rgb(255,120,180)">[TIPPER]</font> {message.PrefixText}`
			end
		end
		return props
	end
end

function PresenceService.OnPlayerAdded(player: Player)
	ensureLeaderstats(player)
	DataService.OnProfileLoaded(player, function()
		updateLeaderstats(player)
	end)
end

function PresenceService.Init()
	applyChatTags()
	task.spawn(function()
		while true do
			task.wait(LEADERSTATS_REFRESH)
			for _, p in ipairs(Players:GetPlayers()) do
				updateLeaderstats(p)
			end
		end
	end)
end

return PresenceService
