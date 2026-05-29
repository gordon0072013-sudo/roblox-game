--!strict

local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local SpectateController = {}

local localPlayer = Players.LocalPlayer

local indicator: TextLabel?

local function release()
	local cam = Workspace.CurrentCamera
	if cam and localPlayer.Character then
		cam.CameraSubject = localPlayer.Character:FindFirstChildOfClass("Humanoid")
	end
	if indicator then indicator.Visible = false end
end

local function attach(payload: any)
	if not payload or not payload.targetUserId then return end
	local target = Players:GetPlayerByUserId(payload.targetUserId)
	if not target or not target.Character then return end
	local cam = Workspace.CurrentCamera
	if not cam then return end
	cam.CameraSubject = target.Character:FindFirstChildOfClass("Humanoid")
	if indicator then
		indicator.Text = `👁 Spectating ${payload.targetName or target.Name}`
		indicator.Visible = true
	end
end

function SpectateController.Init(screen: ScreenGui)
	indicator = Instance.new("TextLabel")
	;(indicator :: TextLabel).AnchorPoint = Vector2.new(0.5, 0)
	;(indicator :: TextLabel).Position = UDim2.new(0.5, 0, 0, 78)
	;(indicator :: TextLabel).Size = UDim2.fromOffset(280, 28)
	;(indicator :: TextLabel).BackgroundColor3 = Color3.fromRGB(15, 15, 30)
	;(indicator :: TextLabel).BackgroundTransparency = 0.2
	;(indicator :: TextLabel).BorderSizePixel = 0
	;(indicator :: TextLabel).Font = Enum.Font.GothamBold
	;(indicator :: TextLabel).TextScaled = true
	;(indicator :: TextLabel).TextColor3 = Color3.fromRGB(255, 215, 80)
	;(indicator :: TextLabel).Visible = false
	;(indicator :: TextLabel).Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = indicator

	Remotes.Event(Remotes.Names.Spectate).OnClientEvent:Connect(function(payload)
		if payload and payload.kind == "attach" then attach(payload) end
		if payload and payload.kind == "release" then release() end
	end)
end

return SpectateController
