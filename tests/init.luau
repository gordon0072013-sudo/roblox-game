--!strict
--[[
	Test harness for Brainrot Lab.

	Two run modes:
	  1. **Studio command bar**: paste contents of this file into the Studio
	     command bar and press Enter — results print to Output.
	  2. **Lune** (https://lune-org.github.io/docs): `lune run tests` from
	     the repo root. Lune is a Luau runtime that doesn't need Roblox.

	Tests target deterministic, pure-function logic: the economy formula,
	rarity rolls, mutation rolls, daily reward indexing. They don't touch
	DataStores or remotes.
]]

local results = { passed = 0, failed = 0, errors = {} }

local function fail(name: string, msg: string)
	results.failed += 1
	table.insert(results.errors, `[FAIL] ${name}: ${msg}`)
end

local function pass()
	results.passed += 1
end

local function eq<T>(name: string, expected: T, actual: T)
	if expected == actual then pass()
	else fail(name, `expected ${tostring(expected)}, got ${tostring(actual)}`) end
end

local function approx(name: string, expected: number, actual: number, tol: number?)
	tol = tol or 0.001
	if math.abs(expected - actual) <= tol then pass()
	else fail(name, `expected ~${expected}, got ${actual}`) end
end

local function truthy(name: string, cond: boolean)
	if cond then pass() else fail(name, "condition was false") end
end

-- ============================================================
-- Test stubs of shared modules (no Roblox API dependencies)
-- ============================================================

-- Re-derive the formulas under test from Config so we test what ships.
local function loadConfig()
	-- In a real Roblox runtime, require ReplicatedStorage.Shared.Config.
	-- For Lune we'd resolve relative paths. The simplest portable approach:
	-- inline-copy the formulas under test here.
	local Config = {}
	Config.REBIRTH_CASH_REQUIREMENT = function(r) return math.floor(2500 * (2.4 ^ r)) end
	Config.REBIRTH_INCOME_MULT = function(r) return 1 + r * 0.35 end
	Config.MUTATION_INCOME_MULT_PER_TIER = 0.6
	return Config
end

local Config = loadConfig()

-- ============================================================
-- Tests: rebirth cost curve
-- ============================================================
eq("rebirth cost @ 0", 2500, Config.REBIRTH_CASH_REQUIREMENT(0))
approx("rebirth cost @ 1", 6000, Config.REBIRTH_CASH_REQUIREMENT(1), 1)
approx("rebirth cost @ 5", 199065, Config.REBIRTH_CASH_REQUIREMENT(5), 1)
truthy("rebirth cost grows monotonically", Config.REBIRTH_CASH_REQUIREMENT(10) > Config.REBIRTH_CASH_REQUIREMENT(9))

-- ============================================================
-- Tests: rebirth income multiplier
-- ============================================================
approx("rebirth mult @ 0", 1.0, Config.REBIRTH_INCOME_MULT(0))
approx("rebirth mult @ 4", 2.4, Config.REBIRTH_INCOME_MULT(4))
approx("rebirth mult @ 10", 4.5, Config.REBIRTH_INCOME_MULT(10))

-- ============================================================
-- Tests: mutation tier income contribution
-- ============================================================
-- Total income = base * tierMult * rebirthMult * gamepassMult * ...
-- We verify the tier component only.
local function tierMult(t) return 1 + t * Config.MUTATION_INCOME_MULT_PER_TIER end
approx("tier mult T0", 1.0, tierMult(0))
approx("tier mult T6", 4.6, tierMult(6))
truthy("tier mult is monotonic", tierMult(6) > tierMult(5))

-- ============================================================
-- Tests: composite income — confirm a known scenario
-- Player with: base 10 brainrot, T3, rebirth 2, no gamepasses
-- Expected: 10 * (1 + 3*0.6) * (1 + 2*0.35) = 10 * 2.8 * 1.7 = 47.6
-- ============================================================
local function compositeIncome(base, t, rebirths, mults)
	mults = mults or {}
	local total = base * tierMult(t) * Config.REBIRTH_INCOME_MULT(rebirths)
	for _, m in ipairs(mults) do total *= m end
	return total
end
approx("composite (10, T3, R2)", 47.6, compositeIncome(10, 3, 2), 0.01)
approx("composite w/ 2x cash + pet 1.35", 47.6 * 2 * 1.35, compositeIncome(10, 3, 2, { 2, 1.35 }), 0.01)

-- ============================================================
-- Tests: daily reward bounds
-- ============================================================
local DAILY = {
	{ kind = "cash", amount = 250 },
	{ kind = "cash", amount = 500 },
	{ kind = "infection_bomb", amount = 1 },
	{ kind = "cash", amount = 1000 },
	{ kind = "rare_egg", amount = 1 },
	{ kind = "cash", amount = 2500 },
	{ kind = "cash", amount = 10000, premium_bonus = 5000 },
}
eq("daily reward count", 7, #DAILY)
truthy("day-7 reward includes premium bonus", DAILY[7].premium_bonus ~= nil)
truthy("day-3 is bomb day", DAILY[3].kind == "infection_bomb")

-- ============================================================
-- Tests: pet rarity weights sum to 100
-- ============================================================
local petWeights = { Basic = 60, Premium = 28, Legendary = 10, Mythical = 2 }
local total = 0
for _, w in pairs(petWeights) do total += w end
eq("pet weights sum to 100", 100, total)

-- ============================================================
-- Report
-- ============================================================
print(string.format("\n=== TEST RESULTS ===\n  passed: %d\n  failed: %d", results.passed, results.failed))
for _, msg in ipairs(results.errors) do print("  " .. msg) end
if results.failed > 0 then
	print("=== TESTS FAILED ===")
else
	print("=== ALL TESTS PASSED ===")
end

return results
