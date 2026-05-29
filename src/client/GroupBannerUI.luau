--!strict
--[[
	GroupBannerUI — small top-right banner that prompts the player to join
	the Roblox group for a permanent +25% cash boost. Hides itself once the
	player is detected as a group member.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local GroupBannerUI = {}

local localPlayer = Players.LocalPlayer
local frame: Frame
local statusLabel: TextLabel

local function refresh()
	if Config.GROUP_ID <= 0 then
		frame.Visible = false
		return
	end
	local ok, inGroup = pcall(function() return localPlayer:IsInGroup(Config.GROUP_ID) end)
	if ok and inGroup then
		statusLabel.Text = `✅ Group member · +{math.floor((Config.GROUP_REWARD_MULT - 1)*100)}% cash`
		statusLabel.TextColor3 = Color3.fromRGB(120, 220, 120)
	else
		local pct = math.floor((Config.GROUP_REWARD_MULT - 1) * 100)
		statusLabel.Text = `Join the group for +{pct}% cash`
		statusLabel.TextColor3 = Color3.fromRGB(255, 215, 80)
	end
end

function GroupBannerUI.Init(screen: ScreenGui)
	frame = Instance.new("Frame")
	frame.Name = "GroupBanner"
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.Position = UDim2.new(1, -16, 0, 16)
	frame.Size = UDim2.fromOffset(360, 64)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 215, 80); s.Thickness = 2; s.Parent = frame

	statusLabel = Instance.new("TextLabel")
	statusLabel.Position = UDim2.fromOffset(10, 6)
	statusLabel.Size = UDim2.new(1, -20, 0, 22)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.TextScaled = true
	statusLabel.TextColor3 = Color3.fromRGB(255, 215, 80)
	statusLabel.Text = ""
	statusLabel.Parent = frame

	local btn = Instance.new("TextButton")
	btn.Position = UDim2.fromOffset(10, 30)
	btn.Size = UDim2.new(1, -20, 0, 28)
	btn.Font = Enum.Font.GothamBlack
	btn.TextScaled = true
	btn.BackgroundColor3 = Color3.fromRGB(255, 80, 200)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.BorderSizePixel = 0
	btn.Text = "VIEW GROUP & RECHECK"
	btn.Parent = frame
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = btn
	btn.MouseButton1Click:Connect(function()
		if Config.GROUP_ID > 0 then
			-- Opens the in-experience group page if available; otherwise just notifies.
			local SocialService = game:GetService("SocialService")
			pcall(function() SocialService:PromptGameInvite(localPlayer) end)
		end
		Remotes.Event(Remotes.Names.RequestRecheckGroup):FireServer()
		task.wait(1.2)
		refresh()
	end)

	task.delay(2, refresh)
	-- re-poll occasionally so banner updates if they join via the website
	task.spawn(function()
		while true do
			task.wait(15)
			refresh()
		end
	end)
end

return GroupBannerUI
