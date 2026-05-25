--!strict

local Config = {}

Config.GAME_NAME    = "Chartbreak"
Config.GAME_VERSION = "0.1.0"

Config.FAST_TEST_MODE  = false
Config.DATASTORE_SCOPE = "Chartbreak_v1"

-- ============================================================
-- LANES & INPUTS
-- ============================================================
-- 4-lane standard. Add more keys here if you ever want 6K or 7K modes;
-- ChartLibrary's note.lane is interpreted modulo Config.LANES.
Config.LANES = 4
Config.LANE_KEYS = {
	Enum.KeyCode.D,
	Enum.KeyCode.F,
	Enum.KeyCode.J,
	Enum.KeyCode.K,
}

-- ============================================================
-- TIMING WINDOWS (milliseconds from perfect)
-- ============================================================
-- Single source of truth for both client-side feedback and server-side
-- validation. AntiCheat rejects any judgement claim outside MISS.
Config.JUDGEMENT_WINDOWS = {
	{ id = "marvelous", ms = 22,  scoreWeight = 1.00, comboKeep = true  },
	{ id = "perfect",   ms = 45,  scoreWeight = 0.95, comboKeep = true  },
	{ id = "great",     ms = 90,  scoreWeight = 0.70, comboKeep = true  },
	{ id = "good",      ms = 135, scoreWeight = 0.40, comboKeep = false },
	{ id = "miss",      ms = 180, scoreWeight = 0,    comboKeep = false },
}

-- ============================================================
-- SCORING
-- ============================================================
Config.MAX_SCORE_PER_NOTE = 1000
Config.COMBO_BONUS_CAP    = 1.5  -- combo multiplier soft-caps at 1.5x
Config.COMBO_RAMP_NOTES   = 100  -- combo multiplier reaches cap at this combo

Config.HEALTH_MAX             = 100
Config.HEALTH_PER_HIT         = 2
Config.HEALTH_PENALTY_MISS    = 10
Config.HEALTH_FAIL_THRESHOLD  = 0     -- fail-out at 0 health

-- ============================================================
-- ROUND TIMING
-- ============================================================
Config.PRE_ROUND_SECONDS  = 3   -- countdown after song select
Config.POST_ROUND_SECONDS = 8   -- results screen display time
Config.SONG_LOAD_TIMEOUT  = 6   -- how long we wait for client to confirm chart loaded

-- ============================================================
-- MONETIZATION  (replace 0s with real IDs after publishing)
-- ============================================================
Config.GAMEPASSES = {
	PremiumPass     = { id = 0, price = 499, name = "Premium Pass" },         -- access premium songs + cosmetics
	DoubleScore     = { id = 0, price = 299, name = "Double Score" },         -- 2x score multiplier permanent
	AutoRetry       = { id = 0, price = 149, name = "Auto Retry" },           -- skip the results delay on fail
	CustomSkins     = { id = 0, price = 199, name = "Note Skin Pack" },       -- unlocks alternate note skins
}

Config.DEV_PRODUCTS = {
	Boost1000       = { id = 0, price = 99,  name = "Score Boost (next song)",    kind = "next_song_boost", amount = 1.5 },
	UnlockSongHard  = { id = 0, price = 199, name = "Unlock 'Hard' Difficulty",   kind = "unlock_difficulty", value = "hard" },
	UnlockSongInsane= { id = 0, price = 299, name = "Unlock 'Insane' Difficulty", kind = "unlock_difficulty", value = "insane" },
	-- Per-song unlocks come from the ChartLibrary at runtime (one product per premium song).
}

-- ============================================================
-- ANTI-CHEAT TUNING
-- ============================================================
-- Notes-per-second cap. Even on Insane charts a player can't sustain
-- > 18 hits/s. Higher rates almost certainly mean a TAS or macro.
Config.MAX_HIT_RATE_PER_SECOND = 18

-- A perfect run (every note marvelous) is allowed but flagged in analytics
-- for human review above this threshold of consecutive marvelous hits.
Config.SUSPICIOUS_MARVELOUS_STREAK = 250

-- Per-round score sanity. Anything above this implies fabricated input.
Config.MAX_PLAUSIBLE_SCORE_RATIO = 1.05 -- 5% headroom over theoretical max

-- ============================================================
-- DAILY REWARDS
-- ============================================================
Config.DAILY_REWARDS = {
	{ kind = "currency", amount = 250  },
	{ kind = "currency", amount = 500  },
	{ kind = "boost",    amount = 1    },
	{ kind = "currency", amount = 1000 },
	{ kind = "currency", amount = 1500 },
	{ kind = "boost",    amount = 2    },
	{ kind = "currency", amount = 5000, premiumBonus = 2500 },
}

return Config
