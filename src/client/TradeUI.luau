--!strict
--[[
	TradeUI — minimal but functional trade window. Two columns (you / them),
	each showing offered brainrots + cash. Click an inventory entry to add
	from your side, click an offer entry to remove. Confirm button changes
	color on commit; either-side edit un-confirms both.

	Also handles incoming invite prompts and provides a "Send invite to
	nearest player" button on the trade button row.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)
local BrainrotData = require(Shared.BrainrotData)
local MutationData = require(Shared.MutationData)

local TradeUI = {}

local localPlayer = Players.LocalPlayer

local frame: Frame
local headerLabel: TextLabel
local sideAFrame: Frame
local sideBFrame: Frame
local cashInputA: TextBox
local confirmABtn: TextButton
local sideALabel: TextLabel
local sideBLabel: TextLabel
local inventoryList: ScrollingFrame

local latestInventory: any = { inventory = {}, capacity = 0, max = 200 }
local latestTrade: any = nil

local function brainrotDisplay(b: any): string
	local def = BrainrotData.Get(b.speciesId)
	local display = def and def.displayName or "?"
	for _, mutId in ipairs(b.mutations) do
		local m = MutationData.Get(mutId)
		if m then display = `${m.suffix} ${display}` end
	end
	return display .. ` [T${b.mutationTier}]`
end

local function renderOfferList(parent: Frame, uids: { string }, sourcePlayer: Player?)
	for _, c in ipairs(parent:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	local layout = parent:FindFirstChildOfClass("UIListLayout")
	if not layout then
		layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 4)
		layout.Parent = parent
	end

	for _, uid in ipairs(uids) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -6, 0, 28)
		row.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		row.BorderSizePixel = 0
		row.Parent = parent
		local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 4); rc.Parent = row

		-- We don't have rich data on the other side's offer, so just show uid as a placeholder.
		-- For our own side, look up from latestInventory.
		local text = `· ${string.sub(uid, 1, 8)}`
		if sourcePlayer == localPlayer then
			for _, b in ipairs(latestInventory.inventory) do
				if b.uid == uid then text = "· " .. brainrotDisplay(b); break end
			end
		end

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.Gotham
		lbl.TextScaled = true
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextColor3 = Color3.fromRGB(240, 240, 240)
		lbl.Text = text
		lbl.Parent = row
		local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 6); pad.Parent = lbl

		if sourcePlayer == localPlayer then
			row.MouseEnter:Connect(function() row.BackgroundColor3 = Color3.fromRGB(80, 50, 70) end)
			row.MouseLeave:Connect(function() row.BackgroundColor3 = Color3.fromRGB(50, 50, 70) end)
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.fromScale(1, 1)
			btn.BackgroundTransparency = 1
			btn.Text = ""
			btn.Parent = row
			btn.MouseButton1Click:Connect(function()
				Remotes.Event(Remotes.Names.RequestTradeRemoveBrainrot):FireServer(uid)
			end)
		end
	end
end

local function rebuildTrade(payload: any)
	if payload.cancelled then
		latestTrade = nil
		headerLabel.Text = "No active trade · click an inventory entry below after pressing TRADE (T)"
		renderOfferList(sideAFrame, {}, localPlayer)
		renderOfferList(sideBFrame, {}, nil)
		sideALabel.Text = "You"
		sideBLabel.Text = "Them"
		confirmABtn.Text = "Send trade invite (T near player)"
		confirmABtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
		confirmABtn.AutoButtonColor = false
		return
	end
	latestTrade = payload
	local mySide, theirSide
	local theirUserId
	if payload.a.userId == localPlayer.UserId then
		mySide, theirSide = payload.a, payload.b
		theirUserId = payload.b.userId
	else
		mySide, theirSide = payload.b, payload.a
		theirUserId = payload.a.userId
	end
	local theirPlayer = Players:GetPlayerByUserId(theirUserId)
	headerLabel.Text = `Trading with ${(theirPlayer and theirPlayer.DisplayName) or "?"} · confirm twice to commit`
	sideALabel.Text = `You · ${Util.FormatShortNumber(mySide.cash)} cash` .. (mySide.confirmed and " ✓" or "")
	sideBLabel.Text = `${(theirPlayer and theirPlayer.DisplayName) or "?"} · ${Util.FormatShortNumber(theirSide.cash)} cash` .. (theirSide.confirmed and " ✓" or "")
	renderOfferList(sideAFrame, mySide.brainrotUids, localPlayer)
	renderOfferList(sideBFrame, theirSide.brainrotUids, nil)
	confirmABtn.Text = mySide.confirmed and "✓ CONFIRMED" or "CONFIRM"
	confirmABtn.BackgroundColor3 = mySide.confirmed and Color3.fromRGB(60, 140, 60) or Color3.fromRGB(80, 200, 120)
	confirmABtn.AutoButtonColor = true
