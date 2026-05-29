--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local RemoteNames = {
	-- Server -> client
	HudUpdate          = "HudUpdate",
	Notify             = "Notify",
	RoundState         = "RoundState",         -- countdown / playing / results
	ScoreFrame         = "ScoreFrame",          -- live score during round
	LeaderboardUpdate  = "LeaderboardUpdate",
	DailyRewardUpdate  = "DailyRewardUpdate",
	SongLibrary        = "SongLibrary",         -- replicates unlocked songs

	-- Client -> server
	RequestSongList         = "RequestSongList",
	RequestPlaySong         = "RequestPlaySong",
	RequestHit              = "RequestHit",
	RequestQuit             = "RequestQuit",
	RequestPromptPurchase   = "RequestPromptPurchase",
	RequestClaimDaily       = "RequestClaimDaily",
}

local Remotes = {}
Remotes.Names = RemoteNames

local folder: Folder?

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
		folder = ReplicatedStorage:WaitForChild("Remotes", 30) :: Folder
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
	return f:WaitForChild(name, 30) :: RemoteEvent
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
	return f:WaitForChild(name, 30) :: RemoteFunction
end

function Remotes.InitServer()
	assert(RunService:IsServer())
	for _, n in pairs(RemoteNames) do
		Remotes.Event(n)
	end
end

return Remotes
