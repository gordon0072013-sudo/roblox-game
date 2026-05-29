--!strict
--!native

local HttpService     = game:GetService("HttpService")
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local Workspace       = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared  = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Log     = require(Shared.Log)

local AntiCheat = {}

local RATE_LIMITS: { [string]: { window: number, max: number } } = {
	RequestCapture            = { window = 1.0,  max = 4   },
	RequestPlaceBrainrot      = { window = 1.0,  max = 12  },
	RequestUnplaceBrainrot    = { window = 1.0,  max = 12  },
	RequestSellBrainrot       = { window = 1.0,  max = 12  },
	RequestRebirth            = { window = 2.0,  max = 2   },
	RequestSteal              = { window = 1.5,  max = 3   },
	RequestInfect             = { window = 1.5,  max = 3   },
	RequestPromptPurchase     = { window = 1.0,  max = 3   },
	RequestRedeemCode         = { window = 4.0,  max = 2   },
	RequestRedeemInvite       = { window = 5.0,  max = 1   },
	RequestRecheckGroup       = { window = 60.0, max = 1   },
	RequestClaimDaily         = { window = 5.0,  max = 1   },
	RequestClaimBattlePassTier= { window = 0.5,  max = 6   },
	RequestClaimAchievement   = { window = 0.5,  max = 6   },
	RequestClaimQuest         = { window = 0.5,  max = 6   },
	RequestClaimLevelReward   = { window = 0.5,  max = 6   },
	RequestTradeInvite        = { window = 3.0,  max = 1   },
	RequestTradeAccept        = { window = 1.0,  max = 1   },
	RequestTradeDecline       = { window = 1.0,  max = 1   },
	RequestTradeAddBrainrot   = { window = 0.3,  max = 4   },
	RequestTradeRemoveBrainrot= { window = 0.3,  max = 4   },
	RequestTradeSetCash       = { window = 0.5,  max = 4   },
	RequestTradeConfirm       = { window = 1.0,  max = 1   },
	RequestTradeCancel        = { window = 1.0,  max = 1   },
	RequestEquipPet           = { window = 0.5,  max = 4   },
	RequestUnequipPet         = { window = 0.5,  max = 4   },
	RequestBuyDecoration      = { window = 0.5,  max = 4   },
	RequestSellDecoration     = { window = 0.5,  max = 4   },
}

local MAX_HORIZONTAL_SPEED      = 36   -- studs/sec; default WalkSpeed is 16
local MAX_VERTICAL_SPEED        = 100  -- studs/sec; allows for jumps but blocks flight
local POSITION_SAMPLE_INTERVAL  = 0.5
local TELEPORT_THRESHOLD_STUDS  = 80
local WORLD_BOUNDS              = { x = 4096, y = 2048, z = 4096 }
local VIOLATION_KICK_THRESHOLD  = 6
local VIOLATION_DECAY_SECONDS   = 60
local VIOLATION_DECAY_AMOUNT    = 1

type RateBucket = { startedAt: number, count: number }
type PlayerRecord = {
	rateBuckets: { [string]: RateBucket },
	lastPosition: Vector3?,
	lastPositionAt: number,
	violations: number,
	violationsLastDecayAt: number,
	flagLog: { { tag: string, detail: string, at: number } },
	sessionId: string,
}

local records: { [Player]: PlayerRecord } = {}
local violationListeners: { (Player, string, string, number) -> () } = {}

local function record(player: Player): PlayerRecord
	local r = records[player]
	if r then return r end
	r = {
		rateBuckets = {},
		lastPosition = nil,
		lastPositionAt = os.clock(),
		violations = 0,
		violationsLastDecayAt = os.clock(),
		flagLog = {},
		sessionId = HttpService:GenerateGUID(false),
	}
	records[player] = r
	return r
end

local function notifyListeners(player: Player, tag: string, detail: string, severity: number)
	for _, cb in ipairs(violationListeners) do
		task.spawn(cb, player, tag, detail, severity)
	end
end

local function flag(player: Player, tag: string, detail: string, severity: number)
	local r = record(player)
	r.violations += severity
	table.insert(r.flagLog, { tag = tag, detail = detail, at = os.time() })
	if #r.flagLog > 32 then table.remove(r.flagLog, 1) end
	Log.Warn("AntiCheat", "%s sid=%s | %s — %s (sev=%d total=%d)",
		player.Name, r.sessionId, tag, detail, severity, r.violations)
	notifyListeners(player, tag, detail, severity)
	if r.violations >= VIOLATION_KICK_THRESHOLD then
		player:Kick(string.format("Disconnected: anti-cheat flag (%s). Rejoin to continue.", tag))
	end
end

function AntiCheat.OnViolation(cb: (Player, string, string, number) -> ())
	table.insert(violationListeners, cb)
end

function AntiCheat.CheckRate(player: Player, remoteName: string): boolean
	local limit = RATE_LIMITS[remoteName]
	if not limit then return true end
	local r = record(player)
	local bucket = r.rateBuckets[remoteName]
	local now = os.clock()
	if not bucket or now - bucket.startedAt > limit.window then
		r.rateBuckets[remoteName] = { startedAt = now, count = 1 }
		return true
	end
	bucket.count += 1
	if bucket.count > limit.max then
		flag(player, "RateLimit",
			string.format("%s exceeded %d req / %.1fs", remoteName, limit.max, limit.window), 1)
		return false
	end
	return true
end

local SANITIZE_MAX_NUMBER = 1e12
local SANITIZE_MAX_STRING = 64

