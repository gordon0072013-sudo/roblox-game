--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config       = require(Shared.Config)
local Remotes      = require(Shared.Remotes)
local BrainrotData = require(Shared.BrainrotData)
local Util         = require(Shared.Util)
local Log          = require(Shared.Log)

local DataService    = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local OfflineCashService = {}

-- How much of a player's offline time we credit. We cap at 8 hours so that
-- players who leave for days don't return to absurd payouts that destroy
-- the early-game economy.
local MAX_OFFLINE_HOURS    = 8
local OFFLINE_INCOME_RATIO = 0.40    -- offline income at 40% of live rate
local MIN_OFFLINE_SECONDS  = 60      -- ignore session-resume blips

local function estimatedIncomePerSec(player: Player): number
	local data = DataService.Get(player)
	if not data then return 0 end
	-- We use the *inventory* (not just placed) at 60% to reflect the fact
	-- that placed slots are bounded by plot capacity. Players with deep
	-- benches benefit from the offline window even without re-placing.
	local total = 0
	local rebirthMult = Config.REBIRTH_INCOME_MULT(data.rebirths)
	local cashMult = if data.gamepasses["Cash2x"] then 2 else 1
	for _, b in ipairs(data.inventory) do
		local def = BrainrotData.Get(b.speciesId)
		if def then
			local tierMult = 1 + b.mutationTier * Config.MUTATION_INCOME_MULT_PER_TIER
			total += def.baseIncomePerSecond * tierMult
		end
	end
	return total * rebirthMult * cashMult * 0.6
end

function OfflineCashService.OnPlayerAdded(player: Player)
	DataService.OnProfileLoaded(player, function()
		local data = DataService.Get(player)
		if not data then return end
		local prevLeftAt = (data :: any)._lastLeftAt or 0
		if prevLeftAt == 0 then
			(data :: any)._lastLeftAt = os.time()
			return
		end
		local elapsed = math.min(os.time() - prevLeftAt, MAX_OFFLINE_HOURS * 3600)
		if elapsed < MIN_OFFLINE_SECONDS then return end
		local perSec = estimatedIncomePerSec(player)
		if perSec <= 0 then return end
		local earned = math.floor(perSec * elapsed * OFFLINE_INCOME_RATIO)
		if earned <= 0 then return end
		EconomyService.AwardCash(player, earned)
		Remotes.Event(Remotes.Names.Notify):FireClient(player, {
			kind = "capture",
			text = string.format("Welcome back! +%s cash earned while away (%s).",
				Util.FormatShortNumber(earned), Util.SecondsToClock(elapsed)),
		})
		Log.Info("OfflineCash", "%s offline %ds -> +%d cash", player.Name, elapsed, earned)
	end)
end

function OfflineCashService.OnPlayerRemoving(player: Player)
	local data = DataService.Get(player)
	if data then (data :: any)._lastLeftAt = os.time() end
end

function OfflineCashService.Init() end

return OfflineCashService
