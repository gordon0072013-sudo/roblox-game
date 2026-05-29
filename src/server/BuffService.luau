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