end

local function rebuildInventory(payload: any)
	latestInventory = payload
	inventoryList:ClearAllChildren()
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = inventoryList
	for _, b in ipairs(payload.inventory) do
		local row = Instance.new("TextButton")
		row.Size = UDim2.new(1, -6, 0, 28)
		row.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		row.BorderSizePixel = 0
		row.Text = "+ " .. brainrotDisplay(b)
		row.Font = Enum.Font.Gotham
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = Color3.fromRGB(240, 240, 240)
		row.AutoButtonColor = true
		row.Parent = inventoryList
		local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 4); rc.Parent = row
		local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 6); pad.Parent = row
		row.MouseButton1Click:Connect(function()
			if latestTrade then
				Remotes.Event(Remotes.Names.RequestTradeAddBrainrot):FireServer(b.uid)
			end
		end)
	end
end

function TradeUI.Init(screen: ScreenGui, UIController)
	frame = Instance.new("Frame")
	frame.Name = "Trade"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(720, 460)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 180, 80); s.Thickness = 2; s.Parent = frame

	headerLabel = Instance.new("TextLabel")
	headerLabel.Position = UDim2.fromOffset(12, 8)
	headerLabel.Size = UDim2.new(1, -24, 0, 28)
	headerLabel.BackgroundTransparency = 1
	headerLabel.Font = Enum.Font.GothamBold
	headerLabel.TextScaled = true
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left
	headerLabel.TextColor3 = Color3.fromRGB(255, 180, 80)
	headerLabel.Text = "Trade"
	headerLabel.Parent = frame

	sideALabel = Instance.new("TextLabel")
	sideALabel.Position = UDim2.fromOffset(12, 44)
	sideALabel.Size = UDim2.fromOffset(330, 24)
	sideALabel.BackgroundTransparency = 1
	sideALabel.Font = Enum.Font.GothamBlack
	sideALabel.TextScaled = true
	sideALabel.TextXAlignment = Enum.TextXAlignment.Left
	sideALabel.TextColor3 = Color3.fromRGB(120, 220, 120)
	sideALabel.Text = "You"
	sideALabel.Parent = frame

	sideAFrame = Instance.new("Frame")
	sideAFrame.Position = UDim2.fromOffset(12, 72)
	sideAFrame.Size = UDim2.fromOffset(330, 160)
	sideAFrame.BackgroundColor3 = Color3.fromRGB(30, 40, 30)
	sideAFrame.BorderSizePixel = 0
	sideAFrame.Parent = frame
	local sac = Instance.new("UICorner"); sac.CornerRadius = UDim.new(0, 8); sac.Parent = sideAFrame
	local sap = Instance.new("UIPadding"); sap.PaddingTop = UDim.new(0, 4); sap.PaddingLeft = UDim.new(0, 4); sap.Parent = sideAFrame

	sideBLabel = Instance.new("TextLabel")
	sideBLabel.Position = UDim2.fromOffset(360, 44)
	sideBLabel.Size = UDim2.fromOffset(330, 24)
	sideBLabel.BackgroundTransparency = 1
	sideBLabel.Font = Enum.Font.GothamBlack
	sideBLabel.TextScaled = true
	sideBLabel.TextXAlignment = Enum.TextXAlignment.Left
	sideBLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	sideBLabel.Text = "Them"
	sideBLabel.Parent = frame

	sideBFrame = Instance.new("Frame")
	sideBFrame.Position = UDim2.fromOffset(360, 72)
	sideBFrame.Size = UDim2.fromOffset(330, 160)
	sideBFrame.BackgroundColor3 = Color3.fromRGB(40, 30, 30)
	sideBFrame.BorderSizePixel = 0
	sideBFrame.Parent = frame
	local sbc = Instance.new("UICorner"); sbc.CornerRadius = UDim.new(0, 8); sbc.Parent = sideBFrame
	local sbp = Instance.new("UIPadding"); sbp.PaddingTop = UDim.new(0, 4); sbp.PaddingLeft = UDim.new(0, 4); sbp.Parent = sideBFrame

	cashInputA = Instance.new("TextBox")
	cashInputA.Position = UDim2.fromOffset(12, 240)
	cashInputA.Size = UDim2.fromOffset(220, 32)
	cashInputA.Font = Enum.Font.GothamBold
	cashInputA.TextScaled = true
	cashInputA.PlaceholderText = "Your cash offer…"
	cashInputA.Text = ""
	cashInputA.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	cashInputA.TextColor3 = Color3.fromRGB(255, 215, 80)
	cashInputA.ClearTextOnFocus = false
	cashInputA.Parent = frame
	local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(0, 6); ic.Parent = cashInputA
	cashInputA.FocusLost:Connect(function()
		local n = tonumber(cashInputA.Text) or 0
		Remotes.Event(Remotes.Names.RequestTradeSetCash):FireServer(n)
	end)

	confirmABtn = Instance.new("TextButton")
	confirmABtn.Position = UDim2.fromOffset(240, 240)
	confirmABtn.Size = UDim2.fromOffset(220, 32)
	confirmABtn.Font = Enum.Font.GothamBlack
	confirmABtn.TextScaled = true
	confirmABtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
	confirmABtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmABtn.BorderSizePixel = 0
	confirmABtn.Text = "CONFIRM"
	confirmABtn.Parent = frame
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 6); cc.Parent = confirmABtn
	confirmABtn.MouseButton1Click:Connect(function()
		if latestTrade then
			Remotes.Event(Remotes.Names.RequestTradeConfirm):FireServer()
		else
			-- send invite to nearest player
			local nearest
			local char = localPlayer.Character
			if not char then return end
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then return end
			local bestDist = math.huge
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= localPlayer and p.Character then
					local ohrp = p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
					if ohrp then
						local d = (ohrp.Position - hrp.Position).Magnitude
						if d < bestDist then bestDist = d; nearest = p end
					end
				end
			end
			if nearest then
				Remotes.Event(Remotes.Names.RequestTradeInvite):FireServer(nearest.UserId)
			end
		end
	end)

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Position = UDim2.fromOffset(470, 240)
	cancelBtn.Size = UDim2.fromOffset(220, 32)
	cancelBtn.Font = Enum.Font.GothamBold
	cancelBtn.TextScaled = true
	cancelBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
	cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelBtn.BorderSizePixel = 0
	cancelBtn.Text = "CANCEL TRADE"
	cancelBtn.Parent = frame
	local cbc = Instance.new("UICorner"); cbc.CornerRadius = UDim.new(0, 6); cbc.Parent = cancelBtn
	cancelBtn.MouseButton1Click:Connect(function()
		Remotes.Event(Remotes.Names.RequestTradeCancel):FireServer()
	end)

	local invHd = Instance.new("TextLabel")
	invHd.Position = UDim2.fromOffset(12, 284)
	invHd.Size = UDim2.new(1, -24, 0, 22)
	invHd.BackgroundTransparency = 1
	invHd.Font = Enum.Font.GothamBold
	invHd.TextScaled = true
	invHd.TextXAlignment = Enum.TextXAlignment.Left
	invHd.TextColor3 = Color3.fromRGB(180, 180, 200)
	invHd.Text = "Your inventory — click to add to offer"
	invHd.Parent = frame

	inventoryList = Instance.new("ScrollingFrame")
	inventoryList.Position = UDim2.fromOffset(12, 308)
	inventoryList.Size = UDim2.new(1, -24, 0, 140)
	inventoryList.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	inventoryList.BackgroundTransparency = 0.3
	inventoryList.BorderSizePixel = 0
	inventoryList.ScrollBarThickness = 6
	inventoryList.CanvasSize = UDim2.new(0, 0, 0, 0)
	inventoryList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	inventoryList.Parent = frame
	local invc = Instance.new("UICorner"); invc.CornerRadius = UDim.new(0, 8); invc.Parent = inventoryList

	Remotes.Event(Remotes.Names.TradeUpdate).OnClientEvent:Connect(rebuildTrade)
	Remotes.Event(Remotes.Names.InventoryUpdate).OnClientEvent:Connect(rebuildInventory)

	-- Invite popup
	Remotes.Event(Remotes.Names.TradeInvite).OnClientEvent:Connect(function(invite)
		local popup = Instance.new("Frame")
		popup.AnchorPoint = Vector2.new(0.5, 0)
		popup.Position = UDim2.new(0.5, 0, 0, 80)
		popup.Size = UDim2.fromOffset(420, 80)
		popup.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
		popup.BackgroundTransparency = 0.1
		popup.Parent = screen
		local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 10); pc.Parent = popup
		local ps = Instance.new("UIStroke"); ps.Color = Color3.fromRGB(255, 180, 80); ps.Thickness = 2; ps.Parent = popup
		local label = Instance.new("TextLabel")
		label.Position = UDim2.fromOffset(10, 6)
		label.Size = UDim2.new(1, -20, 0, 24)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(255, 215, 80)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = `${invite.fromName} wants to trade`
		label.Parent = popup
		local acc = Instance.new("TextButton")
		acc.Position = UDim2.fromOffset(10, 36)
		acc.Size = UDim2.fromOffset(190, 36)
		acc.Font = Enum.Font.GothamBlack
		acc.TextScaled = true
		acc.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
		acc.TextColor3 = Color3.fromRGB(255, 255, 255)
		acc.BorderSizePixel = 0
		acc.Text = "ACCEPT"
		acc.Parent = popup
		local acc_c = Instance.new("UICorner"); acc_c.CornerRadius = UDim.new(0, 6); acc_c.Parent = acc
		local dec = Instance.new("TextButton")
		dec.Position = UDim2.fromOffset(210, 36)
		dec.Size = UDim2.fromOffset(190, 36)
		dec.Font = Enum.Font.GothamBlack
		dec.TextScaled = true
		dec.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
		dec.TextColor3 = Color3.fromRGB(255, 255, 255)
		dec.BorderSizePixel = 0
		dec.Text = "DECLINE"
		dec.Parent = popup
		local dec_c = Instance.new("UICorner"); dec_c.CornerRadius = UDim.new(0, 6); dec_c.Parent = dec
		acc.MouseButton1Click:Connect(function()
			Remotes.Event(Remotes.Names.RequestTradeAccept):FireServer()
			popup:Destroy()
			UIController.ToggleScreen("Trade")
		end)
		dec.MouseButton1Click:Connect(function()
			Remotes.Event(Remotes.Names.RequestTradeDecline):FireServer()
			popup:Destroy()
		end)
		task.delay(invite.ttl or 30, function() if popup.Parent then popup:Destroy() end end)
	end)

	UIController.Register("Trade", frame, "🤝 Trade", Color3.fromRGB(255, 180, 80))

	rebuildTrade({ cancelled = true })
end

return TradeUI
