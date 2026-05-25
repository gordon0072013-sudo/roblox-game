--!strict

local Players           = game:GetService("Players")
local SocialService     = game:GetService("SocialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Log     = require(Shared.Log)

local SocialInviteService = {}

function SocialInviteService.CanInvite(player: Player): boolean
	local ok, can = pcall(function()
		return SocialService:CanSendGameInviteAsync(player)
	end)
	return ok and can or false
end

function SocialInviteService.Prompt(player: Player)
	local can = SocialInviteService.CanInvite(player)
	if not can then
		Remotes.Event(Remotes.Names.Notify):FireClient(player, {
			kind = "error",
			text = "Invites unavailable in this session — try from the Roblox app on mobile.",
		})
		return
	end
	local ok, err = pcall(function()
		SocialService:PromptGameInvite(player)
	end)
	if not ok then
		Log.Warn("Social", "PromptGameInvite failed for %s: %s", player.Name, tostring(err))
	end
end

function SocialInviteService.Init() end

return SocialInviteService
