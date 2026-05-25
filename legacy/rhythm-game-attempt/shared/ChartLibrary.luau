--!strict

local Types = require(script.Parent.Types)

local function c3(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-- Chart generators. We build charts procedurally from BPM + a pattern grammar
-- so the data stays small and human-readable. Each generator returns a
-- Types.Chart with notes pre-sorted by time.

type Pattern = {
	bars: number,                -- how many measures to span
	lanes: { number },           -- which lanes the pattern uses (0-indexed)
	subdivision: number,         -- notes per beat (1 = quarter, 2 = eighth, 4 = sixteenth)
	style: "stream" | "jump" | "lr" | "alt" | "single",
}

local function beatSeconds(bpm: number): number
	return 60 / bpm
end

local function generateChart(bpm: number, durationSec: number, patterns: { Pattern }): Types.Chart
	local notes: { Types.Note } = {}
	local beatSec = beatSeconds(bpm)
	local cursorBeat = 4 -- 1 bar of lead-in
	local patternIdx = 1
	local maxBeats = durationSec / beatSec

	while cursorBeat < maxBeats - 4 do
		local p = patterns[patternIdx]
		patternIdx = (patternIdx % #patterns) + 1
		local beatsInPattern = p.bars * 4
		local notesPerBeat = p.subdivision
		local notesInPattern = beatsInPattern * notesPerBeat

		for i = 0, notesInPattern - 1 do
			local atBeat = cursorBeat + i / notesPerBeat
			if atBeat >= maxBeats - 2 then break end
			local t = atBeat * beatSec
			if p.style == "single" then
				table.insert(notes, { t = t, lane = p.lanes[1] })
			elseif p.style == "alt" then
				local lane = p.lanes[(i % #p.lanes) + 1]
				table.insert(notes, { t = t, lane = lane })
			elseif p.style == "lr" then
				local lane = if i % 2 == 0 then p.lanes[1] else p.lanes[#p.lanes]
				table.insert(notes, { t = t, lane = lane })
			elseif p.style == "stream" then
				local lane = p.lanes[((i) % #p.lanes) + 1]
				table.insert(notes, { t = t, lane = lane })
			elseif p.style == "jump" then
				if i % 4 == 0 then
					table.insert(notes, { t = t, lane = p.lanes[1] })
					if p.lanes[#p.lanes] ~= p.lanes[1] then
						table.insert(notes, { t = t, lane = p.lanes[#p.lanes] })
					end
				else
					local lane = p.lanes[(i % #p.lanes) + 1]
					table.insert(notes, { t = t, lane = lane })
				end
			end
		end
		cursorBeat += beatsInPattern
	end

	table.sort(notes, function(a, b)
		if a.t == b.t then return a.lane < b.lane end
		return a.t < b.t
	end)

	-- compute peak NPS (1-second sliding window)
	local peak = 0
	local i = 1
	for j = 1, #notes do
		while notes[j].t - notes[i].t > 1 do i += 1 end
		local count = j - i + 1
		if count > peak then peak = count end
	end

	return { notes = notes, npsPeak = peak, noteCount = #notes }
end

-- ============================================================
-- SONG DEFINITIONS
-- ============================================================
-- Audio IDs are placeholder rbxassetids. Replace with real uploads before
-- publishing. Premium songs require the PremiumPass gamepass or an
-- individual unlockProductId purchase.

local easyPatterns: { Pattern } = {
	{ bars = 2, lanes = { 1, 2 },          subdivision = 1, style = "alt" },
	{ bars = 2, lanes = { 0, 3 },          subdivision = 1, style = "lr"  },
	{ bars = 2, lanes = { 0, 1, 2, 3 },    subdivision = 1, style = "stream" },
	{ bars = 1, lanes = { 0, 3 },          subdivision = 1, style = "jump" },
}

local normalPatterns: { Pattern } = {
	{ bars = 2, lanes = { 0, 1, 2, 3 },    subdivision = 2, style = "stream" },
	{ bars = 2, lanes = { 1, 2 },          subdivision = 2, style = "alt"    },
	{ bars = 1, lanes = { 0, 3 },          subdivision = 2, style = "jump"   },
	{ bars = 2, lanes = { 0, 2, 1, 3 },    subdivision = 2, style = "stream" },
}

local hardPatterns: { Pattern } = {
	{ bars = 2, lanes = { 0, 1, 2, 3 },    subdivision = 4, style = "stream" },
	{ bars = 1, lanes = { 0, 3 },          subdivision = 2, style = "jump"   },
	{ bars = 2, lanes = { 1, 2, 0, 3 },    subdivision = 4, style = "alt"    },
	{ bars = 1, lanes = { 0, 1, 2, 3 },    subdivision = 4, style = "stream" },
	{ bars = 2, lanes = { 0, 3 },          subdivision = 4, style = "lr"     },
}

local insanePatterns: { Pattern } = {
	{ bars = 2, lanes = { 0, 1, 2, 3 },    subdivision = 4, style = "stream" },
	{ bars = 2, lanes = { 0, 2, 1, 3, 2, 0, 3, 1 }, subdivision = 4, style = "stream" },
	{ bars = 1, lanes = { 0, 3 },          subdivision = 4, style = "jump"   },
	{ bars = 2, lanes = { 1, 0, 2, 3 },    subdivision = 4, style = "alt"    },
}

local function buildSong(def: {
	id: string, title: string, artist: string, bpm: number, durationSeconds: number,
	audioId: string?, premium: boolean?, color: Color3, unlockProductId: number?,
}): Types.SongDefinition
	return {
		id = def.id,
		title = def.title,
		artist = def.artist,
		bpm = def.bpm,
		durationSeconds = def.durationSeconds,
		audioId = def.audioId,
		previewStartSec = 30,
		premium = def.premium == true,
		unlockProductId = def.unlockProductId,
		color = def.color,
		charts = {
			easy   = generateChart(def.bpm, def.durationSeconds, easyPatterns),
			normal = generateChart(def.bpm, def.durationSeconds, normalPatterns),
			hard   = generateChart(def.bpm, def.durationSeconds, hardPatterns),
			insane = generateChart(def.bpm, def.durationSeconds, insanePatterns),
		},
	}
end

local songs: { Types.SongDefinition } = {
	buildSong{ id="opener",    title="Opener Beat",          artist="House Producer",   bpm=120, durationSeconds=120, color=c3(80,180,255),  audioId=nil },
	buildSong{ id="midnight",  title="Midnight Drive",       artist="Synthwave Studio", bpm=128, durationSeconds=150, color=c3(255,80,200),  audioId=nil },
	buildSong{ id="rapidfire", title="Rapidfire",            artist="DnB Project",      bpm=174, durationSeconds=180, color=c3(255,160,40),  audioId=nil },
	buildSong{ id="emberfall", title="Emberfall",            artist="Hardcore Lab",     bpm=200, durationSeconds=160, color=c3(255,60,60),   audioId=nil },
	buildSong{ id="prismatic", title="Prismatic",            artist="Trance Atelier",   bpm=138, durationSeconds=200, color=c3(120,220,160), audioId=nil, premium=true },
	buildSong{ id="zerohour",  title="Zero Hour",            artist="Industrial Suite", bpm=160, durationSeconds=180, color=c3(80,80,160),   audioId=nil, premium=true },
	buildSong{ id="apex",      title="Apex",                 artist="Speedcore Inc.",   bpm=222, durationSeconds=140, color=c3(255,255,80),  audioId=nil, premium=true },
}

local byId: { [string]: Types.SongDefinition } = {}
for _, s in ipairs(songs) do byId[s.id] = s end

local ChartLibrary = {}

function ChartLibrary.GetAll(): { Types.SongDefinition }
	return songs
end

function ChartLibrary.Get(id: string): Types.SongDefinition?
	return byId[id]
end

function ChartLibrary.GetChart(id: string, difficulty: string): Types.Chart?
	local song = byId[id]
	if not song then return nil end
	return song.charts[difficulty :: Types.Difficulty]
end

return ChartLibrary
