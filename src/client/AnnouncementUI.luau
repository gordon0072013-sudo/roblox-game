--!strict
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local AnnouncementUI = {}

local label: TextLabel
local frame: Frame

function AnnouncementUI.Init(screen: ScreenGui)
	frame = Instance.new("Frame")
	frame.Name = "AnnouncementTicker"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0, 144)
	frame.Size = UDim2.fromOffset(700, 36)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 215, 80); s.Thickness = 1; s.Parent = frame

	label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 215, 80)
	label.Text = ""
	label.Parent = frame
	local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12); pad.Parent = label

	Remotes.Event(Remotes.Names.AnnouncementShow).OnClientEvent:Connect(function(payload)
		if not payload then return end
		label.Text = payload.text
		if payload.color then
			label.TextColor3 = Color3.fromRGB(payload.color[1], payload.color[2], payload.color[3])
		end
		frame.BackgroundTransparency = 1
		TweenService:Create(frame, TweenInfo.new(0.3), { BackgroundTransparency = 0.2 }):Play()
	end)
end

return AnnouncementUI
