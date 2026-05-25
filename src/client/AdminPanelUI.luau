--!strict

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

local Shared  = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local AdminPanelUI = {}

local UPDATE_REMOTE = "AdminUpdate"
local RUN_REMOTE    = "AdminRunCommand"

local localPlayer = Players.LocalPlayer

local panel:        Frame?
local resultLabel:  TextLabel?
local playersList:  ScrollingFrame?
local input:        TextBox?
local toggleButton: TextButton?
local isOwner = false

local function applyStyle(b: TextButton, color: Color3)
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	b.BackgroundColor3 = color
	b.TextColor3 = Color3.fromRGB(255,255,255)
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = b
end

local function mkButton(parent: Instance, text: string, color: Color3, onClick: () -> ()): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(120, 30)
	b.Text = text
	b.Parent = parent
	applyStyle(b, color)
	b.MouseButton1Click:Connect(onClick)
	return b
end

local function renderPlayers(list: { any })
	if not playersList then return end
	playersList:ClearAllChildren()
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = playersList

	for _, p in ipairs(list) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 56)
		row.BackgroundColor3 = if p.isOwner then Color3.fromRGB(70, 60, 30)
			elseif p.isAdmin then Color3.fromRGB(40, 60, 40)
			elseif p.violations > 0 then Color3.fromRGB(70, 30, 30)
			else Color3.fromRGB(35, 35, 50)
		row.BorderSizePixel = 0
		row.Parent = playersList
		local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 6); rc.Parent = row

		local name = Instance.new("TextLabel")
		name.Position = UDim2.fromOffset(10, 4)
		name.Size = UDim2.new(1, -260, 0, 22)
		name.BackgroundTransparency = 1
		name.Font = Enum.Font.GothamBold
		name.TextScaled = true
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextColor3 = Color3.fromRGB(255,255,255)
		local badge = p.isOwner and " 👑" or (p.isAdmin and " 🛡️" or "")
		name.Text = `${p.displayName}${badge}  (${p.name})`
		name.Parent = row

		local stats = Instance.new("TextLabel")
		stats.Position = UDim2.fromOffset(10, 28)
		stats.Size = UDim2.new(1, -260, 0, 22)
		stats.BackgroundTransparency = 1
		stats.Font = Enum.Font.Gotham
		stats.TextScaled = true
		stats.TextXAlignment = Enum.TextXAlignment.Left
		stats.TextColor3 = Color3.fromRGB(200, 200, 220)
		stats.Text = string.format("%d cash · R%d · %d brainrots · vio %d",
			p.cash, p.rebirths, p.brainrots, p.violations)
		stats.Parent = row

		local function quick(name: string, color: Color3, line: string, dx: number)
			local b = mkButton(row, name, color, function()
				Remotes.Event(RUN_REMOTE):FireServer(line)
			end)
			b.AnchorPoint = Vector2.new(1, 0.5)
			b.Position = UDim2.new(1, dx, 0.5, 0)
			b.Size = UDim2.fromOffset(80, 40)
		end

		quick("Give 10k", Color3.fromRGB(80, 200, 120), `give ${p.name} 10000`, -10)
		quick("Mutate",   Color3.fromRGB(255, 100, 220), `mutate-all ${p.name}`, -96)
		quick("Kick",     Color3.fromRGB(220, 80, 80),  `kick ${p.name}`, -182)
	end
end

local function showResult(text: string)
	if resultLabel then
		resultLabel.Text = text
	end
end

