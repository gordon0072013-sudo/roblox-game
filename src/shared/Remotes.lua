--!strict
-- Remotes.lua
-- Lazily creates and returns the RemoteEvents/RemoteFunctions used to talk
-- between client and server. Both sides require this module so the names
-- always match.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local FOLDER_NAME = "CoinClickerRemotes"

local function getFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing then
		return existing :: Folder
	end
	-- On the server we create it; on the client we wait for it.
	if game:GetService("RunService"):IsServer() then
		local folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
		return folder
	else
		return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
	end
end

local function getRemote(name: string, className: string): Instance
	local folder = getFolder()
	local existing = folder:FindFirstChild(name)
	if existing then
		return existing
	end
	if game:GetService("RunService"):IsServer() then
		local remote = Instance.new(className)
		remote.Name = name
		remote.Parent = folder
		return remote
	else
		return folder:WaitForChild(name)
	end
end

function Remotes.Click(): RemoteEvent
	return getRemote("Click", "RemoteEvent") :: RemoteEvent
end

function Remotes.StatsUpdated(): RemoteEvent
	return getRemote("StatsUpdated", "RemoteEvent") :: RemoteEvent
end

function Remotes.PromptPurchase(): RemoteEvent
	-- client -> server -> client; carries a product/pass key string
	return getRemote("PromptPurchase", "RemoteEvent") :: RemoteEvent
end

function Remotes.GetCatalog(): RemoteFunction
	return getRemote("GetCatalog", "RemoteFunction") :: RemoteFunction
end

return Remotes
