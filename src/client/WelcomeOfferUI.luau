--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Util    = require(Shared.Util)

local WelcomeOfferUI = {}

function WelcomeOfferUI.Init(screen: ScreenGui)
	Remotes.Event(Remotes.Names.WelcomeOffer).OnClientEvent:Connect(function(payload)
		if not payload or payload.kind ~= "show" then return end

		local existing = screen:FindFirstChild("WelcomeOffer")
		if existing then existing:Destroy() end

		local backdrop = Instance.new("Frame")
		backdrop.Name = "WelcomeOffer"
		backdrop.Size = UDim2.fromScale(1, 1)
		backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		backdrop.BackgroundTransparency = 0.4
		backdrop.BorderSizePixel = 0
		backdrop.Parent = screen

		local frame = Instance.new("Frame")
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(0.5, 0.5)
		frame.Size = UDim2.fromOffset(420, 320)
		frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
		frame.BorderSizePixel = 0
		frame.Parent = backdrop
		local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(0, 16); fc.Parent = frame
		local fs = Instance.new("UIStroke"); fs.Color = Color3.fromRGB(255, 215, 80); fs.Thickness = 3; fs.Parent = frame

		local ribbon = Instance.new("TextLabel")
		ribbon.AnchorPoint = Vector2.new(0.5, 0)
		ribbon.Position = UDim2.new(0.5, 0, 0, -16)
		ribbon.Size = UDim2.fromOffset(180, 32)
		ribbon.BackgroundColor3 = Color3.fromRGB(255, 80, 200)
		ribbon.Font = Enum.Font.GothamBlack
		ribbon.TextScaled = true
		ribbon.TextColor3 = Color3.fromRGB(255, 255, 255)
		ribbon.Text = "STARTER OFFER"
		ribbon.Parent = frame
		local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 8); rc.Parent = ribbon

		local title = Instance.new("TextLabel")
		title.Position = UDim2.fromOffset(20, 30)
		title.Size = UDim2.new(1, -40, 0, 48)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBlack
		title.TextScaled = true
		title.TextWrapped = true
		title.TextColor3 = Color3.fromRGB(255, 215, 80)
		title.Text = payload.title or "Welcome Offer"
		title.Parent = frame

		local body = Instance.new("TextLabel")
		body.Position = UDim2.fromOffset(20, 86)
		body.Size = UDim2.new(1, -40, 0, 112)
		body.BackgroundTransparency = 1
		body.Font = Enum.Font.Gotham
		body.TextScaled = true
		body.TextWrapped = true
		body.TextYAlignment = Enum.TextYAlignment.Top
		body.TextColor3 = Color3.fromRGB(220, 220, 230)
		body.Text = payload.body or ""
		body.Parent = frame

		local timer = Instance.new("TextLabel")
		timer.Position = UDim2.fromOffset(20, 200)
		timer.Size = UDim2.new(1, -40, 0, 22)
		timer.BackgroundTransparency = 1
		timer.Font = Enum.Font.GothamBold
		timer.TextScaled = true
		timer.TextColor3 = Color3.fromRGB(255, 120, 120)
		timer.Text = ""
		timer.Parent = frame

		local buy = Instance.new("TextButton")
		buy.Position = UDim2.fromOffset(20, 232)
		buy.Size = UDim2.new(1, -40, 0, 48)
		buy.Font = Enum.Font.GothamBlack
		buy.TextScaled = true
		buy.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
		buy.TextColor3 = Color3.fromRGB(255, 255, 255)
		buy.BorderSizePixel = 0
		buy.Text = string.format("BUY · R$ %d", payload.productPrice or 0)
		buy.Parent = frame
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 10); bc.Parent = buy

		local close = Instance.new("TextButton")
		close.AnchorPoint = Vector2.new(1, 0)
		close.Position = UDim2.new(1, -8, 0, 8)
		close.Size = UDim2.fromOffset(32, 32)
		close.Font = Enum.Font.GothamBold
		close.TextScaled = true
		close.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
		close.TextColor3 = Color3.fromRGB(220, 220, 220)
		close.BorderSizePixel = 0
		close.Text = "✕"
		close.Parent = frame
		local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 6); cc.Parent = close

		local closed = false
		local function dismiss()
			if closed then return end
			closed = true
			local tw = TweenService:Create(backdrop, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
			tw:Play()
			tw.Completed:Wait()
			backdrop:Destroy()
		end

		close.MouseButton1Click:Connect(dismiss)
		buy.MouseButton1Click:Connect(function()
			if payload.productKey then
				Remotes.Event(Remotes.Names.RequestPromptPurchase):FireServer("product", payload.productKey)
			end
			task.delay(0.5, dismiss)
		end)

		-- Auto-dismiss countdown
		task.spawn(function()
			local expires = os.time() + (payload.expiresIn or 600)
			while not closed do
				local left = expires - os.time()
				if left <= 0 then dismiss(); break end
				timer.Text = `Expires in {Util.SecondsToClock(left)}`
				task.wait(1)
			end
		end)
	end)
end

return WelcomeOfferUI
