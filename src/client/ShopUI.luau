--!strict
--[[
	ShopUI — gamepass + dev product storefront. Reads Config so it
	autopopulates whenever you add a new product.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local ShopUI = {}

local function buildPanel(parent: Frame)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 50); pad.PaddingBottom = UDim.new(0, 12)
	pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = parent

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.new(0.5, 0, 0, -42)
	title.Size = UDim2.fromOffset(400, 36)
	title.BackgroundTransparency = 1
	title.Text = "SHOP — fund the chaos"
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 215, 80)
	title.Parent = parent

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = parent

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 8)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = scroll

	local function mkRow(kind: string, key: string, name: string, price: number, subtitle: string?)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 64)
		row.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
		row.BorderSizePixel = 0
		row.Parent = scroll
		local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 8); rc.Parent = row

		local label = Instance.new("TextLabel")
		label.AnchorPoint = Vector2.new(0, 0.5)
		label.Position = UDim2.new(0, 12, 0.5, 0)
		label.Size = UDim2.new(1, -150, 1, -10)
		label.BackgroundTransparency = 1
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Text = subtitle and `${name}\n${subtitle}` or name
		label.Parent = row

		local btn = Instance.new("TextButton")
		btn.AnchorPoint = Vector2.new(1, 0.5)
		btn.Position = UDim2.new(1, -10, 0.5, 0)
		btn.Size = UDim2.fromOffset(120, 44)
		btn.Font = Enum.Font.GothamBlack
		btn.TextScaled = true
		btn.BackgroundColor3 = if kind == "gamepass" then Color3.fromRGB(255, 80, 200) else Color3.fromRGB(80, 200, 120)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.BorderSizePixel = 0
		btn.Text = `R$ ${price}`
		btn.Parent = row
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = btn
		btn.MouseButton1Click:Connect(function()
			Remotes.Event(Remotes.Names.RequestPromptPurchase):FireServer(kind, key)
		end)
	end

	-- Header: gamepasses
	local hp = Instance.new("TextLabel")
	hp.Size = UDim2.new(1, -10, 0, 28)
	hp.BackgroundTransparency = 1
	hp.Font = Enum.Font.GothamBlack
	hp.TextColor3 = Color3.fromRGB(255, 100, 220)
	hp.TextScaled = true
	hp.TextXAlignment = Enum.TextXAlignment.Left
	hp.Text = "GAMEPASSES (one-time, permanent)"
	hp.Parent = scroll
	hp.LayoutOrder = 1

	local subtitles: { [string]: string } = {
		MutationSpeed2x = "2x mutation rolls — see results faster",
		Cash2x = "All cash income doubled",
		VIPLab = "Golden plot, VIP brainrots, partial steal protection",
		InfectionShield = "Big resistance to infection bombs + 50% steal blocks",
		LuckyMutations = "Mutation rolls biased toward rare suffixes",
		TripleCapture = "Capture button gives 3 brainrots per click",
		RainbowTrail = "Equip a rainbow trail (flex flex flex)",
		GoldenPlot = "Your lab floor turns gold + glowing sign",
	}

	for key, gp in pairs(Config.GAMEPASSES) do
		mkRow("gamepass", key, gp.name, gp.price, subtitles[key])
	end

	local hd = Instance.new("TextLabel")
	hd.Size = UDim2.new(1, -10, 0, 28)
	hd.BackgroundTransparency = 1
	hd.Font = Enum.Font.GothamBlack
	hd.TextColor3 = Color3.fromRGB(120, 220, 100)
	hd.TextScaled = true
	hd.TextXAlignment = Enum.TextXAlignment.Left
	hd.Text = "DEV PRODUCTS (instant)"
	hd.LayoutOrder = 99
	hd.Parent = scroll

	for key, dp in pairs(Config.DEV_PRODUCTS) do
		mkRow("product", key, dp.name, dp.price, nil)
	end
end

function ShopUI.Init(screen: ScreenGui, UIController)
	local frame = Instance.new("Frame")
	frame.Name = "Shop"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(520, 520)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 215, 80); s.Thickness = 2; s.Parent = frame
	buildPanel(frame)
	UIController.Register("Shop", frame, "🛒 Shop", Color3.fromRGB(255, 215, 80))
end

return ShopUI
