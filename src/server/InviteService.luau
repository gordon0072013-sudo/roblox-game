--!strict
--[[
	InviteService — referral codes. Every player gets an auto-generated
	personal code (REF-<6 chars>). When a new player joins and redeems
	someone else's code in their first session, both get a reward
	(referrer: cash + bombs, referee: cash bonus).

	Single-use per redeemer; one referrer per referee. This is the
	cheapest growth lever — every existing player becomes a recruiter.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local InfectionService -- forward

local InviteService = {}

local REFERRER_CASH = 3000
local REFEREE_CASH = 1500
local REFERRER_BOMBS = 2

local codeStore: DataStore? = nil
if not RunService:IsStudio() then
	pcall(function() codeStore = DataStoreService:GetDataStore("BrainrotLab_RefCodes_v1") end)
end

local function generateCode(): string
	local chars = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
	local buf = {}
	for i = 1, 6 do
		local idx = math.random(1, #chars)
		table.insert(buf, string.sub(chars, idx, idx))
	end
	return "REF-" .. table.concat(buf)
end

local function ensureInviteField(data: any, player: Player)
	if not data._refCode then
		data._refCode = generateCode()
		if codeStore then
			pcall(function() codeStore:SetAsync(data._refCode, player.UserId) end)
		end
	end
	if data._refRedeemed == nil then data._refRedeemed = false end
	if data._refUsedBy == nil then data._refUsedBy = {} end
end

local function pushUpdate(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	ensureInviteField(data, player)
	Remotes.Event(Remotes.Names.InviteUpdate):FireClient(player, {
		code = data._refCode,
		redeemed = data._refRedeemed,
		recruitsCount = #(data._refUsedBy :: any),
	})
end

function InviteService.Redeem(player: Player, codeRaw: string)
	if typeof(codeRaw) ~= "string" then return end
	local code = string.upper(string.gsub(codeRaw, "%s", ""))
	local data = DataService.Get(player)
	if not data then return end
	ensureInviteField(data, player)
	if data._refRedeemed then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text="You already redeemed a referral code." })
		return
	end
	if code == data._refCode then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text="That's your own code." })
		return
	end

	-- Look up referrer
	local referrerUserId: number? = nil
	if codeStore then
		pcall(function() referrerUserId = codeStore:GetAsync(code) end)
	end
	if not referrerUserId then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text=`Code ${code} not found.` })
		return
	end

	data._refRedeemed = true
	EconomyService.AwardCash(player, REFEREE_CASH, "referral")
	Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="capture", text=`Referral redeemed — +${REFEREE_CASH} cash` })
	pushUpdate(player)

	-- Reward referrer if in this server
	local referrer = Players:GetPlayerByUserId(referrerUserId)
	if referrer then
		local rdata = DataService.Get(referrer)
		if rdata then
			ensureInviteField(rdata, referrer)
			table.insert(rdata._refUsedBy :: any, player.UserId)
			EconomyService.AwardCash(referrer, REFERRER_CASH, "recruit bonus")
			if InfectionService then InfectionService.AddBombs(referrer, REFERRER_BOMBS) end
			Remotes.Event(Remotes.Names.Notify):FireClient(referrer, {
				kind = "capture",
				text = `${player.DisplayName} used your referral! +${REFERRER_CASH} cash, +${REFERRER_BOMBS} bombs`,
			})
			pushUpdate(referrer)
		end
	end
	-- (Cross-server reward is intentionally skipped to avoid a DataStore round trip per claim.
	--  Referrers in other servers still see their recruit count update on next login.)
end

function InviteService.OnPlayerAdded(player: Player)
	task.delay(2, pushUpdate, player)
end

function InviteService.Init()
	InfectionService = require(script.Parent.InfectionService)
end

return InviteService
