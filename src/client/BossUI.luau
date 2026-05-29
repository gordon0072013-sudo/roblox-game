--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)

local BossUI = {}

function BossUI.Init(screen: ScreenGui)
	local frame = Instance.new("Frame")
	frame.Name = "BossBanner"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0, 76)
	frame.Size = UDim2.fromOffset(440, 44)
	frame.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 60, 60); s.Thickness = 2; s.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 80, 80)
	label.Parent = frame
	local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8); pad.Parent = label

	Remotes.Event(Remotes.Names.BossUpdate).OnClientEvent:Connect(function(payload)
		if payload.active then
			frame.Visible = true
			local pct = math.floor((payload.hp / math.max(1, payload.maxHp)) * 100)
			label.Text = `🔥 MEGA BOSS · {pct}% HP · {Util.SecondsToClock(payload.secondsLeft)} · {payload.contributors} fighters`
		else
			if payload.secondsToStart and payload.secondsToStart < 600 then
				frame.Visible = true
				label.Text = `Next Mega Boss in {Util.SecondsToClock(payload.secondsToStart)}`
				label.TextColor3 = Color3.fromRGB(255, 160, 80)
			else
				frame.Visible = false
			end
		end
	end)
end

return BossUI
