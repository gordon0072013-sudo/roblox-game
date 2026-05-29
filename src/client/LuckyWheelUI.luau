--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Util    = require(Shared.Util)

local LuckyWheelUI = {}

local frame: Frame?
local wheel: Frame?
local needle: Frame?
local statusLabel: TextLabel?
local freeBtn: TextButton?
local storedBtn: TextButton?
local buyBtn: TextButton?
local cachedSegments: { any } = {}
local cachedPayload: any = nil
local spinning = false

local function rebuildWheel(segments: { any })
	if not wheel then return end
	wheel:ClearAllChildren()
	cachedSegments = segments
	local count = #segments
	if count == 0 then return end
	local angleStep = 360 / count
	for i, seg in ipairs(segments) do
		local sliceContainer = Instance.new("Frame")
		sliceContainer.AnchorPoint = Vector2.new(0.5, 1)
		sliceContainer.Position = UDim2.fromScale(0.5, 0.5)
		sliceContainer.Size = UDim2.fromScale(1, 0.5)
		sliceContainer.BackgroundTransparency = 1
		sliceContainer.Rotation = (i - 1) * angleStep - 90
		sliceContainer.Parent = wheel
		-- Simulate a pie slice with a colored rectangle clipped by rotation;
		-- looks reasonable enough for non-image fallback rendering.
		local block = Instance.new("Frame")
		block.AnchorPoint = Vector2.new(0.5, 1)
		block.Position = UDim2.fromScale(0.5, 1)
		block.Size = UDim2.fromOffset(60, 140)
		block.BackgroundColor3 = Color3.fromRGB(seg.color[1], seg.color[2], seg.color[3])
		block.BorderSizePixel = 0
		block.Parent = sliceContainer
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = block

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromOffset(56, 24)
		label.Position = UDim2.fromOffset(2, 4)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(20, 20, 35)
		label.TextStrokeTransparency = 0.5
		label.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
		label.Text = seg.label
		label.Parent = block
	end
end

local function updateStatus(payload: any)
	cachedPayload = payload
	if not statusLabel or not freeBtn or not storedBtn then return end
	if payload.freeReady then
		statusLabel.Text = "Free spin ready"
		freeBtn.Text = "FREE SPIN"
		freeBtn.AutoButtonColor = true
		freeBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
	else
		statusLabel.Text = string.format("Free spin in %s", Util.SecondsToClock(payload.secondsToFree))
		freeBtn.Text = "WAIT"
		freeBtn.AutoButtonColor = false
		freeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	end
	storedBtn.Text = string.format("USE SPIN (%d)", payload.spinsAvailable)
	storedBtn.AutoButtonColor = payload.spinsAvailable > 0
	storedBtn.BackgroundColor3 = if payload.spinsAvailable > 0 then Color3.fromRGB(120, 80, 200) else Color3.fromRGB(60, 60, 80)
end

local function spinTo(segmentIndex: number)
	if not wheel then return end
	local count = #cachedSegments
	if count == 0 then return end
	spinning = true
	local angleStep = 360 / count
	local landAngle = (segmentIndex - 1) * angleStep
	local fullSpins = 4
	local target = -(fullSpins * 360 + landAngle)
	local tw = TweenService:Create(wheel, TweenInfo.new(3.0, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Rotation = wheel.Rotation + target,
	})
	tw:Play()
	tw.Completed:Wait()
	spinning = false
end

