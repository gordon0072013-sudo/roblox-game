--!strict
--[[
	LabService — owns plots, placed brainrots (the visual scene), capture
	pads, and the income tick that converts placed brainrots into cash.

	Plot layout: 8 plots arranged in a 2x4 grid on the baseplate. Each plot
	is 80x80 studs. Slot count = STARTING_CAPACITY + rebirths*CAPACITY_PER_REBIRTH
	(soft-cap on how many you can place at once).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(Shared.Config)
local Types = require(Shared.Types)
local BrainrotData = require(Shared.BrainrotData)
local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)

local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local LabService = {}

local PLOT_COUNT = 8
local PLOT_SIZE = 80
local PLOT_SPACING = 12

local plots: { Plot } = {}
local plotOwner: { [number]: Player? } = {}
local playerPlot: { [Player]: number? } = {}
-- Active placed brainrot models keyed by player -> uid -> model
local placedModels: { [Player]: { [string]: Model } } = {}

type Plot = {
	id: number,
	folder: Folder,
	center: Vector3,
	slots: { Vector3 },
	signPart: Part,
	captureButton: Part,
}

local function buildPlot(id: number): Plot
	local plotsFolder = Workspace:WaitForChild("Plots") :: Folder
	local folder = Instance.new("Folder")
	folder.Name = `Plot_{id}`
	folder.Parent = plotsFolder

	local col = (id - 1) % 4
	local row = math.floor((id - 1) / 4)
	local center = Vector3.new(
		(col - 1.5) * (PLOT_SIZE + PLOT_SPACING),
		1,
		(row - 0.5) * (PLOT_SIZE + PLOT_SPACING)
	)

	-- Floor
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Anchored = true
	floor.Size = Vector3.new(PLOT_SIZE, 1, PLOT_SIZE)
	floor.Position = center
	floor.Color = Color3.fromRGB(60, 60, 80)
	floor.Material = Enum.Material.SmoothPlastic
	floor.Parent = folder

	-- Sign
	local sign = Instance.new("Part")
	sign.Name = "Sign"
	sign.Anchored = true
	sign.Size = Vector3.new(10, 6, 0.5)
	sign.Position = center + Vector3.new(0, 6, -PLOT_SIZE/2 + 1)
	sign.Color = Color3.fromRGB(40, 40, 60)
	sign.Material = Enum.Material.Neon
	sign.Parent = folder

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.CanvasSize = Vector2.new(800, 480)
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.fromRGB(255, 230, 120)
	label.Text = "UNCLAIMED LAB"
	label.Parent = gui

	-- Capture button
	local capture = Instance.new("Part")
	capture.Name = "CaptureButton"
	capture.Anchored = true
	capture.Size = Vector3.new(8, 1, 8)
	capture.Position = center + Vector3.new(-PLOT_SIZE/2 + 8, 1.5, -PLOT_SIZE/2 + 8)
	capture.Color = Color3.fromRGB(60, 200, 100)
	capture.Material = Enum.Material.Neon
	capture.Parent = folder
	capture:SetAttribute("PlotId", id)
	capture:SetAttribute("Kind", "Capture")

	-- Slot positions (10 evenly-spaced points along a 4x3 grid on the plot)
	local slots: { Vector3 } = {}
	for r = 1, 3 do
		for c = 1, 4 do
			local sp = Vector3.new(
				center.X + (c - 2.5) * 14,
				2,
				center.Z + (r - 2) * 14 + 8
			)
			table.insert(slots, sp)
		end
	end

	return {
		id = id,
		folder = folder,
		center = center,
		slots = slots,
		signPart = sign,
		captureButton = capture,
	}
end

local function updatePlotSign(plot: Plot, ownerName: string?, info: string?)
	local label = plot.signPart:FindFirstChildOfClass("SurfaceGui")
	if label then
		local txt = label:FindFirstChild("Label") :: TextLabel?
		if txt then
			if ownerName then
				txt.Text = `${ownerName}'s Lab\n${info or ""}`
			else
				txt.Text = "UNCLAIMED LAB"
			end
		end
	end
end

local function applyPlotCosmetics(player: Player, plot: Plot)
	local data = DataService.Get(player)
	if not data then return end
	local floor = plot.folder:FindFirstChild("Floor") :: BasePart?
	if not floor then return end
	if data.gamepasses["GoldenPlot"] then
		floor.Color = Color3.fromRGB(255, 215, 60)
		floor.Material = Enum.Material.Neon
		plot.signPart.Color = Color3.fromRGB(200, 160, 30)
	else
		floor.Color = Color3.fromRGB(60, 60, 80)
		floor.Material = Enum.Material.SmoothPlastic
		plot.signPart.Color = Color3.fromRGB(40, 40, 60)
	end
end

local function assignPlot(player: Player): number?
	for id = 1, PLOT_COUNT do
		if plotOwner[id] == nil then
			plotOwner[id] = player
			playerPlot[player] = id
			placedModels[player] = {}
			updatePlotSign(plots[id], player.DisplayName, "")
			applyPlotCosmetics(player, plots[id])
			return id
		end
	end
	return nil
end

function LabService.RefreshPlotCosmetics(player: Player)
	local id = playerPlot[player]
	if not id then return end
	applyPlotCosmetics(player, plots[id])
end

local function releasePlot(player: Player)
	local id = playerPlot[player]
	if not id then return end
	local models = placedModels[player]
	if models then
		for _, m in pairs(models) do m:Destroy() end
	end
	placedModels[player] = nil
	plotOwner[id] = nil
	playerPlot[player] = nil
	updatePlotSign(plots[id], nil, nil)
end

-- ============================================================
-- Brainrot model construction (placeholder primitives)
-- ============================================================
local function buildBrainrotModel(brainrot: Types.OwnedBrainrot, position: Vector3): Model
	local def = BrainrotData.Get(brainrot.speciesId)
	local MutationData = require(Shared.MutationData)
	if not def then
		-- shouldn't happen; build a question-mark cube
		local fallback = Instance.new("Model")
		local p = Instance.new("Part")
		p.Anchored = true
		p.Size = Vector3.new(2,2,2)
		p.Position = position
		p.Color = Color3.fromRGB(255,0,255)
		p.Parent = fallback
		fallback.PrimaryPart = p
		return fallback
	end

	local model = Instance.new("Model")
	model.Name = `Brainrot_{brainrot.uid}`

	-- Compose color & scale from mutation chain
	local color = def.color
	local scaleMult = 1
	local effects: { string } = {}
	for _, mutId in ipairs(brainrot.mutations) do
		local m = MutationData.Get(mutId)
		if m then
			if m.colorShift then
				color = color:Lerp(m.colorShift, 0.5)
			end
			scaleMult *= m.scaleMult
			if m.effect ~= "None" then
				table.insert(effects, m.effect)
			end
		end
	end

	local size = def.sizeStuds * scaleMult

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Anchored = true
	body.Size = size
	body.Position = position + Vector3.new(0, size.Y/2 + 0.5, 0)
	body.Color = color
	body.Material = Enum.Material.SmoothPlastic
	if def.primaryShape == "Ball" then
		body.Shape = Enum.PartType.Ball
	elseif def.primaryShape == "Cylinder" then
		body.Shape = Enum.PartType.Cylinder
	elseif def.primaryShape == "Wedge" then
		-- Use WedgePart
		body:Destroy()
		body = Instance.new("WedgePart")
		body.Name = "Body"
		body.Anchored = true
		body.Size = size
		body.Position = position + Vector3.new(0, size.Y/2 + 0.5, 0)
		body.Color = color
		body.Material = Enum.Material.SmoothPlastic
	end
	body.Parent = model

	-- Effects
	for _, e in ipairs(effects) do
		if e == "Sparkle" then
			local s = Instance.new("Sparkles")
			s.Parent = body
		elseif e == "Fire" then
			local f = Instance.new("Fire")
			f.Size = 5
			f.Heat = 8
			f.Parent = body
		elseif e == "Smoke" then
			local sm = Instance.new("Smoke")
			sm.Size = 3
			sm.Opacity = 0.4
			sm.Parent = body
		elseif e == "Rainbow" then
			task.spawn(function()
				local t = 0
				while body.Parent do
					t += 0.05
					body.Color = Color3.fromHSV((t % 5)/5, 0.6, 1)
					task.wait(0.1)
				end
			end)
		elseif e == "Glitch" then
			task.spawn(function()
				while body.Parent do
					body.Transparency = math.random(0, 4) * 0.1
					task.wait(0.15)
				end
			end)
		end
	end

	-- Floating name label
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(220, 60)
	bb.StudsOffset = Vector3.new(0, size.Y/2 + 2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = body
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1,1)
	lbl.BackgroundTransparency = 1
	lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBold
	lbl.TextColor3 = Color3.fromRGB(255,255,255)
	lbl.TextStrokeTransparency = 0
	local displayName = def.displayName
	for _, mutId in ipairs(brainrot.mutations) do
		local m = MutationData.Get(mutId)
		if m then displayName = `${m.suffix} ${displayName}` end
	end
	lbl.Text = `${displayName}\n[T${brainrot.mutationTier}]`
	lbl.Parent = bb

	-- Click-to-collect detector
	local cd = Instance.new("ClickDetector")
	cd.MaxActivationDistance = 18
	cd.Parent = body

	model.PrimaryPart = body
	model:SetAttribute("BrainrotUid", brainrot.uid)
	model:SetAttribute("OwnerUserId", 0) -- set when parented
	return model
end

-- Pull a brainrot's underlying record from inventory
local function findBrainrot(player: Player, uid: string): Types.OwnedBrainrot?
	local data = DataService.Get(player)
	if not data then return nil end
	for _, b in ipairs(data.inventory) do
		if b.uid == uid then return b end
	end
	return nil
end

function LabService.GetPlotIdForPlayer(player: Player): number?
	return playerPlot[player]
end

function LabService.GetPlotOwner(plotId: number): Player?
	return plotOwner[plotId]
end

function LabService.GetPlot(plotId: number): Plot?
	return plots[plotId]
end

function LabService.GetPlacedModels(player: Player): { [string]: Model }
	return placedModels[player] or {}
end

function LabService.PlaceBrainrot(player: Player, uid: string): boolean
	local data = DataService.Get(player)
	if not data then return false end
	local plotId = playerPlot[player]
	if not plotId then return false end
	local plot = plots[plotId]
	if not plot then return false end

	local brainrot = findBrainrot(player, uid)
	if not brainrot or brainrot.placed then return false end

	local capacity = Config.STARTING_CAPACITY + data.rebirths * Config.CAPACITY_PER_REBIRTH
	local placedCount = 0
	for _, b in ipairs(data.inventory) do
		if b.placed then placedCount += 1 end
	end
	if placedCount >= capacity or placedCount >= #plot.slots then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, {
			kind = "error",
			text = "Lab is full. Sell, rebirth (more capacity), or unplace one.",
		})
		return false
	end

	-- find first free slot index
	local used: { [number]: boolean } = {}
	for _, b in ipairs(data.inventory) do
		if b.placed and b.slotIndex then used[b.slotIndex] = true end
	end
	local slotIdx = 1
	while used[slotIdx] do slotIdx += 1 end

	brainrot.placed = true
	brainrot.slotIndex = slotIdx
	local pos = plot.slots[slotIdx] or plot.center
	local model = buildBrainrotModel(brainrot, pos)
	model:SetAttribute("OwnerUserId", player.UserId)
	model.Parent = plot.folder
	placedModels[player] = placedModels[player] or {}
	placedModels[player][uid] = model

	LabService.PushInventory(player)
	return true
