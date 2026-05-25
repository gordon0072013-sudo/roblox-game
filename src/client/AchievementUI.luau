--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)

local AchievementUI = {}

local list: ScrollingFrame

local function rebuild(payload: any)
	list:ClearAllChildren()
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	for i, a in ipairs(payload) do
		local row = Instance.new("Frame")
		row.LayoutOrder = if a.complete and not a.claimed then i
			elseif a.claimed then i + 1000
			else i + 500
		row.Size = UDim2.new(1, -10, 0, 64)
		row.BackgroundColor3 = if a.claimed then Color3.fromRGB(40, 60, 40)
			elseif a.complete then Color3.fromRGB(70, 70, 35)
			else Color3.fromRGB(40, 40, 55)
		row.BorderSizePixel = 0
		row.Parent = list
		local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 8); rc.Parent = row

		local title = Instance.new("TextLabel")
		title.Position = UDim2.fromOffset(12, 4)
		title.Size = UDim2.new(1, -150, 0, 22)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBlack
		title.TextScaled = true
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = if a.claimed then Color3.fromRGB(120, 200, 120)
			elseif a.complete then Color3.fromRGB(255, 215, 80)
			else Color3.fromRGB(220, 220, 220)
		title.Text = a.name
		title.Parent = row

		local sub = Instance.new("TextLabel")
		sub.Position = UDim2.fromOffset(12, 26)
		sub.Size = UDim2.new(1, -150, 0, 18)
		sub.BackgroundTransparency = 1
		sub.Font = Enum.Font.Gotham
		sub.TextScaled = true
		sub.TextXAlignment = Enum.TextXAlignment.Left
		sub.TextColor3 = Color3.fromRGB(180, 180, 200)
		sub.Text = a.description
		sub.Parent = row

		local prog = Instance.new("TextLabel")
		prog.Position = UDim2.fromOffset(12, 46)
		prog.Size = UDim2.new(1, -150, 0, 16)
		prog.BackgroundTransparency = 1
		prog.Font = Enum.Font.GothamBold
		prog.TextScaled = true
		prog.TextXAlignment = Enum.TextXAlignment.Left
		prog.TextColor3 = Color3.fromRGB(140, 200, 255)
		prog.Text = string.format("%s / %s · reward: %d %s",
			Util.FormatShortNumber(a.progress),
			Util.FormatShortNumber(a.target),
			a.rewardAmount or 1,
			a.rewardKind)
		prog.Parent = row

		local btn = Instance.new("TextButton")
		btn.AnchorPoint = Vector2.new(1, 0.5)
		btn.Position = UDim2.new(1, -10, 0.5, 0)
		btn.Size = UDim2.fromOffset(120, 48)
		btn.Font = Enum.Font.GothamBlack
		btn.TextScaled = true
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.BorderSizePixel = 0
		btn.Parent = row
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = btn

		if a.claimed then
			btn.Text = "✓ DONE"
			btn.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
			btn.AutoButtonColor = false
		elseif a.complete then
			btn.Text = "CLAIM"
			btn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
			btn.MouseButton1Click:Connect(function()
				Remotes.Event(Remotes.Names.RequestClaimAchievement):FireServer(a.id)
			end)
		else
			btn.Text = "LOCKED"
			btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
			btn.AutoButtonColor = false
		end
	end
end

function AchievementUI.Init(screen: ScreenGui, UIController)
	local frame = Instance.new("Frame")
	frame.Name = "Achievements"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(600, 560)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 215, 80); s.Thickness = 2; s.Parent = frame

	local header = Instance.new("TextLabel")
	header.Position = UDim2.fromOffset(12, 8)
	header.Size = UDim2.new(1, -24, 0, 32)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBlack
	header.TextColor3 = Color3.fromRGB(255, 215, 80)
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextScaled = true
	header.Text = "🏅 Achievements"
	header.Parent = frame

	list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(12, 48)
	list.Size = UDim2.new(1, -24, 1, -60)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = frame

	Remotes.Event(Remotes.Names.AchievementUpdate).OnClientEvent:Connect(rebuild)
	UIController.Register("Achievements", frame, "🏅 Goals", Color3.fromRGB(255, 215, 80))
end

return AchievementUI
