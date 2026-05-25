--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local AutoSellUI = {}

local RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }

local function pushSet(enabled: boolean, threshold: string, excludeMutated: boolean)
	Remotes.Event(Remotes.Names.RequestSetAutoSell):FireServer(enabled, threshold, excludeMutated)
end

function AutoSellUI.Init(screen: ScreenGui, UIController)
	local frame = Instance.new("Frame")
	frame.Name = "AutoSell"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(440, 360)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	frame.BackgroundTransparency = 0.05
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 160, 80); s.Thickness = 2; s.Parent = frame

	local hd = Instance.new("TextLabel")
	hd.Position = UDim2.fromOffset(12, 8)
	hd.Size = UDim2.new(1, -24, 0, 30)
	hd.BackgroundTransparency = 1
	hd.Font = Enum.Font.GothamBlack
	hd.TextScaled = true
	hd.TextColor3 = Color3.fromRGB(255, 160, 80)
	hd.TextXAlignment = Enum.TextXAlignment.Left
	hd.Text = "♻ Auto-Sell"
	hd.Parent = frame

	local explain = Instance.new("TextLabel")
	explain.Position = UDim2.fromOffset(12, 48)
	explain.Size = UDim2.new(1, -24, 0, 36)
	explain.BackgroundTransparency = 1
	explain.Font = Enum.Font.Gotham
	explain.TextScaled = true
	explain.TextWrapped = true
	explain.TextXAlignment = Enum.TextXAlignment.Left
	explain.TextColor3 = Color3.fromRGB(220, 220, 230)
	explain.Text = "Newly-captured brainrots at or below this rarity are automatically sold for cash. Mutated brainrots are kept by default."
	explain.Parent = frame

	local enabled = false
	local threshold = "Common"
	local excludeMutated = true

	local toggle = Instance.new("TextButton")
	toggle.Position = UDim2.fromOffset(12, 100)
	toggle.Size = UDim2.fromOffset(180, 40)
	toggle.Font = Enum.Font.GothamBlack
	toggle.TextScaled = true
	toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggle.BorderSizePixel = 0
	toggle.Text = "OFF"
	toggle.Parent = frame
	local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 8); tc.Parent = toggle

	local mutToggle = Instance.new("TextButton")
	mutToggle.Position = UDim2.fromOffset(200, 100)
	mutToggle.Size = UDim2.fromOffset(228, 40)
	mutToggle.Font = Enum.Font.GothamBold
	mutToggle.TextScaled = true
	mutToggle.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
	mutToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
	mutToggle.BorderSizePixel = 0
	mutToggle.Text = "Keep mutated: ON"
	mutToggle.Parent = frame
	local mtc = Instance.new("UICorner"); mtc.CornerRadius = UDim.new(0, 8); mtc.Parent = mutToggle

	local label = Instance.new("TextLabel")
	label.Position = UDim2.fromOffset(12, 152)
	label.Size = UDim2.new(1, -24, 0, 22)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(200, 200, 220)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = "Sell at or below:"
	label.Parent = frame

	local rarityRow = Instance.new("Frame")
	rarityRow.Position = UDim2.fromOffset(12, 182)
	rarityRow.Size = UDim2.new(1, -24, 0, 44)
	rarityRow.BackgroundTransparency = 1
	rarityRow.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 4)
	layout.Parent = rarityRow

	local rarityButtons: { TextButton } = {}
	local function refreshButtons()
		toggle.Text = enabled and "ON" or "OFF"
		toggle.BackgroundColor3 = if enabled then Color3.fromRGB(80, 200, 120) else Color3.fromRGB(60, 60, 80)
		mutToggle.Text = excludeMutated and "Keep mutated: ON" or "Keep mutated: OFF"
		mutToggle.BackgroundColor3 = if excludeMutated then Color3.fromRGB(80, 200, 120) else Color3.fromRGB(200, 80, 80)
		for _, b in ipairs(rarityButtons) do
			local selected = b:GetAttribute("Rarity") == threshold
			b.BackgroundColor3 = if selected then Color3.fromRGB(255, 160, 80) else Color3.fromRGB(50, 50, 70)
		end
	end

	for _, r in ipairs(RARITIES) do
		local b = Instance.new("TextButton")
		b:SetAttribute("Rarity", r)
		b.Size = UDim2.fromOffset(80, 44)
		b.Font = Enum.Font.GothamBold
		b.TextScaled = true
		b.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
		b.BorderSizePixel = 0
		b.Text = r
		b.Parent = rarityRow
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = b
		table.insert(rarityButtons, b)
		b.MouseButton1Click:Connect(function()
			threshold = r
			refreshButtons()
			pushSet(enabled, threshold, excludeMutated)
		end)
	end

	toggle.MouseButton1Click:Connect(function()
		enabled = not enabled
		refreshButtons()
		pushSet(enabled, threshold, excludeMutated)
	end)
	mutToggle.MouseButton1Click:Connect(function()
		excludeMutated = not excludeMutated
		refreshButtons()
		pushSet(enabled, threshold, excludeMutated)
	end)

	Remotes.Event(Remotes.Names.AutoSellUpdate).OnClientEvent:Connect(function(payload)
		if not payload then return end
		enabled = payload.enabled == true
		threshold = payload.threshold or "Common"
		excludeMutated = payload.excludeMutated ~= false
		refreshButtons()
	end)

	refreshButtons()
	UIController.Register("AutoSell", frame, "♻ Auto", Color3.fromRGB(255, 160, 80))
end

return AutoSellUI
