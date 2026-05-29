--!strict
--[[
	LeaderboardService — pushes a server-local top-10 every 10s. Three boards:
	Top Cash, Top Mutations, Top Thieves. Resets per server, not global —
	keeps it cheap (no OrderedDataStore queries on tick).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)
local DataService = require(script.Parent.DataService)

local LeaderboardService = {}

local function snapshot()
	local entries = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local d = DataService.Get(p)
		if d then
			table.insert(entries, {
				userId = p.UserId,
				name = p.DisplayName,
				cash = d.cash,
				rebirths = d.rebirths,
				mutations = d.stats.totalMutations,
				steals = d.stats.totalSteals,
				infections = d.stats.totalInfections,
			})
		end
	end

	local function topBy(key: string, limit: number)
		local sorted = table.clone(entries)
		table.sort(sorted, function(a, b) return (a :: any)[key] > (b :: any)[key] end)
		local out = {}
		for i = 1, math.min(limit, #sorted) do table.insert(out, sorted[i]) end
		return out
	end

	return {
		cash = topBy("cash", 10),
		mutations = topBy("mutations", 10),
		thieves = topBy("steals", 10),
	}
end

local function pushAll()
	local payload = snapshot()
	for _, p in ipairs(Players:GetPlayers()) do
		Remotes.Event(Remotes.Names.LeaderboardUpdate):FireClient(p, payload)
	end
end

function LeaderboardService.Init()
	task.spawn(function()
		while true do
			pushAll()
			task.wait(10)
		end
	end)
end

return LeaderboardService
