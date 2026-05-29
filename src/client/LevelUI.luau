--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)

local LevelUI = {}

local headerLabel: TextLabel
local barFill: Frame
local barLabel: TextLabel
local list: ScrollingFrame

local function rebuild(payload: any)
	headerLabel.Text = `⭐ Level {payload.level}`
	local pct = math.clamp(payload.xpInLevel / payload.xpPerLevel, 0, 1)
	barFill.Size = UDim2.fromScale(pct, 1)
	barLabel.Text = `{Util.FormatShortNumber(payload.xpInLevel)} / {Util.FormatShortNumber(payload.xpPerLevel)} XP to level {payload.level + 1}`

	list:ClearAllChildren()
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = list

	for lvl = 1, math.max(20, payload.level + 5) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 32)
		row.BackgroundColor3 = if lvl <= payload.level then Color3.fromRGB(40, 60, 40) else Color3.fromRGB(40, 40, 55)
		row.BorderSizePixel = 0
		row.Parent = list
		local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 6); rc.Parent = row

		local lbl = Instance.new("TextLabel")
		lbl.AnchorPoint = Vector2.new(0, 0.5)
		lbl.Position = UDim2.new(0, 12, 0.5, 0)
		lbl.Size = UDim2.new(1, -120, 1, -8)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.TextScaled = true
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
		lbl.Text = `Level {lvl} · reward: {lvl * 500} cash`
		lbl.Parent = row

		local btn = Instance.new("TextButton")
		btn.AnchorPoint = Vector2.new(1, 0.5)
		btn.Position = UDim2.new(1, -10, 0.5, 0)
		btn.Size = UDim2.fromOffset(96, 26)
		btn.Font = Enum.Font.GothamBlack
		btn.TextScaled = true
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.BorderSizePixel = 0
		btn.Parent = row
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 4); bc.Parent = btn
		if payload.claimed[tostring(lvl)] then
			btn.Text = "✓"; btn.BackgroundColor3 = Color3.fromRGB(60, 100, 60); btn.AutoButtonColor = false
		elseif lvl <= payload.level then
			btn.Text = "CLAIM"; btn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
			btn.MouseButton1Click:Connect(function()
				Remotes.Event(Remotes.Names.RequestClaimLevelReward):FireServer(lvl)
			end)
		else
			btn.Text = "LOCKED"; btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80); btn.AutoButtonColor = false
		end
	end
end

function LevelUI.Init(screen: ScreenGui, UIController)
	local frame = Instance.new("Frame")
	frame.Name = "Levels"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(540, 540)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(120, 200, 255); s.Thickness = 2; s.Parent = frame

	headerLabel = Instance.new("TextLabel")
	headerLabel.Position = UDim2.fromOffset(12, 8)
	headerLabel.Size = UDim2.new(1, -24, 0, 30)
	headerLabel.BackgroundTransparency = 1
	headerLabel.Font = Enum.Font.GothamBlack
	headerLabel.TextScaled = true
	headerLabel.TextColor3 = Color3.fromRGB(120, 200, 255)
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left
	headerLabel.Text = "⭐ Level"
	headerLabel.Parent = frame

	local barBg = Instance.new("Frame")
	barBg.Position = UDim2.fromOffset(12, 44)
	barBg.Size = UDim2.new(1, -24, 0, 14)
	barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	barBg.BorderSizePixel = 0
	barBg.Parent = frame
	local bgc = Instance.new("UICorner"); bgc.CornerRadius = UDim.new(0, 6); bgc.Parent = barBg
	barFill = Instance.new("Frame")
	barFill.Size = UDim2.fromScale(0, 1)
	barFill.BackgroundColor3 = Color3.fromRGB(120, 200, 255)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	local bfc = Instance.new("UICorner"); bfc.CornerRadius = UDim.new(0, 6); bfc.Parent = barFill

	barLabel = Instance.new("TextLabel")
	barLabel.Position = UDim2.fromOffset(12, 62)
	barLabel.Size = UDim2.new(1, -24, 0, 18)
	barLabel.BackgroundTransparency = 1
	barLabel.Font = Enum.Font.Gotham
	barLabel.TextScaled = true
	barLabel.TextXAlignment = Enum.TextXAlignment.Left
	barLabel.TextColor3 = Color3.fromRGB(180, 200, 220)
	barLabel.Text = ""
	barLabel.Parent = frame

	list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(12, 88)
	list.Size = UDim2.new(1, -24, 1, -100)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = frame

	Remotes.Event(Remotes.Names.LevelUpdate).OnClientEvent:Connect(rebuild)
	UIController.Register("Levels", frame, "⭐ Lvl", Color3.fromRGB(120, 200, 255))
end

return LevelUI
