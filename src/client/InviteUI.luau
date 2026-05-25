--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local InviteUI = {}

local codeLabel: TextLabel
local statusLabel: TextLabel
local input: TextBox
local redeemBtn: TextButton

function InviteUI.Init(screen: ScreenGui, UIController)
	local frame = Instance.new("Frame")
	frame.Name = "Invite"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(460, 300)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 100, 200); s.Thickness = 2; s.Parent = frame

	local hd = Instance.new("TextLabel")
	hd.Position = UDim2.fromOffset(12, 8)
	hd.Size = UDim2.new(1, -24, 0, 30)
	hd.BackgroundTransparency = 1
	hd.Font = Enum.Font.GothamBlack
	hd.TextScaled = true
	hd.TextColor3 = Color3.fromRGB(255, 100, 200)
	hd.TextXAlignment = Enum.TextXAlignment.Left
	hd.Text = "👥 Invite Friends"
	hd.Parent = frame

	local subtext = Instance.new("TextLabel")
	subtext.Position = UDim2.fromOffset(12, 42)
	subtext.Size = UDim2.new(1, -24, 0, 26)
	subtext.BackgroundTransparency = 1
	subtext.Font = Enum.Font.Gotham
	subtext.TextScaled = true
	subtext.TextWrapped = true
	subtext.TextXAlignment = Enum.TextXAlignment.Left
	subtext.TextColor3 = Color3.fromRGB(220, 220, 230)
	subtext.Text = "Share your code. Friend redeems → both get rewards."
	subtext.Parent = frame

	codeLabel = Instance.new("TextLabel")
	codeLabel.Position = UDim2.fromOffset(12, 76)
	codeLabel.Size = UDim2.new(1, -24, 0, 56)
	codeLabel.BackgroundColor3 = Color3.fromRGB(40, 30, 50)
	codeLabel.BorderSizePixel = 0
	codeLabel.Font = Enum.Font.RobotoMono
	codeLabel.TextScaled = true
	codeLabel.TextColor3 = Color3.fromRGB(255, 215, 80)
	codeLabel.Text = "REF-…"
	codeLabel.Parent = frame
	local clc = Instance.new("UICorner"); clc.CornerRadius = UDim.new(0, 8); clc.Parent = codeLabel

	statusLabel = Instance.new("TextLabel")
	statusLabel.Position = UDim2.fromOffset(12, 138)
	statusLabel.Size = UDim2.new(1, -24, 0, 22)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextScaled = true
	statusLabel.TextColor3 = Color3.fromRGB(180, 220, 180)
	statusLabel.Text = ""
	statusLabel.Parent = frame

	input = Instance.new("TextBox")
	input.Position = UDim2.fromOffset(12, 174)
	input.Size = UDim2.fromOffset(280, 48)
	input.Font = Enum.Font.RobotoMono
	input.TextScaled = true
	input.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	input.TextColor3 = Color3.fromRGB(255, 255, 255)
	input.PlaceholderText = "Enter a friend's code…"
	input.ClearTextOnFocus = false
	input.Text = ""
	input.Parent = frame
	local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(0, 6); ic.Parent = input

	redeemBtn = Instance.new("TextButton")
	redeemBtn.Position = UDim2.fromOffset(300, 174)
	redeemBtn.Size = UDim2.fromOffset(148, 48)
	redeemBtn.Font = Enum.Font.GothamBlack
	redeemBtn.TextScaled = true
	redeemBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
	redeemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	redeemBtn.BorderSizePixel = 0
	redeemBtn.Text = "REDEEM"
	redeemBtn.Parent = frame
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = redeemBtn

	local function fire()
		local code = input.Text
		if code and #code > 0 then
			Remotes.Event(Remotes.Names.RequestRedeemInvite):FireServer(code)
			input.Text = ""
		end
	end
	redeemBtn.MouseButton1Click:Connect(fire)
	input.FocusLost:Connect(function(enter) if enter then fire() end end)

	Remotes.Event(Remotes.Names.InviteUpdate).OnClientEvent:Connect(function(payload)
		codeLabel.Text = payload.code or "REF-…"
		statusLabel.Text = `Recruited ${payload.recruitsCount or 0} friends` .. (payload.redeemed and " · You redeemed a code already" or "")
	end)

	UIController.Register("Invite", frame, "👥 Invite", Color3.fromRGB(255, 100, 200))
end

return InviteUI
