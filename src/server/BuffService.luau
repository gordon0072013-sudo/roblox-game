--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Util    = require(Shared.Util)
local Log     = require(Shared.Log)

local BuffService = {}

-- Per-player temporary multipliers, applied on top of the existing
-- EconomyService stack. Used by AdminService /buff for compensation
-- ('sorry your brainrot got eaten by the bug, here's 2x income for 5
-- minutes') and live-ops bursts.

type Buff = {
	kind: string,     -- "income" | "mutation"
	mult: number,
	expiresAt: number,
}

local buffs: { [number]: { [string]: Buff } } = {}

local function get(userId: number, kind: string): number
	local set = buffs[userId]
	if not set then return 1 end
	local b = set[kind]
	if not b then return 1 end
	if os.time() >= b.expiresAt then
		set[kind] = nil
		return 1
	end
	return b.mult
end

function BuffService.GetIncomeMult(player: Player): number
	return get(player.UserId, "income")
end

function BuffService.GetMutationMult(player: Player): number
	return get(player.UserId, "mutation")
end

function BuffService.Apply(player: Player, kind: string, mult: number, seconds: number)
	if kind ~= "income" and kind ~= "mutation" then return false end
	-- Reject pathological inputs: mult must be positive, seconds must be a
	-- reasonable positive integer. Negative mult would invert income/mutation,
	-- zero would freeze the player out of the loop.
	if typeof(mult) ~= "number" or mult <= 0 or mult ~= mult then return false end
	if typeof(seconds) ~= "number" or seconds <= 0 or seconds ~= seconds then return false end
	mult = math.min(mult, 100)            -- absurd-mult cap
	seconds = math.min(math.floor(seconds), 86400)   -- 1-day cap
	buffs[player.UserId] = buffs[player.UserId] or {}
	buffs[player.UserId][kind] = {
		kind = kind,
		mult = mult,
		expiresAt = os.time() + seconds,
	}
	Remotes.Event(Remotes.Names.Notify):FireClient(player, {
		kind = "info",
		text = string.format("⚡ %s buff x%.2f for %s", kind, mult, Util.SecondsToClock(seconds)),
	})
	Log.Info("Buff", "applied %s x%.2f to %s for %ds", kind, mult, player.Name, seconds)
	return true
end

function BuffService.OnPlayerRemoving(player: Player)
	buffs[player.UserId] = nil
end

function BuffService.Init() end

return BuffService
