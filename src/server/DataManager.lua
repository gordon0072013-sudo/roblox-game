--!strict
-- DataManager.lua
-- Handles per-player persistent data using DataStoreService, with an
-- in-memory session cache, retry-on-failure saving, and BindToClose
-- protection so progress is not lost on server shutdown.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local DataManager = {}

local store = DataStoreService:GetDataStore(Config.DataStoreName)

-- userId -> profile table
local sessions: { [number]: { coins: number, totalEarned: number, clicks: number } } = {}

local DEFAULT_PROFILE = function()
	return {
		coins = Config.StartingCoins,
		totalEarned = 0,
		clicks = 0,
	}
end

local function key(userId: number): string
	return "player_" .. tostring(userId)
end

-- Generic retry wrapper for DataStore calls.
local function withRetry(fn: () -> any, attempts: number): (boolean, any)
	local lastErr
	for i = 1, attempts do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		task.wait(2 ^ (i - 1)) -- 1s, 2s, 4s...
	end
	return false, lastErr
end

function DataManager.Load(player: Player)
	local userId = player.UserId
	local ok, data = withRetry(function()
		return store:GetAsync(key(userId))
	end, 4)

	local profile
	if ok and type(data) == "table" then
		profile = {
			coins = tonumber(data.coins) or Config.StartingCoins,
			totalEarned = tonumber(data.totalEarned) or 0,
			clicks = tonumber(data.clicks) or 0,
		}
	else
		profile = DEFAULT_PROFILE()
		if not ok then
			warn(("[DataManager] Load failed for %d, using default: %s"):format(userId, tostring(data)))
		end
	end

	sessions[userId] = profile
	return profile
end

function DataManager.Get(player: Player)
	return sessions[player.UserId]
end

function DataManager.Save(player: Player)
	local userId = player.UserId
	local profile = sessions[userId]
	if not profile then
		return
	end
	local ok, err = withRetry(function()
		return store:SetAsync(key(userId), profile)
	end, 4)
	if not ok then
		warn(("[DataManager] Save failed for %d: %s"):format(userId, tostring(err)))
	end
	return ok
end

function DataManager.Release(player: Player)
	DataManager.Save(player)
	sessions[player.UserId] = nil
end

-- Save everyone (used by autosave loop and BindToClose).
function DataManager.SaveAll()
	for _, player in ipairs(Players:GetPlayers()) do
		DataManager.Save(player)
	end
end

return DataManager
