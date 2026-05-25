--!strict

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Log     = require(Shared.Log)

local DataService = require(script.Parent.DataService)
local LabService  = require(script.Parent.LabService)

local AutoSellService = {}

-- Per-player auto-sell rules. Player picks a rarity threshold; anything at or
-- below that rarity is auto-sold on capture. Solves late-game inventory
-- bloat that drives players to quit instead of grinding higher rebirths.

local RARITY_RANK: { [string]: number } = {
	Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6, Outbreak = 7,
}

local function ensure(data: any)
	data._autoSell = data._autoSell or {
		enabled = false,
		threshold = "Common",       -- below or equal to this gets sold
		excludeMutated = true,       -- never auto-sell a mutated brainrot
	}
end

local function pushUpdate(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	ensure(data)
	Remotes.Event(Remotes.Names.AutoSellUpdate):FireClient(player, data._autoSell)
end

-- Hook called by LabService.GiveBrainrot once a new brainrot lands in
-- inventory. We re-check eligibility and trigger a sell if applicable.
function AutoSellService.OnCapture(player: Player, brainrotUid: string)
	local data = DataService.Get(player)
	if not data then return end
	ensure(data)
	if not data._autoSell.enabled then return end
	for _, b in ipairs(data.inventory) do
		if b.uid == brainrotUid then
			if data._autoSell.excludeMutated and b.mutationTier > 0 then return end
			local BrainrotData = require(Shared.BrainrotData)
			local def = BrainrotData.Get(b.speciesId)
			if not def then return end
			local thRank = RARITY_RANK[data._autoSell.threshold] or 1
			local rank = RARITY_RANK[def.rarity] or 1
			if rank <= thRank then
				task.defer(function() LabService.SellBrainrot(player, brainrotUid) end)
			end
			return
		end
	end
end

function AutoSellService.SetConfig(player: Player, enabled: boolean, threshold: string, excludeMutated: boolean)
	local data = DataService.Get(player)
	if not data then return end
	ensure(data)
	if not RARITY_RANK[threshold] then return end
	data._autoSell.enabled = enabled and true or false
	data._autoSell.threshold = threshold
	data._autoSell.excludeMutated = excludeMutated and true or false
	pushUpdate(player)
	Log.Info("AutoSell", "%s -> enabled=%s threshold=%s excludeMutated=%s",
		player.Name, tostring(enabled), threshold, tostring(excludeMutated))
end

function AutoSellService.OnPlayerAdded(player: Player)
	task.delay(2, pushUpdate, player)
end

function AutoSellService.Init()
	Remotes.Event(Remotes.Names.AutoSellUpdate)
end

return AutoSellService
