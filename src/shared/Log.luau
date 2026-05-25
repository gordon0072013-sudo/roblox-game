--!strict

local RunService = game:GetService("RunService")

local Log = {}

local LEVELS = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 }
local LEVEL_NAMES = { "DEBUG", "INFO", "WARN", "ERROR" }
local activeLevel = if RunService:IsStudio() then LEVELS.DEBUG else LEVELS.INFO

local function format(level: number, scope: string, msg: string): string
	return string.format("[%s][%s] %s", LEVEL_NAMES[level], scope, msg)
end

function Log.SetLevel(level: number)
	activeLevel = level
end

function Log.Debug(scope: string, msg: string, ...)
	if activeLevel > LEVELS.DEBUG then return end
	if select("#", ...) > 0 then msg = string.format(msg, ...) end
	print(format(LEVELS.DEBUG, scope, msg))
end

function Log.Info(scope: string, msg: string, ...)
	if activeLevel > LEVELS.INFO then return end
	if select("#", ...) > 0 then msg = string.format(msg, ...) end
	print(format(LEVELS.INFO, scope, msg))
end

function Log.Warn(scope: string, msg: string, ...)
	if activeLevel > LEVELS.WARN then return end
	if select("#", ...) > 0 then msg = string.format(msg, ...) end
	warn(format(LEVELS.WARN, scope, msg))
end

function Log.Error(scope: string, msg: string, ...)
	if select("#", ...) > 0 then msg = string.format(msg, ...) end
	warn(format(LEVELS.ERROR, scope, msg))
end

Log.LEVELS = LEVELS

return Log
