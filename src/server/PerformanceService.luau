--!strict

local Players          = game:GetService("Players")
local Workspace        = game:GetService("Workspace")
local Stats            = game:GetService("Stats")
local RunService       = game:GetService("RunService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log    = require(Shared.Log)

local PerformanceService = {}

-- Runtime server-side performance monitor. Logs a warning if the
-- physics/heartbeat step time blows up, which is the early signal of
-- a runaway loop or an unbounded model-creation pattern (the most
-- common cause of low-end device drop-off).

local SAMPLE_INTERVAL    = 15      -- seconds
local STEP_WARN_MS       = 30      -- single-step ceiling we care about
local PLOT_PART_LIMIT    = 800     -- if a plot folder exceeds this we warn

local function countDescendantsBaseparts(folder: Instance): number
	local n = 0
	for _, d in ipairs(folder:GetDescendants()) do
		if d:IsA("BasePart") then n += 1 end
	end
	return n
end

local function checkPlotBudgets()
	local plots = Workspace:FindFirstChild("Plots")
	if not plots then return end
	for _, plot in ipairs(plots:GetChildren()) do
		local count = countDescendantsBaseparts(plot)
		if count > PLOT_PART_LIMIT then
			Log.Warn("Perf", "%s has %d parts (limit %d) — consider mesh consolidation",
				plot.Name, count, PLOT_PART_LIMIT)
		end
	end
end

local function snapshotStats()
	local heartbeat = Stats:FindFirstChild("Heartbeat") and Stats.Heartbeat:GetValue() or 0
	local physics   = Stats:FindFirstChild("Physics") and Stats.Physics:GetValue() or 0
	local players   = #Players:GetPlayers()
	Log.Debug("Perf", "players=%d heartbeat=%.2fms physics=%.2fms", players, heartbeat * 1000, physics * 1000)
	if heartbeat * 1000 > STEP_WARN_MS then
		Log.Warn("Perf", "heartbeat exceeded %dms (was %.1fms) — investigate hot loops",
			STEP_WARN_MS, heartbeat * 1000)
	end
end

function PerformanceService.Init()
	if RunService:IsClient() then return end
	task.spawn(function()
		while true do
			task.wait(SAMPLE_INTERVAL)
			snapshotStats()
			checkPlotBudgets()
		end
	end)
end

return PerformanceService
