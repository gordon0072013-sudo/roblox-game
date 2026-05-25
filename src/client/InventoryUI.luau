--!strict
--[[
	InventoryUI — list of owned brainrots with Place / Unplace / Sell controls.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local BrainrotData = require(Shared.BrainrotData)
local MutationData = require(Shared.MutationData)

local InventoryUI = {}

local list: ScrollingFrame
local headerLabel: TextLabel

local function rebuild(payload: any)
	list:ClearAllChildren()
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local placedCount = 0
	for _, b in ipairs(payload.inventory) do
		if b.placed then placedCount += 1 end
	end
	headerLabel.Text = `INVENTORY · ${#payload.inventory}/${payload.max} · placed ${placedCount}/${payload.capacity}`

	for i, b in ipairs(payload.inventory) do
		local def = BrainrotData.Get(b.speciesId)
		local row = Instance.new("Frame")
		row.LayoutOrder = i
		row.Size = UDim2.new(1, -10, 0, 64)
		row.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
		row.BorderSizePixel = 0
		row.Parent = list
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = row

		local display = def and def.displayName or "?"
		for _, mutId in ipairs(b.mutations) do
			local m = MutationData.Get(mutId)
			if m then display = `${m.suffix} ${display}` end
		end
		display = `${display}  [T${b.mutationTier}]  · ${def and def.rarity or "?"}`

		local label = Instance.new("TextLabel")
		label.AnchorPoint = Vector2.new(0, 0.5)
		label.Position = UDim2.new(0, 12, 0.5, 0)
		label.Size = UDim2.new(1, -260, 1, -10)
		label.BackgroundTransparency = 1
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.TextColor3 = Color3.fromRGB(255,255,255)
		label.Text = display
		label.Parent = row

		local function mkBtn(text: string, color: Color3, rightOffset: number, cb: () -> ()): TextButton
			local btn = Instance.new("TextButton")
			btn.AnchorPoint = Vector2.new(1, 0.5)
			btn.Position = UDim2.new(1, rightOffset, 0.5, 0)
			btn.Size = UDim2.fromOffset(72, 44)
			btn.Font = Enum.Font.GothamBlack
			btn.TextScaled = true
			btn.BackgroundColor3 = color
			btn.TextColor3 = Color3.fromRGB(255,255,255)
			btn.BorderSizePixel = 0
			btn.Text = text
			btn.Parent = row
			local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = btn
			btn.MouseButton1Click:Connect(cb)
			return btn
		end

		mkBtn("Sell", Color3.fromRGB(200, 80, 80), -10, function()
			Remotes.Event(Remotes.Names.RequestSellBrainrot):FireServer(b.uid)
		end)
		if b.placed then
			mkBtn("Pull", Color3.fromRGB(200, 200, 80), -92, function()
				Remotes.Event(Remotes.Names.RequestUnplaceBrainrot):FireServer(b.uid)
			end)
		else
			mkBtn("Place", Color3.fromRGB(80, 200, 120), -92, function()
				Remotes.Event(Remotes.Names.RequestPlaceBrainrot):FireServer(b.uid)
			end)
		end
		mkBtn("?", Color3.fromRGB(80, 120, 200), -174, function() end)
	end
end

function InventoryUI.Init(screen: ScreenGui, UIController)
	local frame = Instance.new("Frame")
	frame.Name = "Inventory"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(560, 540)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(100, 200, 255); s.Thickness = 2; s.Parent = frame

	headerLabel = Instance.new("TextLabel")
	headerLabel.Position = UDim2.fromOffset(12, 8)
	headerLabel.Size = UDim2.new(1, -24, 0, 32)
	headerLabel.BackgroundTransparency = 1
	headerLabel.Font = Enum.Font.GothamBlack
	headerLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left
	headerLabel.TextScaled = true
	headerLabel.Text = "INVENTORY"
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

	Remotes.Event(Remotes.Names.InventoryUpdate).OnClientEvent:Connect(rebuild)
	UIController.Register("Inventory", frame, "🧠 Lab", Color3.fromRGB(100, 200, 255))
end

return InventoryUI
