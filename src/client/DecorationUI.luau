--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)

local DecorationUI = {}

local list: ScrollingFrame
local headerLabel: TextLabel
local hasPremium = false

local function rebuild(payload: any)
	hasPremium = payload.hasPremium == true
	local placed = #payload.owned
	headerLabel.Text = `🪴 Decorations · ${placed}/${payload.capacity} placed`

	list:ClearAllChildren()
	local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 6); layout.Parent = list

	-- Catalog (buy entries)
	for _, def in ipairs(payload.catalog) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 56)
		row.BackgroundColor3 = if def.premium and not hasPremium then Color3.fromRGB(60, 40, 40) else Color3.fromRGB(40, 40, 55)
		row.BorderSizePixel = 0
		row.Parent = list
		local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 8); rc.Parent = row

		local lbl = Instance.new("TextLabel")
		lbl.Position = UDim2.fromOffset(12, 4)
		lbl.Size = UDim2.new(1, -120, 1, -8)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.TextScaled = true
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextColor3 = if def.premium then Color3.fromRGB(255, 215, 80) else Color3.fromRGB(220, 220, 230)
		lbl.Text = `${def.name}${def.premium and " ⭐" or ""}\n${Util.FormatShortNumber(def.cost)} cash`
		lbl.Parent = row

		local btn = Instance.new("TextButton")
		btn.AnchorPoint = Vector2.new(1, 0.5)
		btn.Position = UDim2.new(1, -10, 0.5, 0)
		btn.Size = UDim2.fromOffset(96, 44)
		btn.Font = Enum.Font.GothamBlack
		btn.TextScaled = true
		btn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.BorderSizePixel = 0
		btn.Text = "BUY"
		btn.Parent = row
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = btn
		btn.MouseButton1Click:Connect(function()
			Remotes.Event(Remotes.Names.RequestBuyDecoration):FireServer(def.id)
		end)
	end

	-- Owned (sell entries)
	if #payload.owned > 0 then
		local hd = Instance.new("TextLabel")
		hd.Size = UDim2.new(1, -10, 0, 24)
		hd.BackgroundTransparency = 1
		hd.Font = Enum.Font.GothamBold
		hd.TextColor3 = Color3.fromRGB(200, 200, 220)
		hd.TextScaled = true
		hd.TextXAlignment = Enum.TextXAlignment.Left
		hd.Text = "Placed (tap to sell — 50% refund)"
		hd.Parent = list
	end
	for _, entry in ipairs(payload.owned) do
		local row = Instance.new("TextButton")
		row.Size = UDim2.new(1, -10, 0, 32)
		row.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
		row.BorderSizePixel = 0
		row.Font = Enum.Font.GothamBold
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = Color3.fromRGB(220, 220, 230)
		row.Text = `· ${entry.id} (slot ${entry.slot}) · tap to sell`
		row.Parent = list
		local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 6); rc.Parent = row
		local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 12); pad.Parent = row
		row.MouseButton1Click:Connect(function()
			Remotes.Event(Remotes.Names.RequestSellDecoration):FireServer(entry.uid)
		end)
	end
end

function DecorationUI.Init(screen: ScreenGui, UIController)
	local frame = Instance.new("Frame")
	frame.Name = "Decor"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(540, 520)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(120, 220, 200); s.Thickness = 2; s.Parent = frame

	headerLabel = Instance.new("TextLabel")
	headerLabel.Position = UDim2.fromOffset(12, 8)
	headerLabel.Size = UDim2.new(1, -24, 0, 32)
	headerLabel.BackgroundTransparency = 1
	headerLabel.Font = Enum.Font.GothamBlack
	headerLabel.TextScaled = true
	headerLabel.TextColor3 = Color3.fromRGB(120, 220, 200)
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left
	headerLabel.Text = "🪴 Decorations"
	headerLabel.Parent = frame

	list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(12, 48)
	list.Size = UDim2.new(1, -24, 1, -60)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = frame

	Remotes.Event(Remotes.Names.DecorationUpdate).OnClientEvent:Connect(rebuild)
	UIController.Register("Decor", frame, "🪴 Decor", Color3.fromRGB(120, 220, 200))
end

return DecorationUI
