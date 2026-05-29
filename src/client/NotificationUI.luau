--!strict
--[[
	NotificationUI — bottom-right toast queue. Drives re-engagement when
	stolen from / infected (FOMO + revenge mechanic).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local NotificationUI = {}

local container: Frame

local KIND_COLOR: { [string]: Color3 } = {
	cash = Color3.fromRGB(255, 215, 80),
	capture = Color3.fromRGB(120, 220, 120),
	mutation = Color3.fromRGB(255, 100, 220),
	error = Color3.fromRGB(255, 100, 100),
	info = Color3.fromRGB(120, 200, 255),
	rebirth = Color3.fromRGB(255, 160, 80),
}

local function toast(payload: any)
	local color = KIND_COLOR[payload.kind] or Color3.fromRGB(255, 255, 255)
	local row = Instance.new("Frame")
	row.Size = UDim2.fromOffset(360, 48)
	row.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	row.BackgroundTransparency = 0.1
	row.BorderSizePixel = 0
	row.Parent = container
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = row
	local s = Instance.new("UIStroke"); s.Color = color; s.Thickness = 2; s.Parent = row

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextScaled = true
	lbl.TextColor3 = color
	lbl.Text = tostring(payload.text)
	lbl.Parent = row
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, 8); p.PaddingRight = UDim.new(0, 8)
	p.Parent = lbl

	task.delay(4, function()
		local tw = TweenService:Create(row, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
		tw:Play()
		tw.Completed:Wait()
		row:Destroy()
	end)
end

function NotificationUI.Init(screen: ScreenGui)
	container = Instance.new("Frame")
	container.Name = "Toasts"
	container.AnchorPoint = Vector2.new(1, 1)
	container.Position = UDim2.new(1, -16, 1, -100)
	container.Size = UDim2.fromOffset(380, 320)
	container.BackgroundTransparency = 1
	container.Parent = screen
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 6)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.HorizontalAlignment = Enum.HorizontalAlignment.Right
	list.Parent = container

	-- Rate-limit identical toasts: if the same text fires within 750ms of
	-- the previous identical toast, suppress it. Prevents toast spam from
	-- burst events (rapid mutations, capture loops).
	local lastByText: { [string]: number } = {}
	Remotes.Event(Remotes.Names.Notify).OnClientEvent:Connect(function(payload)
		if not payload or typeof(payload) ~= "table" then return end
		local key = tostring(payload.text or "")
		local now = os.clock()
		if lastByText[key] and now - lastByText[key] < 0.75 then return end
		lastByText[key] = now
		toast(payload)
	end)
end

return NotificationUI
