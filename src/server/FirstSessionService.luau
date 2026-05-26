--!strict

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes      = require(Shared.Remotes)
local BrainrotData = require(Shared.BrainrotData)
local Util         = require(Shared.Util)
local Log          = require(Shared.Log)

local DataService    = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local FirstSessionService = {}

-- Brand-new players get a 5-minute "First Session" window where:
--   * Cash income is boosted 3x (gives them tangible early progress)
--   * A free Epic brainrot drops at 60s (the "wow moment" that hooks them)
--   * A SocialService invite nudge appears at 3 min (peak engagement)
-- Drives the single biggest D1 conversion lever: the player has to feel
-- the dopamine of a juicy reward inside the first 90 seconds or they bounce.

local FIRST_SESSION_DURATION = 300  -- 5 minutes
local EPIC_GIFT_DELAY        = 60
local INVITE_PROMPT_DELAY    = 180
local INCOME_BOOST           = 3.0

local activeFirstSession: { [number]: number } = {} -- userId -> expiresAt

function FirstSessionService.GetCashMult(player: Player): number
	local expires = activeFirstSession[player.UserId]
	if expires and os.time() < expires then return INCOME_BOOST end
	return 1
end

function FirstSessionService.IsActive(player: Player): boolean
	local expires = activeFirstSession[player.UserId]
	return expires ~= nil and os.time() < expires
end

local function isBrandNew(data: any): boolean
	-- A "brand-new" player is one whose profile was created within the
	-- last 60 seconds AND has zero stats activity.
	if not data.createdAt or data.createdAt == 0 then return false end
	if (os.time() - data.createdAt) > 60 then return false end
	if (data.stats and data.stats.totalCashEarned > 100) then return false end
	return true
end

local function giveEpicGift(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	-- Pick a random Epic species
	local epics: { string } = {}
	for _, def in ipairs(BrainrotData.GetAll()) do
		if def.rarity == "Epic" then table.insert(epics, def.id) end
	end
	if #epics == 0 then return end
	local pick = epics[math.random(1, #epics)]
	local def = BrainrotData.Get(pick)
	if not def then return end

	local CaptureService = require(script.Parent.CaptureService)
	CaptureService.GiveOutbreakBrainrot(player, pick)
	Remotes.Event(Remotes.Names.Notify):FireClient(player, {
		kind = "capture",
		text = string.format("✨ FIRST-TIME GIFT: %s (%s) for free!", def.displayName, def.rarity),
	})
	Log.Info("FirstSession", "gave %s to %s", pick, player.Name)
end

local function nudgeInvite(player: Player)
	Remotes.Event(Remotes.Names.Notify):FireClient(player, {
		kind = "info",
		text = "👋 Invite a friend — both of you get a bonus when they join!",
	})
end

function FirstSessionService.OnPlayerAdded(player: Player)
	DataService.OnProfileLoaded(player, function()
		local data = DataService.Get(player)
		if not data then return end
		if not isBrandNew(data) then return end

		activeFirstSession[player.UserId] = os.time() + FIRST_SESSION_DURATION
		EconomyService.PushHud(player)

		Remotes.Event(Remotes.Names.Notify):FireClient(player, {
			kind = "capture",
			text = string.format("🎉 Welcome! 3x cash for %s — make it count.",
				Util.SecondsToClock(FIRST_SESSION_DURATION)),
		})

		task.delay(EPIC_GIFT_DELAY, function()
			if player.Parent then giveEpicGift(player) end
		end)
		task.delay(INVITE_PROMPT_DELAY, function()
			if player.Parent then nudgeInvite(player) end
		end)
		task.delay(FIRST_SESSION_DURATION, function()
			activeFirstSession[player.UserId] = nil
			if player.Parent then
				EconomyService.PushHud(player)
				Remotes.Event(Remotes.Names.Notify):FireClient(player, {
					kind = "info",
					text = "First session boost ended. Keep grinding!",
				})
			end
		end)
	end)
end

function FirstSessionService.OnPlayerRemoving(player: Player)
	activeFirstSession[player.UserId] = nil
end

function FirstSessionService.Init() end

return FirstSessionService
