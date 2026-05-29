--!strict

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config       = require(Shared.Config)
local Remotes      = require(Shared.Remotes)
local Log          = require(Shared.Log)
local BrainrotData = require(Shared.BrainrotData)

local DataService     = require(script.Parent.DataService)
local EconomyService  = require(script.Parent.EconomyService)
local CaptureService  = require(script.Parent.CaptureService)
local MutationService = require(script.Parent.MutationService)
local AntiCheat       = require(script.Parent.AntiCheat)

local AdminService = {}

-- ============================================================
-- AUTHORIZATION
-- ============================================================
-- Owner is auto-detected via game.CreatorId (works for both User-owned
-- and Group-owned experiences). Additional admin UserIds can be added
-- via Config.ADMIN_USER_IDS.

local function isOwner(userId: number): boolean
	if userId == game.CreatorId then return true end
	if game.CreatorType == Enum.CreatorType.Group then
		local ok, rank = pcall(function() return Players:GetPlayerByUserId(userId):GetRankInGroup(game.CreatorId) end)
		if ok and rank and rank >= 254 then return true end -- group owner / co-owner
	end
	return false
end

local function isAdmin(userId: number): boolean
	if isOwner(userId) then return true end
	for _, id in ipairs((Config :: any).ADMIN_USER_IDS or {}) do
		if id == userId then return true end
	end
	return false
end

function AdminService.IsAdmin(player: Player): boolean
	return isAdmin(player.UserId)
end

function AdminService.IsOwner(player: Player): boolean
	return isOwner(player.UserId)
end

-- ============================================================
-- COMMANDS
-- ============================================================

type Command = {
	name: string,
	usage: string,
	help: string,
	ownerOnly: boolean?,
	fn: (Player, { string }) -> string,
}

local commands: { Command } = {}

local function find(commands_: { Command }, name: string): Command?
	name = string.lower(name)
	for _, c in ipairs(commands_) do
		if c.name == name then return c end
	end
	return nil
end

