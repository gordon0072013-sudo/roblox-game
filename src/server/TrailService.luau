--!strict
--[[
	TrailService — attaches a cycling-rainbow Trail to the character of any
	player with the Rainbow Trail gamepass. Cosmetic, status-symbol, high
	conversion rate among "look at me" players. Re-attaches on respawn.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local DataService = require(script.Parent.DataService)

local TrailService = {}

local function attachTrail(character: Model)
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end
	if hrp:FindFirstChild("RainbowTrail") then return end

	local a0 = Instance.new("Attachment")
	a0.Name = "RainbowTrailA0"
	a0.Position = Vector3.new(0, 1.5, 0)
	a0.Parent = hrp
	local a1 = Instance.new("Attachment")
	a1.Name = "RainbowTrailA1"
	a1.Position = Vector3.new(0, -1.5, 0)
	a1.Parent = hrp

	local trail = Instance.new("Trail")
	trail.Name = "RainbowTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 1.2
	trail.MinLength = 0
	trail.WidthScale = NumberSequence.new(1, 0)
	local hue = 0
	trail.Color = ColorSequence.new(Color3.fromHSV(0, 1, 1))
	trail.Parent = hrp

	task.spawn(function()
		while trail.Parent do
			hue = (hue + 0.02) % 1
			trail.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, 1, 1)),
				ColorSequenceKeypoint.new(0.5, Color3.fromHSV((hue + 0.33) % 1, 1, 1)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV((hue + 0.66) % 1, 1, 1)),
			})
			task.wait(0.1)
		end
	end)
end

local function tryAttach(player: Player)
	local data = DataService.Get(player)
	if not data or not data.gamepasses["RainbowTrail"] then return end
	if player.Character then attachTrail(player.Character) end
end

function TrailService.OnPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(char)
		task.wait(0.5)
		tryAttach(player)
	end)
	task.delay(2, tryAttach, player)
end

function TrailService.OnGamepassGranted(player: Player, key: string)
	if key == "RainbowTrail" then tryAttach(player) end
end

function TrailService.Init()
	-- Suppress unused
	local _ = Players
	local _2 = ReplicatedStorage
	local _3 = Shared
end

return TrailService
