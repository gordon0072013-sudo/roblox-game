--!strict

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config       = require(Shared.Config)
local Remotes      = require(Shared.Remotes)
local Types        = require(Shared.Types)
local ChartLibrary = require(Shared.ChartLibrary)
local Log          = require(Shared.Log)

local DataService = require(script.Parent.DataService)
local AntiCheat   = require(script.Parent.AntiCheat)

-- Forward declarations resolved in Init() to break circular requires.
local LeaderboardService
local BadgeService
local CurrencyService

local ChartService = {}

type ActiveRound = {
	player:           Player,
	songId:           string,
	difficulty:       Types.Difficulty,
	chart:            Types.Chart,
	startedAt:        number,    -- os.clock() at countdown end
	noteCount:        number,
	nextNoteIndex:    number,    -- 1-based, next pending note in the chart
	consumedIndices:  { [number]: boolean },
	score:            number,
	combo:            number,
	maxCombo:         number,
	health:           number,
	judgements:       { [string]: number },
	hitTimestamps:    { number }, -- recent hit times (clock), for NPS rate-cap sliding window
	marvelousStreak:  number,
	failed:           boolean,
	scoreBoost:       number,    -- next-song boost multiplier (consumed at round end)
}

local rounds: { [Player]: ActiveRound } = {}

-- ============================================================
-- HELPERS
-- ============================================================

local function judgementFor(deltaMs: number): (string?, number, boolean)
	local abs = math.abs(deltaMs)
	for _, w in ipairs(Config.JUDGEMENT_WINDOWS) do
		if abs <= w.ms then
			return w.id, w.scoreWeight, w.comboKeep
		end
	end
	return nil, 0, false
end

local function comboMultiplier(combo: number): number
	if combo <= 0 then return 1 end
	local ramp = math.min(combo / Config.COMBO_RAMP_NOTES, 1)
	return 1 + (Config.COMBO_BONUS_CAP - 1) * ramp
end

local function pushScoreFrame(round: ActiveRound)
	local totalJudged = 0
	local weighted = 0
	for id, count in pairs(round.judgements) do
		totalJudged += count
		for _, w in ipairs(Config.JUDGEMENT_WINDOWS) do
			if w.id == id then weighted += w.scoreWeight * count end
		end
	end
	local accuracy = if totalJudged > 0 then weighted / totalJudged else 1
	local frame: Types.ScoreFrame = {
		score = round.score,
		combo = round.combo,
		maxCombo = round.maxCombo,
		health = round.health,
		accuracy = accuracy,
		judgements = round.judgements,
		noteIndex = round.nextNoteIndex - 1,
		failed = round.failed,
	}
	Remotes.Event(Remotes.Names.ScoreFrame):FireClient(round.player, frame)
end

local function endRound(round: ActiveRound)
	rounds[round.player] = nil

	local totalNotes = round.noteCount
	local hits = 0
	local weighted = 0
	for id, count in pairs(round.judgements) do
		if id ~= "miss" then hits += count end
		for _, w in ipairs(Config.JUDGEMENT_WINDOWS) do
			if w.id == id then weighted += w.scoreWeight * count end
		end
	end
	local accuracy = if totalNotes > 0 then weighted / totalNotes else 0
	local fullCombo = (round.judgements.miss or 0) == 0 and (round.judgements.good or 0) == 0 and not round.failed
	local allMarvelous = (round.judgements.marvelous or 0) == totalNotes and not round.failed

	-- Currency reward proportional to accuracy and difficulty.
	local diffMult = ({ easy = 1, normal = 1.5, hard = 2.5, insane = 4 })[round.difficulty] or 1
	local currencyReward = math.floor(50 * diffMult * accuracy * (1 + round.maxCombo / 200))
	if fullCombo then currencyReward = math.floor(currencyReward * 1.5) end
	if allMarvelous then currencyReward = math.floor(currencyReward * 2) end

	if CurrencyService and currencyReward > 0 then
		CurrencyService.Award(round.player, currencyReward, "song reward")
	end

	-- Persist best score if we beat it
	local data = DataService.Get(round.player)
	if data and not round.failed then
		data.bestScores[round.songId] = data.bestScores[round.songId] or {}
		local prevBest = data.bestScores[round.songId][round.difficulty] or 0
		if round.score > prevBest then
			data.bestScores[round.songId][round.difficulty] = round.score
			if LeaderboardService then
				LeaderboardService.Submit(round.player, round.songId, round.difficulty, round.score)
			end
		end
		data.stats.songsPlayed += 1
		if fullCombo then data.stats.fullCombos += 1 end
		if allMarvelous then data.stats.allMarvelousRuns += 1 end
		data.stats.totalNotesHit += hits
		data.stats.totalNotesMissed += round.judgements.miss or 0
	end

	if BadgeService then
		if fullCombo then BadgeService.Fire(round.player, "full_combo") end
		if allMarvelous then BadgeService.Fire(round.player, "all_marvelous") end
	end

	local result: Types.RoundResult = {
		songId = round.songId,
		difficulty = round.difficulty,
		score = round.score,
		maxCombo = round.maxCombo,
		accuracy = accuracy,
		judgements = round.judgements,
		failed = round.failed,
		fullCombo = fullCombo,
		allMarvelous = allMarvelous,
		currencyReward = currencyReward,
	}

	Remotes.Event(Remotes.Names.RoundState):FireClient(round.player, {
		phase = "results",
		result = result,
	})
	Log.Info("Chart", "%s finished %s [%s] score=%d acc=%.2f%% fc=%s",
		round.player.Name, round.songId, round.difficulty, round.score, accuracy*100, tostring(fullCombo))
