--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local CinematicService = {}

-- Fires a "cinematic" event to a player. Client side renders a brief
-- full-screen overlay tuned per kind. Used for moments worth pausing for:
-- big mutations, rebirths, full-combo equivalents.
type Cinematic = {
	kind: string,                 -- "rebirth" | "apex_mutation" | "mythic_drop"
	title: string,
	subtitle: string?,
	color: { number }?,            -- {r,g,b}
	durationSeconds: number?,
}

function CinematicService.Play(player: Player, cine: Cinematic)
	Remotes.Event(Remotes.Names.Cinematic):FireClient(player, cine)
end

function CinematicService.OnPlayerAdded(_: Player) end

function CinematicService.Init()
	Remotes.Event(Remotes.Names.Cinematic)
end

return CinematicService