function LuckyWheelUI.Init(screen: ScreenGui, UIController)
	frame = Instance.new("Frame")
	;(frame :: Frame).Name = "Wheel"
	;(frame :: Frame).AnchorPoint = Vector2.new(0.5, 0.5)
	;(frame :: Frame).Position = UDim2.fromScale(0.5, 0.5)
	;(frame :: Frame).Size = UDim2.fromOffset(440, 540)
	;(frame :: Frame).BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	;(frame :: Frame).BackgroundTransparency = 0.05
	;(frame :: Frame).BorderSizePixel = 0
	;(frame :: Frame).Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 215, 80); s.Thickness = 2; s.Parent = frame

	local hd = Instance.new("TextLabel")
	hd.Position = UDim2.fromOffset(12, 8)
	hd.Size = UDim2.new(1, -24, 0, 32)
	hd.BackgroundTransparency = 1
	hd.Font = Enum.Font.GothamBlack
	hd.TextScaled = true
	hd.TextColor3 = Color3.fromRGB(255, 215, 80)
	hd.TextXAlignment = Enum.TextXAlignment.Left
	hd.Text = "🎰 Lucky Wheel"
	hd.Parent = frame

	local wheelContainer = Instance.new("Frame")
	wheelContainer.AnchorPoint = Vector2.new(0.5, 0)
	wheelContainer.Position = UDim2.new(0.5, 0, 0, 48)
	wheelContainer.Size = UDim2.fromOffset(320, 320)
	wheelContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	wheelContainer.BorderSizePixel = 0
	wheelContainer.Parent = frame
	local wcc = Instance.new("UICorner"); wcc.CornerRadius = UDim.new(1, 0); wcc.Parent = wheelContainer

	wheel = Instance.new("Frame")
	;(wheel :: Frame).Size = UDim2.fromScale(1, 1)
	;(wheel :: Frame).BackgroundTransparency = 1
	;(wheel :: Frame).Parent = wheelContainer

	needle = Instance.new("Frame")
	;(needle :: Frame).AnchorPoint = Vector2.new(0.5, 0)
	;(needle :: Frame).Position = UDim2.new(0.5, 0, 0, -10)
	;(needle :: Frame).Size = UDim2.fromOffset(16, 32)
	;(needle :: Frame).BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	;(needle :: Frame).BorderSizePixel = 0
	;(needle :: Frame).Parent = wheelContainer
	local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0, 4); nc.Parent = needle

	statusLabel = Instance.new("TextLabel")
	;(statusLabel :: TextLabel).Position = UDim2.fromOffset(12, 376)
	;(statusLabel :: TextLabel).Size = UDim2.new(1, -24, 0, 24)
	;(statusLabel :: TextLabel).BackgroundTransparency = 1
	;(statusLabel :: TextLabel).Font = Enum.Font.GothamBold
	;(statusLabel :: TextLabel).TextScaled = true
	;(statusLabel :: TextLabel).TextColor3 = Color3.fromRGB(220, 220, 230)
	;(statusLabel :: TextLabel).Text = "Loading..."
	;(statusLabel :: TextLabel).Parent = frame

	local function mkBtn(x: number, w: number, text: string): TextButton
		local b = Instance.new("TextButton")
		b.Position = UDim2.fromOffset(x, 408)
		b.Size = UDim2.fromOffset(w, 48)
		b.Font = Enum.Font.GothamBlack
		b.TextScaled = true
		b.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
		b.BorderSizePixel = 0
		b.Text = text
		b.Parent = frame
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = b
		return b
	end

	freeBtn   = mkBtn(12,  200, "FREE SPIN")
	storedBtn = mkBtn(220, 200, "USE SPIN (0)")

	buyBtn = Instance.new("TextButton")
	;(buyBtn :: TextButton).Position = UDim2.fromOffset(12, 468)
	;(buyBtn :: TextButton).Size = UDim2.new(1, -24, 0, 48)
	;(buyBtn :: TextButton).Font = Enum.Font.GothamBlack
	;(buyBtn :: TextButton).TextScaled = true
	;(buyBtn :: TextButton).BackgroundColor3 = Color3.fromRGB(255, 100, 200)
	;(buyBtn :: TextButton).TextColor3 = Color3.fromRGB(255, 255, 255)
	;(buyBtn :: TextButton).BorderSizePixel = 0
	;(buyBtn :: TextButton).Text = "BUY 5 SPINS · 79 R$"
	;(buyBtn :: TextButton).Parent = frame
	local pbc = Instance.new("UICorner"); pbc.CornerRadius = UDim.new(0, 8); pbc.Parent = buyBtn

	;(freeBtn :: TextButton).MouseButton1Click:Connect(function()
		if spinning then return end
		Remotes.Event(Remotes.Names.RequestWheelSpin):FireServer("free")
	end)
	;(storedBtn :: TextButton).MouseButton1Click:Connect(function()
		if spinning then return end
		Remotes.Event(Remotes.Names.RequestWheelSpin):FireServer("stored")
	end)
	;(buyBtn :: TextButton).MouseButton1Click:Connect(function()
		Remotes.Event(Remotes.Names.RequestPromptPurchase):FireServer("product", "WheelSpinPack5")
	end)

	Remotes.Event(Remotes.Names.WheelUpdate).OnClientEvent:Connect(function(payload)
		rebuildWheel(payload.segments)
		updateStatus(payload)
	end)

	Remotes.Event(Remotes.Names.WheelSpinResult).OnClientEvent:Connect(function(result)
		spinTo(result.segmentIndex)
	end)

	UIController.Register("Wheel", frame :: Frame, "🎰 Wheel", Color3.fromRGB(255, 215, 80))
end

return LuckyWheelUI
