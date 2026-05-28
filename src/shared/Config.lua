--!strict
-- Config.lua
-- Central game-balance + monetization configuration.
--
-- >>> THIS IS THE ONLY FILE YOU NORMALLY NEED TO EDIT <<<
-- After you create your Game Passes and Developer Products on the Roblox
-- Creator Dashboard (see SETUP.md), paste their numeric IDs below.
-- Everything else wires itself up automatically.

local Config = {}

-- ===== Core economy =====
Config.StartingCoins = 0
Config.BaseCoinsPerClick = 1
Config.AutoClickerInterval = 1.0 -- seconds between auto-clicks (if owned)

-- ===== Saving =====
Config.DataStoreName = "CoinClickerTycoon_v1"
Config.AutoSaveInterval = 60 -- seconds

-- ===== Monetization =====
-- Replace each 0 with the real ID from the Creator Dashboard.
-- A value of 0 means "not configured yet" and is safely ignored at runtime.

-- Game Passes: one-time purchases that grant a permanent perk.
Config.GamePasses = {
	-- key       = { id = <GamePassId>, name = "...", description = "...", grants = "..." }
	DoubleCoins   = { id = 0, name = "2x Coins",      description = "Permanently double every coin you earn.", grants = "x2 coin multiplier" },
	AutoClicker   = { id = 0, name = "Auto Clicker",  description = "Earns coins automatically while you play.", grants = "auto-click" },
	VIP           = { id = 0, name = "VIP",           description = "x3 coins, VIP tag, and exclusive area.",   grants = "x3 coin multiplier + tag" },
}

-- Developer Products: repeatable purchases (consumables).
Config.DeveloperProducts = {
	-- key        = { id = <ProductId>, name = "...", coins = <amount granted> }
	Coins1k       = { id = 0, name = "1,000 Coins",    coins = 1000 },
	Coins10k      = { id = 0, name = "10,000 Coins",   coins = 10000 },
	Coins100k     = { id = 0, name = "100,000 Coins",  coins = 100000 },
}

-- ===== Multipliers granted by passes (kept here so server logic stays generic) =====
Config.PassMultipliers = {
	DoubleCoins = 2,
	VIP = 3,
}

return Config
