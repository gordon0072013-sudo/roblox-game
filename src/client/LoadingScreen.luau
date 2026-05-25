--!strict
--[[
	LoadingScreen — covers the screen during initial asset/replication load.
	Shows the game name, a fake loading bar (real load time on Roblox is
	usually <2s anyway), and most importantly the active redemption codes
	+ Discord/Group CTAs. First impression frame = highest-attention frame.
]]

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LoadingScreen = {}

function LoadingScreen.Init()
	-- Hide Roblox's default loading screen
	pcall(function() ReplicatedFirst:RemoveDefaultLoadingScreen() end)

	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "LoadingScreen"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 100
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(15, 10, 30)
	bg.BorderSizePixel = 0
	bg.Parent = gui

	local title = Instance.new("TextLabel")
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.new(0.5, 0, 0, 80)
	title.Size = UDim2.fromOffset(900, 120)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 215, 80)
	title.Text = "🧠 BRAINROT LAB"
	title.Parent = bg

	local sub = Instance.new("TextLabel")
	sub.AnchorPoint = Vector2.new(0.5, 0)
	sub.Position = UDim2.new(0.5, 0, 0, 200)
	sub.Size = UDim2.fromOffset(700, 40)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamBold
	sub.TextScaled = true
	sub.TextColor3 = Color3.fromRGB(255, 100, 200)
	sub.Text = "Mutation & Infection Tycoon"
	sub.Parent = bg

	-- Codes panel
	local codesPanel = Instance.new("Frame")
	codesPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	codesPanel.Position = UDim2.fromScale(0.5, 0.5)
	codesPanel.Size = UDim2.fromOffset(520, 240)
	codesPanel.BackgroundColor3 = Color3.fromRGB(25, 20, 45)
	codesPanel.BorderSizePixel = 0
	codesPanel.Parent = bg
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 12); cc.Parent = codesPanel
	local cs = Instance.new("UIStroke"); cs.Color = Color3.fromRGB(120, 220, 120); cs.Thickness = 2; cs.Parent = codesPanel

	local codesTitle = Instance.new("TextLabel")
	codesTitle.Position = UDim2.fromOffset(12, 8)
	codesTitle.Size = UDim2.new(1, -24, 0, 30)
	codesTitle.BackgroundTransparency = 1
	codesTitle.Font = Enum.Font.GothamBlack
	codesTitle.TextScaled = true
	codesTitle.TextColor3 = Color3.fromRGB(120, 220, 120)
	codesTitle.Text = "🎟 ACTIVE CODES (free cash!)"
	codesTitle.TextXAlignment = Enum.TextXAlignment.Left
	codesTitle.Parent = codesPanel

	local codeBody = Instance.new("TextLabel")
	codeBody.Position = UDim2.fromOffset(12, 44)
	codeBody.Size = UDim2.new(1, -24, 1, -56)
	codeBody.BackgroundTransparency = 1
	codeBody.Font = Enum.Font.Gotham
	codeBody.TextScaled = true
	codeBody.TextColor3 = Color3.fromRGB(255, 255, 255)
	codeBody.TextXAlignment = Enum.TextXAlignment.Left
	codeBody.TextYAlignment = Enum.TextYAlignment.Top
	codeBody.TextWrapped = true
	codeBody.Text = "• LAUNCH — 2,500 cash\n• BRAINROT — 1,500 cash\n• SIGMA — rare brainrot egg\n• OUTBREAK — 3 infection bombs\n• MUTATE — free instant mutation"
	codeBody.Parent = codesPanel

	-- Bottom: bar + CTA
	local barBg = Instance.new("Frame")
	barBg.AnchorPoint = Vector2.new(0.5, 1)
	barBg.Position = UDim2.new(0.5, 0, 1, -80)
	barBg.Size = UDim2.fromOffset(420, 14)
	barBg.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
	barBg.BorderSizePixel = 0
	barBg.Parent = bg
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = barBg

	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.fromScale(0, 1)
	barFill.BackgroundColor3 = Color3.fromRGB(255, 100, 200)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	local bfc = Instance.new("UICorner"); bfc.CornerRadius = UDim.new(0, 6); bfc.Parent = barFill

	local cta = Instance.new("TextLabel")
	cta.AnchorPoint = Vector2.new(0.5, 1)
	cta.Position = UDim2.new(0.5, 0, 1, -32)
	cta.Size = UDim2.fromOffset(700, 28)
	cta.BackgroundTransparency = 1
	cta.Font = Enum.Font.Gotham
	cta.TextScaled = true
	cta.TextColor3 = Color3.fromRGB(200, 200, 220)
	cta.Text = "Tip: join the group for permanent +25% cash · check 🎟 Codes after spawn"
	cta.Parent = bg

	local function fade(targetT)
		local tw = TweenService:Create(bg, TweenInfo.new(0.4), { BackgroundTransparency = targetT })
		tw:Play()
		return tw
	end

	-- Animate bar
	task.spawn(function()
		local start = os.clock()
		while gui.Parent do
			local elapsed = os.clock() - start
			barFill.Size = UDim2.fromScale(math.min(1, elapsed / 3), 1)
			task.wait(0.05)
			if elapsed > 3 then break end
		end
	end)

	-- Wait for game to load, then fade out
	game.Loaded:Wait()
	task.wait(1) -- let players read the codes
	for _, child in ipairs(bg:GetChildren()) do
		if child:IsA("GuiObject") then
			TweenService:Create(child, TweenInfo.new(0.4), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
		end
	end
	fade(1).Completed:Wait()
	gui:Destroy()
end

return LoadingScreen
