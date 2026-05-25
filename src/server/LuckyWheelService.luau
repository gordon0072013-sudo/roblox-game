--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Util    = require(Shared.Util)
local Log     = require(Shared.Log)

local DataService     = require(script.Parent.DataService)
local EconomyService  = require(script.Parent.EconomyService)

local InfectionService -- forward
local CaptureService -- forward

local LuckyWheelService = {}

-- Wheel segments. Each segment has a weight (probability mass) and a reward.
-- Weights are relative; the wheel rolls a single segment per spin.
type Segment = {
	id: string,
	label: string,
	color: { number },     -- {r,g,b} for client display
	weight: number,
	kind: string,
	amount: number?,
}

local SEGMENTS: { Segment } = {
	{ id = "cash_small",  label = "500 cash",   color = {200,200,80},  weight = 30, kind = "cash",            amount = 500   },
	{ id = "cash_med",    label = "1.5K cash",  color = {120,220,80},  weight = 22, kind = "cash",            amount = 1500  },
	{ id = "cash_big",    label = "5K cash",    color = {80,200,160},  weight = 10, kind = "cash",            amount = 5000  },
	{ id = "cash_huge",   label = "20K cash",   color = {80,140,255},  weight = 2,  kind = "cash",            amount = 20000 },
	{ id = "bomb",        label = "+1 bomb",    color = {120,255,120}, weight = 14, kind = "infection_bomb", amount = 1     },
	{ id = "bombs",       label = "+3 bombs",   color = {60,200,60},   weight = 6,  kind = "infection_bomb", amount = 3     },
	{ id = "rare_egg",    label = "Rare Egg",   color = {255,180,40},  weight = 4,  kind = "rare_egg",        amount = 1     },
	{ id = "dud",         label = "Try again",  color = {120,120,140}, weight = 12, kind = "dud",             amount = 0     },
}

local FREE_SPIN_INTERVAL_HOURS = 12   -- one free spin per 12 hours

local function ensure(data: any)
	data._wheel = data._wheel or {
		lastFreeSpinAt = 0,
		spinsAvailable = 1,     -- new players get their first spin immediately
		totalSpins     = 0,
	}
end

local function pushUpdate(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	ensure(data)
	local now = os.time()
	local freeReady = now - data._wheel.lastFreeSpinAt >= FREE_SPIN_INTERVAL_HOURS * 3600
	Remotes.Event(Remotes.Names.WheelUpdate):FireClient(player, {
		segments = SEGMENTS,
		spinsAvailable = data._wheel.spinsAvailable,
		freeReady = freeReady,
		secondsToFree = math.max(0, FREE_SPIN_INTERVAL_HOURS * 3600 - (now - data._wheel.lastFreeSpinAt)),
	})
end

local function deliver(player: Player, segment: Segment)
	if segment.kind == "cash" then
		EconomyService.AwardCash(player, segment.amount or 0, "wheel")
	elseif segment.kind == "infection_bomb" then
		if InfectionService then InfectionService.AddBombs(player, segment.amount or 1) end
	elseif segment.kind == "rare_egg" then
		if CaptureService then CaptureService.AttemptCapture(player, { freeRare = true, count = segment.amount or 1 }) end
	end
end

local function rollSegment(rng: Random): (Segment, number)
	local total = 0
	for _, seg in ipairs(SEGMENTS) do total += seg.weight end
	local pick = rng:NextNumber(0, total)
	local cursor = 0
	for i, seg in ipairs(SEGMENTS) do
		cursor += seg.weight
		if pick <= cursor then return seg, i end
	end
	return SEGMENTS[#SEGMENTS], #SEGMENTS
end

local rng = Random.new()

function LuckyWheelService.Spin(player: Player, kind: string)
	local data = DataService.Get(player)
	if not data then return end
	ensure(data)
	local now = os.time()

	if kind == "free" then
		if now - data._wheel.lastFreeSpinAt < FREE_SPIN_INTERVAL_HOURS * 3600 then
			Remotes.Event(Remotes.Names.Notify):FireClient(player, {
				kind = "error",
				text = string.format("Free spin in %s",
					Util.SecondsToClock(FREE_SPIN_INTERVAL_HOURS * 3600 - (now - data._wheel.lastFreeSpinAt))),
			})
			return
		end
		data._wheel.lastFreeSpinAt = now
	elseif kind == "stored" then
		if data._wheel.spinsAvailable <= 0 then
			Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind = "error", text = "No spins available." })
			return
		end
		data._wheel.spinsAvailable -= 1
	else
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind = "error", text = "Invalid spin kind." })
		return
	end

	local segment, index = rollSegment(rng)
	data._wheel.totalSpins += 1
	deliver(player, segment)

	Remotes.Event(Remotes.Names.WheelSpinResult):FireClient(player, {
		segmentIndex = index,
		segmentId = segment.id,
		label = segment.label,
	})
	pushUpdate(player)
	Log.Info("Wheel", "%s %s spin -> %s", player.Name, kind, segment.id)
end

function LuckyWheelService.GrantSpins(player: Player, count: number)
	local data = DataService.Get(player)
	if not data then return end
	ensure(data)
	data._wheel.spinsAvailable += count
	pushUpdate(player)
end

function LuckyWheelService.OnPlayerAdded(player: Player)
	task.delay(2, pushUpdate, player)
end

function LuckyWheelService.Init()
	InfectionService = require(script.Parent.InfectionService)
	CaptureService   = require(script.Parent.CaptureService)
	Remotes.Event(Remotes.Names.WheelUpdate)
	Remotes.Event(Remotes.Names.WheelSpinResult)
end

return LuckyWheelService
