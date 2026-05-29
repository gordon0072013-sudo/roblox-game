--!strict
--[[
	BossEventService — once every 45 min a "Mega Brainrot" boss spawns at
	the plaza. All players in the server can damage it by clicking. The
	boss has lots of HP; damage scales with the attacker's rebirth tier so
	high-rebirth players carry but everyone contributes. Each damaging
	player gets a share of the loot pool (cash + rare egg roll) on kill.

	Why cooperative? It's the one mode where players HAVE to interact
	without fighting each other. Cooperative events drive friendship loops
	and group voice-chat retention, both of which dominate LTV in tycoon
	games (Adopt Me's adoption + trade community is the canonical example).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local CaptureService -- forward

local BossEventService = {}

local BOSS_INTERVAL = if Config.FAST_TEST_MODE then 90 else 2700 -- 45 min
local BOSS_DURATION = 240
local BOSS_HP_BASE = 50000

local nextBossAt = os.time() + BOSS_INTERVAL
local activeBoss: { model: Model, hp: number, maxHp: number, damageBy: { [number]: number }, endsAt: number }? = nil

local function bossCenter(): Vector3
	return Vector3.new(160, 6, -200)
end

local function broadcastState()
	local payload
	if activeBoss then
		payload = {
			active = true,
			hp = activeBoss.hp,
			maxHp = activeBoss.maxHp,
			secondsLeft = math.max(0, activeBoss.endsAt - os.time()),
			contributors = 0,
		}
		for _ in pairs(activeBoss.damageBy) do payload.contributors += 1 end
	else
		payload = {
			active = false,
			secondsToStart = math.max(0, nextBossAt - os.time()),
		}
	end
	for _, p in ipairs(Players:GetPlayers()) do
		Remotes.Event(Remotes.Names.BossUpdate):FireClient(p, payload)
	end
end

local function payoutAndEnd(victory: boolean)
	if not activeBoss then return end
	local pool = victory and 50000 or 10000
	local total = 0
	for _, dmg in pairs(activeBoss.damageBy) do total += dmg end
	if total > 0 then
		for userId, dmg in pairs(activeBoss.damageBy) do
			local player = Players:GetPlayerByUserId(userId)
			if player then
				local share = math.floor(pool * dmg / total)
				EconomyService.AwardCash(player, share, "boss share")
				if victory and dmg / total >= 0.05 then
					-- Top contributors get a rare egg
					if CaptureService then
						CaptureService.AttemptCapture(player, { freeRare = true, count = 1 })
					end
				end
				Remotes.Event(Remotes.Names.Notify):FireClient(player, {
					kind = victory and "capture" or "info",
					text = victory and `Boss defeated! +{share} cash` or `Boss escaped. +{share} cash`,
				})
			end
		end
	end
	if activeBoss.model.Parent then activeBoss.model:Destroy() end
	activeBoss = nil
	nextBossAt = os.time() + BOSS_INTERVAL
	broadcastState()
end

local function spawnBoss()
	local center = bossCenter()
	local model = Instance.new("Model")
	model.Name = "MegaBrainrot"

	local body = Instance.new("Part")
	body.Anchored = true
	body.Size = Vector3.new(18, 18, 18)
	body.Position = center + Vector3.new(0, body.Size.Y/2, 0)
	body.Color = Color3.fromRGB(255, 60, 60)
	body.Material = Enum.Material.Neon
	body.Shape = Enum.PartType.Ball
	body.Parent = model
	model.PrimaryPart = body

	local fire = Instance.new("Fire")
	fire.Size = 20
	fire.Heat = 12
	fire.Parent = body

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(420, 100)
	bb.StudsOffset = Vector3.new(0, 14, 0)
	bb.AlwaysOnTop = true
	bb.Parent = body
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextScaled = true
	lbl.TextColor3 = Color3.fromRGB(255, 80, 80)
	lbl.TextStrokeTransparency = 0
	lbl.Text = "MEGA BRAINROT\nCLICK TO ATTACK"
	lbl.Name = "Label"
	lbl.Parent = bb

	local maxHp = BOSS_HP_BASE + (#Players:GetPlayers() * 15000)
	activeBoss = {
		model = model,
		hp = maxHp,
		maxHp = maxHp,
		damageBy = {},
		endsAt = os.time() + BOSS_DURATION,
	}

	local cd = Instance.new("ClickDetector")
	cd.MaxActivationDistance = 60
	cd.Parent = body
	cd.MouseClick:Connect(function(player)
		if not activeBoss then return end
		local data = DataService.Get(player)
		if not data then return end
		local dmg = 100 + data.rebirths * 80
		activeBoss.hp = math.max(0, activeBoss.hp - dmg)
		activeBoss.damageBy[player.UserId] = (activeBoss.damageBy[player.UserId] or 0) + dmg
		lbl.Text = string.format("MEGA BRAINROT\n%d / %d HP", activeBoss.hp, activeBoss.maxHp)
		if activeBoss.hp == 0 then
			payoutAndEnd(true)
		end
	end)

	model.Parent = Workspace

	for _, p in ipairs(Players:GetPlayers()) do
		Remotes.Event(Remotes.Names.Notify):FireClient(p, {
			kind = "info",
			text = `🔥 MEGA BOSS at the arena! Click to attack — coop kill = big cash + rare egg.`,
		})
	end
	broadcastState()
end

function BossEventService.Init()
	CaptureService = require(script.Parent.CaptureService)

	-- Arena pad
	local pad = Instance.new("Part")
	pad.Anchored = true
	pad.Size = Vector3.new(60, 1, 60)
	pad.Position = bossCenter() - Vector3.new(0, 6, 0)
	pad.Color = Color3.fromRGB(60, 0, 0)
	pad.Material = Enum.Material.Neon
	pad.Name = "BossArena"
	pad.Parent = Workspace

	task.spawn(function()
		while true do
			task.wait(1)
			if not activeBoss and os.time() >= nextBossAt then
				spawnBoss()
			elseif activeBoss and os.time() >= activeBoss.endsAt then
				payoutAndEnd(false)
			end
			if os.time() % 5 == 0 then broadcastState() end
		end
	end)
end

function BossEventService.ForceSpawn()
	if activeBoss then return end
	spawnBoss()
end

function BossEventService.OnPlayerAdded(player: Player)
	task.delay(2, broadcastState)
end

return BossEventService
