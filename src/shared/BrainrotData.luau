--!strict
--[[
	BrainrotData — the content catalogue. Names and visuals follow the
	Italian/sigma brainrot meme family. Swap meshes/sounds in Studio later;
	the gameplay tunings (income, rarity) are what matter for balance.

	Rarity floor income (per second, before mutations & rebirth mult):
	  Common      1.5
	  Uncommon    4
	  Rare        10
	  Epic        28
	  Legendary   75
	  Mythic      180
	  Outbreak   500 (event-only)
]]

local Types = require(script.Parent.Types)

local function c3(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local catalog: { Types.BrainrotDefinition } = {
	-- Common (drop pool for basic captures)
	{ id="tralalero",  displayName="Tralalero Tralala",     rarity="Common", baseIncomePerSecond=1.5, color=c3(80,170,255),  primaryShape="Block",    sizeStuds=Vector3.new(3,3,4),   tagline="Three legs, three sins." },
	{ id="bombardiro", displayName="Bombardiro Crocodilo",  rarity="Common", baseIncomePerSecond=1.8, color=c3(80,140,80),   primaryShape="Cylinder", sizeStuds=Vector3.new(4,2,4),   tagline="Flies. Bombs. Crocodile." },
	{ id="brrbrr",     displayName="Brr Brr Patapim",        rarity="Common", baseIncomePerSecond=2.0, color=c3(120,90,60),   primaryShape="Block",    sizeStuds=Vector3.new(3,4,3),   tagline="Tree with feet." },
	{ id="lirili",     displayName="Lirili Larila",          rarity="Common", baseIncomePerSecond=2.3, color=c3(200,180,90),  primaryShape="Wedge",    sizeStuds=Vector3.new(3,3,3),   tagline="Cactus. Sandals. Elephant." },

	-- Uncommon
	{ id="bombombini", displayName="Bombombini Gusini",      rarity="Uncommon", baseIncomePerSecond=4,  color=c3(170,170,170), primaryShape="Cylinder", sizeStuds=Vector3.new(3,2,5),   tagline="Goose. Bomber. Annoying." },
	{ id="trippi",     displayName="Trippi Troppi",          rarity="Uncommon", baseIncomePerSecond=4.5,color=c3(220,150,200), primaryShape="Ball",     sizeStuds=Vector3.new(3,3,3),   tagline="Shrimp cat. Fashion icon." },
	{ id="boneca",     displayName="Boneca Ambalabu",        rarity="Uncommon", baseIncomePerSecond=5,  color=c3(80,200,200),  primaryShape="Ball",     sizeStuds=Vector3.new(3,3,3),   tagline="Frog tire person." },

	-- Rare
	{ id="udin",       displayName="Udin Din Din Dun",       rarity="Rare", baseIncomePerSecond=10, color=c3(255,140,40),  primaryShape="Block",    sizeStuds=Vector3.new(4,4,4),   tagline="Drum legs. Goes hard." },
	{ id="frigo",      displayName="Frigo Camelo",           rarity="Rare", baseIncomePerSecond=12, color=c3(220,220,255), primaryShape="Block",    sizeStuds=Vector3.new(4,5,4),   tagline="Fridge camel. Stays cool." },
	{ id="pipi",       displayName="Pipi Avocado",           rarity="Rare", baseIncomePerSecond=14, color=c3(120,200,80),  primaryShape="Ball",     sizeStuds=Vector3.new(3,3,3),   tagline="Avocado that hums." },
	{ id="zibra",      displayName="Zibra Zibra",            rarity="Rare", baseIncomePerSecond=16, color=c3(240,240,240), primaryShape="Block",    sizeStuds=Vector3.new(4,3,5),   tagline="Stripes loading…" },

	-- Epic
	{ id="tunglur",    displayName="Tung Tung Tung Sahur",   rarity="Epic", baseIncomePerSecond=28, color=c3(80,60,40),    primaryShape="Cylinder", sizeStuds=Vector3.new(2,5,2),   tagline="Wood log. Holy stick." },
	{ id="capucino",   displayName="Cappuccino Assassino",   rarity="Epic", baseIncomePerSecond=32, color=c3(110,70,40),   primaryShape="Cylinder", sizeStuds=Vector3.new(3,4,3),   tagline="Espresso, two katanas." },
	{ id="ballerina",  displayName="Ballerina Cappuccina",   rarity="Epic", baseIncomePerSecond=36, color=c3(220,180,140), primaryShape="Block",    sizeStuds=Vector3.new(3,5,3),   tagline="Pirouette. Caffeinated." },
	{ id="chimpanzini",displayName="Chimpanzini Bananini",   rarity="Epic", baseIncomePerSecond=40, color=c3(220,200,50),  primaryShape="Ball",     sizeStuds=Vector3.new(3,4,3),   tagline="Banana monkey. Trades stocks." },

	-- Legendary
	{ id="lirilarila", displayName="Lirili Larila Supremo",  rarity="Legendary", baseIncomePerSecond=75, color=c3(255,220,120), primaryShape="Wedge", sizeStuds=Vector3.new(5,4,5), tagline="Time bends for him." },
	{ id="bombarmiro", displayName="Bombardino Lucertola",   rarity="Legendary", baseIncomePerSecond=90, color=c3(60,180,90),   primaryShape="Cylinder", sizeStuds=Vector3.new(5,3,5), tagline="Lizard bomber, Mach 9." },
	{ id="orangutini", displayName="Orangutini Ananasini",   rarity="Legendary", baseIncomePerSecond=110, color=c3(255,160,40),  primaryShape="Ball",     sizeStuds=Vector3.new(4,5,4), tagline="Pineapple primate, listed on NYSE." },

	-- Mythic (rare drops, big income)
	{ id="trulimero",  displayName="Trulimero Trulicina",    rarity="Mythic", baseIncomePerSecond=180, color=c3(255,80,180),  primaryShape="Ball",     sizeStuds=Vector3.new(5,5,5), tagline="Fish-cat-deity. Don't ask." },
	{ id="cocofanto",  displayName="Cocofanto Elefanto",     rarity="Mythic", baseIncomePerSecond=220, color=c3(120,80,40),   primaryShape="Block",    sizeStuds=Vector3.new(6,6,7), tagline="Coconut elephant. Heavy." },
	{ id="lalilulalero",displayName="La Lila Lulu Lalero",   rarity="Mythic", baseIncomePerSecond=260, color=c3(180,80,255),  primaryShape="Cylinder", sizeStuds=Vector3.new(4,7,4), tagline="Skibidi's accountant." },

	-- Outbreak (event-only, can be captured during Outbreak event)
	{ id="patriarch",  displayName="Patriarchus Sigmus",     rarity="Outbreak", baseIncomePerSecond=500, color=c3(255,215,0),   primaryShape="Wedge", sizeStuds=Vector3.new(7,7,7), tagline="The original. The mind virus." },
	{ id="apexor",     displayName="Apexor Brainrot",        rarity="Outbreak", baseIncomePerSecond=650, color=c3(255,0,120),   primaryShape="Ball",  sizeStuds=Vector3.new(7,7,7), tagline="Final form. Final boss." },

	-- Additional content (v2 expansion — depth keeps players collecting)
	{ id="garamaraman",   displayName="Garamaraman Garamamarinanara", rarity="Common",    baseIncomePerSecond=2.6, color=c3(80,200,200),  primaryShape="Ball",     sizeStuds=Vector3.new(3,3,3),   tagline="Says many words. Means none." },
	{ id="trippitroppa",  displayName="Trippi Troppa Sigma",          rarity="Uncommon",  baseIncomePerSecond=5.5, color=c3(255,80,180),  primaryShape="Ball",     sizeStuds=Vector3.new(4,3,4),   tagline="Shrimp dad. Six pack abs." },
	{ id="bobritini",     displayName="Bobritini Crocodilini",        rarity="Rare",      baseIncomePerSecond=18,  color=c3(50,140,80),   primaryShape="Cylinder", sizeStuds=Vector3.new(5,2,5),   tagline="Bob with teeth." },
	{ id="brrbrrtim",     displayName="Brr Brr Tim Tim",              rarity="Rare",      baseIncomePerSecond=20,  color=c3(140,100,70),  primaryShape="Block",    sizeStuds=Vector3.new(4,4,3),   tagline="Two trees, one mission." },
	{ id="trulilulilu",   displayName="Trulilu Lirili Lulilu",        rarity="Epic",      baseIncomePerSecond=44,  color=c3(220,140,255), primaryShape="Wedge",    sizeStuds=Vector3.new(4,5,4),   tagline="Forgets what time means." },
	{ id="bombobambino",  displayName="Bombobambino Bambinello",      rarity="Epic",      baseIncomePerSecond=50,  color=c3(180,200,80),  primaryShape="Cylinder", sizeStuds=Vector3.new(3,3,3),   tagline="Tiny bombs. Big anger." },
	{ id="cappuccinetto", displayName="Cappuccinetto Mezzanotte",     rarity="Legendary", baseIncomePerSecond=140, color=c3(60,30,20),    primaryShape="Cylinder", sizeStuds=Vector3.new(3,4,3),   tagline="Espresso at 3am. Unstoppable." },
	{ id="frigocamelona", displayName="Frigo Camelona Suprema",       rarity="Legendary", baseIncomePerSecond=160, color=c3(255,255,255), primaryShape="Block",    sizeStuds=Vector3.new(5,6,5),   tagline="Holds the cold and the truth." },
	{ id="balerinamamma", displayName="Ballerina Mamma Mia",          rarity="Mythic",    baseIncomePerSecond=320, color=c3(255,200,220), primaryShape="Block",    sizeStuds=Vector3.new(4,6,4),   tagline="Dances on dimensions." },
	{ id="lalilelilu",    displayName="La Lili Le Li Lu",             rarity="Mythic",    baseIncomePerSecond=380, color=c3(180,0,255),   primaryShape="Cylinder", sizeStuds=Vector3.new(4,7,4),   tagline="Numbers became sounds, sounds became him." },
}

local byId: { [string]: Types.BrainrotDefinition } = {}
for _, def in ipairs(catalog) do
	byId[def.id] = def
end

-- Rarity probability table for normal captures.
local captureRollWeights: { [Types.Rarity]: number } = {
	Common = 60,
	Uncommon = 22,
	Rare = 12,
	Epic = 4.5,
	Legendary = 1.3,
	Mythic = 0.2,
	Outbreak = 0,
}

-- Rarity probability table during Outbreak events (heavily skewed).
local outbreakRollWeights: { [Types.Rarity]: number } = {
	Common = 5,
	Uncommon = 10,
	Rare = 20,
	Epic = 30,
	Legendary = 22,
	Mythic = 10,
	Outbreak = 3,
}

local BrainrotData = {}

function BrainrotData.GetAll(): { Types.BrainrotDefinition }
	return catalog
end

function BrainrotData.Get(id: string): Types.BrainrotDefinition?
	return byId[id]
end

function BrainrotData.RollSpecies(rng: Random, outbreak: boolean, luckyBias: number?): Types.BrainrotDefinition
	local weights = if outbreak then outbreakRollWeights else captureRollWeights
	local bias = luckyBias or 0

	-- Lucky bias shifts weight from Common toward Mythic/Legendary by a fractional amount
	local adjusted: { [Types.Rarity]: number } = table.clone(weights) :: any
	if bias > 0 and not outbreak then
		local steal = adjusted.Common * bias
		adjusted.Common -= steal
		adjusted.Legendary += steal * 0.5
		adjusted.Mythic += steal * 0.3
		adjusted.Epic += steal * 0.2
	end

	local total = 0
	for _, w in pairs(adjusted) do total += w end
	local pick = rng:NextNumber(0, total)
	local cursor = 0
	local chosenRarity: Types.Rarity = "Common"
	for rarity, w in pairs(adjusted) do
		cursor += w
		if pick <= cursor then
			chosenRarity = rarity
			break
		end
	end

	local pool: { Types.BrainrotDefinition } = {}
	for _, def in ipairs(catalog) do
		if def.rarity == chosenRarity then
			table.insert(pool, def)
		end
	end

	if #pool == 0 then
		-- Fallback: any non-outbreak species
		for _, def in ipairs(catalog) do
			if def.rarity ~= "Outbreak" then
				table.insert(pool, def)
			end
		end
	end

	return pool[rng:NextInteger(1, #pool)]
end

return BrainrotData
