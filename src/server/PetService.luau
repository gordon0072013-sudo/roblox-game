--!strict
--[[
	PetService — pet inventory, hatching from Pet Eggs (dev product), and
	equipping a single active pet that hovers next to the character and
	applies its buff to the player.

	Pet buffs are added to EconomyService via a hook on PetService.GetCashMult.
	On equip the active pet's id is written to profile so it persists.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local PetData = require(Shared.PetData)
local Util = require(Shared.Util)

local DataService = require(script.Parent.DataService)

local PetService = {}

local petModels: { [Player]: Model } = {}

local function ensurePetField(data: any)
	data._pets = data._pets or {}        -- { [uid] = petId }
	data._equippedPet = data._equippedPet or nil
end

local function applyVisual(player: Player)
	if petModels[player] then petModels[player]:Destroy(); petModels[player] = nil end
	local data = DataService.Get(player)
	if not data then return end
	ensurePetField(data)
	local petId = data._equippedPet
	if not petId then return end
	local def = PetData.Get(petId)
	if not def then return end
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local model = Instance.new("Model")
	model.Name = "Pet"
	local body = Instance.new("Part")
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(2, 2, 2)
	body.Color = def.color
	body.Material = Enum.Material.Neon
	body.CanCollide = false
	body.Anchored = false
	body.Massless = true
	body.Parent = model

	local att0 = Instance.new("Attachment"); att0.Parent = hrp
	local att1 = Instance.new("Attachment"); att1.Position = Vector3.new(0, 0, 0); att1.Parent = body

	local align = Instance.new("AlignPosition")
	align.Attachment0 = att1
	align.Attachment1 = att0
	align.MaxForce = 1e6
	align.Responsiveness = 35
	align.Parent = body

	-- Offset target via a "leash" attachment
	att0.Position = Vector3.new(3, 2, -2)

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(120, 24)
	bb.StudsOffset = Vector3.new(0, 1.5, 0)
	bb.AlwaysOnTop = true
	bb.Parent = body
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextScaled = true
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.TextStrokeTransparency = 0
	lbl.Text = def.name
	lbl.Parent = bb

	model.PrimaryPart = body
	model.Parent = char
	petModels[player] = model
end

local function pushUpdate(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	ensurePetField(data)
	local list = {}
	for uid, petId in pairs(data._pets) do
		local def = PetData.Get(petId)
		if def then
			table.insert(list, {
				uid = uid,
				id = def.id,
				name = def.name,
				rarity = def.rarity,
				buffKind = def.buffKind,
				buffValue = def.buffValue,
				tagline = def.tagline,
				equipped = data._equippedPet == uid,
			})
		end
	end
	Remotes.Event(Remotes.Names.PetUpdate):FireClient(player, list)
end

function PetService.Hatch(player: Player, lucky: boolean?)
	local data = DataService.Get(player)
	if not data then return end
	ensurePetField(data)
	local rng = Random.new()
	local bias = 0
	if lucky then bias = 0.5 end
	if data.gamepasses["LuckyMutations"] then bias += 0.1 end
	local def = PetData.Roll(rng, bias)
	local uid = Util.GenerateUid()
	data._pets[uid] = def.id
	-- Auto-equip if none equipped
	if not data._equippedPet then
		data._equippedPet = uid
		applyVisual(player)
	end
	Remotes.Event(Remotes.Names.Notify):FireClient(player, {
		kind = "capture",
		text = `🥚 Hatched: ${def.name} [${def.rarity}] — ${def.tagline}`,
	})
	pushUpdate(player)
end

function PetService.Equip(player: Player, uid: string)
	local data = DataService.Get(player)
	if not data then return end
	ensurePetField(data)
	if not data._pets[uid] then return end
	data._equippedPet = uid
	applyVisual(player)
	pushUpdate(player)
end

function PetService.Unequip(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	data._equippedPet = nil
	applyVisual(player)
	pushUpdate(player)
end

function PetService.GetEquippedDef(player: Player): any?
	local data = DataService.Get(player)
	if not data then return nil end
	ensurePetField(data)
	local uid = data._equippedPet
	if not uid then return nil end
	local petId = data._pets[uid]
	if not petId then return nil end
	return PetData.Get(petId)
end

-- Hook for EconomyService to multiply income
function PetService.GetCashMult(player: Player): number
	local def = PetService.GetEquippedDef(player)
	if def and def.buffKind == "cashMult" then return def.buffValue end
	return 1
end

function PetService.GetMutationSpeedMult(player: Player): number
	local def = PetService.GetEquippedDef(player)
	if def and def.buffKind == "mutationSpeed" then return def.buffValue end
	return 1
end

function PetService.OnPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function() task.delay(0.5, applyVisual, player) end)
	task.delay(2, function()
		applyVisual(player)
		pushUpdate(player)
	end)
end

function PetService.Init()
	-- Suppress unused
	local _ = Config
	local _2 = Players
end

return PetService
