--!strict
--[[
	AnalyticsService — lightweight in-process counters and a DataStore-backed
	purchase log. Use the in-Studio Output to monitor purchase rates during
	playtest; for production, swap in your preferred analytics SDK
	(PlayFab, GameAnalytics, etc.) by extending LogPurchase.
]]

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local AnalyticsService = {}

local purchases: { { userId: number, kind: string, key: string, price: number, at: number } } = {}

local store: DataStore? = nil
pcall(function()
	if not RunService:IsStudio() then
		store = DataStoreService:GetDataStore("BrainrotLab_Analytics_v1")
	end
end)

function AnalyticsService.LogPurchase(player: Player, kind: string, key: string, price: number)
	local entry = { userId = player.UserId, kind = kind, key = key, price = price, at = os.time() }
	table.insert(purchases, entry)
	print(string.format("[ANALYTICS] %s bought %s (%s) for %d R$ — total purchases this server: %d",
		player.DisplayName, key, kind, price, #purchases))
	if store then
		pcall(function()
			store:SetAsync(`${player.UserId}_${os.time()}_${key}`, entry)
		end)
	end
	local ok, WebhookService = pcall(require, script.Parent.WebhookService)
	if ok then WebhookService.PostSale(player, kind, key, price) end
end

function AnalyticsService.Summary(): { totalRobux: number, count: number }
	local total = 0
	for _, p in ipairs(purchases) do total += p.price end
	return { totalRobux = total, count = #purchases }
end

function AnalyticsService.Init() end

return AnalyticsService
