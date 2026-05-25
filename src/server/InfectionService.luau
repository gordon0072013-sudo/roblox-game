--!strict
--[[
	InfectionService — the second PvP novelty. Attacker spends one
	Infection Bomb to debuff a victim's whole income for INFECTION_DEBUFF_DURATION.
	The visual is a green smoke cloud over the victim's plot.

	Bombs come from: (a) starter grant, (b) daily reward, (c) dev product purchase.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local LabService = require(script.Parent.LabService)
local BattlePassService -- forward

local InfectionService = {}

local function playInfectionVfx(plotId: number)
	local plot = LabService.GetPlot(plotId)
	if not plot then return end
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = Vector3.new(1,1,1)
	part.Position = plot.center + Vector3.new(0, 30, 0)
	part.Parent = Workspace
	local smoke = Instance.new("Smoke")
	smoke.Color = Color3.fromRGB(80, 220, 80)
	smoke.Size = 40
	smoke.Opacity = 0.7
	smoke.RiseVelocity = 5
	smoke.Parent = part
	task.delay(10, function() part:Destroy() end)
end

function InfectionService.AddBombs(player: Player, count: number)
	local data = DataService.Get(player)
	if not data then return end
	data.infectionBombs += count
	EconomyService.PushHud(player)
end

function InfectionService.GrantInfectionBomb(player: Player, count: number)
	InfectionService.AddBombs(player, count)
end

function InfectionService.AttemptInfect(attacker: Player, victimUserId: number)
	if attacker.UserId == victimUserId then
		Remotes.Event(Remotes.Names.Notify):FireClient(attacker, { kind="error", text="Cannot infect yourself." })
		return
	end
	local atkData = DataService.Get(attacker)
	if not atkData then return end
	if atkData.infectionBombs <= 0 then
		Remotes.Event(Remotes.Names.Notify):FireClient(attacker, { kind="error", text="Out of Infection Bombs — buy more in the shop." })
		return
	end
	local victim = Players:GetPlayerByUserId(victimUserId)
	if not victim then return end
	local victimData = DataService.Get(victim)
	if not victimData then return end

	atkData.infectionBombs -= 1
	victimData.infectedUntil = math.max(victimData.infectedUntil, os.time()) + Config.INFECTION_DEBUFF_DURATION
	atkData.stats.totalInfections += 1
	if BattlePassService then BattlePassService.AwardXp(attacker, "infection") end

	local victimPlot = LabService.GetPlotIdForPlayer(victim)
	if victimPlot then playInfectionVfx(victimPlot) end

	EconomyService.PushHud(attacker)
	EconomyService.PushHud(victim)

	Remotes.Event(Remotes.Names.Notify):FireClient(attacker, {
		kind="capture", text=`Infected ${victim.DisplayName}!`,
	})
	Remotes.Event(Remotes.Names.Notify):FireClient(victim, {
		kind="error", text=`${attacker.DisplayName} infected your lab! Income reduced.`,
	})
end

function InfectionService.Init()
	BattlePassService = require(script.Parent.BattlePassService)
end

return InfectionService
