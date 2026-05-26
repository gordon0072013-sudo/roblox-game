--!strict
--[[
	Config — single source of truth for tuning + monetization IDs.

	After publishing your gamepasses and developer products in the Roblox
	Creator Dashboard, paste their numeric IDs into the tables below. Leaving
	zeros will cause MarketplaceService prompts to fail silently in Studio
	(MonetizationService logs a warning so you can tell).
]]

local Config = {}

-- ============================================================
-- DEV / RELEASE TOGGLES
-- ============================================================
-- Bump this any time you ship a meaningful update — the new-update badge
-- on PatchNotesUI pings any player whose last-seen version is older.
Config.GAME_VERSION = "0.1.0"

-- Set to false before publishing to slow mutations to a believable cadence.
Config.FAST_TEST_MODE = false

-- Use a separate DataStore key prefix while iterating so prod saves are safe.
Config.DATASTORE_SCOPE = "BrainrotLab_v1"

-- ============================================================
-- ECONOMY
-- ============================================================
Config.STARTING_CASH = 500
Config.STARTING_CAPACITY = 4 -- brainrot slots per plot at tier 0
Config.CAPACITY_PER_REBIRTH = 2
Config.REBIRTH_CASH_REQUIREMENT = function(rebirths: number): number
	-- exponential cost curve
	return math.floor(2500 * (2.4 ^ rebirths))
end
Config.REBIRTH_INCOME_MULT = function(rebirths: number): number
	return 1 + rebirths * 0.35
end

-- Auto-collect interval (seconds) — owners gain cash without standing on plot
Config.AUTO_COLLECT_INTERVAL = 4

-- ============================================================
-- MUTATION
-- ============================================================
-- Seconds between mutation rolls per brainrot. Lower = more spectacle.
Config.MUTATION_INTERVAL = if Config.FAST_TEST_MODE then 8 else 90
Config.MUTATION_MAX_TIER = 6 -- after T6 a brainrot is "Apex" and stops mutating
Config.MUTATION_INCOME_MULT_PER_TIER = 0.6 -- +60% income per tier
Config.MUTATION_GAMEPASS_SPEED_MULT = 2 -- 2x Mutation Speed gamepass effect
Config.MUTATION_LUCKY_RARITY_BIAS = 0.35 -- Lucky Mutations gamepass — pushes toward rarer rolls

-- ============================================================
-- CAPTURE
-- ============================================================
Config.CAPTURE_COST = function(playerRebirths: number): number
	return 50 + playerRebirths * 25
end
Config.CAPTURE_BASE_COUNT = 1
Config.TRIPLE_CAPTURE_COUNT = 3 -- Triple Capture gamepass

-- ============================================================
-- PVP — STEAL
-- ============================================================
Config.STEAL_COOLDOWN = 120 -- per-victim per-attacker
Config.STEAL_GRACE_PERIOD_AFTER_JOIN = 90 -- new joiners are safe for 90s
Config.STEAL_MAX_TIER_DELTA = 2 -- can only steal brainrots within 2 tiers of your best
Config.STEAL_DETECTION_RADIUS = 14 -- studs from any brainrot the attacker must be inside

-- ============================================================
-- PVP — INFECTION
-- ============================================================
Config.INFECTION_DEBUFF_DURATION = 180
Config.INFECTION_INCOME_MULT = 0.4 -- victim earns 40% during debuff
Config.INFECTION_BOMB_STARTER_COUNT = 1 -- new players get 1 free bomb
Config.INFECTION_BOMB_DEVPRODUCT_COUNT = 5
Config.INFECTION_SHIELD_GAMEPASS_REDUCTION = 0.7 -- 70% damage reduction on the multiplier penalty

-- ============================================================
-- OUTBREAK (server-wide event)
-- ============================================================
Config.OUTBREAK_INTERVAL = if Config.FAST_TEST_MODE then 60 else 1200 -- 20 min
Config.OUTBREAK_DURATION = 180
Config.OUTBREAK_SPAWN_COUNT = 8
Config.OUTBREAK_RARE_BIAS = 0.7 -- bias toward Epic+

-- ============================================================
-- DAILY REWARDS (7-day cycle)
-- ============================================================
Config.DAILY_REWARDS = {
	{ kind = "cash", amount = 250 },
	{ kind = "cash", amount = 500 },
	{ kind = "infection_bomb", amount = 1 },
	{ kind = "cash", amount = 1000 },
	{ kind = "rare_egg", amount = 1 },
	{ kind = "cash", amount = 2500 },
	{ kind = "cash", amount = 10000, premium_bonus = 5000 },
}

-- ============================================================
-- MONETIZATION IDs  (replace 0s with real IDs after publishing)
-- ============================================================
Config.GAMEPASSES = {
	MutationSpeed2x = { id = 0, price = 199, name = "2x Mutation Speed" },
	Cash2x          = { id = 0, price = 249, name = "2x Cash" },
	VIPLab          = { id = 0, price = 499, name = "VIP Lab" },
	InfectionShield = { id = 0, price = 299, name = "Infection Shield" },
	LuckyMutations  = { id = 0, price = 349, name = "Lucky Mutations" },
	TripleCapture   = { id = 0, price = 399, name = "Triple Capture" },
	RainbowTrail    = { id = 0, price = 149, name = "Rainbow Trail" }, -- cosmetic, high-margin whale slot
	GoldenPlot      = { id = 0, price = 199, name = "Golden Plot" },   -- cosmetic floor + sign upgrade
	PetLucky        = { id = 0, price = 299, name = "Pet Lucky" },     -- biases pet rolls toward Legendary/Mythical
	DecorationPack  = { id = 0, price = 249, name = "Decoration Pack" }, -- unlocks premium-tier decorations
}

