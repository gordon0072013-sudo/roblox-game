--!strict
--[[
	MutationData — the table of possible mutations a brainrot can acquire.
	Each tier roll picks ONE mutation from this list (weighted) and appends
	it to the brainrot's mutation chain.

	The visual stack is additive: tier 3 brainrot has 3 mutations applied,
	colors blend, scale multiplies, effects layer. This is the "screenshot
	bait" — every plot ends up unique.
]]

local Types = require(script.Parent.Types)

local function c3(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local mutations: { Types.Mutation } = {
	{ id="sigma",     displayName="Sigma",     suffix="Sigma",     rarityWeight=40, colorShift=c3(255,215,0),  scaleMult=1.05, incomeMult=1.15, effect="Sparkle" },
	{ id="skibidi",   displayName="Skibidi",   suffix="Skibidi",   rarityWeight=35, colorShift=c3(100,180,255),scaleMult=1.10, incomeMult=1.20, effect="Smoke" },
	{ id="ohio",      displayName="Ohio",      suffix="from Ohio", rarityWeight=30, colorShift=c3(120,60,160), scaleMult=1.08, incomeMult=1.25, effect="Glitch" },
	{ id="gyatt",     displayName="Gyatt",     suffix="Gyatt",     rarityWeight=28, colorShift=c3(255,120,150),scaleMult=1.20, incomeMult=1.10, effect="Sparkle" },
	{ id="rizzler",   displayName="Rizzler",   suffix="Rizzler",   rarityWeight=22, colorShift=c3(255,80,200), scaleMult=1.05, incomeMult=1.40, effect="Rainbow" },
	{ id="cursed",    displayName="Cursed",    suffix="Cursed",    rarityWeight=14, colorShift=c3(40,0,60),    scaleMult=1.12, incomeMult=1.55, effect="Smoke" },
	{ id="glitched",  displayName="Glitched",  suffix="Glitched",  rarityWeight=10, colorShift=c3(0,255,180),  scaleMult=1.00, incomeMult=1.80, effect="Glitch" },
	{ id="celestial", displayName="Celestial", suffix="Celestial", rarityWeight=5,  colorShift=c3(255,255,255),scaleMult=1.25, incomeMult=2.20, effect="Rainbow" },
	{ id="apex",      displayName="Apex",      suffix="Apex",      rarityWeight=1.5,colorShift=c3(255,0,0),    scaleMult=1.35, incomeMult=3.00, effect="Fire" },
}

local MutationData = {}

function MutationData.GetAll(): { Types.Mutation }
	return mutations
end

function MutationData.RollMutation(rng: Random, luckyBias: number?): Types.Mutation
	local bias = luckyBias or 0
	local total = 0
	for _, m in ipairs(mutations) do
		-- Lucky bias slightly inverts the weight to favor rarer mutations
		local w = m.rarityWeight
		if bias > 0 and w < 15 then
			w = w * (1 + bias)
		elseif bias > 0 and w > 25 then
			w = w * (1 - bias * 0.4)
		end
		total += w
	end
	local pick = rng:NextNumber(0, total)
	local cursor = 0
	for _, m in ipairs(mutations) do
		local w = m.rarityWeight
		if bias > 0 and w < 15 then
			w = w * (1 + bias)
		elseif bias > 0 and w > 25 then
			w = w * (1 - bias * 0.4)
		end
		cursor += w
		if pick <= cursor then
			return m
		end
	end
	return mutations[1]
end

function MutationData.Get(id: string): Types.Mutation?
	for _, m in ipairs(mutations) do
		if m.id == id then return m end
	end
	return nil
end

return MutationData
