--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)

local QuestUI = {}

local list: ScrollingFrame

local function rebuild(payload: any)
	list:ClearAllChildren()
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = list

	for _, q in ipairs(payload) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 64)
		row.BackgroundColor3 = if q.claimed then Color3.fromRGB(40, 60, 40)
			elseif q.complete then Color3.fromRGB(70, 70, 35)
			else Color3.fromRGB(40, 40, 55)
		row.BorderSizePixel = 0
		row.Parent = list
		local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 8); rc.Parent = row

		local title = Instance.new("TextLabel")
		title.Position = UDim2.fromOffset(12, 4)
		title.Size = UDim2.new(1, -140, 0, 24)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBlack
		title.TextScaled = true
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = if q.complete then Color3.fromRGB(255, 215, 80) else Color3.fromRGB(220, 220, 220)
		title.Text = q.label
		title.Parent = row

		local prog = Instance.new("TextLabel")
		prog.Position = UDim2.fromOffset(12, 30)
		prog.Size = UDim2.new(1, -140, 0, 28)
		prog.BackgroundTransparency = 1
		prog.Font = Enum.Font.Gotham
		prog.TextScaled = true
		prog.TextXAlignment = Enum.TextXAlignment.Left
		prog.TextColor3 = Color3.fromRGB(150, 200, 255)
		prog.Text = string.format("%s / %s · reward: %d %s",
			Util.FormatShortNumber(q.progress), Util.FormatShortNumber(q.target),
			q.rewardAmount, q.rewardKind)
		prog.Parent = row

		local btn = Instance.new("TextButton")
		btn.AnchorPoint = Vector2.new(1, 0.5)
		btn.Position = UDim2.new(1, -10, 0.5, 0)
		btn.Size = UDim2.fromOffset(110, 48)
		btn.Font = Enum.Font.GothamBlack
		btn.TextScaled = true
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.BorderSizePixel = 0
		btn.Parent = row
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = btn
		if q.claimed then
			btn.Text = "✓ DONE"; btn.BackgroundColor3 = Color3.fromRGB(60, 100, 60); btn.AutoButtonColor = false
		elseif q.complete then
			btn.Text = "CLAIM"; btn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
			btn.MouseButton1Click:Connect(function()
				Remotes.Event(Remotes.Names.RequestClaimQuest):FireServer(q.id)
			end)
		else
			btn.Text = "DO IT"; btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80); btn.AutoButtonColor = false
		end
	end
end

function QuestUI.Init(screen: ScreenGui, UIController)
	local frame = Instance.new("Frame")
	frame.Name = "Quests"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(540, 320)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(150, 200, 255); s.Thickness = 2; s.Parent = frame

	local hd = Instance.new("TextLabel")
	hd.Position = UDim2.fromOffset(12, 8)
	hd.Size = UDim2.new(1, -24, 0, 32)
	hd.BackgroundTransparency = 1
	hd.Font = Enum.Font.GothamBlack
	hd.TextScaled = true
	hd.TextXAlignment = Enum.TextXAlignment.Left
	hd.TextColor3 = Color3.fromRGB(150, 200, 255)
	hd.Text = "📋 Daily Quests (reset at midnight UTC)"
	hd.Parent = frame

	list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(12, 48)
	list.Size = UDim2.new(1, -24, 1, -60)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = frame

	Remotes.Event(Remotes.Names.QuestUpdate).OnClientEvent:Connect(rebuild)
	UIController.Register("Quests", frame, "📋 Quests", Color3.fromRGB(150, 200, 255))
end

return QuestUI
