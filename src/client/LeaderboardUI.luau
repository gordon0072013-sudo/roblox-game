--!strict
--[[
	LeaderboardUI — three columns: top cash, top mutations, top thieves.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)

local LeaderboardUI = {}

local cashCol: Frame
local mutCol: Frame
local thiefCol: Frame

local function fill(col: Frame, title: string, entries: { any }, valueKey: string, formatter: ((number) -> string)?)
	col:ClearAllChildren()
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = col

	local hd = Instance.new("TextLabel")
	hd.Size = UDim2.new(1, 0, 0, 28)
	hd.BackgroundTransparency = 1
	hd.Font = Enum.Font.GothamBlack
	hd.TextScaled = true
	hd.TextColor3 = Color3.fromRGB(255, 215, 80)
	hd.Text = title
	hd.Parent = col

	for i, e in ipairs(entries) do
		local row = Instance.new("TextLabel")
		row.Size = UDim2.new(1, 0, 0, 22)
		row.BackgroundTransparency = 1
		row.Font = Enum.Font.Gotham
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = if i == 1 then Color3.fromRGB(255,215,80)
			elseif i == 2 then Color3.fromRGB(200,200,200)
			elseif i == 3 then Color3.fromRGB(200,140,80)
			else Color3.fromRGB(220,220,220)
		local v = (e :: any)[valueKey] or 0
		local vs = if formatter then formatter(v) else Util.FormatShortNumber(v)
		row.Text = `${i}. ${e.name} — ${vs}`
		row.Parent = col
	end
end

function LeaderboardUI.Init(screen: ScreenGui, UIController)
	local frame = Instance.new("Frame")
	frame.Name = "Leaderboard"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(720, 380)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 100, 200); s.Thickness = 2; s.Parent = frame

	local function mkCol(x: number): Frame
		local col = Instance.new("Frame")
		col.Position = UDim2.new(x, 8, 0, 8)
		col.Size = UDim2.new(1/3, -16, 1, -16)
		col.BackgroundTransparency = 1
		col.Parent = frame
		return col
	end
	cashCol = mkCol(0)
	mutCol = mkCol(1/3)
	thiefCol = mkCol(2/3)

	Remotes.Event(Remotes.Names.LeaderboardUpdate).OnClientEvent:Connect(function(payload)
		fill(cashCol, "💰 TOP CASH", payload.cash, "cash")
		fill(mutCol, "🧬 TOP MUTATIONS", payload.mutations, "mutations", function(n) return tostring(n) end)
		fill(thiefCol, "🥷 TOP THIEVES", payload.thieves, "steals", function(n) return tostring(n) end)
	end)

	UIController.Register("Leaderboard", frame, "🏆 Top", Color3.fromRGB(255, 100, 200))
end

return LeaderboardUI
