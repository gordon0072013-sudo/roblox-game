--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local CinematicUI = {}

function CinematicUI.Init(screen: ScreenGui)
	Remotes.Event(Remotes.Names.Cinematic).OnClientEvent:Connect(function(cine)
		if not cine or not cine.title then return end

		local color = if cine.color then Color3.fromRGB(cine.color[1], cine.color[2], cine.color[3])
			else Color3.fromRGB(255, 215, 80)
		local duration = cine.durationSeconds or 3

		-- Full-screen vignette + centerpiece title.
		local overlay = Instance.new("Frame")
		overlay.Name = "Cinematic"
		overlay.Size = UDim2.fromScale(1, 1)
		overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		overlay.BackgroundTransparency = 1
		overlay.BorderSizePixel = 0
		overlay.ZIndex = 50
		overlay.Parent = screen

		local title = Instance.new("TextLabel")
		title.AnchorPoint = Vector2.new(0.5, 0.5)
		title.Position = UDim2.fromScale(0.5, 0.45)
		title.Size = UDim2.fromOffset(900, 120)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBlack
		title.TextScaled = true
		title.TextColor3 = color
		title.TextStrokeTransparency = 0
		title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		title.Text = cine.title
		title.TextTransparency = 1
		title.ZIndex = 51
		title.Parent = overlay

		local subtitle = Instance.new("TextLabel")
		subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
		subtitle.Position = UDim2.fromScale(0.5, 0.58)
		subtitle.Size = UDim2.fromOffset(700, 48)
		subtitle.BackgroundTransparency = 1
		subtitle.Font = Enum.Font.GothamBold
		subtitle.TextScaled = true
		subtitle.TextColor3 = Color3.fromRGB(240, 240, 250)
		subtitle.TextStrokeTransparency = 0.2
		subtitle.Text = cine.subtitle or ""
		subtitle.TextTransparency = 1
		subtitle.ZIndex = 51
		subtitle.Parent = overlay

		-- Fade in
		TweenService:Create(overlay, TweenInfo.new(0.25), { BackgroundTransparency = 0.55 }):Play()
		TweenService:Create(title,   TweenInfo.new(0.35), { TextTransparency = 0 }):Play()
		TweenService:Create(subtitle,TweenInfo.new(0.45), { TextTransparency = 0 }):Play()

		task.delay(duration, function()
			local fade = TweenService:Create(overlay, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
			TweenService:Create(title,    TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			TweenService:Create(subtitle, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			fade:Play()
			fade.Completed:Wait()
			overlay:Destroy()
		end)
	end)
end

return CinematicUI