end

function LabService.UnplaceBrainrot(player: Player, uid: string): boolean
	local brainrot = findBrainrot(player, uid)
	if not brainrot or not brainrot.placed then return false end
	brainrot.placed = false
	brainrot.slotIndex = nil
	local models = placedModels[player]
	if models and models[uid] then
		models[uid]:Destroy()
		models[uid] = nil
	end
	LabService.PushInventory(player)
	return true
end

function LabService.RebuildBrainrotVisual(player: Player, uid: string)
	local brainrot = findBrainrot(player, uid)
	if not brainrot or not brainrot.placed then return end
	local plotId = playerPlot[player]
	if not plotId then return end
	local plot = plots[plotId]
	if not plot then return end
	local models = placedModels[player]
	if not models then return end
	if models[uid] then
		models[uid]:Destroy()
	end
	local pos = plot.slots[brainrot.slotIndex or 1] or plot.center
	local model = buildBrainrotModel(brainrot, pos)
	model:SetAttribute("OwnerUserId", player.UserId)
	model.Parent = plot.folder
	models[uid] = model
end

function LabService.SellBrainrot(player: Player, uid: string): boolean
	local data = DataService.Get(player)
	if not data then return false end
	for i, b in ipairs(data.inventory) do
		if b.uid == uid then
			local def = BrainrotData.Get(b.speciesId)
			local refund = 0
			if def then
				local tierMult = 1 + b.mutationTier * Config.MUTATION_INCOME_MULT_PER_TIER
				refund = math.floor(def.baseIncomePerSecond * 60 * tierMult)
			end
			if b.placed then
				LabService.UnplaceBrainrot(player, uid)
			end
			table.remove(data.inventory, i)
			EconomyService.AwardCash(player, refund, "sold")
			LabService.PushInventory(player)
			return true
		end
	end
	return false
