--!strict

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Log     = require(Shared.Log)

local DataService    = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local GraceShutdownService = {}

-- BindToClose only gets ~30s from Roblox before the server is hard-killed.
-- We use that budget to:
--   1. Broadcast a visible 'server restart in 30s' toast.
--   2. Award a small 'sorry for the inconvenience' cash bonus so the
--      memory of the session ends on a positive note (key for D2 return).
--   3. Wait long enough that profile autosaves complete.
-- ProfileService's release-on-shutdown lives in DataService; this service
-- *adds* the user-facing layer on top of it.

local SHUTDOWN_BONUS = 5000

local function broadcast(text: string)
	for _, p in ipairs(Players:GetPlayers()) do
		Remotes.Event(Remotes.Names.Notify):FireClient(p, { kind = "info", text = text })
	end
end

function GraceShutdownService.Init()
	game:BindToClose(function()
		if RunService:IsStudio() then return end
		Log.Info("Shutdown", "shutdown signal received, broadcasting + awarding bonus")
		broadcast("⚠ Server restart in 30 seconds. Cash bonus awarded — rejoin to continue!")
		for _, p in ipairs(Players:GetPlayers()) do
			pcall(EconomyService.AwardCash, p, SHUTDOWN_BONUS, "shutdown bonus")
		end
		-- Give clients ~3s to render the toast, then let DataService.BindToClose
		-- run (it has its own task.wait(2) for profile release).
		task.wait(3)
	end)
end

return GraceShutdownService
