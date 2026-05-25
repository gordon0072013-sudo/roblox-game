--!strict
--[[
	Util — tiny shared helpers.
]]

local Util = {}

function Util.GenerateUid(): string
	-- 12-char base36-ish id, enough for inventory uniqueness
	local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
	local buf = table.create(12)
	for i = 1, 12 do
		local idx = math.random(1, #chars)
		buf[i] = string.sub(chars, idx, idx)
	end
	return table.concat(buf)
end

function Util.DeepCopy<T>(value: T): T
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in pairs(value :: any) do
		out[k] = Util.DeepCopy(v)
	end
	return out :: any
end

function Util.FormatShortNumber(n: number): string
	local abs = math.abs(n)
	if abs >= 1e12 then return string.format("%.2fT", n / 1e12) end
	if abs >= 1e9 then return string.format("%.2fB", n / 1e9) end
	if abs >= 1e6 then return string.format("%.2fM", n / 1e6) end
	if abs >= 1e3 then return string.format("%.1fK", n / 1e3) end
	return tostring(math.floor(n))
end

function Util.SecondsToClock(s: number): string
	s = math.max(0, math.floor(s))
	local h = math.floor(s / 3600)
	local m = math.floor((s % 3600) / 60)
	local sec = s % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, sec)
	end
	return string.format("%d:%02d", m, sec)
end

function Util.DayIndex(t: number?): number
	return math.floor((t or os.time()) / 86400)
end

return Util