end

function LabService.GiveBrainrot(player: Player, brainrot: Types.OwnedBrainrot)
	local data = DataService.Get(player)
	if not data then return end
	if #data.inventory >= Config.MAX_INVENTORY_SIZE then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, {
			kind = "error",
			text = "Inventory full — sell some brainrots first.",
		})
		return
	end
	brainrot.placed = false
	brainrot.slotIndex = nil
	table.insert(data.inventory, brainrot)
	data.stats.totalCaptured += 1
	LabService.PushInventory(player)
	Remotes.Event(Remotes.Names.Notify):FireClient(player, {
		kind = "capture",
		text = `Captured ${BrainrotData.Get(brainrot.speciesId) and BrainrotData.Get(brainrot.speciesId).displayName or "?"}!`,
	})
	if data.stats.totalCaptured == 1 then
		local ok, BadgeService = pcall(require, script.Parent.BadgeService)
		if ok then BadgeService.Fire(player, "first_capture") end
	end
	local okL, PlayerLevelService = pcall(require, script.Parent.PlayerLevelService)
	if okL then PlayerLevelService.AwardXp(player, "capture") end
	local okA, AutoSellService = pcall(require, script.Parent.AutoSellService)
	if okA then AutoSellService.OnCapture(player, brainrot.uid) end