Config.DEV_PRODUCTS = {
	-- Cash packs
	CashSmall   = { id = 0, price = 49,  name = "Cash Pack: Small",   kind = "cash", amount = 1000 },
	CashMedium  = { id = 0, price = 99,  name = "Cash Pack: Medium",  kind = "cash", amount = 3000 },
	CashLarge   = { id = 0, price = 199, name = "Cash Pack: Large",   kind = "cash", amount = 7500 },
	CashHuge    = { id = 0, price = 499, name = "Cash Pack: Huge",    kind = "cash", amount = 25000 },
	CashTycoon  = { id = 0, price = 999, name = "Cash Pack: Tycoon",  kind = "cash", amount = 60000 },
	-- Convenience
	InstantMutation = { id = 0, price = 75,  name = "Instant Mutation", kind = "instant_mutation" },
	SkipRebirth     = { id = 0, price = 99,  name = "Skip Rebirth",     kind = "skip_rebirth" },
	RareBrainrotEgg = { id = 0, price = 149, name = "Rare Brainrot Egg", kind = "rare_egg" },
	InfectionBomb5  = { id = 0, price = 89,  name = "Infection Bombs x5", kind = "infection_bomb", amount = 5 },
	-- Battle pass (premium tier purchase)
	BattlePassPremium = { id = 0, price = 999, name = "Premium Battle Pass", kind = "battle_pass" },
	-- Pets (the high-ARPU mechanic)
	PetEgg            = { id = 0, price = 99,  name = "Pet Egg",            kind = "pet_egg" },
	PetEggGolden      = { id = 0, price = 399, name = "Golden Pet Egg (luckier)", kind = "pet_egg_lucky" },
	-- Wheel
	WheelSpinPack5    = { id = 0, price = 79,  name = "5 Wheel Spins",       kind = "wheel_spins", amount = 5 },
	WheelSpinPack25   = { id = 0, price = 299, name = "25 Wheel Spins",      kind = "wheel_spins", amount = 25 },
	-- Tips (developer support)
	TipSmall          = { id = 0, price = 50,  name = "Tip the Dev (Small)", kind = "tip", amount = 50  },
	TipMedium         = { id = 0, price = 200, name = "Tip the Dev",         kind = "tip", amount = 200 },
	TipLarge          = { id = 0, price = 1000,name = "Tip the Dev (Mega)",  kind = "tip", amount = 1000},
}

-- ============================================================
-- BATTLE PASS
-- ============================================================
Config.BATTLE_PASS_XP_PER_TIER = 1000
Config.BATTLE_PASS_TIERS = 30
Config.BATTLE_PASS_DURATION_DAYS = 14
Config.BATTLE_PASS_XP_SOURCES = {
	mutation = 25,
	capture = 15,
	steal = 75,
	infection = 50,
	outbreak_brainrot = 100,
	rebirth = 500,
}

-- ============================================================
-- ANTI-EXPLOIT / SOFT LIMITS
-- ============================================================
Config.MAX_INVENTORY_SIZE = 200
Config.PURCHASE_LOG_RING_SIZE = 50

-- ============================================================
-- ADMIN
-- ============================================================
-- The experience owner (game.CreatorId) is admin by default. Add extra
-- UserIds here to grant admin access without owning the experience.
-- Owner-only commands stay locked to game.CreatorId.
Config.ADMIN_USER_IDS = {} :: { number }

-- ============================================================
-- COMMUNITY / GROUP REWARD
-- ============================================================
-- Replace with your real Roblox group id after creating one. A 0 disables
-- the prompt and reward. Encourage players to join via the in-game banner;
-- group members get a permanent income multiplier and you get a
-- discoverable hub for announcements + Premium-eligible engagement.
Config.GROUP_ID = 0
Config.GROUP_REWARD_MULT = 1.25 -- +25% cash income for group members

-- Optional Discord invite shown in the same banner. Leave nil to hide.
Config.DISCORD_INVITE_URL = nil :: string?

-- ============================================================
-- CODE REDEMPTION (your marketing dial)
-- ============================================================
-- Codes are case-insensitive. Each code may be redeemed once per player.
-- Use these in TikTok/Shorts/Reels videos to drive view-to-play conversion:
--   "Redeem code TIKTOK1K for 1,000 free cash!"
-- After release, just add more entries to this table and republish.
type RedeemableReward = {
	kind: string,
	amount: number?,
	expiresAt: number?, -- unix time; nil = no expiry
	label: string?,
}
Config.REDEMPTION_CODES = {
	LAUNCH        = { kind = "cash", amount = 2500, label = "Launch reward" },
	BRAINROT      = { kind = "cash", amount = 1500, label = "Welcome to the lab" },
	TIKTOK1K      = { kind = "cash", amount = 1000, label = "TikTok viewer reward" },
	OUTBREAK      = { kind = "infection_bomb", amount = 3, label = "Outbreak survival kit" },
	MUTATE        = { kind = "instant_mutation", amount = 1, label = "Free instant mutation" },
	SIGMA         = { kind = "rare_egg", amount = 1, label = "Sigma seed" },
} :: { [string]: RedeemableReward }

return Config
