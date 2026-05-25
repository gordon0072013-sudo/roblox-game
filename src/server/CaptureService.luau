--!strict
--[[
	CaptureService — handles the "buy a new brainrot" action from a plot's
	capture button (and from the Rare Brainrot Egg dev product).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(Shared.Config)
local Types = require(Shared.Types)
local BrainrotData = require(Shared.BrainrotData)
local Util = require(Shared.Util)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local LabService = require(script.Parent.LabService)

local CaptureService = {}

local rng = Random.new()

function CaptureService.AttemptCapture(player: Player, opts: { freeRare: boolean?, count: number? }?)
	local data = DataService.Get(player)
	if not data then return end
	opts = opts or {}
	local count = (opts.count or 0)
	if count == 0 then
		count = if data.gamepasses["TripleCapture"] then Config.TRIPLE_CAPTURE_COUNT else Config.CAPTURE_BASE_COUNT
	end

	local cost = Config.CAPTURE_COST(data.rebirths)
	if not opts.freeRare then
		if not EconomyService.SpendCash(player, cost) then
			Remotes.Event(Remotes.Names.Notify):FireClient(player, {
				kind = "error",
				text = `Need ${cost} cash to capture.`,
			})
			return
		end
	end

	local luckyBias = if data.gamepasses["LuckyMutations"] then Config.MUTATION_LUCKY_RARITY_BIAS else 0
	if opts.freeRare then luckyBias = math.max(luckyBias, 0.8) end

	for _ = 1, count do
		local def = BrainrotData.RollSpecies(rng, false, luckyBias)
		local brainrot: Types.OwnedBrainrot = {
			uid = Util.GenerateUid(),
			speciesId = def.id,
			mutationTier = 0,
			mutations = {},
			bornAt = os.time(),
			lastMutationAt = os.time(),
			placed = false,
		}
		LabService.GiveBrainrot(player, brainrot)
		LabService.PlaceBrainrot(player, brainrot.uid)
	end
end

function CaptureService.GiveOutbreakBrainrot(player: Player, speciesId: string)
	local def = BrainrotData.Get(speciesId)
	if not def then return end
	local brainrot: Types.OwnedBrainrot = {
		uid = Util.GenerateUid(),
		speciesId = def.id,
		mutationTier = 0,
		mutations = {},
		bornAt = os.time(),
		lastMutationAt = os.time(),
		placed = false,
	}
	LabService.GiveBrainrot(player, brainrot)
	LabService.PlaceBrainrot(player, brainrot.uid)
end

function CaptureService.Init() end

return CaptureService
