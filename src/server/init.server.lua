--!strict
-- init.server.lua
-- Server entry point. Wires together data, monetization and game logic,
-- handles player lifecycle, the click loop, auto-clicker, and autosave.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local server = script.Parent
local DataManager = require(server.DataManager)
local Monetization = require(server.Monetization)

-- ===== Coin granting (shared by clicks, products, auto-clicker) =====
local function addCoins(player: Player, amount: number)
	local profile = DataManager.Get(player)
	if not profile then
		return
	end
	profile.coins += amount
	profile.totalEarned += amount
	Remotes.StatsUpdated():FireClient(player, {
		coins = profile.coins,
		totalEarned = profile.totalEarned,
		clicks = profile.clicks,
		multiplier = Monetization.GetMultiplier(player),
	})
end

Monetization.SetGrantCoinsCallback(addCoins)
Monetization.Init()

-- ===== Player lifecycle =====
local function onPlayerAdded(player: Player)
	DataManager.Load(player)
	Monetization.LoadPasses(player)

	local profile = DataManager.Get(player)
	if profile then
		Remotes.StatsUpdated():FireClient(player, {
			coins = profile.coins,
			totalEarned = profile.totalEarned,
			clicks = profile.clicks,
			multiplier = Monetization.GetMultiplier(player),
		})
	end
end

local function onPlayerRemoving(player: Player)
	DataManager.Release(player)
	Monetization.Release(player)
end

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- ===== Click handling =====
-- Server-authoritative: the client only signals "I clicked"; the server
-- decides how many coins that is worth. Basic rate limiting prevents spam.
local lastClick: { [number]: number } = {}
local MIN_CLICK_INTERVAL = 0.05 -- 20 clicks/sec ceiling

Remotes.Click().OnServerEvent:Connect(function(player)
	local now = os.clock()
	if lastClick[player.UserId] and now - lastClick[player.UserId] < MIN_CLICK_INTERVAL then
		return
	end
	lastClick[player.UserId] = now

	local profile = DataManager.Get(player)
	if not profile then
		return
	end
	profile.clicks += 1
	local gain = Config.BaseCoinsPerClick * Monetization.GetMultiplier(player)
	addCoins(player, gain)
end)

-- ===== Purchase prompts (client asks server to open Roblox prompt) =====
Remotes.PromptPurchase().OnServerEvent:Connect(function(player, kind, itemKey)
	if type(kind) ~= "string" or type(itemKey) ~= "string" then
		return
	end
	if kind == "pass" then
		local info = Config.GamePasses[itemKey]
		if info and info.id and info.id > 0 then
			MarketplaceService:PromptGamePassPurchase(player, info.id)
		end
	elseif kind == "product" then
		local info = Config.DeveloperProducts[itemKey]
		if info and info.id and info.id > 0 then
			MarketplaceService:PromptProductPurchase(player, info.id)
		end
	end
end)

-- Re-check pass ownership right after a pass purchase finishes.
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, _gamePassId, wasPurchased)
	if wasPurchased then
		Monetization.LoadPasses(player)
		local profile = DataManager.Get(player)
		if profile then
			Remotes.StatsUpdated():FireClient(player, {
				coins = profile.coins,
				totalEarned = profile.totalEarned,
				clicks = profile.clicks,
				multiplier = Monetization.GetMultiplier(player),
			})
		end
	end
end)

-- ===== Catalog (client builds the shop UI from this) =====
Remotes.GetCatalog().OnServerInvoke = function()
	local passes = {}
	for passKey, info in pairs(Config.GamePasses) do
		table.insert(passes, {
			key = passKey, id = info.id, name = info.name,
			description = info.description, grants = info.grants,
		})
	end
	local products = {}
	for productKey, info in pairs(Config.DeveloperProducts) do
		table.insert(products, {
			key = productKey, id = info.id, name = info.name, coins = info.coins,
		})
	end
	return { passes = passes, products = products }
end

-- ===== Auto-clicker loop (for owners of the AutoClicker pass) =====
task.spawn(function()
	while true do
		task.wait(Config.AutoClickerInterval)
		for _, player in ipairs(Players:GetPlayers()) do
			if Monetization.OwnsPass(player, "AutoClicker") then
				local gain = Config.BaseCoinsPerClick * Monetization.GetMultiplier(player)
				addCoins(player, gain)
			end
		end
	end
end)

-- ===== Autosave loop =====
task.spawn(function()
	while true do
		task.wait(Config.AutoSaveInterval)
		DataManager.SaveAll()
	end
end)

-- ===== Shutdown protection =====
game:BindToClose(function()
	if RunService:IsStudio() then
		return
	end
	DataManager.SaveAll()
	task.wait(3) -- give async saves a moment to flush
end)

print("[CoinClickerTycoon] Server initialized.")
