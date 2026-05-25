--!strict
--[[
	HUD — top-left cash + rebirth panel. Driven by HudUpdate remote.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)

local HUD = {}

local cashLabel: TextLabel
local rebirthLabel: TextLabel
local multLabel: TextLabel
local statusLabel: TextLabel
local rebirthBtn: TextButton

function HUD.Init(screen: ScreenGui)
	local frame = Instance.new("Frame")
	frame.Name = "HUD"
	frame.Position = UDim2.fromOffset(16, 16)
	frame.Size = UDim2.fromOffset(280, 150)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 80)
	stroke.Thickness = 2
	stroke.Parent = frame
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = frame

	local function mkLabel(name: string, y: number, color: Color3, font: Enum.Font): TextLabel
		local l = Instance.new("TextLabel")
		l.Name = name
		l.BackgroundTransparency = 1
		l.Position = UDim2.new(0, 0, 0, y)
		l.Size = UDim2.new(1, 0, 0, 26)
		l.Font = font
		l.TextColor3 = color
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextScaled = true
		l.Parent = frame
		return l
	end

	cashLabel = mkLabel("Cash", 0, Color3.fromRGB(255, 215, 80), Enum.Font.GothamBlack)
	cashLabel.Text = "0 cash"
	rebirthLabel = mkLabel("Rebirth", 30, Color3.fromRGB(180, 220, 255), Enum.Font.GothamBold)
	rebirthLabel.Text = "Rebirth 0"
	multLabel = mkLabel("Mult", 56, Color3.fromRGB(180, 255, 180), Enum.Font.Gotham)
	multLabel.Text = ""
	statusLabel = mkLabel("Status", 82, Color3.fromRGB(255, 120, 120), Enum.Font.GothamBold)
	statusLabel.Text = ""

	rebirthBtn = Instance.new("TextButton")
	rebirthBtn.Size = UDim2.new(1, 0, 0, 30)
	rebirthBtn.Position = UDim2.new(0, 0, 1, -30)
	rebirthBtn.Text = "REBIRTH"
	rebirthBtn.Font = Enum.Font.GothamBlack
	rebirthBtn.TextScaled = true
	rebirthBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 200)
	rebirthBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	rebirthBtn.BorderSizePixel = 0
	rebirthBtn.Parent = frame
	local rbc = Instance.new("UICorner"); rbc.CornerRadius = UDim.new(0, 8); rbc.Parent = rebirthBtn
	local confirming = false
	local confirmExpiresAt = 0
	local function originalText() return "REBIRTH" end
	rebirthBtn.MouseButton1Click:Connect(function()
		if confirming and os.clock() < confirmExpiresAt then
			confirming = false
			rebirthBtn.Text = originalText()
			rebirthBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 200)
			Remotes.Event(Remotes.Names.RequestRebirth):FireServer()
			return
		end
		-- First click: arm the confirmation. Auto-revert after 4s.
		confirming = true
		confirmExpiresAt = os.clock() + 4
		rebirthBtn.Text = "TAP AGAIN TO CONFIRM"
		rebirthBtn.BackgroundColor3 = Color3.fromRGB(255, 160, 80)
		task.delay(4, function()
			if confirming and os.clock() >= confirmExpiresAt then
				confirming = false
				rebirthBtn.Text = originalText()
				rebirthBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 200)
			end
		end)
	end)

	Remotes.Event(Remotes.Names.HudUpdate).OnClientEvent:Connect(function(payload)
		cashLabel.Text = `${Util.FormatShortNumber(payload.cash)} cash`
		rebirthLabel.Text = `Rebirth ${payload.rebirths}  (need ${Util.FormatShortNumber(payload.nextRebirthCost)})`
		local parts = {}
		if payload.cashMult and payload.cashMult > 1 then table.insert(parts, `${payload.cashMult}x cash`) end
		if payload.rebirthMult and payload.rebirthMult > 1 then table.insert(parts, string.format("%.2fx rebirth", payload.rebirthMult)) end
		multLabel.Text = table.concat(parts, "  ·  ")
		if payload.infected then
			statusLabel.Text = `INFECTED · ${math.ceil(payload.infectedSecondsLeft)}s · 🦠`
			statusLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
		else
			statusLabel.Text = `💣 ${payload.infectionBombs or 0} bombs`
			statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
		end
	end)
end

return HUD
