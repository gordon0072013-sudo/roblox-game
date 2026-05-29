--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local PatchNotes = require(Shared.PatchNotes)
local Config = require(Shared.Config)

local PatchNotesUI = {}

local SEEN_KEY = "BrainrotLab.SeenVersion"

function PatchNotesUI.Init(screen: ScreenGui, UIController)
	local frame = Instance.new("Frame")
	frame.Name = "PatchNotes"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(560, 480)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(200, 200, 255); s.Thickness = 2; s.Parent = frame

	local hd = Instance.new("TextLabel")
	hd.Position = UDim2.fromOffset(12, 8)
	hd.Size = UDim2.new(1, -24, 0, 30)
	hd.BackgroundTransparency = 1
	hd.Font = Enum.Font.GothamBlack
	hd.TextScaled = true
	hd.TextColor3 = Color3.fromRGB(200, 200, 255)
	hd.TextXAlignment = Enum.TextXAlignment.Left
	hd.Text = `📝 What's New · v{Config.GAME_VERSION}`
	hd.Parent = frame

	local scroll = Instance.new("ScrollingFrame")
	scroll.Position = UDim2.fromOffset(12, 48)
	scroll.Size = UDim2.new(1, -24, 1, -60)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = frame
	local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 12); layout.Parent = scroll

	for i = #PatchNotes.GetAll(), 1, -1 do
		local entry = PatchNotes.GetAll()[i]
		local block = Instance.new("Frame")
		block.Size = UDim2.new(1, -10, 0, 0)
		block.AutomaticSize = Enum.AutomaticSize.Y
		block.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
		block.BorderSizePixel = 0
		block.Parent = scroll
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = block
		local bp = Instance.new("UIPadding"); bp.PaddingTop = UDim.new(0, 8); bp.PaddingBottom = UDim.new(0, 8); bp.PaddingLeft = UDim.new(0, 10); bp.PaddingRight = UDim.new(0, 10); bp.Parent = block
		local bl = Instance.new("UIListLayout"); bl.Padding = UDim.new(0, 4); bl.Parent = block

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, 0, 0, 24)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBlack
		title.TextColor3 = Color3.fromRGB(255, 215, 80)
		title.TextScaled = true
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Text = `v{entry.version} · {entry.date} — {entry.title}`
		title.Parent = block

		for _, line in ipairs(entry.highlights) do
			local l = Instance.new("TextLabel")
			l.Size = UDim2.new(1, 0, 0, 20)
			l.BackgroundTransparency = 1
			l.Font = Enum.Font.Gotham
			l.TextColor3 = Color3.fromRGB(220, 220, 230)
			l.TextScaled = true
			l.TextXAlignment = Enum.TextXAlignment.Left
			l.Text = "• " .. line
			l.Parent = block
		end
	end

	UIController.Register("PatchNotes", frame, "📝 News", Color3.fromRGB(200, 200, 255))

	-- New-update glow: if local player hasn't seen the current version, flash
	local lp = Players.LocalPlayer
	if lp:GetAttribute(SEEN_KEY) ~= Config.GAME_VERSION then
		task.spawn(function()
			while lp:GetAttribute(SEEN_KEY) ~= Config.GAME_VERSION do
				s.Color = Color3.fromRGB(255, 215, 80)
				task.wait(0.4)
				s.Color = Color3.fromRGB(200, 200, 255)
				task.wait(0.4)
			end
		end)
		-- Mark seen when they open it (visible toggle)
		frame:GetPropertyChangedSignal("Visible"):Connect(function()
			if frame.Visible then
				lp:SetAttribute(SEEN_KEY, Config.GAME_VERSION)
			end
		end)
	end
end

return PatchNotesUI
