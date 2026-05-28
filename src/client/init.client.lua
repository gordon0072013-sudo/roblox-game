--!strict
-- init.client.lua
-- Builds the entire game UI from code (no manual Studio layout needed):
-- a big CLICK button, a live coin/stats display, and a SHOP that lists
-- every configured game pass and developer product. Selling happens here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== Helpers =====
local function fmt(n: number): string
	-- Compact number formatting: 1.2K, 3.4M, etc.
	local abs = math.abs(n)
	if abs >= 1e9 then return string.format("%.2fB", n / 1e9) end
	if abs >= 1e6 then return string.format("%.2fM", n / 1e6) end
	if abs >= 1e3 then return string.format("%.2fK", n / 1e3) end
	return tostring(math.floor(n))
end

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

-- ===== Root UI =====
local gui = Instance.new("ScreenGui")
gui.Name = "CoinClickerUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent = playerGui

-- Stats panel (top-left)
local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(0, 320, 0, 96)
statsFrame.Position = UDim2.new(0, 16, 0, 16)
statsFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
statsFrame.BackgroundTransparency = 0.1
statsFrame.Parent = gui
corner(statsFrame, 12)

local coinLabel = Instance.new("TextLabel")
coinLabel.Size = UDim2.new(1, -20, 0, 48)
coinLabel.Position = UDim2.new(0, 10, 0, 6)
coinLabel.BackgroundTransparency = 1
coinLabel.Font = Enum.Font.GothamBold
coinLabel.TextScaled = true
coinLabel.TextXAlignment = Enum.TextXAlignment.Left
coinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinLabel.Text = "💰 0"
coinLabel.Parent = statsFrame

local subLabel = Instance.new("TextLabel")
subLabel.Size = UDim2.new(1, -20, 0, 32)
subLabel.Position = UDim2.new(0, 10, 0, 56)
subLabel.BackgroundTransparency = 1
subLabel.Font = Enum.Font.Gotham
subLabel.TextScaled = true
subLabel.TextXAlignment = Enum.TextXAlignment.Left
subLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
subLabel.Text = "Multiplier x1  •  0 clicks"
subLabel.Parent = statsFrame

-- Big click button (center-bottom)
local clickButton = Instance.new("TextButton")
clickButton.Size = UDim2.new(0, 220, 0, 220)
clickButton.Position = UDim2.new(0.5, -110, 1, -260)
clickButton.BackgroundColor3 = Color3.fromRGB(255, 195, 0)
clickButton.Font = Enum.Font.GothamBlack
clickButton.TextScaled = true
clickButton.TextColor3 = Color3.fromRGB(40, 30, 0)
clickButton.Text = "CLICK!"
clickButton.AutoButtonColor = true
clickButton.Parent = gui
corner(clickButton, 110)

-- Shop toggle button (top-right)
local shopToggle = Instance.new("TextButton")
shopToggle.Size = UDim2.new(0, 140, 0, 56)
shopToggle.Position = UDim2.new(1, -156, 0, 16)
shopToggle.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
shopToggle.Font = Enum.Font.GothamBold
shopToggle.TextScaled = true
shopToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
shopToggle.Text = "🛒 SHOP"
shopToggle.Parent = gui
corner(shopToggle, 12)

-- ===== Shop window =====
local shop = Instance.new("Frame")
shop.Size = UDim2.new(0, 420, 0, 460)
shop.Position = UDim2.new(0.5, -210, 0.5, -230)
shop.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
shop.Visible = false
shop.Parent = gui
corner(shop, 16)

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(1, -20, 0, 44)
shopTitle.Position = UDim2.new(0, 10, 0, 8)
shopTitle.BackgroundTransparency = 1
shopTitle.Font = Enum.Font.GothamBold
shopTitle.TextScaled = true
shopTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
shopTitle.Text = "Shop"
shopTitle.Parent = shop

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -44, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "X"
closeBtn.Parent = shop
corner(closeBtn, 8)

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -20, 1, -64)
list.Position = UDim2.new(0, 10, 0, 56)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = shop

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local function makeShopItem(title: string, subtitle: string, buttonText: string, enabled: boolean, onBuy: () -> ())
	local item = Instance.new("Frame")
	item.Size = UDim2.new(1, -6, 0, 72)
	item.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
	item.Parent = list
	corner(item, 10)

	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -130, 0, 30)
	t.Position = UDim2.new(0, 12, 0, 8)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextColor3 = Color3.fromRGB(255, 255, 255)
	t.Text = title
	t.Parent = item

	local s = Instance.new("TextLabel")
	s.Size = UDim2.new(1, -130, 0, 24)
	s.Position = UDim2.new(0, 12, 0, 40)
	s.BackgroundTransparency = 1
	s.Font = Enum.Font.Gotham
	s.TextScaled = true
	s.TextXAlignment = Enum.TextXAlignment.Left
	s.TextColor3 = Color3.fromRGB(180, 180, 195)
	s.Text = subtitle
	s.Parent = item

	local buy = Instance.new("TextButton")
	buy.Size = UDim2.new(0, 104, 0, 48)
	buy.Position = UDim2.new(1, -116, 0.5, -24)
	buy.Font = Enum.Font.GothamBold
	buy.TextScaled = true
	buy.TextColor3 = Color3.fromRGB(255, 255, 255)
	corner(buy, 8)
	if enabled then
		buy.BackgroundColor3 = Color3.fromRGB(70, 200, 120)
		buy.Text = buttonText
		buy.Active = true
		buy.AutoButtonColor = true
		buy.MouseButton1Click:Connect(onBuy)
	else
		buy.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
		buy.Text = "Soon"
		buy.Active = false
		buy.AutoButtonColor = false
	end
	buy.Parent = item
end

-- Build the shop from the server catalog.
local function buildShop()
	local catalog = Remotes.GetCatalog():InvokeServer()
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for _, pass in ipairs(catalog.passes) do
		local enabled = pass.id and pass.id > 0
		makeShopItem(pass.name, pass.description or pass.grants or "", "Buy", enabled, function()
			Remotes.PromptPurchase():FireServer("pass", pass.key)
		end)
	end
	for _, product in ipairs(catalog.products) do
		local enabled = product.id and product.id > 0
		makeShopItem(product.name, "Instant coins", "Buy", enabled, function()
			Remotes.PromptPurchase():FireServer("product", product.key)
		end)
	end
end

-- ===== Wiring =====
clickButton.MouseButton1Click:Connect(function()
	Remotes.Click():FireServer()
	-- juicy little pop animation
	clickButton.Size = UDim2.new(0, 205, 0, 205)
	TweenService:Create(clickButton, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 220, 0, 220),
	}):Play()
end)

shopToggle.MouseButton1Click:Connect(function()
	shop.Visible = not shop.Visible
end)
closeBtn.MouseButton1Click:Connect(function()
	shop.Visible = false
end)

Remotes.StatsUpdated().OnClientEvent:Connect(function(stats)
	coinLabel.Text = "💰 " .. fmt(stats.coins or 0)
	subLabel.Text = string.format("Multiplier x%d  •  %d clicks", stats.multiplier or 1, stats.clicks or 0)
end)

buildShop()
print("[CoinClickerTycoon] Client UI ready.")
