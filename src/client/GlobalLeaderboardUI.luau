--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)

local GlobalLeaderboardUI = {}

local headerLabel: TextLabel
local cashCol: Frame
local mutCol: Frame
local stealCol: Frame

local function fill(col: Frame, title: string, entries: any, valueLabel: string)
	col:ClearAllChildren()
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 3)
	layout.Parent = col

	local hd = Instance.new("TextLabel")
	hd.Size = UDim2.new(1, 0, 0, 26)
	hd.BackgroundTransparency = 1
	hd.Font = Enum.Font.GothamBlack
	hd.TextScaled = true
	hd.TextColor3 = Color3.fromRGB(255, 215, 80)
	hd.Text = title
	hd.Parent = col

	for i, e in ipairs(entries) do
		local row = Instance.new("TextLabel")
		row.Size = UDim2.new(1, 0, 0, 18)
		row.BackgroundTransparency = 1
		row.Font = Enum.Font.Gotham
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = if i == 1 then Color3.fromRGB(255, 215, 80)
			elseif i == 2 then Color3.fromRGB(200, 200, 200)
			elseif i == 3 then Color3.fromRGB(200, 140, 80)
			else Color3.fromRGB(220, 220, 220)
		row.Text = `{i}. {e.name} — {Util.FormatShortNumber(e.value)} {valueLabel}`
		row.Parent = col
	end

	if #entries == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, 0, 0, 32)
		empty.BackgroundTransparency = 1
		empty.Font = Enum.Font.GothamItalic
		empty.TextScaled = true
		empty.TextColor3 = Color3.fromRGB(140, 140, 160)
		empty.Text = "No entries yet — be first!"
		empty.Parent = col
	end
end

function GlobalLeaderboardUI.Init(screen: ScreenGui, UIController)
	local frame = Instance.new("Frame")
	frame.Name = "GlobalLeaderboard"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(820, 460)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 100, 100); s.Thickness = 2; s.Parent = frame

	headerLabel = Instance.new("TextLabel")
	headerLabel.Position = UDim2.fromOffset(12, 8)
	headerLabel.Size = UDim2.new(1, -24, 0, 28)
	headerLabel.BackgroundTransparency = 1
	headerLabel.Font = Enum.Font.GothamBlack
	headerLabel.TextScaled = true
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left
	headerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	headerLabel.Text = "🌍 GLOBAL — weekly board (resets Sun 00:00 UTC)"
	headerLabel.Parent = frame

	local function mkCol(x: number): Frame
		local col = Instance.new("ScrollingFrame")
		col.Position = UDim2.new(x, 8, 0, 44)
		col.Size = UDim2.new(1/3, -16, 1, -56)
		col.BackgroundTransparency = 1
		col.BorderSizePixel = 0
		col.ScrollBarThickness = 4
		col.CanvasSize = UDim2.new(0, 0, 0, 0)
		col.AutomaticCanvasSize = Enum.AutomaticSize.Y
		col.Parent = frame
		return col
	end
	cashCol = mkCol(0)
	mutCol = mkCol(1/3)
	stealCol = mkCol(2/3)

	Remotes.Event(Remotes.Names.GlobalLeaderboardUpdate).OnClientEvent:Connect(function(payload)
		local hrs = math.floor(payload.nextResetIn / 3600)
		headerLabel.Text = `🌍 GLOBAL · Week {payload.weekId} · resets in {hrs}h`
		fill(cashCol, "💰 TOP CASH", payload.cash, "cash")
		fill(mutCol, "🧬 TOP MUTATIONS", payload.mutations, "mut")
		fill(stealCol, "🥷 TOP THIEVES", payload.steals, "steals")
	end)

	UIController.Register("Global", frame, "🌍 Global", Color3.fromRGB(255, 100, 100))
end

return GlobalLeaderboardUI
