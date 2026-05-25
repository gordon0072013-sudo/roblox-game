--!strict
--[[
	QuestService — 3 quests per day, deterministic per-player from
	(userId, dayIndex). Quests use the same stats counters as
	achievements but track a delta from the day-start baseline. Reward
	on completion is meaningful but not gamebreaking — cash + a bomb or
	mutation occasionally.

	Why have these alongside daily rewards + achievements? Because the
	quest panel gives a *list of things to do right now*. Players who
	open with a clear short-term goal stay 30–50% longer per session,
	which is the single biggest revenue lever after first-session
	conversion.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local InfectionService -- forward
local CaptureService -- forward
local MutationService -- forward

local QuestService = {}

type QuestTemplate = {
	id: string,
	statKey: string,
	amount: number,
	label: string,
	reward: { kind: string, amount: number },
}

local templates: { QuestTemplate } = {
	{ id="cap3",  statKey="totalCaptured",   amount=3,  label="Capture 3 brainrots",         reward={ kind="cash", amount=1500 } },
	{ id="cap10", statKey="totalCaptured",   amount=10, label="Capture 10 brainrots",        reward={ kind="cash", amount=4000 } },
	{ id="mut5",  statKey="totalMutations",  amount=5,  label="Trigger 5 mutations",         reward={ kind="instant_mutation", amount=1 } },
	{ id="mut15", statKey="totalMutations",  amount=15, label="Trigger 15 mutations",        reward={ kind="cash", amount=5000 } },
	{ id="steal2",statKey="totalSteals",     amount=2,  label="Steal 2 brainrots",           reward={ kind="cash", amount=3000 } },
	{ id="inf2",  statKey="totalInfections", amount=2,  label="Infect 2 players",            reward={ kind="infection_bomb", amount=2 } },
	{ id="reb1",  statKey="rebirths",        amount=1,  label="Rebirth once today",          reward={ kind="cash", amount=8000 } },
	{ id="cash5k",statKey="totalCashEarned", amount=5000, label="Earn 5,000 cash today",     reward={ kind="cash", amount=2500 } },
	{ id="cash20k",statKey="totalCashEarned",amount=20000,label="Earn 20,000 cash today",    reward={ kind="rare_egg", amount=1 } },
}

local function statValue(data: any, key: string): number
	if key == "rebirths" then return data.rebirths or 0 end
	return (data.stats and data.stats[key]) or 0
end

local function pickQuests(userId: number, dayIndex: number): { string }
	-- deterministic shuffle by seeding RNG with userId+day
	local rng = Random.new(userId * 1000003 + dayIndex)
	local indices = {}
	for i = 1, #templates do table.insert(indices, i) end
	-- Fisher-Yates
	for i = #indices, 2, -1 do
		local j = rng:NextInteger(1, i)
		indices[i], indices[j] = indices[j], indices[i]
	end
	return { templates[indices[1]].id, templates[indices[2]].id, templates[indices[3]].id }
end

local function ensureToday(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	local today = Util.DayIndex()
	local q = (data :: any)._quests :: any
	if not q or q.day ~= today then
		-- new day baseline
		local ids = pickQuests(player.UserId, today)
		local baseline: { [string]: number } = {}
		for _, t in ipairs(templates) do
			baseline[t.statKey] = statValue(data, t.statKey)
		end
		;(data :: any)._quests = {
			day = today,
			ids = ids,
			baseline = baseline,
			claimed = {},
		}
	end
end

local function templateById(id: string): QuestTemplate?
	for _, t in ipairs(templates) do
		if t.id == id then return t end
	end
	return nil
end

function QuestService.Push(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	ensureToday(player)
	local q = (data :: any)._quests :: any
	local payload = {}
	for _, id in ipairs(q.ids) do
		local t = templateById(id)
		if t then
			local delta = statValue(data, t.statKey) - (q.baseline[t.statKey] or 0)
			if delta < 0 then delta = 0 end
			table.insert(payload, {
				id = t.id,
				label = t.label,
				progress = math.min(delta, t.amount),
				target = t.amount,
				complete = delta >= t.amount,
				claimed = q.claimed[t.id] == true,
				rewardKind = t.reward.kind,
				rewardAmount = t.reward.amount,
			})
		end
	end
	Remotes.Event(Remotes.Names.QuestUpdate):FireClient(player, payload)
end

local function deliver(player: Player, reward: any)
	if reward.kind == "cash" then
		EconomyService.AwardCash(player, reward.amount, "quest")
	elseif reward.kind == "infection_bomb" then
		InfectionService.AddBombs(player, reward.amount)
	elseif reward.kind == "rare_egg" then
		CaptureService.AttemptCapture(player, { freeRare = true, count = reward.amount })
	elseif reward.kind == "instant_mutation" then
		for _ = 1, reward.amount do MutationService.ForceInstantMutation(player) end
	end
end

function QuestService.Claim(player: Player, id: string)
	local data = DataService.Get(player)
	if not data then return end
	ensureToday(player)
	local q = (data :: any)._quests :: any
	local t = templateById(id)
	if not t then return end
	local listed = false
	for _, qid in ipairs(q.ids) do if qid == id then listed = true; break end end
	if not listed then return end
	if q.claimed[id] then return end
	local delta = statValue(data, t.statKey) - (q.baseline[t.statKey] or 0)
	if delta < t.amount then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text="Quest not complete." })
		return
	end
	q.claimed[id] = true
	deliver(player, t.reward)
	Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="capture", text=`Quest done: ${t.label}` })
	QuestService.Push(player)
end

function QuestService.OnPlayerAdded(player: Player)
	task.delay(2, QuestService.Push, player)
end

function QuestService.Init()
	InfectionService = require(script.Parent.InfectionService)
	CaptureService = require(script.Parent.CaptureService)
	MutationService = require(script.Parent.MutationService)
	task.spawn(function()
		while true do
			task.wait(6)
			for _, p in ipairs(Players:GetPlayers()) do QuestService.Push(p) end
		end
	end)
end

return QuestService
