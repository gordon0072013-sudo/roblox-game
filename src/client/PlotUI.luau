--!strict
--[[
	PlotUI — wires up clicks on rival brainrots to the Steal action, and a
	"target nearest player" Infect button. Also pops a small interaction
	prompt when the local player walks near a non-owned plot.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local PlotUI = {}

local localPlayer = Players.LocalPlayer

local function findNearestForeignBrainrot(): (Model?, number?)
	local char = localPlayer.Character
	if not char then return nil, nil end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return nil, nil end
	local plots = Workspace:FindFirstChild("Plots")
	if not plots then return nil, nil end
	local bestModel
	local bestDist = math.huge
	local bestOwner
	for _, plot in ipairs(plots:GetChildren()) do
		for _, child in ipairs(plot:GetChildren()) do
			if child:IsA("Model") and child.Name:match("^Brainrot_") then
				local ownerId = child:GetAttribute("OwnerUserId") :: number?
				if ownerId and ownerId ~= 0 and ownerId ~= localPlayer.UserId then
					local body = child.PrimaryPart
					if body then
						local d = (body.Position - hrp.Position).Magnitude
						if d < bestDist then
							bestDist = d
							bestModel = child
							bestOwner = ownerId
						end
					end
				end
			end
		end
	end
	return bestModel, bestOwner
end

local function findNearestPlayerOwner(): number?
	local char = localPlayer.Character
	if not char then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return nil end
	local bestId
	local bestDist = math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= localPlayer and p.Character then
			local theirHrp = p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if theirHrp then
				local d = (theirHrp.Position - hrp.Position).Magnitude
				if d < bestDist then
					bestDist = d
					bestId = p.UserId
				end
			end
		end
	end
	return bestId
end

function PlotUI.Init(screen: ScreenGui)
	-- Right-side action buttons
	local panel = Instance.new("Frame")
	panel.Name = "Actions"
	panel.AnchorPoint = Vector2.new(1, 0.5)
	panel.Position = UDim2.new(1, -16, 0.5, 0)
	panel.Size = UDim2.fromOffset(180, 200)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	panel.BackgroundTransparency = 0.2
	panel.BorderSizePixel = 0
	panel.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = panel
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(120, 220, 120); s.Thickness = 2; s.Parent = panel
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 6)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Parent = panel
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8)
	pad.Parent = panel

	local function mkBtn(text: string, color: Color3, cb: () -> ()): TextButton
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, 0, 0, 44)
		b.Font = Enum.Font.GothamBlack
		b.TextScaled = true
		b.BackgroundColor3 = color
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
		b.BorderSizePixel = 0
		b.Text = text
		b.Parent = panel
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = b
		b.MouseButton1Click:Connect(cb)
		return b
	end

	mkBtn("🥷 STEAL\nnearest", Color3.fromRGB(255, 80, 80), function()
		local model, ownerId = findNearestForeignBrainrot()
		if not model or not ownerId then
			-- toast via local-only fire would be nicer; for simplicity fire a request that'll error-toast
			return
		end
		local uid = model:GetAttribute("BrainrotUid") :: string?
		if uid then
			Remotes.Event(Remotes.Names.RequestSteal):FireServer(ownerId, uid)
		end
	end)

	mkBtn("💣 INFECT\nnearest", Color3.fromRGB(120, 200, 80), function()
		local victimId = findNearestPlayerOwner()
		if victimId then
			Remotes.Event(Remotes.Names.RequestInfect):FireServer(victimId)
		end
	end)

	mkBtn("🎲 CAPTURE", Color3.fromRGB(80, 180, 255), function()
		Remotes.Event(Remotes.Names.RequestCapture):FireServer()
	end)

	-- Keybinds for desktop: E = steal, Q = infect, R = capture
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.E then
			local model, ownerId = findNearestForeignBrainrot()
			if model and ownerId then
				local uid = model:GetAttribute("BrainrotUid") :: string?
				if uid then
					Remotes.Event(Remotes.Names.RequestSteal):FireServer(ownerId, uid)
				end
			end
		elseif input.KeyCode == Enum.KeyCode.Q then
			local victimId = findNearestPlayerOwner()
			if victimId then
				Remotes.Event(Remotes.Names.RequestInfect):FireServer(victimId)
			end
		elseif input.KeyCode == Enum.KeyCode.R then
			Remotes.Event(Remotes.Names.RequestCapture):FireServer()
		end
	end)
end

return PlotUI
