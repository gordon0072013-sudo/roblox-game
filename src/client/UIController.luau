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

function UIController.Register(name: string, frame: Frame, label: string, color: Color3?)
	screens[name] = frame
	frame.Visible = false

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