end

-- ============================================================
-- PUBLIC API
-- ============================================================

function ChartService.RequestPlay(player: Player, songId: string, difficulty: string)
	if rounds[player] then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text="Already in a round." })
		return
	end

	local song = ChartLibrary.Get(songId)
	if not song then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text="Unknown song." })
		return
	end

	local data = DataService.Get(player)
	if not data then return end

	if song.premium then
		local hasPass = data.gamepasses["PremiumPass"] == true
		local hasUnlock = data.unlockedSongs[songId] == true
		if not hasPass and not hasUnlock then
			Remotes.Event(Remotes.Names.Notify):FireClient(player, {
				kind="error", text=`'${song.title}' is premium — buy Premium Pass or unlock this song.`,
			})
			return
		end
	end

	if (difficulty == "hard" or difficulty == "insane") and not data.unlockedDifficulties[difficulty] then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, {
			kind="error", text=`'${difficulty}' difficulty locked — unlock in shop.`,
		})
		return
	end

	local chart = song.charts[difficulty :: Types.Difficulty]
	if not chart or #chart.notes == 0 then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text="No chart for that difficulty." })
		return
	end

	local round: ActiveRound = {
		player = player,
		songId = songId,
		difficulty = difficulty :: Types.Difficulty,
		chart = chart,
		startedAt = os.clock() + Config.PRE_ROUND_SECONDS,
		noteCount = chart.noteCount,
		nextNoteIndex = 1,
		consumedIndices = {},
		score = 0,
		combo = 0,
		maxCombo = 0,
		health = Config.HEALTH_MAX,
		judgements = { marvelous=0, perfect=0, great=0, good=0, miss=0 },
		hitTimestamps = {},
		marvelousStreak = 0,
		failed = false,
		scoreBoost = (data :: any)._pendingBoost or 1,
	}
	;(data :: any)._pendingBoost = nil
	rounds[player] = round

	Remotes.Event(Remotes.Names.RoundState):FireClient(player, {
		phase = "countdown",
		songId = songId,
		difficulty = difficulty,
		title = song.title,
		artist = song.artist,
		bpm = song.bpm,
		color = { song.color.R*255, song.color.G*255, song.color.B*255 },
		notes = chart.notes,
		preRoundSeconds = Config.PRE_ROUND_SECONDS,
		audioId = song.audioId,
	})

	Log.Info("Chart", "%s started %s [%s] (%d notes, peak %d nps)",
		player.Name, songId, difficulty, chart.noteCount, chart.npsPeak)
end

