--!strict
--[[
	PatchNotes — chronological release notes shown in-game. Add an entry
	whenever you bump Config.GAME_VERSION. Players whose lastSeenVersion
	doesn't match the latest get a glowing badge on the PatchNotes tab
	until they open it.
]]

export type PatchEntry = {
	version: string,
	date: string,
	title: string,
	highlights: { string },
}

local PatchNotes: { PatchEntry } = {
	{
		version = "0.1.0",
		date = "2026-05-25",
		title = "BRAINROT LAB — Opening Week",
		highlights = {
			"33 brainrots across Common → Outbreak rarity",
			"Live mutation system with 6 tiers + 9 mutation suffixes",
			"Steal + Infection PvP mechanics",
			"30-tier Battle Pass, daily quests, achievements",
			"Server-wide Outbreak (20 min) + Mega Boss (45 min) events",
			"Cross-server weekly leaderboards",
			"Trade system with cash add-ons",
			"Pet companions, collectible buffs",
			"Player levels + level reward chests",
			"Seasonal limited-time brainrots (rotates every 2 weeks)",
			"ES + PT localization",
		},
	},
}

local module = {}

function module.GetAll(): { PatchEntry }
	return PatchNotes
end

function module.Latest(): PatchEntry
	return PatchNotes[#PatchNotes]
end

return module
