--!strict
--[[
	OutbreakService — runs a server-wide "Outbreak" event on a timer:
	spawns OUTBREAK_SPAWN_COUNT rare brainrots in the center plaza. Whoever
	touches one captures it (free, no cash cost). FOMO + multiplayer drama.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local BrainrotData = require(Shared.BrainrotData)
local Util = require(Shared.Util)

local DataService = require(script.Parent.DataService)
local CaptureService = require(script.Parent.CaptureService)
local BattlePassService -- forward

local OutbreakService = {}

local nextOutbreakAt: number = os.time() + Config.OUTBREAK_INTERVAL
local activeUntil: number = 0
local activeSpawns: { Model } = {}
local rng = Random.new()

local function plazaCenter(): Vector3
	return Vector3.new(0, 4, -200)
end

local function pushOutbreakState()
	local payload = {
		active = os.time() < activeUntil,
		secondsToStart = math.max(0, nextOutbreakAt - os.time()),
		secondsLeft = math.max(0, activeUntil - os.time()),
		spawnsRemaining = #activeSpawns,
	}
	for _, p in ipairs(Players:GetPlayers()) do
		Remotes.Event(Remotes.Names.OutbreakUpdate):FireClient(p, payload)
	end
end

local function spawnOne()
	local def = BrainrotData.RollSpecies(rng, true)
	local center = plazaCenter()
	local pos = center + Vector3.new(rng:NextNumber(-30,30), 0, rng:NextNumber(-30,30))

	local model = Instance.new("Model")
	model.Name = `OutbreakBrainrot_{def.id}`
	local body = Instance.new("Part")
	body.Anchored = true
	body.Size = def.sizeStuds * 1.4
	body.Position = pos + Vector3.new(0, body.Size.Y/2, 0)
	body.Color = def.color
	body.Material = Enum.Material.Neon
	if def.primaryShape == "Ball" then body.Shape = Enum.PartType.Ball end
	if def.primaryShape == "Cylinder" then body.Shape = Enum.PartType.Cylinder end
	body.Parent = model
	model.PrimaryPart = body

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(260, 80)
	bb.StudsOffset = Vector3.new(0, body.Size.Y/2 + 2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = body
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1,1)
	lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextColor3 = Color3.fromRGB(255,80,80)
	lbl.TextStrokeTransparency = 0
	lbl.Text = `OUTBREAK!\n${def.displayName}\n[${def.rarity}]`
	lbl.Parent = bb

	local fire = Instance.new("Fire")
	fire.Size = 8
	fire.Color = Color3.fromRGB(120, 255, 120)
	fire.Parent = body

	local touched = false
	body.Touched:Connect(function(hit)
		if touched then return end
		local char = hit:FindFirstAncestorOfClass("Model")
		if not char then return end
		local player = Players:GetPlayerFromCharacter(char)
		if not player then return end
		touched = true
		CaptureService.GiveOutbreakBrainrot(player, def.id)
		if BattlePassService then BattlePassService.AwardXp(player, "outbreak_brainrot") end
		local ok, BadgeService = pcall(require, script.Parent.BadgeService)
		if ok then BadgeService.Fire(player, "first_outbreak") end
		Remotes.Event(Remotes.Names.Notify):FireClient(player, {
			kind="capture",
			text=`OUTBREAK CAPTURE: ${def.displayName}!`,
		})
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player then
				Remotes.Event(Remotes.Names.Notify):FireClient(other, {
					kind="info",
					text=`${player.DisplayName} captured ${def.displayName}!`,
				})
			end
		end
		model:Destroy()
		for i, m in ipairs(activeSpawns) do
			if m == model then table.remove(activeSpawns, i) break end
		end
		pushOutbreakState()
	end)

	model.Parent = Workspace
	table.insert(activeSpawns, model)
end

local function startOutbreak()
	activeUntil = os.time() + Config.OUTBREAK_DURATION
	nextOutbreakAt = os.time() + Config.OUTBREAK_INTERVAL
	for _ = 1, Config.OUTBREAK_SPAWN_COUNT do
		spawnOne()
	end
	for _, p in ipairs(Players:GetPlayers()) do
		Remotes.Event(Remotes.Names.Notify):FireClient(p, {
			kind="info",
			text=`OUTBREAK at the plaza! ${Config.OUTBREAK_SPAWN_COUNT} rare brainrots spawned.`,
		})
	end
	pushOutbreakState()
end

local function endOutbreak()
	for _, m in ipairs(activeSpawns) do
		m:Destroy()
	end
	activeSpawns = {}
	pushOutbreakState()
end

function OutbreakService.Init()
	BattlePassService = require(script.Parent.BattlePassService)
	-- Plaza visual: a glowing pad
	local plaza = Instance.new("Part")
	plaza.Anchored = true
	plaza.Size = Vector3.new(80, 1, 80)
	plaza.Position = plazaCenter() - Vector3.new(0, 4, 0)
	plaza.Color = Color3.fromRGB(80, 0, 120)
	plaza.Material = Enum.Material.Neon
	plaza.Name = "OutbreakPlaza"
	plaza.Parent = Workspace

	local sign = Instance.new("Part")
	sign.Anchored = true
	sign.Size = Vector3.new(20, 8, 0.5)
	sign.Position = plazaCenter() + Vector3.new(0, 12, -42)
	sign.Color = Color3.fromRGB(20, 0, 30)
	sign.Material = Enum.Material.Neon
	sign.Parent = Workspace
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.CanvasSize = Vector2.new(800, 320)
	gui.Parent = sign
	local lbl = Instance.new("TextLabel")
	lbl.Name = "Label"
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextColor3 = Color3.fromRGB(255, 100, 255)
	lbl.Text = "OUTBREAK PLAZA"
	lbl.Parent = gui

	task.spawn(function()
		while true do
			task.wait(1)
			if os.time() >= nextOutbreakAt and os.time() >= activeUntil then
				startOutbreak()
			end
			if activeUntil > 0 and os.time() >= activeUntil and #activeSpawns > 0 then
				endOutbreak()
			end
			if os.time() % 5 == 0 then pushOutbreakState() end
		end
	end)
end

function OutbreakService.ForceStart()
	if os.time() < activeUntil then return end
	startOutbreak()
end

function OutbreakService.OnPlayerAdded(player: Player)
	task.delay(2, pushOutbreakState)
end

return OutbreakService
