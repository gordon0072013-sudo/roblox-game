--!strict

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Log     = require(Shared.Log)

local AnnouncementService -- forward

local HotStreakService = {}

-- Cash multiplier ramps with concurrent player count. Drives social proof
-- (high CCU server feels rewarding to be in) and counter-intuitively
-- *retains* players when a server is full — they don't want to leave the
-- party.
local STREAK_TIERS = {
	{ minPlayers = 2,  mult = 1.10, label = "Cozy"  },
	{ minPlayers = 4,  mult = 1.25, label = "Warm"  },
	{ minPlayers = 6,  mult = 1.50, label = "Hot"   },
	{ minPlayers = 8,  mult = 1.75, label = "BLAZING"},
}

local currentMult = 1
local currentLabel = ""

local function recompute()
	local n = #Players:GetPlayers()
	local mult = 1
	local label = ""
	for _, tier in ipairs(STREAK_TIERS) do
		if n >= tier.minPlayers then
			mult = tier.mult
			label = tier.label
		end
	end
	if mult ~= currentMult then
		Log.Info("HotStreak", "%d players → %s (%.2fx)", n, label, mult)
		if label ~= "" and AnnouncementService then
			AnnouncementService.Push(string.format("🔥 %s server — every player earns %.2fx cash!", label, mult),
				{ 255, 120, 60 }, 30)
		end
	end
	currentMult = mult
	currentLabel = label
end

function HotStreakService.GetMultiplier(): number
	return currentMult
end

function HotStreakService.GetLabel(): string
	return currentLabel
end

function HotStreakService.OnPlayerAdded(_: Player)
	recompute()
end

function HotStreakService.OnPlayerRemoving(_: Player)
	task.defer(recompute)
end

function HotStreakService.Init()
	AnnouncementService = require(script.Parent.AnnouncementService)
	Players.PlayerAdded:Connect(function() recompute() end)
	Players.PlayerRemoving:Connect(function() task.defer(recompute) end)
	recompute()
	-- Suppress unused
	local _ = Remotes
end

return HotStreakService
