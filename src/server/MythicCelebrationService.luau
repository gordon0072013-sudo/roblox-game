--!strict

local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes      = require(Shared.Remotes)
local BrainrotData = require(Shared.BrainrotData)
local Log          = require(Shared.Log)

local LabService -- forward
local AnnouncementService -- forward
local CinematicService -- forward

local MythicCelebrationService = {}

-- When any player captures a Mythic or Outbreak brainrot, we shoot
-- visible fireworks from their plot, fire a server-wide announcement,
-- and play a cinematic for the achiever. The fireworks are a
-- screenshot/clip moment for them and a 'wow that could be me' moment
-- for everyone else — designed to surface as TikTok clips.

local function shootFireworks(player: Player)
	if not LabService then return end
	local plotId = LabService.GetPlotIdForPlayer(player)
	if not plotId then return end
	local plot = LabService.GetPlot(plotId)
	if not plot then return end
	local origin = plot.center + Vector3.new(0, 6, 0)

	for i = 1, 12 do
		task.delay(i * 0.15, function()
			local part = Instance.new("Part")
			part.Anchored = false
			part.CanCollide = false
			part.Size = Vector3.new(0.6, 0.6, 0.6)
			part.Material = Enum.Material.Neon
			part.Color = Color3.fromHSV(math.random(), 0.8, 1)
			part.Position = origin + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
			part.AssemblyLinearVelocity = Vector3.new(
				math.random(-15, 15),
				60 + math.random(0, 30),
				math.random(-15, 15))
			part.Parent = Workspace
			local fire = Instance.new("Fire")
			fire.Color = part.Color
			fire.Size = 4
			fire.Parent = part
			task.delay(2.0, function() part:Destroy() end)
		end)
	end
end

function MythicCelebrationService.OnCapture(player: Player, speciesId: string)
	local def = BrainrotData.Get(speciesId)
	if not def then return end
	if def.rarity ~= "Mythic" and def.rarity ~= "Outbreak" then return end

	shootFireworks(player)

	local color = if def.rarity == "Outbreak" then { 255, 80, 60 } else { 255, 100, 220 }

	if AnnouncementService then
		AnnouncementService.Push(
			string.format("✨ %s captured a %s — %s!",
				player.DisplayName, def.rarity, def.displayName),
			color, 18)
	end

	if CinematicService then
		CinematicService.Play(player, {
			kind = "mythic_drop",
			title = `${string.upper(def.rarity)} DROP`,
			subtitle = def.displayName,
			color = color,
			durationSeconds = 4,
		})
	end

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			Remotes.Event(Remotes.Names.Notify):FireClient(p, {
				kind = "info",
				text = string.format("✨ %s captured %s [%s]!",
					player.DisplayName, def.displayName, def.rarity),
			})
		end
	end

	Log.Info("MythicCelebration", "%s captured %s (%s)", player.Name, speciesId, def.rarity)
end

function MythicCelebrationService.Init()
	LabService = require(script.Parent.LabService)
	AnnouncementService = require(script.Parent.AnnouncementService)
	CinematicService = require(script.Parent.CinematicService)
end

return MythicCelebrationService
