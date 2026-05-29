--!strict
--[[
	WebhookService — posts notable events to a Discord webhook URL. Two
	channels supported by default:
	  * SALES — purchase notifications (gamepass + dev product receipts)
	  * MILESTONES — boss kills, rare drops, Apex mutations, big rebirths

	Setup:
	  1. In Discord server settings → Integrations → Webhooks → New
	  2. Copy the URL
	  3. Paste into the URL constants below and republish

	Discord webhook responses can fail in waves under high traffic; we
	silently swallow errors so a Discord outage never breaks the game.
]]

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local WebhookService = {}

-- IMPORTANT: never commit a real webhook URL — anyone who has the URL
-- can spam your channel. Use environment-style replacement on publish.
local SALES_WEBHOOK_URL: string? = nil      -- e.g. "https://discord.com/api/webhooks/.../..."
local MILESTONES_WEBHOOK_URL: string? = nil

local function postAsync(url: string, payload: any)
	if RunService:IsStudio() then return end
	if not url or url == "" then return end
	local body = HttpService:JSONEncode(payload)
	pcall(function()
		HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson)
	end)
end

function WebhookService.PostSale(player: Player, kind: string, key: string, price: number)
	if not SALES_WEBHOOK_URL then return end
	postAsync(SALES_WEBHOOK_URL, {
		username = "BrainrotLab Sales",
		content = string.format("💰 **%s** bought **%s** (%s) for **%d R$**",
			player.DisplayName, key, kind, price),
	})
end

function WebhookService.PostMilestone(message: string, severity: string?)
	if not MILESTONES_WEBHOOK_URL then return end
	postAsync(MILESTONES_WEBHOOK_URL, {
		username = "BrainrotLab",
		content = (severity == "big" and "🚨 " or "✨ ") .. message,
	})
end

function WebhookService.Init()
	if RunService:IsStudio() then return end
	if not SALES_WEBHOOK_URL and not MILESTONES_WEBHOOK_URL then
		print("[WebhookService] No webhook URLs configured. Edit src/server/WebhookService.luau before publishing if you want Discord notifications.")
	end
end

return WebhookService