local function buildPanel(screen: ScreenGui)
	panel = Instance.new("Frame")
	(panel :: Frame).Name = "AdminPanel"
	(panel :: Frame).AnchorPoint = Vector2.new(0.5, 0.5)
	(panel :: Frame).Position = UDim2.fromScale(0.5, 0.5)
	(panel :: Frame).Size = UDim2.fromOffset(760, 580)
	(panel :: Frame).BackgroundColor3 = Color3.fromRGB(15, 15, 30)
	(panel :: Frame).BackgroundTransparency = 0.05
	(panel :: Frame).BorderSizePixel = 0
	(panel :: Frame).Visible = false
	(panel :: Frame).Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = panel
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 80, 80); s.Thickness = 2; s.Parent = panel

	local header = Instance.new("TextLabel")
	header.Position = UDim2.fromOffset(14, 8)
	header.Size = UDim2.new(1, -28, 0, 32)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBlack
	header.TextScaled = true
	header.TextColor3 = Color3.fromRGB(255, 80, 80)
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = "🛡 ADMIN PANEL — owner only"
	header.Parent = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Position = UDim2.new(1, -10, 0, 8)
	closeBtn.Size = UDim2.fromOffset(60, 32)
	closeBtn.Parent = panel
	applyStyle(closeBtn, Color3.fromRGB(60, 60, 80))
	closeBtn.Text = "✕"
	closeBtn.MouseButton1Click:Connect(function()
		if panel then panel.Visible = false end
	end)

	playersList = Instance.new("ScrollingFrame")
	(playersList :: ScrollingFrame).Position = UDim2.fromOffset(14, 50)
	(playersList :: ScrollingFrame).Size = UDim2.new(1, -28, 0, 360)
	(playersList :: ScrollingFrame).BackgroundColor3 = Color3.fromRGB(22, 22, 38)
	(playersList :: ScrollingFrame).BackgroundTransparency = 0.3
	(playersList :: ScrollingFrame).BorderSizePixel = 0
	(playersList :: ScrollingFrame).ScrollBarThickness = 6
	(playersList :: ScrollingFrame).CanvasSize = UDim2.new(0, 0, 0, 0)
	(playersList :: ScrollingFrame).AutomaticCanvasSize = Enum.AutomaticSize.Y
	(playersList :: ScrollingFrame).Parent = panel
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 8); pc.Parent = playersList

	-- Quick commands row
	local quickRow = Instance.new("Frame")
	quickRow.Position = UDim2.fromOffset(14, 420)
	quickRow.Size = UDim2.new(1, -28, 0, 40)
	quickRow.BackgroundTransparency = 1
	quickRow.Parent = panel
	local qrLayout = Instance.new("UIListLayout")
	qrLayout.FillDirection = Enum.FillDirection.Horizontal
	qrLayout.Padding = UDim.new(0, 6)
	qrLayout.Parent = quickRow

	mkButton(quickRow, "Outbreak",   Color3.fromRGB(255, 120, 60),  function() Remotes.Event(RUN_REMOTE):FireServer("skip-outbreak") end)
	mkButton(quickRow, "Spawn Boss", Color3.fromRGB(255, 80, 80),   function() Remotes.Event(RUN_REMOTE):FireServer("spawn-boss") end)
	mkButton(quickRow, "Flags",      Color3.fromRGB(200, 200, 80),  function() Remotes.Event(RUN_REMOTE):FireServer("flags") end)
	mkButton(quickRow, "Stats",      Color3.fromRGB(120, 200, 255), function() Remotes.Event(RUN_REMOTE):FireServer("stats") end)
	mkButton(quickRow, "Help",       Color3.fromRGB(180, 180, 200), function() Remotes.Event(RUN_REMOTE):FireServer("help") end)

	-- Custom command input
	local inputRow = Instance.new("Frame")
	inputRow.Position = UDim2.fromOffset(14, 470)
	inputRow.Size = UDim2.new(1, -28, 0, 36)
	inputRow.BackgroundTransparency = 1
	inputRow.Parent = panel

	input = Instance.new("TextBox")
	(input :: TextBox).Size = UDim2.new(1, -120, 1, 0)
	(input :: TextBox).Position = UDim2.fromOffset(0, 0)
	(input :: TextBox).Font = Enum.Font.RobotoMono
	(input :: TextBox).TextScaled = true
	(input :: TextBox).BackgroundColor3 = Color3.fromRGB(30, 30, 50)
	(input :: TextBox).TextColor3 = Color3.fromRGB(255, 255, 255)
	(input :: TextBox).PlaceholderText = "/give <player> <amount>  (try /help)"
	(input :: TextBox).Text = ""
	(input :: TextBox).ClearTextOnFocus = false
	(input :: TextBox).Parent = inputRow
	local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(0, 6); ic.Parent = input

	local runBtn = Instance.new("TextButton")
	runBtn.AnchorPoint = Vector2.new(1, 0)
	runBtn.Position = UDim2.new(1, 0, 0, 0)
	runBtn.Size = UDim2.fromOffset(110, 36)
	runBtn.Parent = inputRow
	applyStyle(runBtn, Color3.fromRGB(80, 200, 120))
	runBtn.Text = "RUN"
	local function runIt()
		if input and input.Text and #input.Text > 0 then
			Remotes.Event(RUN_REMOTE):FireServer(input.Text)
			input.Text = ""
		end
	end
	runBtn.MouseButton1Click:Connect(runIt)
	;(input :: TextBox).FocusLost:Connect(function(enter) if enter then runIt() end end)

	-- Result label
	resultLabel = Instance.new("TextLabel")
	(resultLabel :: TextLabel).Position = UDim2.fromOffset(14, 516)
	(resultLabel :: TextLabel).Size = UDim2.new(1, -28, 0, 56)
	(resultLabel :: TextLabel).BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	(resultLabel :: TextLabel).BackgroundTransparency = 0.6
	(resultLabel :: TextLabel).BorderSizePixel = 0
	(resultLabel :: TextLabel).Font = Enum.Font.RobotoMono
	(resultLabel :: TextLabel).TextScaled = true
	(resultLabel :: TextLabel).TextWrapped = true
	(resultLabel :: TextLabel).TextXAlignment = Enum.TextXAlignment.Left
	(resultLabel :: TextLabel).TextYAlignment = Enum.TextYAlignment.Top
	(resultLabel :: TextLabel).TextColor3 = Color3.fromRGB(180, 220, 180)
	(resultLabel :: TextLabel).Text = "Output appears here. Try the buttons above or type a command."
	(resultLabel :: TextLabel).Parent = panel
	local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 6); rc.Parent = resultLabel
