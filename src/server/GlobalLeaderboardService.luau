--!strict
--[[
	GlobalLeaderboardService — cross-server top-100 boards backed by
	OrderedDataStore. Three boards (cash, mutations, steals) with weekly
	resets. The board UID rolls forward every Sunday 00:00 UTC, so a fresh
	competition starts every week (re-engagement spike).

	Why weekly resets? Because permanent all-time boards stagnate after the
	first month — the top spots feel unreachable and casual players bounce.
	Weekly resets give every active player a real shot, every week, which
	is the #1 retention pattern in tycoon games (proven by Pet Simulator 99,
	Blade Ball, Anime Defenders, etc.).

	Updates push every ~60s per active player (throttled). Reads happen on
	demand when a player opens the global leaderboard tab.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local DataService = require(script.Parent.DataService)

local GlobalLeaderboardService = {}

local BOARDS = { "cash", "mutations", "steals" }

local stores: { [string]: OrderedDataStore? } = {}
local nameStore: DataStore? = nil

local function weekId(): string
	-- ISO-ish: integer week number since the epoch. Boundary at Sun 00:00 UTC.
	-- Epoch (1970-01-01) was a Thursday, so subtract 4 days to align week starts.
	local days = math.floor(os.time() / 86400)
	local week = math.floor((days + 4) / 7)
	return tostring(week)
end

local function storeKey(board: string): string
	return `BrainrotLab_GLB_{board}_{weekId()}`
end

local function ensureStores()
	if RunService:IsStudio() then return end
	for _, b in ipairs(BOARDS) do
		stores[b] = DataStoreService:GetOrderedDataStore(storeKey(b))
	end
	nameStore = DataStoreService:GetDataStore("BrainrotLab_DisplayNames")
end

local lastUpdate: { [Player]: number } = {}

local function pushPlayer(player: Player)
	local now = os.clock()
	if lastUpdate[player] and now - lastUpdate[player] < 55 then return end
	lastUpdate[player] = now
	if RunService:IsStudio() then return end
	local data = DataService.Get(player)
	if not data then return end

	-- Cache display name once per session (cheap)
	if nameStore then
		pcall(function() nameStore:SetAsync(tostring(player.UserId), player.DisplayName) end)
	end

	-- Re-resolve stores in case week rolled over mid-session
	ensureStores()

	pcall(function()
		if stores.cash then stores.cash:SetAsync(tostring(player.UserId), math.floor(data.cash)) end
	end)
	pcall(function()
		if stores.mutations then stores.mutations:SetAsync(tostring(player.UserId), data.stats.totalMutations) end
	end)
	pcall(function()
		if stores.steals then stores.steals:SetAsync(tostring(player.UserId), data.stats.totalSteals) end
	end)
end

local function readBoard(board: string, limit: number): { { userId: number, name: string, value: number } }
	local out = {}
	if RunService:IsStudio() then return out end
	local store = stores[board]
	if not store then return out end
	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, limit)
	end)
	if not ok or not pages then return out end
	local page = pages:GetCurrentPage()
	for _, entry in ipairs(page) do
		local uid = tonumber(entry.key) or 0
		local name = `User_{entry.key}`
		if nameStore then
			pcall(function() name = nameStore:GetAsync(entry.key) or name end)
		end
		table.insert(out, { userId = uid, name = name, value = entry.value })
	end
	return out
end

function GlobalLeaderboardService.PushAll()
	local payload = {
		weekId = weekId(),
		nextResetIn = (math.floor((tonumber(weekId()) :: number + 1) * 7 - 4) * 86400) - os.time(),
		cash = readBoard("cash", 25),
		mutations = readBoard("mutations", 25),
		steals = readBoard("steals", 25),
	}
	for _, p in ipairs(Players:GetPlayers()) do
		Remotes.Event(Remotes.Names.GlobalLeaderboardUpdate):FireClient(p, payload)
	end
end

function GlobalLeaderboardService.OnPlayerAdded(player: Player)
	task.delay(3, pushPlayer, player)
end

function GlobalLeaderboardService.OnPlayerRemoving(player: Player)
	-- Final flush so people who quit while leading stay on the board
	pushPlayer(player)
	lastUpdate[player] = nil
end

function GlobalLeaderboardService.Init()
	ensureStores()

	-- Periodic per-player writes (throttled inside pushPlayer)
	task.spawn(function()
		while true do
			task.wait(60)
			for _, p in ipairs(Players:GetPlayers()) do
				pushPlayer(p)
			end
		end
	end)

	-- Read + broadcast every 5 minutes
	task.spawn(function()
		while true do
			GlobalLeaderboardService.PushAll()
			task.wait(300)
		end
	end)
end

return GlobalLeaderboardService
