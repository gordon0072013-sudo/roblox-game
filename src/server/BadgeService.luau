--!strict
--[[
	BadgeService — awards Roblox Badges for milestone events. Badges show
	on the player's Roblox profile permanently, which is the most viral
	thing in the platform's social graph (friends see them, recommendation
	algorithms bias toward profiles with rare badges).

	Workflow: create badges on the Creator Dashboard (one per entry in
	BADGES below) → paste IDs → republish. Each badge is awarded at most
	once per player; BadgeService gates with a profile flag and the
	platform's :UserHasBadgeAsync check.
]]

local BadgeService_Roblox = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local DataService = require(script.Parent.DataService)
local Remotes = require(Shared.Remotes)

local BadgeService = {}

-- Replace 0s with real Badge IDs from Creator Dashboard → Badges → Create.
-- Suggested badge icons documented in launch/MARKETING.md.
local BADGES: { [string]: { id: number, name: string, trigger: string } } = {
	FirstSteps    = { id = 0, name = "First Steps",     trigger = "join" },               -- first join
	FirstCapture  = { id = 0, name = "First Capture",   trigger = "first_capture" },
	FirstMutation = { id = 0, name = "First Mutation",  trigger = "first_mutation" },
	FirstSteal    = { id = 0, name = "Sticky Fingers",  trigger = "first_steal" },
	FirstInfect   = { id = 0, name = "Patient Zero",    trigger = "first_infect" },
	FirstRebirth  = { id = 0, name = "Reborn",          trigger = "first_rebirth" },
	OutbreakHero  = { id = 0, name = "Outbreak Hero",   trigger = "first_outbreak" },
	ApexAchieved  = { id = 0, name = "Apex Tier",       trigger = "apex_mutation" },     -- mutate any to T6
	Tycoon100K    = { id = 0, name = "100K Earner",     trigger = "cash_100k" },
	Tycoon1M      = { id = 0, name = "Millionaire",     trigger = "cash_1m" },
	Founder       = { id = 0, name = "Founder",         trigger = "joined_in_launch_week" },
}

local function shouldAwardFounder(): boolean
	-- Awards "Founder" badge to anyone joining within the first 14 days.
	-- Update this timestamp when you publish — printed to console below.
	local LAUNCH_TS = 0 -- e.g. os.time() at launch
	if LAUNCH_TS == 0 then return false end
	return os.time() - LAUNCH_TS < 14 * 24 * 3600
end

local function tryAward(player: Player, key: string)
	local b = BADGES[key]
	if not b or b.id <= 0 then return end
	local data = DataService.Get(player)
	if not data then return end
	(data :: any)._badges = (data :: any)._badges or {}
	local log = (data :: any)._badges :: { [string]: boolean }
	if log[key] then return end
	-- Don't re-grant if Roblox already has it (cross-session check)
	local ok, owned = pcall(function()
		return BadgeService_Roblox:UserHasBadgeAsync(player.UserId, b.id)
	end)
	if ok and owned then
		log[key] = true
		return
	end
	-- AwardBadge returns a boolean. pcall protects against network errors;
	-- the returned bool tells us whether Roblox actually granted the badge
	-- (false typically means the badge is private or unowned). Treating a
	-- silent false as success would mark the local log so this player never
	-- retries — leading to permanently un-awarded badges after fixing
	-- visibility on the dashboard. Capture both.
	local callOk, awardSuccess = pcall(function()
		return BadgeService_Roblox:AwardBadge(player.UserId, b.id)
	end)
	if callOk and awardSuccess then
		log[key] = true
		Remotes.Event(Remotes.Names.Notify):FireClient(player, {
			kind = "capture",
			text = `🏆 Badge unlocked: ${b.name}`,
		})
	end
end

function BadgeService.Fire(player: Player, trigger: string)
	for key, b in pairs(BADGES) do
		if b.trigger == trigger then
			tryAward(player, key)
		end
	end
end

function BadgeService.OnPlayerAdded(player: Player)
	task.delay(2, function()
		BadgeService.Fire(player, "join")
		if shouldAwardFounder() then
			tryAward(player, "Founder")
		end
	end)
end

function BadgeService.Init()
	if BADGES.FirstSteps.id <= 0 then
		print("[BadgeService] No badge IDs configured. Create badges in Creator Dashboard and paste IDs into BadgeService.luau.")
	end
	-- Suppress unused
	local _ = Players
end

return BadgeService
