--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes      = require(Shared.Remotes)
local BrainrotData = require(Shared.BrainrotData)
local Util         = require(Shared.Util)
local Log          = require(Shared.Log)
local Types        = require(Shared.Types)

local DataService = require(script.Parent.DataService)
local LabService  = require(script.Parent.LabService)

local FusionService = {}

-- Combine 3 brainrots into a guaranteed roll from the next rarity tier.
-- Inputs must be the same species (forces deeper grinding into the
-- gacha) and unmutated. Outputs are a random species of the next rarity.
local RARITY_LADDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }

local function nextRarityName(r: string): string?
	for i, name in ipairs(RARITY_LADDER) do
		if name == r and RARITY_LADDER[i + 1] then return RARITY_LADDER[i + 1] end
	end
	return nil
end

local function speciesOfRarity(rarity: string): { Types.BrainrotDefinition }
	local out = {}
	for _, d in ipairs(BrainrotData.GetAll()) do
		if d.rarity == rarity then table.insert(out, d) end
	end
	return out
end

local rng = Random.new()

function FusionService.Attempt(player: Player, uids: { string })
	if #uids ~= 3 then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text="Fusion needs exactly 3 brainrots." })
		return
	end
	local data = DataService.Get(player)
	if not data then return end

	-- Resolve all three; require same species & no mutations.
	local resolved: { Types.OwnedBrainrot } = {}
	for _, uid in ipairs(uids) do
		local found
		for _, b in ipairs(data.inventory) do
			if b.uid == uid then found = b; break end
		end
		if not found then
			Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text="Brainrot not in inventory." })
			return
		end
		if found.mutationTier > 0 then
			Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text="Cannot fuse mutated brainrots." })
			return
		end
		table.insert(resolved, found)
	end

	local species = resolved[1].speciesId
	for _, b in ipairs(resolved) do
		if b.speciesId ~= species then
			Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text="All 3 must be the same species." })
			return
		end
	end

	local def = BrainrotData.Get(species)
	if not def then return end
	local nextRarity = nextRarityName(def.rarity)
	if not nextRarity then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text="Already at top fuseable rarity." })
		return
	end

	-- Roll the output species
	local pool = speciesOfRarity(nextRarity)
	if #pool == 0 then return end
	local newDef = pool[rng:NextInteger(1, #pool)]

	-- Atomically: remove the three inputs, give the output.
	local toRemove: { [string]: boolean } = {}
	for _, u in ipairs(uids) do toRemove[u] = true end

	-- Unplace any that are placed (TransferBrainrot path expects this)
	for _, u in ipairs(uids) do
		LabService.UnplaceBrainrot(player, u)
	end
	for i = #data.inventory, 1, -1 do
		if toRemove[data.inventory[i].uid] then
			table.remove(data.inventory, i)
		end
	end

	local newBrainrot: Types.OwnedBrainrot = {
		uid = Util.GenerateUid(),
		speciesId = newDef.id,
		mutationTier = 0,
		mutations = {},
		bornAt = os.time(),
		lastMutationAt = os.time(),
		placed = false,
	}
	LabService.GiveBrainrot(player, newBrainrot)
	LabService.PlaceBrainrot(player, newBrainrot.uid)
	LabService.PushInventory(player)
	Remotes.Event(Remotes.Names.Notify):FireClient(player, {
		kind = "capture",
		text = string.format("✨ Fused 3x %s → %s [%s]", def.displayName, newDef.displayName, newDef.rarity),
	})
	Log.Info("Fusion", "%s fused 3x %s -> %s", player.Name, def.id, newDef.id)
end

function FusionService.Init()
	-- Suppress unused
	local _ = Util
end

return FusionService
