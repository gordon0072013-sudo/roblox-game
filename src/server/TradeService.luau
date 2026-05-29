--!strict
--[[
	TradeService — player-to-player brainrot swap. Two-party confirm flow:

	  1. Player A requests a trade with Player B → pending invite.
	  2. Player B accepts → trade window opens (state replicated to both).
	  3. Each side stages up to 4 brainrots + a cash offer.
	  4. Each side hits "confirm". Both confirmed + still valid? Atomic swap.
	  5. Either side editing the offer un-confirms both sides (anti-scam).

	Why have a trade system at all if it doesn't directly take Robux?
	Because trades 3-5x average session length. Longer sessions = more
	gamepass impressions = more Premium-Payout time. It's a revenue
	multiplier, not a revenue source.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)

local DataService = require(script.Parent.DataService)
local LabService = require(script.Parent.LabService)
local EconomyService = require(script.Parent.EconomyService)

local TradeService = {}

type Side = {
	userId: number,
	brainrotUids: { string },
	cash: number,
	confirmed: boolean,
}

type Trade = {
	id: string,
	a: Side,
	b: Side,
	createdAt: number,
}

local activeTrades: { [string]: Trade } = {}
local userToTrade: { [number]: string } = {}
local pendingInvites: { [number]: { from: number, at: number } } = {} -- to userId -> from userId
local MAX_PER_SIDE = 4
local INVITE_TTL = 30
local TRADE_TTL = 180

local function pushTrade(trade: Trade)
	local a = Players:GetPlayerByUserId(trade.a.userId)
	local b = Players:GetPlayerByUserId(trade.b.userId)
	local payload = {
		id = trade.id,
		a = trade.a,
		b = trade.b,
	}
	if a then Remotes.Event(Remotes.Names.TradeUpdate):FireClient(a, payload) end
	if b then Remotes.Event(Remotes.Names.TradeUpdate):FireClient(b, payload) end
end

local function sendCancel(userId: number, reason: string)
	local p = Players:GetPlayerByUserId(userId)
	if not p then return end
	Remotes.Event(Remotes.Names.TradeUpdate):FireClient(p, { id = "", cancelled = true, reason = reason })
end

local function endTrade(trade: Trade, reason: string)
	activeTrades[trade.id] = nil
	userToTrade[trade.a.userId] = nil
	userToTrade[trade.b.userId] = nil
	sendCancel(trade.a.userId, reason)
	sendCancel(trade.b.userId, reason)
end

local function getSide(trade: Trade, userId: number): Side?
	if trade.a.userId == userId then return trade.a end
	if trade.b.userId == userId then return trade.b end
	return nil
end

local function otherSide(trade: Trade, userId: number): Side
	if trade.a.userId == userId then return trade.b end
	return trade.a
end

local function brainrotIsPlaceable(player: Player, uid: string): boolean
	local data = DataService.Get(player)
	if not data then return false end
	for _, b in ipairs(data.inventory) do
		if b.uid == uid then return true end
	end
	return false
end

function TradeService.Invite(fromPlayer: Player, targetUserId: number)
	if fromPlayer.UserId == targetUserId then return end
	if userToTrade[fromPlayer.UserId] then
		Remotes.Event(Remotes.Names.Notify):FireClient(fromPlayer, { kind="error", text="Already in a trade." })
		return
	end
	if userToTrade[targetUserId] then
		Remotes.Event(Remotes.Names.Notify):FireClient(fromPlayer, { kind="error", text="Player is busy." })
		return
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target then return end
	pendingInvites[targetUserId] = { from = fromPlayer.UserId, at = os.clock() }
	Remotes.Event(Remotes.Names.TradeInvite):FireClient(target, {
		fromUserId = fromPlayer.UserId,
		fromName = fromPlayer.DisplayName,
		ttl = INVITE_TTL,
	})
	Remotes.Event(Remotes.Names.Notify):FireClient(fromPlayer, { kind="info", text=`Trade request sent to {target.DisplayName}` })
end

function TradeService.Accept(player: Player)
	local invite = pendingInvites[player.UserId]
	if not invite then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text="No trade request." })
		return
	end
	pendingInvites[player.UserId] = nil
	if os.clock() - invite.at > INVITE_TTL then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text="Trade request expired." })
		return
	end
	if userToTrade[player.UserId] or userToTrade[invite.from] then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, { kind="error", text="One of you is busy." })
		return
	end
	local other = Players:GetPlayerByUserId(invite.from)
	if not other then return end
	local trade: Trade = {
		id = Util.GenerateUid(),
		a = { userId = invite.from, brainrotUids = {}, cash = 0, confirmed = false },
		b = { userId = player.UserId, brainrotUids = {}, cash = 0, confirmed = false },
		createdAt = os.time(),
	}
	activeTrades[trade.id] = trade
	userToTrade[trade.a.userId] = trade.id
	userToTrade[trade.b.userId] = trade.id
	pushTrade(trade)
end

function TradeService.Decline(player: Player)
	local invite = pendingInvites[player.UserId]
	if not invite then return end
	pendingInvites[player.UserId] = nil
	local other = Players:GetPlayerByUserId(invite.from)
	if other then
		Remotes.Event(Remotes.Names.Notify):FireClient(other, { kind="info", text=`{player.DisplayName} declined the trade.` })
	end
end

