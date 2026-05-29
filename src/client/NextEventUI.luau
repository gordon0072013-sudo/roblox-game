--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Util    = require(Shared.Util)

local NextEventUI = {}

-- A small always-visible widget pinned under the HUD showing the next
-- couple of major engagement moments. Drives anticipation: a player
-- staring at the screen sees "Wheel free spin in 11:32" and stays.
-- Updates are driven by remote payloads from server services we
-- already have (OutbreakUpdate, WheelUpdate, DailyRewardUpdate);
-- TopOfHour falls out from a math.floor on os.time().

local labels: { [string]: TextLabel } = {}

local state = {
	outbreakSeconds   = 0,
	wheelSeconds      = 0,
	dailyRecovered    = false,
	dailySecondsLeft  = 0,
}

local function refresh()
	if labels.outbreak then
		labels.outbreak.Text = `🚨 Outbreak: {Util.SecondsToClock(math.max(0, state.outbreakSeconds))}`
	end
	if labels.wheel then
		labels.wheel.Text = `🎰 Wheel: {Util.SecondsToClock(math.max(0, state.wheelSeconds))}`
	end
	if labels.hour then
		local now = os.time()
		local secondsToHour = 3600 - (now % 3600)
		labels.hour.Text = `⏰ Top of hour: {Util.SecondsToClock(secondsToHour)}`
	end
	if labels.daily then
		labels.daily.Text = state.dailyRecovered
			and "🎁 Daily reward: ready!"
			or `🎁 Daily reward: {Util.SecondsToClock(math.max(0, state.dailySecondsLeft))}`
	end
end

function NextEventUI.Init(screen: ScreenGui)
	local frame = Instance.new("Frame")
	frame.Name = "NextEvent"
	frame.AnchorPoint = Vector2.new(0, 0)
	frame.Position = UDim2.fromOffset(16, 180)  -- below HUD
	frame.Size = UDim2.fromOffset(280, 108)
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(120, 200, 255); s.Thickness = 1; s.Parent = frame
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6); pad.PaddingBottom = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = frame
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 2)
	list.Parent = frame

	local function mkLabel(key: string, color: Color3): TextLabel
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, 0, 0, 22)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.GothamBold
		l.TextScaled = true
		l.TextColor3 = color
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextStrokeTransparency = 0.7
		l.Text = ""
		l.Parent = frame
		labels[key] = l
		return l
	end

	mkLabel("outbreak", Color3.fromRGB(255, 160, 120))
	mkLabel("wheel",    Color3.fromRGB(255, 215, 100))
	mkLabel("hour",     Color3.fromRGB(180, 220, 255))
	mkLabel("daily",    Color3.fromRGB(200, 255, 180))

	Remotes.Event(Remotes.Names.OutbreakUpdate).OnClientEvent:Connect(function(payload)
		if not payload then return end
		state.outbreakSeconds = payload.secondsToStart or 0
		if payload.active then state.outbreakSeconds = -1 * (payload.secondsLeft or 0) end
		refresh()
	end)

	Remotes.Event(Remotes.Names.WheelUpdate).OnClientEvent:Connect(function(payload)
		if not payload then return end
		state.wheelSeconds = payload.secondsToFree or 0
		refresh()
	end)

	Remotes.Event(Remotes.Names.DailyRewardUpdate).OnClientEvent:Connect(function(payload)
		if not payload then return end
		state.dailyRecovered = payload.canClaim == true
		-- canClaim payload doesn't include nextAvailable seconds; fall back to
		-- "tomorrow at UTC midnight" approximation.
		if not state.dailyRecovered then
			local now = os.time()
			state.dailySecondsLeft = 86400 - (now % 86400)
		end
		refresh()
	end)

	-- Local tick — decrement displayed timers between server pushes so the
	-- numbers actually move every second.
	local lastTick = os.clock()
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - lastTick < 1 then return end
		local dt = math.floor(now - lastTick)
		lastTick = now
		if state.outbreakSeconds > 0 then state.outbreakSeconds -= dt end
		if state.wheelSeconds > 0 then state.wheelSeconds -= dt end
		if state.dailySecondsLeft > 0 then state.dailySecondsLeft -= dt end
		refresh()
	end)

	refresh()
end

return NextEventUI
