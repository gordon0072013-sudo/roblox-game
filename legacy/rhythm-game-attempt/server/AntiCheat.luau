--!strict

local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Config  = require(Shared.Config)
local Log     = require(Shared.Log)

local AntiCheat = {}

-- Sliding-window rate limits per remote. Values picked to comfortably exceed
-- normal play but reject scripted spam.
local RATE_LIMITS: { [string]: { window: number, max: number } } = {
	RequestSongList         = { window = 2.0,  max = 4   },
	RequestPlaySong         = { window = 2.0,  max = 2   },
	RequestHit              = { window = 1.0,  max = math.ceil(Config.MAX_HIT_RATE_PER_SECOND * 1.4) },
	RequestQuit             = { window = 1.0,  max = 2   },
	RequestPromptPurchase   = { window = 1.0,  max = 3   },
	RequestClaimDaily       = { window = 5.0,  max = 1   },
}

local VIOLATION_KICK_THRESHOLD = 8
local VIOLATION_DECAY_SECONDS  = 60

local POSITION_SAMPLE_INTERVAL = 0.5
local MAX_HORIZONTAL_SPEED     = 36
local MAX_VERTICAL_SPEED       = 100
local TELEPORT_THRESHOLD_STUDS = 80
local WORLD_BOUNDS             = { x = 4096, y = 2048, z = 4096 }

type RateBucket = { startedAt: number, count: number }
type PlayerRecord = {
	rateBuckets:        { [string]: RateBucket },
	lastPosition:       Vector3?,
	lastPositionAt:     number,
	violations:         number,
	violationsDecayedAt:number,
	flagLog:            { { tag: string, detail: string, at: number } },
	sessionId:          string,
}

local records: { [Player]: PlayerRecord } = {}
local listeners: { (Player, string, string, number) -> () } = {}

local function record(player: Player): PlayerRecord
	local r = records[player]
	if r then return r end
	r = {
		rateBuckets         = {},
		lastPosition        = nil,
		lastPositionAt      = os.clock(),
		violations          = 0,
		violationsDecayedAt = os.clock(),
		flagLog             = {},
		sessionId           = HttpService:GenerateGUID(false),
	}
	records[player] = r
	return r
end

local function notifyListeners(player: Player, tag: string, detail: string, severity: number)
	for _, cb in ipairs(listeners) do task.spawn(cb, player, tag, detail, severity) end
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
		player:Kick(string.format("Disconnected: anti-cheat (%s)", tag))
	end
end

function AntiCheat.OnViolation(cb: (Player, string, string, number) -> ())
	table.insert(listeners, cb)
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
			string.format("%s > %d/%.1fs", remoteName, limit.max, limit.window), 1)
		return false
	end
	return true
end

local SANITIZE_MAX_NUMBER = 1e12
local SANITIZE_MAX_STRING = 64

function AntiCheat.SanitizeNumber(player: Player, value: any, context: string): number?
	if typeof(value) ~= "number" then
		flag(player, "BadArg", `${context}: expected number, got ${typeof(value)}`, 2); return nil
	end
	if value ~= value or value == math.huge or value == -math.huge then
		flag(player, "BadArg", `${context}: NaN/inf`, 2); return nil
	end
	if math.abs(value) > SANITIZE_MAX_NUMBER then
		flag(player, "BadArg", `${context}: out of range`, 2); return nil
	end
	return value
end

function AntiCheat.SanitizeString(player: Player, value: any, context: string, maxLen: number?): string?
	if typeof(value) ~= "string" then
		flag(player, "BadArg", `${context}: expected string, got ${typeof(value)}`, 2); return nil
	end
	local cap = maxLen or SANITIZE_MAX_STRING
	if #value > cap then
		flag(player, "BadArg", `${context}: string len ${#value} > ${cap}`, 2); return nil
	end
	return value
end

function AntiCheat.SanitizeUid(player: Player, value: any, context: string): string?
	local s = AntiCheat.SanitizeString(player, value, context, 32)
	if not s then return nil end
	if not string.match(s, "^[%w%-_]+$") then
		flag(player, "BadArg", `${context}: invalid uid`, 2); return nil
	end
	return s
end

function AntiCheat.Flag(player: Player, tag: string, detail: string, severity: number)
	flag(player, tag, detail, severity)
end

local function checkPosition(player: Player)
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
		local horiz = math.sqrt(delta.X * delta.X + delta.Z * delta.Z)
		local vert  = math.abs(delta.Y)
		if horiz > TELEPORT_THRESHOLD_STUDS then
			flag(player, "Teleport", string.format("dx=%.1f in %.2fs", horiz, dt), 2)
		elseif horiz / dt > MAX_HORIZONTAL_SPEED then
			flag(player, "SpeedHack", string.format("h=%.1f s/s", horiz / dt), 1)
		end
		if vert / dt > MAX_VERTICAL_SPEED then
			flag(player, "VerticalSpeed", string.format("v=%.1f s/s", vert / dt), 1)
		end
	end
	r.lastPosition = pos
	r.lastPositionAt = now

	if now - r.violationsDecayedAt >= VIOLATION_DECAY_SECONDS and r.violations > 0 then
		r.violations = math.max(0, r.violations - 1)
		r.violationsDecayedAt = now
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
		local r = records[player]; if r then r.lastPosition = nil end
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
		if not ok then Log.Error("AntiCheat", "handler %s errored: %s", name, tostring(err)) end
	end)
end

function AntiCheat.Snapshot(): { [string]: any }
	local out = {}
	for player, r in pairs(records) do
		out[player.Name] = { violations = r.violations, flags = r.flagLog, sessionId = r.sessionId }
	end
	return out
end

function AntiCheat.Init()
	if RunService:IsClient() then return end
	task.spawn(function()
		while true do
			task.wait(POSITION_SAMPLE_INTERVAL)
			for _, p in ipairs(Players:GetPlayers()) do checkPosition(p) end
		end
	end)
	local _ = Remotes
end

return AntiCheat
