--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)

local BattlePassUI = {}

local headerLabel: TextLabel
local list: ScrollingFrame
local premiumBtn: TextButton

local function rebuild(payload: any)
	headerLabel.Text = string.format(
		"Season %s · Tier %d/%d · XP %d (next: %d)",
		payload.seasonId, payload.tier, payload.maxTier,
		payload.xp, math.max(0, (payload.tier + 1) * payload.xpPerTier - payload.xp)
	)
	premiumBtn.Visible = not payload.premium

	list:ClearAllChildren()
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = list

	for tier = 1, payload.maxTier do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 38)
		row.BackgroundColor3 = if tier <= payload.tier then Color3.fromRGB(50, 70, 50) else Color3.fromRGB(40, 40, 55)
		row.BorderSizePixel = 0
		row.Parent = list
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = row

		local lbl = Instance.new("TextLabel")
		lbl.AnchorPoint = Vector2.new(0, 0.5)
		lbl.Position = UDim2.new(0, 12, 0.5, 0)
		lbl.Size = UDim2.new(1, -120, 1, -10)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.TextScaled = true
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		local claimedFree = payload.claimed[`f:${tier}`] and "✓" or "·"
		local claimedPrem = payload.claimed[`p:${tier}`] and "✓" or "·"
		lbl.Text = `Tier ${tier} [free ${claimedFree}] [prem ${claimedPrem}]`
		lbl.Parent = row

		local btn = Instance.new("TextButton")
		btn.AnchorPoint = Vector2.new(1, 0.5)
		btn.Position = UDim2.new(1, -10, 0.5, 0)
		btn.Size = UDim2.fromOffset(96, 28)
		btn.Font = Enum.Font.GothamBlack
		btn.TextScaled = true
		btn.Text = if tier <= payload.tier then "CLAIM" else "LOCKED"
		btn.AutoButtonColor = tier <= payload.tier
		btn.BackgroundColor3 = if tier <= payload.tier then Color3.fromRGB(80, 200, 120) else Color3.fromRGB(80, 80, 100)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.BorderSizePixel = 0
		btn.Parent = row
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 4); bc.Parent = btn
		if tier <= payload.tier then
			btn.MouseButton1Click:Connect(function()
				Remotes.Event(Remotes.Names.RequestClaimBattlePassTier):FireServer(tier)
			end)
		end
	end
end

function BattlePassUI.Init(screen: ScreenGui, UIController)
	local frame = Instance.new("Frame")
	frame.Name = "BattlePass"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(560, 540)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 80, 200); s.Thickness = 2; s.Parent = frame

	headerLabel = Instance.new("TextLabel")
	headerLabel.Position = UDim2.fromOffset(12, 8)
	headerLabel.Size = UDim2.new(1, -24, 0, 32)
	headerLabel.BackgroundTransparency = 1
	headerLabel.Font = Enum.Font.GothamBold
	headerLabel.TextColor3 = Color3.fromRGB(255, 100, 220)
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left
	headerLabel.TextScaled = true
	headerLabel.Text = "Battle Pass"
	headerLabel.Parent = frame

	premiumBtn = Instance.new("TextButton")
	premiumBtn.AnchorPoint = Vector2.new(1, 0)
	premiumBtn.Position = UDim2.new(1, -12, 0, 8)
	premiumBtn.Size = UDim2.fromOffset(180, 32)
	premiumBtn.Font = Enum.Font.GothamBlack
	premiumBtn.TextScaled = true
	premiumBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 200)
	premiumBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	premiumBtn.BorderSizePixel = 0
	premiumBtn.Text = "Buy Premium Pass"
	premiumBtn.Parent = frame
	local pbc = Instance.new("UICorner"); pbc.CornerRadius = UDim.new(0, 6); pbc.Parent = premiumBtn
	premiumBtn.MouseButton1Click:Connect(function()
		Remotes.Event(Remotes.Names.RequestPromptPurchase):FireServer("product", "BattlePassPremium")
	end)

	list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(12, 48)
	list.Size = UDim2.new(1, -24, 1, -60)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = frame

	Remotes.Event(Remotes.Names.BattlePassUpdate).OnClientEvent:Connect(rebuild)
	UIController.Register("BattlePass", frame, "🎖 Pass", Color3.fromRGB(255, 80, 200))

	-- avoid unused-local lint
	local _ = Util
end

return BattlePassUI
