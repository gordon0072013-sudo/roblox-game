--!strict
--[[
	CodeService — redeems marketing codes from Config.REDEMPTION_CODES.
	Each (player, codeKey) pair is single-use; we track redemptions on the
	profile so they survive reconnects.

	Workflow: post a TikTok/Shorts/Reels with a redemption code at the end
	of the video → viewers join → redeem → engagement spike → cash hooks
	convert. This is the dial you control without redeploying code (just
	add more entries to Config.REDEMPTION_CODES and republish).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local InfectionService -- forward
local CaptureService -- forward
local MutationService -- forward

local CodeService = {}

-- Runtime-added codes (in-memory only; lost on shutdown). Filled by
-- AdminService's /addcode command so the owner can drop a fresh code
-- mid-stream without republishing the place.
local runtimeCodes: { [string]: any } = {}

local function deliverReward(player: Player, code: string, reward: any): boolean
	if reward.kind == "cash" then
		EconomyService.AwardCash(player, reward.amount or 0, `code ${code}`)
	elseif reward.kind == "infection_bomb" then
		InfectionService.AddBombs(player, reward.amount or 1)
	elseif reward.kind == "rare_egg" then
		CaptureService.AttemptCapture(player, { freeRare = true, count = reward.amount or 1 })
	elseif reward.kind == "instant_mutation" then
		for _ = 1, (reward.amount or 1) do
			MutationService.ForceInstantMutation(player)
		end
	else
		warn(`[CodeService] Unknown reward kind: ${tostring(reward.kind)}`)
		return false
	end
	return true
end

function CodeService.Redeem(player: Player, codeRaw: string)
	if typeof(codeRaw) ~= "string" then return end
	local code = string.upper(string.gsub(codeRaw, "%s", ""))
	local reward = (Config.REDEMPTION_CODES :: any)[code] or runtimeCodes[code]
	if not reward then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text=`Invalid code: ${code}` })
		return
	end
	if reward.expiresAt and os.time() > reward.expiresAt then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text=`Code expired: ${code}` })
		return
	end
	local data = DataService.Get(player)
	if not data then return end
	(data :: any)._redeemedCodes = (data :: any)._redeemedCodes or {}
	local log = (data :: any)._redeemedCodes :: { [string]: boolean }
	if log[code] then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text=`Already redeemed: ${code}` })
		return
	end
	local ok = deliverReward(player, code, reward)
	if not ok then return end
	log[code] = true
	Remotes.Event(Remotes.Names.Notify):FireClient(player, {
		kind = "capture",
		text = `Code ${code} — ${reward.label or "reward"} granted!`,
	})
end

function CodeService.Init()
	InfectionService = require(script.Parent.InfectionService)
	CaptureService = require(script.Parent.CaptureService)
	MutationService = require(script.Parent.MutationService)
end

function CodeService.List(): { string }
	local out: { string } = {}
	local seen: { [string]: boolean } = {}
	for code, _ in pairs((Config.REDEMPTION_CODES or {}) :: any) do
		if not seen[code] then table.insert(out, code); seen[code] = true end
	end
	for code, _ in pairs(runtimeCodes) do
		if not seen[code] then table.insert(out, code .. " (runtime)"); seen[code] = true end
	end
	table.sort(out)
	return out
end

function CodeService.AddRuntime(code: string, cashAmount: number)
	runtimeCodes[string.upper(code)] = { kind = "cash", amount = cashAmount }
end

return CodeService