function ChartService.HandleHit(player: Player, payload: any)
	local round = rounds[player]
	if not round or round.failed then return end

	-- Validate payload shape
	if typeof(payload) ~= "table" then
		AntiCheat.Flag(player, "BadHit", "non-table payload", 2)
		return
	end
	local noteIndex = payload.noteIndex
	local hitTimeMs = payload.hitTimeMs
	local lane      = payload.lane
	if typeof(noteIndex) ~= "number" or typeof(hitTimeMs) ~= "number" or typeof(lane) ~= "number" then
		AntiCheat.Flag(player, "BadHit", "missing/typed fields", 2)
		return
	end
	noteIndex = math.floor(noteIndex)
	lane = math.floor(lane)

	if noteIndex < 1 or noteIndex > round.noteCount then
		AntiCheat.Flag(player, "BadHit", `index ${noteIndex} out of range`, 2)
		return
	end
	if round.consumedIndices[noteIndex] then
		AntiCheat.Flag(player, "BadHit", `index ${noteIndex} already consumed`, 1)
		return
	end

	local note = round.chart.notes[noteIndex]
	if note.lane ~= lane then
		AntiCheat.Flag(player, "BadHit", `lane mismatch (claimed ${lane} vs chart ${note.lane})`, 1)
		return
	end

	-- NPS rate-cap (sliding 1s window, anchored to server clock).
	local now = os.clock()
	table.insert(round.hitTimestamps, now)
	while #round.hitTimestamps > 0 and now - round.hitTimestamps[1] > 1 do
		table.remove(round.hitTimestamps, 1)
	end
	if #round.hitTimestamps > Config.MAX_HIT_RATE_PER_SECOND then
		AntiCheat.Flag(player, "HitRate", `${#round.hitTimestamps} hits/s`, 2)
		return
	end

	-- Server-side judgement using SERVER clock as the source of truth.
	-- The client's hitTimeMs is informational — server uses (now - startedAt)
	-- to time the input. This makes client-side time manipulation moot.
	local songElapsedSec = now - round.startedAt
	if songElapsedSec < -0.5 then
		AntiCheat.Flag(player, "EarlyHit", `hit ${songElapsedSec*1000:.0f}ms before song start`, 2)
		return
	end
	local deltaMs = (songElapsedSec - note.t) * 1000
	local maxWindow = Config.JUDGEMENT_WINDOWS[#Config.JUDGEMENT_WINDOWS].ms
	if math.abs(deltaMs) > maxWindow + 50 then
		-- well outside any valid window; ignore but don't flag (legitimate dropped frames)
		return
	end

	local id, scoreWeight, comboKeep = judgementFor(deltaMs)
	if not id then return end

	round.consumedIndices[noteIndex] = true
	round.judgements[id] = (round.judgements[id] or 0) + 1

	if id == "marvelous" then
		round.marvelousStreak += 1
		if round.marvelousStreak >= Config.SUSPICIOUS_MARVELOUS_STREAK then
			AntiCheat.Flag(player, "SuspiciousStreak", `marvelous streak ${round.marvelousStreak}`, 1)
		end
	else
		round.marvelousStreak = 0
	end

	if comboKeep and id ~= "miss" then
		round.combo += 1
		if round.combo > round.maxCombo then round.maxCombo = round.combo end
	else
		round.combo = 0
	end

	local baseScore = math.floor(Config.MAX_SCORE_PER_NOTE * scoreWeight * comboMultiplier(round.combo) * round.scoreBoost)
	round.score += baseScore

	if id == "miss" then
		round.health = math.max(0, round.health - Config.HEALTH_PENALTY_MISS)
	else
		round.health = math.min(Config.HEALTH_MAX, round.health + Config.HEALTH_PER_HIT)
	end

	-- Sanity ceiling on score (defense in depth)
	local theoretical = Config.MAX_SCORE_PER_NOTE * Config.COMBO_BONUS_CAP * round.scoreBoost * noteIndex
	if round.score > theoretical * Config.MAX_PLAUSIBLE_SCORE_RATIO then
		AntiCheat.Flag(player, "ScoreCeiling", `${round.score} > ${math.floor(theoretical)}`, 3)
		round.failed = true
	end

	if round.health <= Config.HEALTH_FAIL_THRESHOLD then
		round.failed = true
	end

	pushScoreFrame(round)

	if round.failed then
		endRound(round)
	end
end

function ChartService.RequestQuit(player: Player)
	local round = rounds[player]
	if round then
		round.failed = true
		endRound(round)
	end
end

function ChartService.SetNextSongBoost(player: Player, multiplier: number)
	local data = DataService.Get(player)
	if not data then return end
	(data :: any)._pendingBoost = math.max(1, math.min(3, multiplier))
end

local function chartTickAll()
	local now = os.clock()
	for player, round in pairs(rounds) do
		if round.failed then continue end
		-- Auto-miss notes whose window has passed entirely.
		local missWindow = Config.JUDGEMENT_WINDOWS[#Config.JUDGEMENT_WINDOWS].ms / 1000
		local songElapsed = now - round.startedAt
		while round.nextNoteIndex <= round.noteCount do
			local note = round.chart.notes[round.nextNoteIndex]
			if round.consumedIndices[round.nextNoteIndex] then
				round.nextNoteIndex += 1
				continue
			end
			if songElapsed - note.t > missWindow then
				round.judgements.miss += 1
				round.consumedIndices[round.nextNoteIndex] = true
				round.combo = 0
				round.health = math.max(0, round.health - Config.HEALTH_PENALTY_MISS)
				round.marvelousStreak = 0
				round.nextNoteIndex += 1
				if round.health <= Config.HEALTH_FAIL_THRESHOLD then
					round.failed = true
					pushScoreFrame(round)
					endRound(round)
					goto continue_outer
				end
			else
				break
			end
		end

		-- End of song?
		local song = ChartLibrary.Get(round.songId)
		if song and songElapsed >= song.durationSeconds + 1 then
			pushScoreFrame(round)
			endRound(round)
		else
			-- periodic score frame
			if math.floor(songElapsed * 4) ~= math.floor((songElapsed - 0.5) * 4) then
				pushScoreFrame(round)
			end
		end
		::continue_outer::
	end
end

function ChartService.OnPlayerRemoving(player: Player)
	local round = rounds[player]
	if round then rounds[player] = nil end
end

function ChartService.Init()
	LeaderboardService = require(script.Parent.LeaderboardService)
	BadgeService       = require(script.Parent.BadgeService)
	CurrencyService    = require(script.Parent.CurrencyService)

	task.spawn(function()
		while true do
			task.wait(0.25)
			chartTickAll()
		end
	end)
end

return ChartService
