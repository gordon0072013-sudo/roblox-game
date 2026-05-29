--!strict
--[[
	PetData — pet companions. Each pet:
	  * Floats next to the player when equipped
	  * Provides a passive buff (cash mult, mutation speed, etc.)
	  * Has a rarity-tier visual

	Pets are intentionally separate from brainrots so they constitute a
	second collection dimension (= second grind motivation = second egg
	dev-product slot). Players collect pets AND brainrots.
]]

export type PetRarity = "Basic" | "Premium" | "Legendary" | "Mythical"

export type PetDefinition = {
	id: string,
	name: string,
	rarity: PetRarity,
	color: Color3,
	buffKind: string, -- "cashMult" | "mutationSpeed" | "captureLuck" | "infectionPower"
	buffValue: number, -- e.g. 1.10 = +10%
	tagline: string,
}

local function c3(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local catalog: { PetDefinition } = {
	{ id="pup",     name="Sigma Pup",       rarity="Basic",    color=c3(180,180,180), buffKind="cashMult",       buffValue=1.05, tagline="+5% cash" },
	{ id="kit",     name="Brainrot Kit",    rarity="Basic",    color=c3(220,160,80),  buffKind="captureLuck",    buffValue=0.10, tagline="+10% lucky" },
	{ id="dragon",  name="Mini Dragon",     rarity="Premium",  color=c3(255,80,80),   buffKind="cashMult",       buffValue=1.15, tagline="+15% cash" },
	{ id="ghost",   name="Lab Ghost",       rarity="Premium",  color=c3(220,220,255), buffKind="mutationSpeed",  buffValue=1.20, tagline="+20% mutation speed" },
	{ id="phoenix", name="Phoenix Sigma",   rarity="Legendary",color=c3(255,140,60),  buffKind="cashMult",       buffValue=1.35, tagline="+35% cash" },
	{ id="wyrm",    name="Outbreak Wyrm",   rarity="Legendary",color=c3(120,255,140), buffKind="infectionPower", buffValue=1.50, tagline="+50% infection damage" },
	{ id="apex",    name="Apex Familiar",   rarity="Mythical", color=c3(255,0,200),   buffKind="cashMult",       buffValue=1.75, tagline="+75% cash" },
	{ id="celest",  name="Celestial Eye",   rarity="Mythical", color=c3(255,255,255), buffKind="mutationSpeed",  buffValue=1.60, tagline="+60% mutation speed" },
}

local byId: { [string]: PetDefinition } = {}
for _, d in ipairs(catalog) do byId[d.id] = d end

local rollWeights: { [PetRarity]: number } = {
	Basic = 60,
	Premium = 28,
	Legendary = 10,
	Mythical = 2,
}

local module = {}

function module.GetAll(): { PetDefinition }
	return catalog
end

function module.Get(id: string): PetDefinition?
	return byId[id]
end

function module.Roll(rng: Random, luckyBias: number?): PetDefinition
	local bias = luckyBias or 0
	local adjusted = table.clone(rollWeights) :: any
	if bias > 0 then
		local steal = adjusted.Basic * bias
		adjusted.Basic -= steal
		adjusted.Legendary += steal * 0.6
		adjusted.Mythical += steal * 0.4
	end
	local total = 0
	for _, w in pairs(adjusted) do total += w end
	local pick = rng:NextNumber(0, total)
	local cursor = 0
	local chosen: PetRarity = "Basic"
	for r, w in pairs(adjusted) do
		cursor += w
		if pick <= cursor then chosen = r; break end
	end
	local pool: { PetDefinition } = {}
	for _, d in ipairs(catalog) do
		if d.rarity == chosen then table.insert(pool, d) end
	end
	return pool[rng:NextInteger(1, #pool)]
end

return module
