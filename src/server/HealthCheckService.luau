--!strict

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log    = require(Shared.Log)
local Remotes= require(Shared.Remotes)

local DataService = require(script.Parent.DataService)

local HealthCheckService = {}

-- Lightweight periodic check that the data plane is healthy. Logs at
-- Warn level if any invariant is broken so the user sees it in the
-- Studio Output or in a connected analytics sink. Designed to catch
-- the regressions that don't show up in static audits: profiles
-- silently failing to load, remotes folder being deleted by a
-- third-party plugin, etc.

type Probe = {
	name: string,
	check: () -> (boolean, string?),
}

local probes: { Probe } = {}

local function addProbe(name: string, check: () -> (boolean, string?))
	table.insert(probes, { name = name, check = check })
end

addProbe("RemotesFolder", function()
	local rs = ReplicatedStorage:FindFirstChild("Remotes")
	if not rs then return false, "ReplicatedStorage.Remotes missing" end
	if #rs:GetChildren() < 30 then return false, "Remotes folder has < 30 children" end
	return true
end)

addProbe("ProfilesLoaded", function()
	for _, p in ipairs(Players:GetPlayers()) do
		if not DataService.Get(p) then
			-- Allow up to 10s for joiners to load. Stale "never loaded" is
			-- the actual signal — we just warn if a player has been here
			-- for >30s without a profile.
			local joinedAt = p:GetAttribute("_joinedAt")
			if joinedAt and (os.clock() - joinedAt) > 30 then
				return false, p.Name .. " has no profile after 30s"
			end
		end
	end
	return true
end)

addProbe("WorkspacePlots", function()
	local plots = workspace:FindFirstChild("Plots")
	if not plots then return false, "Workspace.Plots missing" end
	return true
end)

local function runAll()
	local fails = 0
	for _, probe in ipairs(probes) do
		local ok, healthy, detail = pcall(probe.check)
		if not ok then
			Log.Warn("Health", "probe '%s' errored: %s", probe.name, tostring(healthy))
			fails += 1
		elseif not healthy then
			Log.Warn("Health", "probe '%s' failed: %s", probe.name, tostring(detail))
			fails += 1
		end
	end
	if fails == 0 then
		Log.Debug("Health", "%d probes passed", #probes)
	end
end

function HealthCheckService.OnPlayerAdded(player: Player)
	player:SetAttribute("_joinedAt", os.clock())
end

function HealthCheckService.AddProbe(name: string, check: () -> (boolean, string?))
	addProbe(name, check)
end

function HealthCheckService.Init()
	task.spawn(function()
		while true do
			task.wait(60)
			runAll()
		end
	end)
	local _ = Remotes  -- suppress unused
end

return HealthCheckService
