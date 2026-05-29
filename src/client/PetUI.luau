--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local PetUI = {}

local RARITY_COLOR = {
	Basic = Color3.fromRGB(180, 180, 180),
	Premium = Color3.fromRGB(120, 200, 255),
	Legendary = Color3.fromRGB(255, 180, 60),
	Mythical = Color3.fromRGB(255, 80, 220),
}

local list: ScrollingFrame

local function rebuild(payload: any)
	list:ClearAllChildren()
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = list

	for _, pet in ipairs(payload) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 56)
		row.BackgroundColor3 = if pet.equipped then Color3.fromRGB(40, 60, 40) else Color3.fromRGB(40, 40, 55)
		row.BorderSizePixel = 0
		row.Parent = list
		local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 8); rc.Parent = row

		local color = RARITY_COLOR[pet.rarity] or Color3.fromRGB(220, 220, 220)
		local stroke = Instance.new("UIStroke"); stroke.Color = color; stroke.Thickness = 2; stroke.Parent = row

		local title = Instance.new("TextLabel")
		title.Position = UDim2.fromOffset(12, 4)
		title.Size = UDim2.new(1, -120, 0, 26)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBlack
		title.TextScaled = true
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = color
		title.Text = `{pet.name} [{pet.rarity}]`
		title.Parent = row

		local sub = Instance.new("TextLabel")
		sub.Position = UDim2.fromOffset(12, 30)
		sub.Size = UDim2.new(1, -120, 0, 22)
		sub.BackgroundTransparency = 1
		sub.Font = Enum.Font.Gotham
		sub.TextScaled = true
		sub.TextXAlignment = Enum.TextXAlignment.Left
		sub.TextColor3 = Color3.fromRGB(220, 220, 220)
		sub.Text = pet.tagline
		sub.Parent = row

		local btn = Instance.new("TextButton")
		btn.AnchorPoint = Vector2.new(1, 0.5)
		btn.Position = UDim2.new(1, -10, 0.5, 0)
		btn.Size = UDim2.fromOffset(96, 40)
		btn.Font = Enum.Font.GothamBlack
		btn.TextScaled = true
		btn.BackgroundColor3 = if pet.equipped then Color3.fromRGB(200, 80, 80) else Color3.fromRGB(80, 200, 120)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.BorderSizePixel = 0
		btn.Text = if pet.equipped then "UNEQUIP" else "EQUIP"
		btn.Parent = row
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = btn
		btn.MouseButton1Click:Connect(function()
			if pet.equipped then
				Remotes.Event(Remotes.Names.RequestUnequipPet):FireServer()
			else
				Remotes.Event(Remotes.Names.RequestEquipPet):FireServer(pet.uid)
			end
		end)
	end

	if #payload == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, -10, 0, 64)
		empty.BackgroundTransparency = 1
		empty.Font = Enum.Font.GothamItalic
		empty.TextScaled = true
		empty.TextColor3 = Color3.fromRGB(160, 160, 160)
		empty.TextWrapped = true
		empty.Text = "No pets yet — buy a Pet Egg in the Shop."
		empty.Parent = list
	end
end

function PetUI.Init(screen: ScreenGui, UIController)
	local frame = Instance.new("Frame")
	frame.Name = "Pets"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(540, 480)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 80, 220); s.Thickness = 2; s.Parent = frame

	local hd = Instance.new("TextLabel")
	hd.Position = UDim2.fromOffset(12, 8)
	hd.Size = UDim2.new(1, -24, 0, 32)
	hd.BackgroundTransparency = 1
	hd.Font = Enum.Font.GothamBlack
	hd.TextScaled = true
	hd.TextColor3 = Color3.fromRGB(255, 80, 220)
	hd.TextXAlignment = Enum.TextXAlignment.Left
	hd.Text = "🐾 Pets"
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

	Remotes.Event(Remotes.Names.PetUpdate).OnClientEvent:Connect(rebuild)
	UIController.Register("Pets", frame, "🐾 Pets", Color3.fromRGB(255, 80, 220))
end

return PetUI
