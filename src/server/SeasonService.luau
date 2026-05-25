--!strict
--[[
	SeasonService — manages a 2-week seasonal brainrot rotation. Each
	"season" gates one limited brainrot variant that's only obtainable
	during that window. After the season ends, the brainrot is no longer
	dropable (existing copies remain) — which gives them trade value and
	creates a strong FOMO pull for the next season.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local SeasonService = {}

type Season = {
	id: string,
	name: string,
	limitedBrainrotId: string,
	startTs: number,
	endTs: number,
}

local SEASON_DURATION = 14 * 24 * 3600

-- Hardcoded seasons table — add more as you ship new content.
-- Existing seasons in the past are kept for the patch-notes ribbon.
local SEASONS: { Season } = {
	{ id="s1_outbreak", name="Outbreak Season", limitedBrainrotId="patriarch",
	  startTs = 0, endTs = 0 }, -- filled in dynamically on Init below
}

local activeSeason: Season? = nil

local function broadcast()
	for _, p in ipairs(Players:GetPlayers()) do
		Remotes.Event(Remotes.Names.SeasonUpdate):FireClient(p, {
			active = activeSeason ~= nil,
			id = activeSeason and activeSeason.id,
			name = activeSeason and activeSeason.name,
			endTs = activeSeason and activeSeason.endTs,
			limitedBrainrotId = activeSeason and activeSeason.limitedBrainrotId,
			secondsLeft = activeSeason and math.max(0, activeSeason.endTs - os.time()) or 0,
		})
	end
end

function SeasonService.GetActiveSeason(): Season?
	return activeSeason
end

function SeasonService.IsSeasonalBrainrotAvailable(brainrotId: string): boolean
	if not activeSeason then return false end
	return activeSeason.limitedBrainrotId == brainrotId
end

function SeasonService.OnPlayerAdded(player: Player)
	task.delay(2, broadcast)
end

function SeasonService.Init()
	-- Pin season 1 to "now" so it just works in fresh installs. In live
	-- ops, replace these with real timestamps so seasons stay aligned
	-- across servers.
	SEASONS[1].startTs = os.time()
	SEASONS[1].endTs = os.time() + SEASON_DURATION

	-- pick active season
	local now = os.time()
	for _, s in ipairs(SEASONS) do
		if now >= s.startTs and now < s.endTs then
			activeSeason = s
			break
		end
	end

	-- season tick (every minute)
	task.spawn(function()
		while true do
			task.wait(60)
			local cur = os.time()
			local prev = activeSeason
			activeSeason = nil
			for _, s in ipairs(SEASONS) do
				if cur >= s.startTs and cur < s.endTs then
					activeSeason = s; break
				end
			end
			if prev ~= activeSeason then
				broadcast()
			end
		end
	end)
end

return SeasonService
