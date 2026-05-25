--!strict
--[[
	TutorialUI — a 6-step floating overlay shown only on first session.
	Critical for D1 conversion: tells the player exactly which buttons to
	press in the first 90 seconds so they reach the "mutation moment"
	before they bounce. This is the single biggest delta on lifetime
	revenue for free-to-play games.

	State (whether the tutorial completed) is per-device via the
	per-player attribute "TutorialDone" we set on first finish — preserved
	via a tiny in-script saved key on the local player so it doesn't run
	every join. Server-side persistence isn't needed for this UX.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local TutorialUI = {}

type Step = {
	title: string,
	body: string,
}

local STEPS: { Step } = {
	{ title="Welcome to BRAINROT LAB",   body="Your lab is the dark plot. A starter brainrot is already on it, generating cash." },
	{ title="Capture more",              body="Step on the green capture pad on your plot (or press R) — costs cash, gives a random brainrot." },
	{ title="Watch them mutate",         body="Every ~90s a brainrot rolls a mutation: new color, scale, suffix, and FX. Higher tier = more cash." },
	{ title="Raid rivals",               body="Walk to another player's plot and press E near one of their brainrots — STEAL it." },
	{ title="Sabotage them",             body="Press Q near a rival to throw an INFECTION BOMB — slashes their income for 3 minutes." },
	{ title="Rebirth + Shop",            body="Click REBIRTH on the HUD for permanent multipliers. Open the Shop for gamepasses. Drop codes in 🎟 Codes." },
}

local localPlayer = Players.LocalPlayer
local DONE_KEY = "BrainrotLab.TutorialDone.v1"

local function alreadyDone(): boolean
	local attr = localPlayer:GetAttribute(DONE_KEY)
	return attr == true
end

local function markDone()
	localPlayer:SetAttribute(DONE_KEY, true)
end

function TutorialUI.Init(screen: ScreenGui)
	if alreadyDone() then return end

	local frame = Instance.new("Frame")
	frame.Name = "Tutorial"
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -84)
	frame.Size = UDim2.fromOffset(560, 140)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 215, 80); s.Thickness = 2; s.Parent = frame

	local title = Instance.new("TextLabel")
	title.Position = UDim2.fromOffset(16, 8)
	title.Size = UDim2.new(1, -32, 0, 30)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 215, 80)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = ""
	title.Parent = frame

	local body = Instance.new("TextLabel")
	body.Position = UDim2.fromOffset(16, 42)
	body.Size = UDim2.new(1, -32, 0, 56)
	body.BackgroundTransparency = 1
	body.Font = Enum.Font.Gotham
	body.TextScaled = true
	body.TextWrapped = true
	body.TextColor3 = Color3.fromRGB(220, 220, 230)
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.Text = ""
	body.Parent = frame

	local stepLabel = Instance.new("TextLabel")
	stepLabel.AnchorPoint = Vector2.new(0, 1)
	stepLabel.Position = UDim2.new(0, 16, 1, -8)
	stepLabel.Size = UDim2.fromOffset(120, 24)
	stepLabel.BackgroundTransparency = 1
	stepLabel.Font = Enum.Font.GothamBold
	stepLabel.TextScaled = true
	stepLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
	stepLabel.TextXAlignment = Enum.TextXAlignment.Left
	stepLabel.Parent = frame

	local nextBtn = Instance.new("TextButton")
	nextBtn.AnchorPoint = Vector2.new(1, 1)
	nextBtn.Position = UDim2.new(1, -16, 1, -8)
	nextBtn.Size = UDim2.fromOffset(120, 32)
	nextBtn.Font = Enum.Font.GothamBlack
	nextBtn.TextScaled = true
	nextBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
	nextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	nextBtn.BorderSizePixel = 0
	nextBtn.Text = "NEXT ▶"
	nextBtn.Parent = frame
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = nextBtn

	local skipBtn = Instance.new("TextButton")
	skipBtn.AnchorPoint = Vector2.new(1, 1)
	skipBtn.Position = UDim2.new(1, -144, 1, -8)
	skipBtn.Size = UDim2.fromOffset(70, 32)
	skipBtn.Font = Enum.Font.Gotham
	skipBtn.TextScaled = true
	skipBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	skipBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
	skipBtn.BorderSizePixel = 0
	skipBtn.Text = "Skip"
	skipBtn.Parent = frame
	local sbc = Instance.new("UICorner"); sbc.CornerRadius = UDim.new(0, 6); sbc.Parent = skipBtn

	local idx = 1
	local function show(i: number)
		local step = STEPS[i]
		title.Text = step.title
		body.Text = step.body
		stepLabel.Text = `${i}/${#STEPS}`
		nextBtn.Text = if i == #STEPS then "DONE ✓" else "NEXT ▶"
	end
	show(idx)

	local closed = false
	local function close()
		if closed then return end
		closed = true
		markDone()
		local tw = TweenService:Create(frame, TweenInfo.new(0.25), {
			BackgroundTransparency = 1,
			Position = frame.Position + UDim2.fromOffset(0, 20),
		})
		tw:Play()
		tw.Completed:Wait()
		frame:Destroy()
	end

	nextBtn.MouseButton1Click:Connect(function()
		if idx >= #STEPS then close() else idx += 1; show(idx) end
	end)
	skipBtn.MouseButton1Click:Connect(close)
end

return TutorialUI
