--!strict
--[[
	Shared type definitions. Used by both server and client modules.
]]

export type Rarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Outbreak"

export type BrainrotDefinition = {
	id: string,
	displayName: string,
	rarity: Rarity,
	baseIncomePerSecond: number,
	color: Color3,
	primaryShape: "Ball" | "Block" | "Cylinder" | "Wedge",
	sizeStuds: Vector3,
	soundAssetId: string?, -- optional meme audio
	tagline: string,
}

export type Mutation = {
	id: string,
	displayName: string,
	suffix: string, -- e.g. "Glitched", "Sigma", "Cursed"
	rarityWeight: number, -- higher = more common
	colorShift: Color3?, -- if set, tints the brainrot
	scaleMult: number,
	incomeMult: number, -- multiplicative bonus stacked on tier bonus
	effect: "None" | "Sparkle" | "Fire" | "Glitch" | "Rainbow" | "Smoke",
}

export type OwnedBrainrot = {
	uid: string, -- unique per brainrot
	speciesId: string,
	mutationTier: number, -- 0..MUTATION_MAX_TIER
	mutations: { string }, -- mutation ids applied (length = mutationTier)
	bornAt: number, -- os.time() when captured
	lastMutationAt: number, -- os.time() of last successful roll
	placed: boolean, -- on this player's plot?
	slotIndex: number?, -- if placed, which slot
}

export type PlayerProfileData = {
	cash: number,
	rebirths: number,
	inventory: { OwnedBrainrot },
	infectionBombs: number,
	infectedUntil: number, -- os.time() — 0 if not infected
	plotId: number?, -- assigned at runtime, not persisted across sessions
	gamepasses: { [string]: boolean },
	battlePass: {
		xp: number,
		tier: number,
		claimed: { [string]: boolean }, -- claimed tier rewards keyed by tier index
		premium: boolean,
		seasonId: string,
	},
	dailyReward: {
		lastClaimDay: number, -- os.time()/86400 floor
		streak: number,
	},
	stats: {
		totalCaptured: number,
		totalMutations: number,
		totalSteals: number,
		totalInfections: number,
		totalCashEarned: number,
	},
	createdAt: number,
}

export type StealRecord = {
	attacker: string, -- userId as string
	victim: string,
	brainrotUid: string,
	at: number,
}

return {}
