--!strict
--[[
	DataService — ProfileService-style session-locked DataStore wrapper.

	Why session-locked: prevents the classic Roblox dupe — same player on two
	servers loads the same profile, sells items on one, buys on another. Lost
	purchases trigger refund-storm complaints, which sink revenue (and risk
	store violation flags). We use the loleris/ProfileService Wally package
	when present, and a thin in-memory fallback when it isn't (test/CI).
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Types = require(Shared.Types)
local Util = require(Shared.Util)

local DataService = {}

local profiles: { [Player]: any } = {}
local profileLoadedSignals: { [Player]: { (any) -> () } } = {}

local DEFAULT_PROFILE: Types.PlayerProfileData = {
	cash = Config.STARTING_CASH,
	rebirths = 0,
	inventory = {},
	infectionBombs = Config.INFECTION_BOMB_STARTER_COUNT,
	infectedUntil = 0,
	plotId = nil,
	gamepasses = {},
	battlePass = {
		xp = 0,
		tier = 0,
		claimed = {},
		premium = false,
		seasonId = "S1",
	},
	dailyReward = {
		lastClaimDay = 0,
		streak = 0,
	},
	stats = {
		totalCaptured = 0,
		totalMutations = 0,
		totalSteals = 0,
		totalInfections = 0,
		totalCashEarned = 0,
	},
	createdAt = 0,
}

local function tryRequireProfileService()
	local pkgs = ServerScriptService:FindFirstChild("ServerPackages")
	if not pkgs then return nil end
	local ps = pkgs:FindFirstChild("ProfileService")
	if not ps then return nil end
	local ok, mod = pcall(require, ps)
	if not ok then return nil end
	return mod
end

local ProfileStore: any = nil
local ProfileService: any = nil

function DataService.Init()
	ProfileService = tryRequireProfileService()
	if ProfileService then
		ProfileStore = ProfileService.GetProfileStore(Config.DATASTORE_SCOPE, Util.DeepCopy(DEFAULT_PROFILE))
	else
		warn("[DataService] ProfileService not found in ServerPackages. Using in-memory fallback (no persistence).")
	end
end

local function makeInMemoryProfile(): any
	return {
		Data = Util.DeepCopy(DEFAULT_PROFILE),
		Release = function() end,
		ListenToRelease = function(_, _) end,
		Reconcile = function() end,
		_isFallback = true,
	}
end

function DataService.LoadProfile(player: Player)
	if profiles[player] then return profiles[player] end

	local profile: any
	if ProfileStore then
		local key = `Player_{player.UserId}`
		profile = ProfileStore:LoadProfileAsync(key, "ForceLoad")
		if profile == nil then
			player:Kick("Profile load failed — please rejoin.")
			return nil
		end
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profile:ListenToRelease(function()
			profiles[player] = nil
			player:Kick("Profile released — your session was opened on another server. Rejoin to continue.")
		end)

		if not player:IsDescendantOf(Players) then
			profile:Release()
			return nil
		end
	else
		profile = makeInMemoryProfile()
	end

	if profile.Data.createdAt == 0 then
		profile.Data.createdAt = os.time()
	end

	profiles[player] = profile

	local waiters = profileLoadedSignals[player]
	profileLoadedSignals[player] = nil
	if waiters then
		for _, cb in ipairs(waiters) do
			task.spawn(cb, profile)
		end
	end

	return profile
end

function DataService.ReleaseProfile(player: Player)
	local profile = profiles[player]
	if profile then
		profile:Release()
		profiles[player] = nil
	end
end

function DataService.Get(player: Player): Types.PlayerProfileData?
	local profile = profiles[player]
	if not profile then return nil end
	return profile.Data
end

function DataService.OnProfileLoaded(player: Player, cb: (any) -> ())
	if profiles[player] then
		task.spawn(cb, profiles[player])
		return
	end
	local list = profileLoadedSignals[player]
	if not list then
		list = {}
		profileLoadedSignals[player] = list
	end
	table.insert(list, cb)
end

function DataService.GetProfile(player: Player): any
	return profiles[player]
end

function DataService.WaitForProfile(player: Player, timeout: number?): any
	local deadline = os.clock() + (timeout or 10)
	while os.clock() < deadline do
		if profiles[player] then return profiles[player] end
		task.wait(0.05)
	end
	return profiles[player]
end

-- Flush all profiles on shutdown so purchases aren't lost.
game:BindToClose(function()
	if RunService:IsStudio() then return end
	for _, profile in pairs(profiles) do
		if not profile._isFallback then
			pcall(function() profile:Release() end)
		end
	end
	task.wait(2)
end)

return DataService
