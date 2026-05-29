--!strict
--[[
	DecorationService — buying and placing cosmetic decorations on a plot.

	Storage: data._decorations = { { id, posOffsetX, posOffsetZ, rotY } }
	Placement: 12 fixed grid slots per plot in the decoration zone (back row).
	Cap: 12 placed at once. Selling refunds 50% of purchase price.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local DecorationData = require(Shared.DecorationData)
local Util = require(Shared.Util)

local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local LabService = require(script.Parent.LabService)

local DecorationService = {}

local placedModels: { [Player]: { [string]: Model } } = {}
local DECO_PER_PLOT = 12

local function decoSlotPositions(plotCenter: Vector3): { Vector3 }
	local slots = {}
	for c = 1, DECO_PER_PLOT do
		local row = math.floor((c - 1) / 4)
		local col = (c - 1) % 4
		table.insert(slots, plotCenter + Vector3.new((col - 1.5) * 10, 2, -28 + row * 8))
	end
	return slots
end

local function ensureDecoField(data: any)
	data._decorations = data._decorations or {}  -- { [uid] = { id, slot } }
end

local function buildDecoModel(def: any, pos: Vector3): Model
	local model = Instance.new("Model")
	model.Name = `Deco_{def.id}`
	local body = Instance.new("Part")
	body.Anchored = true
	body.CanCollide = false
	body.Size = def.size
	body.Position = pos + Vector3.new(0, body.Size.Y/2, 0)
	body.Color = def.color
	body.Material = def.material
	if def.primaryShape == "Ball" then body.Shape = Enum.PartType.Ball
	elseif def.primaryShape == "Cylinder" then body.Shape = Enum.PartType.Cylinder end
	body.Parent = model
	model.PrimaryPart = body

	if def.effect == "Sparkle" then
		local s = Instance.new("Sparkles"); s.Parent = body
	elseif def.effect == "Fire" then
		local f = Instance.new("Fire"); f.Size = 4; f.Parent = body
	elseif def.effect == "Rainbow" then
		task.spawn(function()
			local t = 0
			while body.Parent do
				t += 0.05
				body.Color = Color3.fromHSV((t % 5)/5, 0.7, 1)
				task.wait(0.1)
			end
		end)
	end
	return model
end

local function renderAll(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	ensureDecoField(data)
	local plotId = LabService.GetPlotIdForPlayer(player)
	if not plotId then return end
	local plot = LabService.GetPlot(plotId)
	if not plot then return end

	-- Clear existing
	local models = placedModels[player] or {}
	for _, m in pairs(models) do m:Destroy() end
	placedModels[player] = {}

	local slots = decoSlotPositions(plot.center)
	for uid, entry in pairs(data._decorations) do
		local def = DecorationData.Get(entry.id)
		if def and entry.slot and slots[entry.slot] then
			local model = buildDecoModel(def, slots[entry.slot])
			model:SetAttribute("OwnerUserId", player.UserId)
			model.Parent = plot.folder
			placedModels[player][uid] = model
		end
	end
end

local function nextFreeSlot(data: any): number?
	local used = {}
	for _, entry in pairs(data._decorations) do
		used[entry.slot] = true
	end
	for i = 1, DECO_PER_PLOT do
		if not used[i] then return i end
	end
	return nil
end

local function pushUpdate(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	ensureDecoField(data)
	local owned = {}
	for uid, entry in pairs(data._decorations) do
		table.insert(owned, { uid = uid, id = entry.id, slot = entry.slot })
	end
	Remotes.Event(Remotes.Names.DecorationUpdate):FireClient(player, {
		catalog = DecorationData.GetAll(),
		owned = owned,
		capacity = DECO_PER_PLOT,
		hasPremium = (data.gamepasses :: any)["DecorationPack"] == true,
	})
end

function DecorationService.Buy(player: Player, id: string)
	local def = DecorationData.Get(id)
	if not def then return end
	local data = DataService.Get(player)
	if not data then return end
	ensureDecoField(data)
	if def.premium and not (data.gamepasses :: any)["DecorationPack"] then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text="Premium decoration — needs Decoration Pack gamepass." })
		return
	end
	if not EconomyService.SpendCash(player, def.cost) then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text=`Need {def.cost} cash.` })
		return
	end
	local slot = nextFreeSlot(data)
	if not slot then
		EconomyService.AwardCash(player, def.cost) -- refund
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text="Decoration zone is full." })
		return
	end
	local uid = Util.GenerateUid()
	data._decorations[uid] = { id = def.id, slot = slot, cost = def.cost }
	renderAll(player)
	pushUpdate(player)
	Remotes.Event(Remotes.Names.Notify):FireClient(player, {
		kind = "capture", text = `Placed: {def.name}`,
	})
end

function DecorationService.Sell(player: Player, uid: string)
	local data = DataService.Get(player)
	if not data then return end
	ensureDecoField(data)
	local entry = data._decorations[uid]
	if not entry then return end
	local refund = math.floor((entry.cost or 0) * 0.5)
	data._decorations[uid] = nil
	if refund > 0 then EconomyService.AwardCash(player, refund, "deco refund") end
	renderAll(player)
	pushUpdate(player)
end

function DecorationService.OnPlayerAdded(player: Player)
	placedModels[player] = {}
	task.delay(3, function()
		renderAll(player)
		pushUpdate(player)
	end)
end

function DecorationService.OnPlayerRemoving(player: Player)
	local models = placedModels[player]
	if models then for _, m in pairs(models) do m:Destroy() end end
	placedModels[player] = nil
end

function DecorationService.Init()
	local _ = Config
end

return DecorationService
