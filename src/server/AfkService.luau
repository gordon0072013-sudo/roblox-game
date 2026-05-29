--!strict
--[[
	AfkService — soft-kicks players idle for >20 minutes. With only 8 plots
	per server, an AFK farmer occupies a slot a real new joiner could fill.
	Real joiners are 100x more valuable for revenue than AFK farmers, so
	prioritize them.

	Detection: any character movement, chat, or input resets the timer.
	30s before kick: a warning toast. On kick: a polite "rejoin anytime"
	kick reason that doesn't damage NPS.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local AfkService = {}

local IDLE_KICK_SECONDS = 1200 -- 20 min
local WARN_SECONDS = 30

local lastActive: { [Player]: number } = {}
local warned: { [Player]: boolean } = {}

local function bumpActivity(player: Player)
	lastActive[player] = os.clock()
	warned[player] = false
end

function AfkService.OnPlayerAdded(player: Player)
	bumpActivity(player)
	player.Chatted:Connect(function() bumpActivity(player) end)
	player.CharacterAdded:Connect(function(char)
		bumpActivity(player)
		local humanoid = char:WaitForChild("Humanoid", 5) :: Humanoid?
		if humanoid then
			humanoid.Running:Connect(function(speed) if speed > 0.5 then bumpActivity(player) end end)
			humanoid.Jumping:Connect(function() bumpActivity(player) end)
		end
	end)
	if player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Running:Connect(function(speed) if speed > 0.5 then bumpActivity(player) end end)
		end
	end
end

function AfkService.OnPlayerRemoving(player: Player)
	lastActive[player] = nil
	warned[player] = nil
end

function AfkService.Init()
	task.spawn(function()
		while true do
			task.wait(10)
			-- Snapshot before iterating because player:Kick fires PlayerRemoving
			-- synchronously, which clears lastActive[player] mid-pairs — Lua's
			-- behavior for "set existing key to nil during pairs()" is undefined
			-- and can skip later entries.
			local toKick: { Player } = {}
			for player, ts in pairs(lastActive) do
				local idle = os.clock() - ts
				if idle >= IDLE_KICK_SECONDS then
					table.insert(toKick, player)
				elseif idle >= IDLE_KICK_SECONDS - WARN_SECONDS and not warned[player] then
					warned[player] = true
					Remotes.Event(Remotes.Names.Notify):FireClient(player, {
						kind = "error",
						text = `AFK kick in {WARN_SECONDS}s — move to reset.`,
					})
				end
			end
			for _, player in ipairs(toKick) do
				player:Kick("AFK kick after 20 min — rejoin anytime to keep your progress!")
			end
		end
	end)

	-- Hook every server-bound request as an activity signal
	for _, n in pairs(Remotes.Names) do
		local r = Remotes.Event(n)
		if r:IsA("RemoteEvent") then
			r.OnServerEvent:Connect(function(player) bumpActivity(player) end)
		end
	end
end

return AfkService
