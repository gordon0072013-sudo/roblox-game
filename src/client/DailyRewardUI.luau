--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local DailyRewardUI = {}

local container: Frame
local headerLabel: TextLabel
local claimBtn: TextButton

local function rebuild(payload: any)
	for _, c in ipairs(container:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	headerLabel.Text = `Daily Reward · Streak {payload.streak}` .. (payload.isPremium and " · ⭐ Premium" or "")
	claimBtn.Visible = payload.canClaim
	claimBtn.Text = payload.canClaim and "CLAIM TODAY" or "Already claimed"
	claimBtn.AutoButtonColor = payload.canClaim

	local grid = Instance.new("Frame")
	grid.Size = UDim2.new(1, -24, 0, 140)
	grid.Position = UDim2.fromOffset(12, 80)
	grid.BackgroundTransparency = 1
	grid.Parent = container

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.Padding = UDim.new(0, 6)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Parent = grid

	for i, r in ipairs(payload.rewards) do
		local cell = Instance.new("Frame")
		cell.Size = UDim2.fromOffset(70, 120)
		cell.BackgroundColor3 = if i == payload.streak then Color3.fromRGB(80, 60, 100) else Color3.fromRGB(40, 40, 55)
		cell.BorderSizePixel = 0
		cell.Parent = grid
		local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 6); cc.Parent = cell

		local day = Instance.new("TextLabel")
		day.Size = UDim2.new(1, 0, 0, 22)
		day.BackgroundTransparency = 1
		day.Font = Enum.Font.GothamBold
		day.TextScaled = true
		day.TextColor3 = Color3.fromRGB(255, 215, 80)
		day.Text = `Day {i}`
		day.Parent = cell

		local what = Instance.new("TextLabel")
		what.Position = UDim2.fromOffset(0, 24)
		what.Size = UDim2.new(1, 0, 1, -24)
		what.BackgroundTransparency = 1
		what.Font = Enum.Font.Gotham
		what.TextScaled = true
		what.TextWrapped = true
		what.TextColor3 = Color3.fromRGB(255, 255, 255)
		if r.kind == "cash" then
			what.Text = `{r.amount}\ncash`
		elseif r.kind == "infection_bomb" then
			what.Text = `{r.amount}x\n💣`
		elseif r.kind == "rare_egg" then
			what.Text = `{r.amount}x\nRare 🥚`
		end
		what.Parent = cell
	end
end

function DailyRewardUI.Init(screen: ScreenGui, UIController)
	local frame = Instance.new("Frame")
	frame.Name = "Daily"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(600, 260)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 200, 100); s.Thickness = 2; s.Parent = frame

	container = frame
	headerLabel = Instance.new("TextLabel")
	headerLabel.Position = UDim2.fromOffset(12, 8)
	headerLabel.Size = UDim2.new(1, -24, 0, 32)
	headerLabel.BackgroundTransparency = 1
	headerLabel.Font = Enum.Font.GothamBold
	headerLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left
	headerLabel.TextScaled = true
	headerLabel.Text = "Daily Reward"
	headerLabel.Parent = frame

	claimBtn = Instance.new("TextButton")
	claimBtn.AnchorPoint = Vector2.new(1, 0)
	claimBtn.Position = UDim2.new(1, -12, 0, 8)
	claimBtn.Size = UDim2.fromOffset(180, 36)
	claimBtn.Font = Enum.Font.GothamBlack
	claimBtn.TextScaled = true
	claimBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
	claimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	claimBtn.BorderSizePixel = 0
	claimBtn.Text = "CLAIM"
	claimBtn.Parent = frame
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 6); cc.Parent = claimBtn
	claimBtn.MouseButton1Click:Connect(function()
		Remotes.Event(Remotes.Names.RequestClaimDaily):FireServer()
	end)

	Remotes.Event(Remotes.Names.DailyRewardUpdate).OnClientEvent:Connect(rebuild)
	UIController.Register("Daily", frame, "🎁 Daily", Color3.fromRGB(255, 200, 100))
end

return DailyRewardUI