end

local function buildToggleButton(screen: ScreenGui)
	toggleButton = Instance.new("TextButton")
	(toggleButton :: TextButton).AnchorPoint = Vector2.new(1, 1)
	(toggleButton :: TextButton).Position = UDim2.new(1, -16, 1, -100)
	(toggleButton :: TextButton).Size = UDim2.fromOffset(48, 48)
	(toggleButton :: TextButton).Text = "🛡"
	(toggleButton :: TextButton).Parent = screen
	applyStyle(toggleButton :: TextButton, Color3.fromRGB(255, 80, 80))
	(toggleButton :: TextButton).MouseButton1Click:Connect(function()
		if panel then panel.Visible = not panel.Visible end
	end)
end

function AdminPanelUI.Init(screen: ScreenGui)
	-- Wait for the server to confirm admin status before constructing anything.
	-- Non-admins never see UI, never see remotes registered as accessible.
	Remotes.Event(UPDATE_REMOTE).OnClientEvent:Connect(function(payload)
		if payload.kind == "init" then
			if not panel then
				buildPanel(screen)
				buildToggleButton(screen)
				isOwner = payload.isOwner == true
			end
			renderPlayers(payload.players or {})
		elseif payload.kind == "tick" then
			renderPlayers(payload.players or {})
		elseif payload.kind == "result" then
			showResult(payload.text or "")
		end
	end)

	-- Keybind: Right Shift opens/closes the panel (only does anything if admin).
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.RightShift and panel then
			panel.Visible = not panel.Visible
		end
	end)
end

return AdminPanelUI
