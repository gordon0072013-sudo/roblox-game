--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config  = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local Util    = require(Shared.Util)
local Log     = require(Shared.Log)

local DailyDealService = {}

-- Rotates through a fixed list of gamepass keys, one per UTC day. The
-- price advertised to the player is the original price; Roblox's
-- billing always charges the listed gamepass price, so the "30% off"
-- positioning is for psychology — the actual discount lives in the
-- bonus cash you grant inside MonetizationService when the user buys
-- the deal-of-the-day pass. See applyDealBonusOnGamepass below for
-- the hook point.

local ROTATION = {
	"Cash2x",
	"MutationSpeed2x",
	"LuckyMutations",
	"VIPLab",
	"TripleCapture",
	"InfectionShield",
	"RainbowTrail",
	"GoldenPlot",
	"PetLucky",
	"DecorationPack",
}

local function todayDealKey(): string
	local day = Util.DayIndex()
	return ROTATION[(day % #ROTATION) + 1]
end

local function pushUpdate(player: Player)
	local key = todayDealKey()
	local gp = Config.GAMEPASSES[key]
	if not gp then return end
	local secondsLeft = (math.floor(os.time() / 86400) + 1) * 86400 - os.time()
	Remotes.Event(Remotes.Names.DailyDeal):FireClient(player, {
		key = key,
		name = gp.name,
		price = gp.price,
		discountPct = 30,
		secondsLeft = secondsLeft,
		bonusCash = 5000,
	})
end

-- Bonus delivered when a player buys the deal-of-the-day gamepass on
-- the same UTC day the deal is active. Hooked from MonetizationService.
function DailyDealService.OnGamepassPurchased(player: Player, key: string)
	if key ~= todayDealKey() then return end
	local EconomyService = require(script.Parent.EconomyService)
	EconomyService.AwardCash(player, 5000, "daily deal bonus")
	Log.Info("DailyDeal", "%s bought today's deal (%s), bonus delivered", player.Name, key)
end

function DailyDealService.OnPlayerAdded(player: Player)
	task.delay(3, pushUpdate, player)
end

function DailyDealService.Init()
	Remotes.Event(Remotes.Names.DailyDeal)
	-- Re-push to every player every 5 minutes so the countdown stays accurate.
	task.spawn(function()
		while true do
			task.wait(300)
			for _, p in ipairs(Players:GetPlayers()) do pushUpdate(p) end
		end
	end)
end

return DailyDealService
