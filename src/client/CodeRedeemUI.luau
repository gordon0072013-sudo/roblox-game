--!strict
--[[
	CodeRedeemUI — small input + redeem button. Toggled from the bottom bar.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local CodeRedeemUI = {}

function CodeRedeemUI.Init(screen: ScreenGui, UIController)
	local frame = Instance.new("Frame")
	frame.Name = "CodeRedeem"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(420, 200)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(120, 220, 120); s.Thickness = 2; s.Parent = frame

	local header = Instance.new("TextLabel")
	header.Position = UDim2.fromOffset(12, 8)
	header.Size = UDim2.new(1, -24, 0, 36)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBlack
	header.TextColor3 = Color3.fromRGB(120, 220, 120)
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextScaled = true
	header.Text = "🎟 Redeem Code"
	header.Parent = frame

	local hint = Instance.new("TextLabel")
	hint.Position = UDim2.fromOffset(12, 50)
	hint.Size = UDim2.new(1, -24, 0, 24)
	hint.BackgroundTransparency = 1
	hint.Font = Enum.Font.Gotham
	hint.TextColor3 = Color3.fromRGB(200, 200, 200)
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.TextScaled = true
	hint.Text = "Try: LAUNCH · BRAINROT · SIGMA · MUTATE"
	hint.Parent = frame

	local input = Instance.new("TextBox")
	input.Position = UDim2.fromOffset(12, 82)
	input.Size = UDim2.new(1, -160, 0, 56)
	input.Font = Enum.Font.GothamBold
	input.TextScaled = true
	input.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	input.TextColor3 = Color3.fromRGB(255, 255, 255)
	input.PlaceholderText = "Enter code…"
	input.PlaceholderColor3 = Color3.fromRGB(150, 150, 170)
	input.Text = ""
	input.ClearTextOnFocus = false
	input.Parent = frame
	local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(0, 8); ic.Parent = input

	local btn = Instance.new("TextButton")
	btn.AnchorPoint = Vector2.new(1, 0)
	btn.Position = UDim2.new(1, -12, 0, 82)
	btn.Size = UDim2.fromOffset(140, 56)
	btn.Font = Enum.Font.GothamBlack
	btn.TextScaled = true
	btn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.BorderSizePixel = 0
	btn.Text = "REDEEM"
	btn.Parent = frame
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = btn

	local function fire()
		local code = input.Text
		if code and #code > 0 then
			Remotes.Event(Remotes.Names.RequestRedeemCode):FireServer(code)
			input.Text = ""
		end
	end
	btn.MouseButton1Click:Connect(fire)
	input.FocusLost:Connect(function(enter) if enter then fire() end end)

	UIController.Register("Codes", frame, "🎟 Codes", Color3.fromRGB(120, 220, 120))
end

return CodeRedeemUI
