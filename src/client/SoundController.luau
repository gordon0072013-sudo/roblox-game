--!strict
--[[
	SoundController — registers the SFX library. Asset IDs are placeholders;
	swap them in Studio (or upload your own audio) for full meme effect.
	The README lists known meme audio asset IDs that play well here.
]]

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local SoundController = {}

local function mkSound(name: string, assetId: string?, volume: number)
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = assetId or ""
	s.Volume = volume
	s.Parent = SoundService
end

local function play(name: string)
	local s = SoundService:FindFirstChild(name) :: Sound?
	if s then s:Play() end
end

function SoundController.Init()
	mkSound("MutationPop", "rbxassetid://6895079853", 0.6) -- generic pop, replaceable
	mkSound("Capture",     "rbxassetid://5153734667", 0.8)
	mkSound("Steal",       "rbxassetid://5273593909", 0.9)
	mkSound("Infect",      "rbxassetid://3120909354", 0.7)
	mkSound("Outbreak",    "rbxassetid://9120420410", 0.9)

	-- Map server-fired Notify toasts to sound effects.
	Remotes.Event(Remotes.Names.Notify).OnClientEvent:Connect(function(payload)
		if not payload or typeof(payload) ~= "table" then return end
		local kind = payload.kind
		local text = tostring(payload.text or "")
		if kind == "mutation" then play("MutationPop")
		elseif kind == "capture" then
			if string.find(text, "STOLE") or string.find(text, "Stole") then play("Steal")
			elseif string.find(text, "Infected") or string.find(text, "infected") then play("Infect")
			elseif string.find(text, "OUTBREAK") then play("Outbreak")
			else play("Capture") end
		elseif kind == "rebirth" then play("MutationPop")
		end
	end)

	-- Outbreak start fanfare
	Remotes.Event(Remotes.Names.OutbreakUpdate).OnClientEvent:Connect(function(payload)
		if payload and payload.active and payload.secondsLeft and payload.secondsLeft > 175 then
			play("Outbreak")
		end
	end)
end

return SoundController
