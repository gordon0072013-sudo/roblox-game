--!strict
--[[
	DecorationData — placeable cosmetic items players buy with cash and
	put on their plot. Pure cosmetics; no income impact. Sold through the
	Decoration Shop and a gamepass that unlocks the premium tier set.
]]

export type DecorationDefinition = {
	id: string,
	name: string,
	cost: number,
	premium: boolean, -- requires DecorationPack gamepass to purchase
	primaryShape: "Ball" | "Block" | "Cylinder",
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	effect: "None" | "Sparkle" | "Fire" | "Rainbow",
}

local function c3(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local catalog: { DecorationDefinition } = {
	-- Free tier
	{ id="lamp",   name="Neon Lamp",       cost=500,   premium=false, primaryShape="Cylinder", size=Vector3.new(1.5,4,1.5),  color=c3(255,220,80),  material=Enum.Material.Neon,         effect="None" },
	{ id="bench",  name="Lab Bench",       cost=750,   premium=false, primaryShape="Block",    size=Vector3.new(6,1.5,2),    color=c3(140,80,40),   material=Enum.Material.Wood,         effect="None" },
	{ id="plant",  name="Sigma Plant",     cost=1000,  premium=false, primaryShape="Ball",     size=Vector3.new(3,4,3),      color=c3(60,180,80),   material=Enum.Material.Grass,        effect="None" },
	{ id="speaker",name="Bass Cannon",     cost=1500,  premium=false, primaryShape="Cylinder", size=Vector3.new(2,3,2),      color=c3(40,40,55),    material=Enum.Material.Metal,        effect="None" },
	{ id="trophy", name="Tycoon Trophy",   cost=3000,  premium=false, primaryShape="Block",    size=Vector3.new(2,4,2),      color=c3(255,215,80),  material=Enum.Material.Neon,         effect="Sparkle" },
	-- Premium tier (requires DecorationPack gamepass)
	{ id="fountain", name="Cash Fountain", cost=10000, premium=true,  primaryShape="Cylinder", size=Vector3.new(5,4,5),      color=c3(80,180,255),  material=Enum.Material.Neon,         effect="Sparkle" },
	{ id="brazier",  name="Apex Brazier",  cost=15000, premium=true,  primaryShape="Cylinder", size=Vector3.new(3,5,3),      color=c3(255,80,40),   material=Enum.Material.Neon,         effect="Fire" },
	{ id="orb",      name="Rainbow Orb",   cost=20000, premium=true,  primaryShape="Ball",     size=Vector3.new(4,4,4),      color=c3(255,255,255), material=Enum.Material.ForceField,   effect="Rainbow" },
}

local byId: { [string]: DecorationDefinition } = {}
for _, d in ipairs(catalog) do byId[d.id] = d end

local module = {}
function module.GetAll(): { DecorationDefinition } return catalog end
function module.Get(id: string): DecorationDefinition? return byId[id] end
return module
