--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes      = require(Shared.Remotes)
local MutationData = require(Shared.MutationData)
local Log          = require(Shared.Log)

local DataService    = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local LabService     = require(script.Parent.LabService)

local MutationRerollService = {}

-- Reroll the most-recently-applied mutation on an owned brainrot. Costs
-- scale with current tier so high-tier rerolls cost real money — drives
-- the cash-pack purchase loop (the player has 99k cash, the reroll
-- costs 250k, the cash pack is 199 R$ for 25k cash).

local BASE_COST = 500
local function rerollCost(tier: number): number
	return math.floor(BASE_COST * (2.5 ^ tier))
end

local rng = Random.new()

function MutationRerollService.Reroll(player: Player, uid: string)
	local data = DataService.Get(player)
	if not data then return end
	local target
	for _, b in ipairs(data.inventory) do
		if b.uid == uid then target = b; break end
	end
	if not target then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text="Brainrot not in inventory." })
		return
	end
	if target.mutationTier == 0 then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text="No mutation to reroll." })
		return
	end

	local cost = rerollCost(target.mutationTier)
	if not EconomyService.SpendCash(player, cost) then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, {
			kind="error", text=string.format("Need %d cash to reroll.", cost),
		})
		return
	end

	-- Use the Lucky bias for VIP players so it feels like a perk.
	local luckyBias = if data.gamepasses["LuckyMutations"] then 0.35 else 0
	local newMutation = MutationData.RollMutation(rng, luckyBias)
	local oldId = target.mutations[#target.mutations]
	target.mutations[#target.mutations] = newMutation.id

	LabService.RebuildBrainrotVisual(player, target.uid)
	LabService.PushInventory(player)

	Remotes.Event(Remotes.Names.Notify):FireClient(player, {
		kind = "mutation",
		text = string.format("🎲 Reroll: %s → %s (T%d)",
			(oldId and MutationData.Get(oldId) and MutationData.Get(oldId).suffix) or "?",
			newMutation.suffix, target.mutationTier),
	})
	Log.Info("Reroll", "%s rerolled %s T%d %s -> %s for %d",
		player.Name, target.uid, target.mutationTier,
		tostring(oldId), newMutation.id, cost)
end

function MutationRerollService.GetCost(tier: number): number
	return rerollCost(tier)
end

function MutationRerollService.Init() end

return MutationRerollService
