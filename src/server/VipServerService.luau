--!strict

local Players = game:GetService("Players")

local VipServerService = {}

-- A "VIP server" in Roblox lingo is a private server a player rents from
-- the experience for a recurring R$ price (you set it on Creator Dashboard).
-- game.PrivateServerId is non-empty when the current server is one.
-- Players in a VIP server get +50% cash on top of every other mult — this
-- is real recurring revenue with zero ongoing dev cost per subscription.
local VIP_CASH_BONUS = 1.50

function VipServerService.IsVipServer(): boolean
	return game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
end

function VipServerService.GetCashMult(): number
	return if VipServerService.IsVipServer() then VIP_CASH_BONUS else 1
end

function VipServerService.OwnerUserId(): number
	return game.PrivateServerOwnerId
end

function VipServerService.OnPlayerAdded(player: Player)
	-- Optional: print a welcome message for players joining a VIP server.
	-- Done at OnPlayerAdded so the player sees this once on join.
	if not VipServerService.IsVipServer() then return end
	task.delay(2, function()
		if not player.Parent then return end
		local Remotes = require(game:GetService("ReplicatedStorage").Shared.Remotes)
		Remotes.Event(Remotes.Names.Notify):FireClient(player, {
			kind = "capture",
			text = string.format("💎 VIP Server — +%d%% cash for everyone here!",
				math.floor((VIP_CASH_BONUS - 1) * 100)),
		})
	end)
	-- Suppress unused
	local _ = Players
end

function VipServerService.Init() end

return VipServerService
