--!strict

export type Difficulty = "easy" | "normal" | "hard" | "insane"

export type Note = {
	t: number,        -- target hit time in seconds from chart start
	lane: number,     -- 0..LANES-1
	holdMs: number?,  -- if present, sustained note ending this many ms later
}

export type Chart = {
	notes: { Note },
	npsPeak: number,    -- precomputed sanity ceiling
	noteCount: number,
}

export type SongDefinition = {
	id: string,
	title: string,
	artist: string,
	bpm: number,
	durationSeconds: number,
	audioId: string?,         -- rbxassetid; nil during local dev
	previewStartSec: number?,
	premium: boolean,         -- requires PremiumPass gamepass
	unlockProductId: number?, -- per-song unlock dev product if premium
	color: Color3,
	charts: { [Difficulty]: Chart },
}

export type Judgement = "marvelous" | "perfect" | "great" | "good" | "miss"

export type HitClaim = {
	noteIndex: number,    -- index into the chart's notes array
	hitTimeMs: number,    -- ms since round start when input registered
	lane: number,         -- which lane the player struck
}

export type ScoreFrame = {
	score: number,
	combo: number,
	maxCombo: number,
	health: number,
	accuracy: number,         -- 0..1
	judgements: { [string]: number },
	noteIndex: number,         -- last server-accepted note index
	failed: boolean,
}

export type RoundResult = {
	songId: string,
	difficulty: Difficulty,
	score: number,
	maxCombo: number,
	accuracy: number,
	judgements: { [string]: number },
	failed: boolean,
	fullCombo: boolean,
	allMarvelous: boolean,
	currencyReward: number,
}

export type PlayerProfileData = {
	currency: number,
	gamepasses: { [string]: boolean },
	unlockedDifficulties: { [string]: boolean }, -- "hard" / "insane"
	unlockedSongs: { [string]: boolean },        -- premium song unlocks
	stats: {
		songsPlayed: number,
		fullCombos: number,
		allMarvelousRuns: number,
		totalNotesHit: number,
		totalNotesMissed: number,
	},
	bestScores: { [string]: { [string]: number } }, -- songId -> difficulty -> best score
	dailyReward: { lastClaimDay: number, streak: number },
	createdAt: number,
}

return {}
