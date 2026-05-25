--!strict
--[[
	OutbreakUI — top-center banner showing next outbreak countdown or
	active outbreak alert. Drives FOMO.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)

local OutbreakUI = {}

function OutbreakUI.Init(screen: ScreenGui)
	local frame = Instance.new("Frame")
	frame.Name = "Outbreak"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0, 12)
	frame.Size = UDim2.fromOffset(440, 56)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 120, 80); s.Thickness = 2; s.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 200, 120)
	label.Text = "OUTBREAK: -- --"
	label.Parent = frame
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = label

	Remotes.Event(Remotes.Names.OutbreakUpdate).OnClientEvent:Connect(function(payload)
		if payload.active then
			label.Text = `🚨 OUTBREAK LIVE @ PLAZA · ${Util.SecondsToClock(payload.secondsLeft)} left · ${payload.spawnsRemaining} brainrots`
			label.TextColor3 = Color3.fromRGB(120, 255, 120)
		else
			label.Text = `Next Outbreak in ${Util.SecondsToClock(payload.secondsToStart)}`
			label.TextColor3 = Color3.fromRGB(255, 200, 120)
		end
	end)
end

return OutbreakUI