end

function LabService.TransferBrainrot(fromPlayer: Player, toPlayer: Player, uid: string): boolean
	local data = DataService.Get(fromPlayer)
	if not data then return false end
	for i, b in ipairs(data.inventory) do
		if b.uid == uid then
			if b.placed then
				LabService.UnplaceBrainrot(fromPlayer, uid)
			end
			table.remove(data.inventory, i)
			LabService.GiveBrainrot(toPlayer, b)
			LabService.PushInventory(fromPlayer)
			return true
		end
	end
	return false
end

function LabService.PushInventory(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	Remotes.Event(Remotes.Names.InventoryUpdate):FireClient(player, {
		inventory = data.inventory,
		capacity = Config.STARTING_CAPACITY + data.rebirths * Config.CAPACITY_PER_REBIRTH,
		max = Config.MAX_INVENTORY_SIZE,
	})
end

-- ============================================================
-- Income tick (server-authoritative)
-- ============================================================
local lastAccrue: { [Player]: number } = {}

function LabService.AccruePlayer(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	local now = os.clock()
	local last = lastAccrue[player] or now
	local dt = now - last
	lastAccrue[player] = now
	local total = 0
	for _, b in ipairs(data.inventory) do
		if b.placed then
			total += EconomyService.ComputeBrainrotIncome(player, b) * dt
		end
	end
	if total > 0 then
		EconomyService.AwardCash(player, total)
	end
end

function LabService.OnPlayerAdded(player: Player)
	local plotId = assignPlot(player)
	if not plotId then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, {
			kind = "error",
			text = "Server full — no lab available. Try another server.",
		})
		return
	end
	local data = DataService.Get(player)
	if data then
		data.plotId = plotId
		-- Reset placed flags from previous session (positions don't persist)
		for _, b in ipairs(data.inventory) do
			b.placed = false
			b.slotIndex = nil
		end
		-- Auto-place up to capacity
		local cap = Config.STARTING_CAPACITY + data.rebirths * Config.CAPACITY_PER_REBIRTH
		local placed = 0
		for _, b in ipairs(data.inventory) do
			if placed >= cap then break end
			LabService.PlaceBrainrot(player, b.uid)
			placed += 1
		end
		-- Give starter brainrot if inventory empty
		if #data.inventory == 0 then
			local rng = Random.new()
			local def = BrainrotData.Get("tralalero") or BrainrotData.RollSpecies(rng, false)
			local starter: Types.OwnedBrainrot = {
				uid = Util.GenerateUid(),
				speciesId = def.id,
				mutationTier = 0,
				mutations = {},
				bornAt = os.time(),
				lastMutationAt = os.time(),
				placed = false,
			}
			LabService.GiveBrainrot(player, starter)
			LabService.PlaceBrainrot(player, starter.uid)
		end
	end
	LabService.PushInventory(player)
end

function LabService.OnPlayerRemoving(player: Player)
	releasePlot(player)
	lastAccrue[player] = nil
end

function LabService.Init()
	for i = 1, PLOT_COUNT do
		plots[i] = buildPlot(i)
	end

	-- Click capture button handler
	for _, plot in pairs(plots) do
		local btn = plot.captureButton
		local cd = Instance.new("ClickDetector")
		cd.MaxActivationDistance = 16
		cd.Parent = btn
		cd.MouseClick:Connect(function(player)
			local owner = plotOwner[plot.id]
			if owner ~= player then
				Remotes.Event(Remotes.Names.Notify):FireClient(player, {
					kind = "error",
					text = "That's not your lab.",
				})
				return
			end
			local CaptureService = require(script.Parent.CaptureService)
			CaptureService.AttemptCapture(player)
		end)
	end

	-- Income heartbeat (5 Hz is enough; smooth accrual)
	task.spawn(function()
		while true do
			for _, player in ipairs(Players:GetPlayers()) do
				LabService.AccruePlayer(player)
			end
			task.wait(0.2)
		end
	end)
end

return LabService