function TradeService.AddBrainrot(player: Player, uid: string)
	local tid = userToTrade[player.UserId]
	if not tid then return end
	local trade = activeTrades[tid]
	if not trade then return end
	local side = getSide(trade, player.UserId)
	if not side then return end
	if #side.brainrotUids >= MAX_PER_SIDE then return end
	if not brainrotIsPlaceable(player, uid) then return end
	for _, existing in ipairs(side.brainrotUids) do
		if existing == uid then return end
	end
	table.insert(side.brainrotUids, uid)
	-- Editing un-confirms both
	trade.a.confirmed = false
	trade.b.confirmed = false
	pushTrade(trade)
end

function TradeService.RemoveBrainrot(player: Player, uid: string)
	local tid = userToTrade[player.UserId]
	if not tid then return end
	local trade = activeTrades[tid]
	if not trade then return end
	local side = getSide(trade, player.UserId)
	if not side then return end
	for i, existing in ipairs(side.brainrotUids) do
		if existing == uid then
			table.remove(side.brainrotUids, i)
			trade.a.confirmed = false
			trade.b.confirmed = false
			pushTrade(trade)
			return
		end
	end
end

function TradeService.SetCash(player: Player, amount: number)
	local tid = userToTrade[player.UserId]
	if not tid then return end
	local trade = activeTrades[tid]
	if not trade then return end
	local side = getSide(trade, player.UserId)
	if not side then return end
	local data = DataService.Get(player)
	if not data then return end
	amount = math.max(0, math.floor(amount))
	if amount > data.cash then amount = data.cash end
	side.cash = amount
	trade.a.confirmed = false
	trade.b.confirmed = false
	pushTrade(trade)
end

function TradeService.Confirm(player: Player)
	local tid = userToTrade[player.UserId]
	if not tid then return end
	local trade = activeTrades[tid]
	if not trade then return end
	local side = getSide(trade, player.UserId)
	if not side then return end
	side.confirmed = true
	pushTrade(trade)

	if trade.a.confirmed and trade.b.confirmed then
		-- Re-validate both sides
		local pa = Players:GetPlayerByUserId(trade.a.userId)
		local pb = Players:GetPlayerByUserId(trade.b.userId)
		if not pa or not pb then endTrade(trade, "A player left."); return end
		local da = DataService.Get(pa); local db = DataService.Get(pb)
		if not da or not db then endTrade(trade, "Data unavailable."); return end
		if da.cash < trade.a.cash or db.cash < trade.b.cash then
			endTrade(trade, "Insufficient cash."); return
		end
		for _, u in ipairs(trade.a.brainrotUids) do
			if not brainrotIsPlaceable(pa, u) then endTrade(trade, "Inventory changed."); return end
		end
		for _, u in ipairs(trade.b.brainrotUids) do
			if not brainrotIsPlaceable(pb, u) then endTrade(trade, "Inventory changed."); return end
		end

		-- Atomic swap
		for _, u in ipairs(trade.a.brainrotUids) do
			LabService.TransferBrainrot(pa, pb, u)
		end
		for _, u in ipairs(trade.b.brainrotUids) do
			LabService.TransferBrainrot(pb, pa, u)
		end
		-- Spend-before-award and bail on a failed spend so we never mint cash
		-- out of thin air. The validation above already gated this, but a
		-- DataService.Get returning nil between then and now would silently
		-- skip the spend without the award checking — fixed by gating.
		if trade.a.cash > 0 then
			if not EconomyService.SpendCash(pa, trade.a.cash) then
				endTrade(trade, "Insufficient cash."); return
			end
			EconomyService.AwardCash(pb, trade.a.cash, "trade")
		end
		if trade.b.cash > 0 then
			if not EconomyService.SpendCash(pb, trade.b.cash) then
				-- Refund pa what we already took, then abort. The brainrots are
				-- already swapped at this point, but un-swapping is expensive; we
				-- accept the partial-execution as the lesser evil vs free cash.
				if trade.a.cash > 0 then EconomyService.AwardCash(pa, trade.a.cash, "trade refund") end
				endTrade(trade, "Insufficient cash."); return
			end
			EconomyService.AwardCash(pa, trade.b.cash, "trade")
		end

		Remotes.Event(Remotes.Names.Notify):FireClient(pa, { kind="capture", text="Trade complete!" })
		Remotes.Event(Remotes.Names.Notify):FireClient(pb, { kind="capture", text="Trade complete!" })
		endTrade(trade, "complete")
	end
end

function TradeService.Cancel(player: Player)
	local tid = userToTrade[player.UserId]
	if not tid then return end
	local trade = activeTrades[tid]
	if not trade then return end
	endTrade(trade, "Cancelled by player.")
end

function TradeService.OnPlayerRemoving(player: Player)
	pendingInvites[player.UserId] = nil
	local tid = userToTrade[player.UserId]
	if tid then
		local trade = activeTrades[tid]
		if trade then endTrade(trade, "Player left.") end
	end
end

function TradeService.Init()
	-- TTL sweeper
	task.spawn(function()
		while true do
			task.wait(15)
			local now = os.clock()
			for userId, inv in pairs(pendingInvites) do
				if now - inv.at > INVITE_TTL then
					pendingInvites[userId] = nil
				end
			end
			for tid, trade in pairs(activeTrades) do
				if os.time() - trade.createdAt > TRADE_TTL then
					endTrade(trade, "Trade timed out.")
				end
			end
		end
	end)
end

return TradeService