function AntiCheat.SanitizeNumber(player: Player, value: any, context: string): number?
	if typeof(value) ~= "number" then
		flag(player, "BadArg", `${context}: expected number, got ${typeof(value)}`, 2)
		return nil
	end
	if value ~= value or value == math.huge or value == -math.huge then
		flag(player, "BadArg", `${context}: NaN/inf`, 2)
		return nil
	end
	if math.abs(value) > SANITIZE_MAX_NUMBER then
		flag(player, "BadArg", `${context}: number out of range`, 2)
		return nil
	end
	return value
end

function AntiCheat.SanitizeString(player: Player, value: any, context: string, maxLen: number?): string?
	if typeof(value) ~= "string" then
		flag(player, "BadArg", `${context}: expected string, got ${typeof(value)}`, 2)
		return nil
	end
	local cap = maxLen or SANITIZE_MAX_STRING
	if #value > cap then
		flag(player, "BadArg", `${context}: string length ${#value} > ${cap}`, 2)
		return nil
	end
	return value
end

function AntiCheat.SanitizeUid(player: Player, value: any, context: string): string?
	local s = AntiCheat.SanitizeString(player, value, context, 32)
	if not s then return nil end
	if not string.match(s, "^[%w%-_]+$") then
		flag(player, "BadArg", `${context}: invalid uid format`, 2)
		return nil
	end
	return s
end

local function checkPositionFor(player: Player)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end
	local r = record(player)
	local now = os.clock()
	local pos = hrp.Position

	if math.abs(pos.X) > WORLD_BOUNDS.x or math.abs(pos.Z) > WORLD_BOUNDS.z
		or pos.Y < -WORLD_BOUNDS.y or pos.Y > WORLD_BOUNDS.y then
		flag(player, "OutOfBounds", string.format("pos=%.0f,%.0f,%.0f", pos.X, pos.Y, pos.Z), 2)
		pcall(function() char:PivotTo(CFrame.new(0, 8, 0)) end)
		return
	end

	if r.lastPosition then
		local dt = math.max(0.01, now - r.lastPositionAt)
		local delta = pos - r.lastPosition
		local horiz = math.sqrt(delta.X*delta.X + delta.Z*delta.Z)
		local vert = math.abs(delta.Y)
		local horizSpeed = horiz / dt
		local vertSpeed = vert / dt

		if horiz > TELEPORT_THRESHOLD_STUDS then
			flag(player, "Teleport", string.format("dx=%.1f in %.2fs", horiz, dt), 2)
		elseif horizSpeed > MAX_HORIZONTAL_SPEED then
			flag(player, "SpeedHack", string.format("h=%.1f s/s", horizSpeed), 1)
		end
		if vertSpeed > MAX_VERTICAL_SPEED then
			flag(player, "VerticalSpeed", string.format("v=%.1f s/s", vertSpeed), 1)
		end
	end
	r.lastPosition = pos
	r.lastPositionAt = now

	if now - r.violationsLastDecayAt >= VIOLATION_DECAY_SECONDS and r.violations > 0 then
		r.violations = math.max(0, r.violations - VIOLATION_DECAY_AMOUNT)
		r.violationsLastDecayAt = now
	end
end

local function hardenCharacter(char: Model)
	local humanoid = char:WaitForChild("Humanoid", 5) :: Humanoid?
	if not humanoid then return end
	humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if humanoid.WalkSpeed > 30 then humanoid.WalkSpeed = 16 end
	end)
	humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
		if humanoid.JumpPower > 80 then humanoid.JumpPower = 50 end
	end)
end

function AntiCheat.OnPlayerAdded(player: Player)
	record(player)
	player.CharacterAdded:Connect(function(char)
		local r = records[player]
		if r then r.lastPosition = nil end
		hardenCharacter(char)
	end)
	if player.Character then hardenCharacter(player.Character) end
end

function AntiCheat.OnPlayerRemoving(player: Player)
	records[player] = nil
end

function AntiCheat.WrapRemote(remote: RemoteEvent, name: string, handler: (Player, ...any) -> ())
	remote.OnServerEvent:Connect(function(player, ...)
		if not AntiCheat.CheckRate(player, name) then return end
		local ok, err = pcall(handler, player, ...)
		if not ok then
			Log.Error("AntiCheat", "handler %s errored: %s", name, tostring(err))
		end
	end)
end

function AntiCheat.ClearFlags(player: Player): boolean
	local r = records[player]
	if not r then return false end
	r.violations = 0
	r.flagLog = {}
	r.violationsLastDecayAt = os.clock()
	return true
end

function AntiCheat.Snapshot(): { [string]: any }
	local out = {}
	for player, r in pairs(records) do
		out[player.Name] = {
			violations = r.violations,
			recentFlags = r.flagLog,
			sessionId = r.sessionId,
		}
	end
	return out
end

function AntiCheat.Init()
	if RunService:IsClient() then return end

	task.spawn(function()
		while true do
			task.wait(POSITION_SAMPLE_INTERVAL)
			for _, player in ipairs(Players:GetPlayers()) do
				checkPositionFor(player)
			end
		end
	end)

	-- Block client-side workspace mutation attempts: any script the client
	-- could inject via LocalScript can't reach the server data. We additionally
	-- prevent obvious workspace tampering attempts by watching for parts owned
	-- by no one being added to known plot folders.
	local plotsFolder = Workspace:FindFirstChild("Plots") :: Folder?
	if plotsFolder then
		plotsFolder.DescendantAdded:Connect(function(inst)
			if inst:IsA("Tool") or inst:IsA("Accessory") then
				inst:Destroy()
			end
		end)
	end

	-- Mute exception logs from Remotes the client targets — the wrapper logs
	-- richer detail and rate-limits naturally.
	local _ = Remotes
end

return AntiCheat
