--!strict

local MessagingService = game:GetService("MessagingService")
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log    = require(Shared.Log)

local AnnouncementService -- forward

local CrossServerShoutService = {}

local TOPIC = "BrainrotLab_Shouts_v1"
local ownServerId = HttpService:GenerateGUID(false)
local MIN_SHOUT_THRESHOLD = {
	rebirth = 25,    -- only shout cross-server for Rebirth 25+
	cash    = 10000000, -- 10M total cash earned
}

-- Sends a notable event to every server in the experience. Used sparingly:
-- the MessagingService budget is small (~60 req/min per server) so we only
-- broadcast actually-meaningful milestones.

function CrossServerShoutService.Publish(payload: any)
	if RunService:IsStudio() then return end
	pcall(function()
		MessagingService:PublishAsync(TOPIC, {
			source = ownServerId,
			payload = payload,
		})
	end)
end

function CrossServerShoutService.NotifyRebirth(player: Player, rebirths: number)
	if rebirths < MIN_SHOUT_THRESHOLD.rebirth then return end
	CrossServerShoutService.Publish({
		kind = "rebirth",
		name = player.DisplayName,
		rebirths = rebirths,
	})
end

function CrossServerShoutService.NotifyCash(player: Player, totalEarned: number)
	if totalEarned < MIN_SHOUT_THRESHOLD.cash then return end
	CrossServerShoutService.Publish({
		kind = "cash",
		name = player.DisplayName,
		totalEarned = totalEarned,
	})
end

function CrossServerShoutService.Init()
	if RunService:IsStudio() then return end
	AnnouncementService = require(script.Parent.AnnouncementService)
	local ok = pcall(function()
		MessagingService:SubscribeAsync(TOPIC, function(message: any)
			local body = message.Data
			if not body or body.source == ownServerId then return end
			local p = body.payload
			if not p then return end
			if p.kind == "rebirth" and AnnouncementService then
				AnnouncementService.Push(
					string.format("🌐 Cross-server: %s reached Rebirth %d!", p.name, p.rebirths),
					{ 255, 100, 220 }, 20)
			elseif p.kind == "cash" and AnnouncementService then
				AnnouncementService.Push(
					string.format("🌐 Cross-server: %s passed %d total cash!", p.name, p.totalEarned),
					{ 120, 220, 120 }, 20)
			end
		end)
	end)
	if not ok then
		Log.Warn("CrossShout", "MessagingService unavailable — cross-server shouts disabled")
	end
end

return CrossServerShoutService
