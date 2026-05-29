--!strict
--[[
	UIController — shared toggle bar + screen registration. Each panel
	registers via Register(name, frame) and is opened by ToggleScreen(name).
]]

local UIController = {}

local screens: { [string]: Frame } = {}
local screenButtons: { [string]: TextButton } = {}
local activeScreen: string? = nil
local toggleBar: Frame? = nil

local function applyButtonStyle(btn: TextButton, active: boolean)
	btn.BackgroundColor3 = if active then Color3.fromRGB(255, 80, 200) else Color3.fromRGB(40, 40, 60)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
end

-- Mobile-aware: keep panels inside the viewport. Adds a UISizeConstraint
-- + UIScale so a 720×460 trade window on a phone shrinks instead of clipping.
local function applyResponsiveSizing(frame: Frame)
	-- Cap max size to 90% of viewport
	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(1200, 800)
	sizeConstraint.MinSize = Vector2.new(200, 120)
	sizeConstraint.Parent = frame

	-- Auto-shrink on small screens via UIScale
	local scale = Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = frame

	local Players = game:GetService("Players")
	local cam = workspace.CurrentCamera
	local function update()
		if not cam then return end
		local vs = cam.ViewportSize
		-- Shrink if either dimension exceeds 85% of the viewport
		local sx = (vs.X * 0.92) / frame.AbsoluteSize.X
		local sy = (vs.Y * 0.78) / frame.AbsoluteSize.Y
		scale.Scale = math.clamp(math.min(sx, sy, 1), 0.55, 1)
	end
	frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
	if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(update) end
	task.defer(update)
	local _ = Players
end

function UIController.Register(name: string, frame: Frame, label: string, color: Color3?)
	screens[name] = frame
	frame.Visible = false
	applyResponsiveSizing(frame)

	if toggleBar then
		local btn = Instance.new("TextButton")
		btn.Name = name .. "Btn"
		btn.Size = UDim2.fromOffset(120, 48)
		btn.Text = label
		btn.Font = Enum.Font.GothamBold
		btn.TextScaled = true
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = true
		applyButtonStyle(btn, false)
		local stroke = Instance.new("UIStroke")
		stroke.Color = color or Color3.fromRGB(255, 80, 200)
		stroke.Thickness = 2
		stroke.Parent = btn
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = btn
		btn.Parent = toggleBar
		btn.MouseButton1Click:Connect(function()
			UIController.ToggleScreen(name)
		end)
		screenButtons[name] = btn
	end
end

function UIController.ToggleScreen(name: string)
	if activeScreen == name then
		screens[name].Visible = false
		applyButtonStyle(screenButtons[name], false)
		activeScreen = nil
		return
	end
	if activeScreen and screens[activeScreen] then
		screens[activeScreen].Visible = false
		applyButtonStyle(screenButtons[activeScreen], false)
	end
	if screens[name] then
		screens[name].Visible = true
		applyButtonStyle(screenButtons[name], true)
		activeScreen = name
	end
end

function UIController.CloseAll()
	if activeScreen and screens[activeScreen] then
		screens[activeScreen].Visible = false
		applyButtonStyle(screenButtons[activeScreen], false)
		activeScreen = nil
	end
end

function UIController.Init(screen: ScreenGui)
	local bar = Instance.new("Frame")
	bar.Name = "ToggleBar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -16)
	bar.Size = UDim2.fromOffset(820, 60)
	bar.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	bar.BackgroundTransparency = 0.25
	bar.BorderSizePixel = 0
	bar.Parent = screen
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = bar
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.Parent = bar
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 6)
	list.Parent = bar
	toggleBar = bar
end

return UIController
