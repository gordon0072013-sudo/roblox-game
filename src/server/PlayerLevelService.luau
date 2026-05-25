--!strict
--[[
	PlayerLevelService — persistent XP/level system separate from rebirth
	and battle pass. XP comes from every meaningful action; level rewards
	land in a chest the player claims from the Levels tab.

	Rationale: rebirth is a soft reset (the loop), battle pass is seasonal
	(14 days), but PlayerLevel is *permanent* progression. Players who hit
	level 100 stay engaged trying to hit 150. Long-tail retention curve
	that no other system in the game provides.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local PlayerLevelService = {}

local XP_PER_LEVEL = 1500
local XP_SOURCES: { [string]: number } = {
	capture = 25,
	mutation = 40,
	steal = 100,
	infect = 60,
	rebirth = 1000,
	boss_damage = 1,
	outbreak_capture = 200,
	trade = 50,
	pet_hatch = 75,
	achievement = 250,
}

local function ensure(data: any)
	data._level = data._level or { xp = 0, level = 1, claimed = {} }
end

local function pushUpdate(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	ensure(data)
	local lvl = data._level
	local xpInLevel = lvl.xp - (lvl.level - 1) * XP_PER_LEVEL
	Remotes.Event(Remotes.Names.LevelUpdate):FireClient(player, {
		level = lvl.level,
		xp = lvl.xp,
		xpInLevel = xpInLevel,
		xpPerLevel = XP_PER_LEVEL,
		claimed = lvl.claimed,
	})
end

function PlayerLevelService.AwardXp(player: Player, source: string, amount: number?)
	local data = DataService.Get(player)
	if not data then return end
	ensure(data)
	local xp = amount or XP_SOURCES[source] or 0
	if xp <= 0 then return end
	data._level.xp += xp
	-- level ups
	local newLevel = math.floor(data._level.xp / XP_PER_LEVEL) + 1
	if newLevel > data._level.level then
		data._level.level = newLevel
		Remotes.Event(Remotes.Names.Notify):FireClient(player, {
			kind = "rebirth",
			text = `⭐ LEVEL UP — now level ${newLevel}! Claim reward in Levels tab.`,
		})
	end
	pushUpdate(player)
end

function PlayerLevelService.ClaimLevelReward(player: Player, level: number)
	local data = DataService.Get(player)
	if not data then return end
	ensure(data)
	if level > data._level.level then return end
	if data._level.claimed[tostring(level)] then return end
	data._level.claimed[tostring(level)] = true
	local cash = level * 500
	EconomyService.AwardCash(player, cash, `level ${level} reward`)
	pushUpdate(player)
end

function PlayerLevelService.OnPlayerAdded(player: Player)
	task.delay(2, pushUpdate, player)
end

function PlayerLevelService.Init() end

return PlayerLevelService