local function findPlayer(query: string): Player?
	query = string.lower(query)
	for _, p in ipairs(Players:GetPlayers()) do
		if string.lower(p.Name) == query or string.lower(p.DisplayName) == query
			or string.lower(p.Name):sub(1, #query) == query then
			return p
		end
	end
	return nil
end

local function asNumber(s: string?): number?
	if not s then return nil end
	local n = tonumber(s)
	return if n == n and n ~= math.huge and n ~= -math.huge then n else nil
end

table.insert(commands, {
	name = "help",
	usage = "/help",
	help = "List commands.",
	fn = function(player, args)
		local list = {}
		for _, c in ipairs(commands) do
			table.insert(list, string.format("%s — %s", c.usage, c.help))
		end
		return "Commands:\n" .. table.concat(list, "\n")
	end,
})

table.insert(commands, {
	name = "give",
	usage = "/give <player> <amount>",
	help = "Give cash to a player (owner only).",
	ownerOnly = true,
	fn = function(player, args)
		local target = findPlayer(args[1] or "")
		local amount = asNumber(args[2])
		if not target or not amount then return "usage: /give <player> <amount>" end
		EconomyService.AwardCash(target, math.floor(amount), "admin grant")
		return string.format("granted %d cash to %s", math.floor(amount), target.Name)
	end,
})

table.insert(commands, {
	name = "rebirths",
	usage = "/rebirths <player> <count>",
	help = "Set a player's rebirth count.",
	ownerOnly = true,
	fn = function(player, args)
		local target = findPlayer(args[1] or "")
		local count  = asNumber(args[2])
		if not target or not count then return "usage: /rebirths <player> <count>" end
		local data = DataService.Get(target); if not data then return "no profile" end
		data.rebirths = math.max(0, math.floor(count))
		EconomyService.PushHud(target)
		return string.format("%s rebirths = %d", target.Name, data.rebirths)
	end,
})

table.insert(commands, {
	name = "give-brainrot",
	usage = "/give-brainrot <player> <speciesId>",
	help = "Give a player a specific brainrot. species id in BrainrotData.",
	ownerOnly = true,
	fn = function(player, args)
		local target = findPlayer(args[1] or "")
		local id = args[2]
		if not target or not id then return "usage: /give-brainrot <player> <speciesId>" end
		local def = BrainrotData.Get(id)
		if not def then return "unknown species: " .. id end
		CaptureService.GiveOutbreakBrainrot(target, id)
		return string.format("gave %s to %s", def.displayName, target.Name)
	end,
})

table.insert(commands, {
	name = "skip-outbreak",
	usage = "/skip-outbreak",
	help = "Trigger an Outbreak event immediately.",
	ownerOnly = true,
	fn = function()
		local OutbreakService = require(script.Parent.OutbreakService)
		if OutbreakService and (OutbreakService :: any).ForceStart then
			(OutbreakService :: any).ForceStart()
			return "outbreak forced"
		end
		return "outbreak service does not expose ForceStart yet"
	end,
})

table.insert(commands, {
	name = "spawn-boss",
	usage = "/spawn-boss",
	help = "Spawn the Mega Boss now.",
	ownerOnly = true,
	fn = function()
		local BossEventService = require(script.Parent.BossEventService)
		if BossEventService and (BossEventService :: any).ForceSpawn then
			(BossEventService :: any).ForceSpawn()
			return "boss forced"
		end
		return "boss service does not expose ForceSpawn yet"
	end,
})

table.insert(commands, {
	name = "mutate-all",
	usage = "/mutate-all <player>",
	help = "Force a mutation on every placed brainrot for a player.",
	ownerOnly = true,
	fn = function(player, args)
		local target = findPlayer(args[1] or "")
		if not target then return "usage: /mutate-all <player>" end
		local data = DataService.Get(target); if not data then return "no profile" end
		local n = 0
		for _, b in ipairs(data.inventory) do
			if b.placed then
				MutationService.ForceInstantMutation(target)
				n += 1
			end
		end
		return string.format("forced %d mutations on %s", n, target.Name)
	end,
})

table.insert(commands, {
	name = "tp",
	usage = "/tp <player> [targetPlayer|x,y,z]",
	help = "Teleport a player to another player or coordinates.",
	ownerOnly = true,
	fn = function(player, args)
		local target = findPlayer(args[1] or "")
		if not target or not target.Character then return "usage: /tp <player> <target|x,y,z>" end
		local dest = args[2]
		if not dest then return "missing destination" end
		local destPlayer = findPlayer(dest)
		if destPlayer and destPlayer.Character then
			target.Character:PivotTo(destPlayer.Character:GetPivot())
			return string.format("tp %s -> %s", target.Name, destPlayer.Name)
		end
		local x, y, z = string.match(dest, "(-?%d+%.?%d*),(-?%d+%.?%d*),(-?%d+%.?%d*)")
		if x then
			target.Character:PivotTo(CFrame.new(tonumber(x) :: number, tonumber(y) :: number, tonumber(z) :: number))
			return string.format("tp %s -> %s,%s,%s", target.Name, x, y, z)
		end
		return "could not resolve destination"
	end,
})

table.insert(commands, {
	name = "restart",
	usage = "/restart",
	help = "Shut down this server (BindToClose runs; players get the grace bonus).",
	ownerOnly = true,
	fn = function()
		task.delay(2, function()
			-- BindToClose handlers (GraceShutdownService + DataService) get
			-- the 30s window Roblox provides before hard-kill.
			for _, p in ipairs(Players:GetPlayers()) do
				p:Kick("Server restart — rejoin to continue. (Cash bonus delivered.)")
			end
		end)
		return "restart in 2s (clients get kick + grace bonus)"
	end,
})

table.insert(commands, {
	name = "cleanup",
	usage = "/cleanup",
	help = "Sweep orphaned debris (firework leftovers, lost parts).",
	ownerOnly = true,
	fn = function()
		local Workspace = game:GetService("Workspace")
		local protected = { Baseplate = true, Plots = true, Brainrots = true, OutbreakPlaza = true, BossArena = true, Terrain = true }
		local removed = 0
		for _, inst in ipairs(Workspace:GetChildren()) do
			if not protected[inst.Name] and not inst:IsA("Camera") and not inst:IsA("Terrain") then
				-- Don't sweep player characters
				local ok = true
				for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
					if inst == p.Character then ok = false; break end
				end
				if ok and (inst:IsA("BasePart") or inst:IsA("Model")) then
					inst:Destroy()
					removed += 1
				end
			end
		end
		return string.format("cleaned %d orphaned objects", removed)
	end,
})

table.insert(commands, {
	name = "spectate",
	usage = "/spectate <player|self>",
	help = "Lock the camera onto a target. 'self' to release.",
	ownerOnly = true,
	fn = function(player, args)
		local arg = args[1] or ""
		if arg == "" then return "usage: /spectate <player|self>" end
		if string.lower(arg) == "self" then
			Remotes.Event("Spectate"):FireClient(player, { kind = "release" })
			return "released spectate"
		end
		local target = findPlayer(arg)
		if not target then return "no such player" end
		Remotes.Event("Spectate"):FireClient(player, {
			kind = "attach",
			targetUserId = target.UserId,
			targetName = target.DisplayName,
		})
		return string.format("now spectating %s", target.Name)
	end,
})

table.insert(commands, {
	name = "inventory",
	usage = "/inventory <player>",
	help = "List a player's brainrots.",
	fn = function(player, args)
		local target = findPlayer(args[1] or "")
		if not target then return "usage: /inventory <player>" end
		local data = DataService.Get(target)
		if not data then return "no profile" end
		if #data.inventory == 0 then return target.Name .. " has no brainrots" end
		local lines = { target.Name .. " inventory:" }
		for _, b in ipairs(data.inventory) do
			local def = BrainrotData.Get(b.speciesId)
			local label = def and def.displayName or b.speciesId
			table.insert(lines, string.format("  %s [T%d] %s%s",
				label, b.mutationTier,
				b.placed and "(placed)" or "",
				#b.mutations > 0 and (" {" .. table.concat(b.mutations, ",") .. "}") or ""))
			if #lines > 20 then table.insert(lines, "  ...truncated"); break end
		end
		return table.concat(lines, "\n")
	end,
})

table.insert(commands, {
	name = "heal",
	usage = "/heal <player>",
	help = "Refill a player's character health.",
	ownerOnly = true,
	fn = function(player, args)
		local target = findPlayer(args[1] or "")
		if not target or not target.Character then return "usage: /heal <player>" end
		local hum = target.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return "no humanoid" end
		hum.Health = hum.MaxHealth
		return string.format("healed %s (%.0f/%.0f hp)", target.Name, hum.Health, hum.MaxHealth)
	end,
})

table.insert(commands, {
	name = "health",
	usage = "/health",
	help = "Run HealthCheckService probes now and report.",
	fn = function()
		local ok, HealthCheckService = pcall(require, script.Parent.HealthCheckService)
		if not ok then return "HealthCheckService unavailable" end
		local report = (HealthCheckService :: any).RunOnce and (HealthCheckService :: any).RunOnce()
		return report or "health probes ran (see Output)"
	end,
})

table.insert(commands, {
	name = "test-purchase",
	usage = "/test-purchase <product-key>",
	help = "Deliver a dev product without charging — verify the receipt path.",
	ownerOnly = true,
	fn = function(player, args)
		local key = args[1]
		if not key then return "usage: /test-purchase <product-key>" end
		local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
		local def = Config.DEV_PRODUCTS[key]
		if not def then return "unknown product: " .. key end
		local ok, MonetizationService = pcall(require, script.Parent.MonetizationService)
		if not ok then return "MonetizationService unavailable" end
		local handler = (MonetizationService :: any).DeliverProductTestOnly
		if handler then
			handler(player, key)
			return string.format("delivered %s to %s (test)", key, player.Name)
		end
		-- Fall back to direct cash for cash products if no test hook exists
		if def.kind == "cash" then
			EconomyService.AwardCash(player, def.amount or 0, "test purchase")
			return string.format("test-delivered %s -> +%d cash", key, def.amount or 0)
		end
		return "no test hook for product kind: " .. tostring(def.kind)
	end,
})

table.insert(commands, {
	name = "announce",
	usage = "/announce <text...>",
	help = "Push a banner to every client in this server.",
	ownerOnly = true,
	fn = function(player, args)
		local text = table.concat(args, " ")
		if text == "" then return "usage: /announce <text>" end
		local ok, AnnouncementService = pcall(require, script.Parent.AnnouncementService)
		if not ok then return "AnnouncementService unavailable" end
		AnnouncementService.Push(text, { 255, 215, 80 }, 30)
		return string.format("announced: %s", text)
	end,
})

table.insert(commands, {
	name = "freeze",
	usage = "/freeze <player>",
	help = "Lock a player in place (sets WalkSpeed=0, JumpPower=0).",
	ownerOnly = true,
	fn = function(player, args)
		local target = findPlayer(args[1] or "")
		if not target or not target.Character then return "usage: /freeze <player>" end
		local hum = target.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return "no humanoid" end
		hum.WalkSpeed = 0
		hum.JumpPower = 0
		return string.format("froze %s", target.Name)
	end,
})

table.insert(commands, {
	name = "unfreeze",
	usage = "/unfreeze <player>",
	help = "Restore movement.",
	ownerOnly = true,
	fn = function(player, args)
		local target = findPlayer(args[1] or "")
		if not target or not target.Character then return "usage: /unfreeze <player>" end
		local hum = target.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return "no humanoid" end
		hum.WalkSpeed = 16
		hum.JumpPower = 50
		return string.format("unfroze %s", target.Name)
	end,
})

table.insert(commands, {
	name = "kick",
	usage = "/kick <player> [reason]",
	help = "Kick a player.",
	ownerOnly = true,
	fn = function(player, args)
		local target = findPlayer(args[1] or "")
		if not target then return "usage: /kick <player> [reason]" end
		local reason = table.concat(args, " ", 2)
		if reason == "" then reason = "Removed by admin." end
		target:Kick(reason)
		return string.format("kicked %s — %s", target.Name, reason)
	end,
})

table.insert(commands, {
	name = "ban",
	usage = "/ban <userId|name> [reason]",
	help = "Soft-ban a user (DataStore-backed, persistent).",
	ownerOnly = true,
	fn = function(player, args)
		local first = args[1]
		if not first then return "usage: /ban <userId|name>" end
		local userId = tonumber(first)
		if not userId then
			local p = findPlayer(first)
			if p then userId = p.UserId end
		end
		if not userId then return "could not resolve user" end
		AdminService.SoftBan(userId, table.concat(args, " ", 2))
		local p = Players:GetPlayerByUserId(userId)
		if p then p:Kick("Banned by admin.") end
		return string.format("banned userId %d", userId)
	end,
})

table.insert(commands, {
	name = "unban",
	usage = "/unban <userId>",
	help = "Lift a soft-ban.",
	ownerOnly = true,
	fn = function(player, args)
		local userId = asNumber(args[1])
		if not userId then return "usage: /unban <userId>" end
		AdminService.SoftUnban(math.floor(userId))
		return string.format("unbanned userId %d", math.floor(userId))
	end,
})

table.insert(commands, {
	name = "flags",
	usage = "/flags",
	help = "Show recent anti-cheat flags for all players.",
	fn = function()
		local snap = AntiCheat.Snapshot()
		local lines = {}
		for name, info in pairs(snap) do
			table.insert(lines, string.format("%s (sid=%s, vio=%d, recent=%d)",
				name, info.sessionId, info.violations, #info.recentFlags))
			for _, f in ipairs(info.recentFlags) do
				table.insert(lines, string.format("    %s: %s", f.tag, f.detail))
			end
		end
		return #lines > 0 and table.concat(lines, "\n") or "no flags"
	end,
})

table.insert(commands, {
	name = "stats",
	usage = "/stats",
	help = "Show server stats summary.",
	fn = function()
		local n = #Players:GetPlayers()
		return string.format("server: %d/%d players, uptime %ds", n, Players.MaxPlayers, math.floor(time()))
	end,
})

table.insert(commands, {
	name = "version",
	usage = "/version",
	help = "Show server build identity.",
	fn = function()
		local jobId = game.JobId
		if jobId == "" then jobId = "studio" end
		return string.format("place=%d job=%s placeVer=%d uptime=%ds",
			game.PlaceId, jobId, game.PlaceVersion, math.floor(time()))
	end,
})

table.insert(commands, {
	name = "revenue",
	usage = "/revenue",
	help = "Show this server's purchase summary.",
	fn = function()
		local ok, AnalyticsService = pcall(require, script.Parent.AnalyticsService)
		if not ok then return "AnalyticsService unavailable" end
		local s = AnalyticsService.Summary()
		local rate = if s.count > 0 then s.totalRobux / s.count else 0
		return string.format(
			"server revenue: %d R$ across %d purchases (avg %.1f R$). " ..
			"Devex est: ~$%.2f (~70%% of gross after Roblox cut).",
			s.totalRobux, s.count, rate, (s.totalRobux * 0.7) / 350)
	end,
})

-- ============================================================
-- BAN STORE (persistent across servers)
-- ============================================================
local DataStoreService = game:GetService("DataStoreService")
local banStore: DataStore?
if not RunService:IsStudio() then
	pcall(function() banStore = DataStoreService:GetDataStore(Config.DATASTORE_SCOPE .. "_Bans") end)
end

local banCache: { [number]: { reason: string, at: number } } = {}

function AdminService.SoftBan(userId: number, reason: string?)
	local entry = { reason = reason or "Banned", at = os.time() }
	banCache[userId] = entry
	if banStore then
		pcall(function() banStore:SetAsync(tostring(userId), entry) end)
	end
end

function AdminService.SoftUnban(userId: number)
	banCache[userId] = nil
	if banStore then
		pcall(function() banStore:RemoveAsync(tostring(userId)) end)
	end
end

function AdminService.IsBanned(userId: number): boolean
	if banCache[userId] then return true end
	if not banStore then return false end
	local ok, entry = pcall(function() return banStore:GetAsync(tostring(userId)) end)
	if ok and entry then banCache[userId] = entry; return true end
	return false
end

-- ============================================================
-- DISPATCH
-- ============================================================

function AdminService.RunCommand(player: Player, line: string): string
	if not isAdmin(player.UserId) then
		return "permission denied"
	end
	if string.sub(line, 1, 1) == "/" then line = string.sub(line, 2) end
	local parts: { string } = {}
	for word in string.gmatch(line, "%S+") do table.insert(parts, word) end
	if #parts == 0 then return "type /help" end
	local name = string.lower(table.remove(parts, 1) :: string)
	local cmd = find(commands, name)
	if not cmd then return "unknown command: " .. name end
	if cmd.ownerOnly and not isOwner(player.UserId) then return "owner-only command" end
	local ok, result = pcall(cmd.fn, player, parts)
	if not ok then
		Log.Error("Admin", "%s ran /%s -> %s", player.Name, name, tostring(result))
		return "error: " .. tostring(result)
	end
	Log.Info("Admin", "%s ran /%s -> %s", player.Name, name, tostring(result))
	return tostring(result)
end

function AdminService.SnapshotPlayers(): { any }
	local out = {}
	local flags = AntiCheat.Snapshot()
	for _, p in ipairs(Players:GetPlayers()) do
		local d = DataService.Get(p)
		local f = flags[p.Name] or { violations = 0, recentFlags = {} }
		table.insert(out, {
			userId = p.UserId,
			name = p.Name,
			displayName = p.DisplayName,
			cash = d and d.cash or 0,
			rebirths = d and d.rebirths or 0,
			brainrots = d and #d.inventory or 0,
			violations = f.violations,
			isAdmin = isAdmin(p.UserId),
			isOwner = isOwner(p.UserId),
		})
	end
	return out
end

-- ============================================================
-- INIT
-- ============================================================
local OPEN_REMOTE_NAME = "AdminUpdate"
local RUN_REMOTE_NAME  = "AdminRunCommand"

function AdminService.OnPlayerAdded(player: Player)
	if AdminService.IsBanned(player.UserId) then
		player:Kick("You are banned from this experience.")
		return
	end
	-- Chat-command bridge for all admins regardless of whether the panel is open.
	-- Legacy chat path; the TextChatService path is wired once in Init().
	if isAdmin(player.UserId) then
		player.Chatted:Connect(function(message)
			if string.sub(message, 1, 1) ~= "/" then return end
			local result = AdminService.RunCommand(player, message)
			Remotes.Event(OPEN_REMOTE_NAME):FireClient(player, { kind = "result", text = result })
		end)
		task.delay(2, function()
			Remotes.Event(OPEN_REMOTE_NAME):FireClient(player, {
				kind = "init",
				isOwner = isOwner(player.UserId),
				players = AdminService.SnapshotPlayers(),
			})
		end)
		task.spawn(function()
			while player.Parent do
				task.wait(5)
				if isAdmin(player.UserId) then
					Remotes.Event(OPEN_REMOTE_NAME):FireClient(player, {
						kind = "tick",
						players = AdminService.SnapshotPlayers(),
					})
				end
			end
		end)
	end
end

function AdminService.Init()
	Remotes.Event(OPEN_REMOTE_NAME)

	AntiCheat.WrapRemote(Remotes.Event(RUN_REMOTE_NAME), RUN_REMOTE_NAME, function(player, line)
		if typeof(line) ~= "string" then return end
		if #line > 256 then return end
		local result = AdminService.RunCommand(player, line)
		Remotes.Event(OPEN_REMOTE_NAME):FireClient(player, { kind = "result", text = result })
	end)

	-- TextChatService bridge: modern Roblox chat doesn't fire player.Chatted,
	-- so we intercept SendingMessage. Admin-prefixed '/' messages are
	-- swallowed (destroyed) so other players don't see them.
	local ok, TextChatService = pcall(function() return game:GetService("TextChatService") end)
	if ok and TextChatService and TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		TextChatService.SendingMessage:Connect(function(message)
			local source = message.TextSource
			if not source then return end
			local player = Players:GetPlayerByUserId(source.UserId)
			if not player or not isAdmin(player.UserId) then return end
			local text = message.Text
			if string.sub(text, 1, 1) ~= "/" then return end
			pcall(function() message:Destroy() end)
			local result = AdminService.RunCommand(player, text)
			Remotes.Event(OPEN_REMOTE_NAME):FireClient(player, { kind = "result", text = result })
		end)
	end
end

return AdminService
