--!strict
--[[
	SoundController — registers the SFX library. Asset IDs are placeholders;
	swap them in Studio (or upload your own audio) for full meme effect.
	The README lists known meme audio asset IDs that play well here.
]]

local SoundService = game:GetService("SoundService")

local SoundController = {}

local function mkSound(name: string, assetId: string?, volume: number)
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = assetId or ""
	s.Volume = volume
	s.Parent = SoundService
end

function SoundController.Init()
	mkSound("MutationPop", "rbxassetid://6895079853", 0.6) -- generic pop, replaceable
	mkSound("Capture",     "rbxassetid://5153734667", 0.8)
	mkSound("Steal",       "rbxassetid://5273593909", 0.9)
	mkSound("Infect",      "rbxassetid://3120909354", 0.7)
	mkSound("Outbreak",    "rbxassetid://9120420410", 0.9)
end

return SoundController
