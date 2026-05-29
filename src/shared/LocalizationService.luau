--!strict
--[[
	LocalizationService — string-key lookup with per-locale tables.
	Roblox provides `LocalizationService:GetCountryRegionForPlayerAsync` and
	`Player.LocaleId`, which we map to a locale code (en, es, pt, fr).

	UI calls `Loc(key)` instead of hardcoding text. Untranslated keys fall
	back to English. Roblox's auto-translator handles dynamic content; this
	is for the static UI chrome and the launch CTAs that drive conversion.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalizationService = {}

type LocaleTable = { [string]: string }

local strings: { [string]: LocaleTable } = {
	en = {
		-- HUD
		hud_cash = "%s cash",
		hud_rebirth = "Rebirth %d (need %s)",
		hud_infected = "INFECTED · %ds · 🦠",
		hud_bombs = "💣 %d bombs",
		-- Buttons
		btn_capture = "🎲 CAPTURE",
		btn_steal = "🥷 STEAL\nnearest",
		btn_infect = "💣 INFECT\nnearest",
		btn_rebirth = "REBIRTH",
		btn_redeem = "REDEEM",
		btn_claim = "CLAIM",
		btn_done = "✓ DONE",
		btn_locked = "LOCKED",
		-- Shop tabs
		tab_shop = "🛒 Shop",
		tab_inventory = "🧠 Lab",
		tab_quests = "📋 Quests",
		tab_achievements = "🏅 Goals",
		tab_trade = "🤝 Trade",
		tab_codes = "🎟 Codes",
		tab_daily = "🎁 Daily",
		tab_pass = "🎖 Pass",
		tab_global = "🌍 Global",
		tab_leaderboard = "🏆 Top",
		-- Toasts
		toast_invalid_code = "Invalid code: %s",
		toast_code_expired = "Code expired: %s",
		toast_already_claimed = "Already claimed today.",
		toast_inventory_full = "Inventory full — sell some brainrots first.",
		toast_grace = "Target is in grace period.",
		toast_cooldown = "Cooldown: %ds",
	},
	es = {
		hud_cash = "%s monedas",
		hud_rebirth = "Renacimiento %d (necesitas %s)",
		hud_infected = "INFECTADO · %ds · 🦠",
		hud_bombs = "💣 %d bombas",
		btn_capture = "🎲 CAPTURAR",
		btn_steal = "🥷 ROBAR\ncercano",
		btn_infect = "💣 INFECTAR\ncercano",
		btn_rebirth = "RENACER",
		btn_redeem = "CANJEAR",
		btn_claim = "RECLAMAR",
		btn_done = "✓ HECHO",
		btn_locked = "BLOQUEADO",
		tab_shop = "🛒 Tienda",
		tab_inventory = "🧠 Lab",
		tab_quests = "📋 Misiones",
		tab_achievements = "🏅 Logros",
		tab_trade = "🤝 Intercambio",
		tab_codes = "🎟 Códigos",
		tab_daily = "🎁 Diario",
		tab_pass = "🎖 Pase",
		tab_global = "🌍 Global",
		tab_leaderboard = "🏆 Top",
		toast_invalid_code = "Código inválido: %s",
		toast_code_expired = "Código expirado: %s",
		toast_already_claimed = "Ya reclamado hoy.",
		toast_inventory_full = "Inventario lleno — vende algunos brainrots primero.",
		toast_grace = "Objetivo en periodo de protección.",
		toast_cooldown = "Espera: %ds",
	},
	pt = {
		hud_cash = "%s dinheiro",
		hud_rebirth = "Renascimento %d (precisa %s)",
		hud_infected = "INFECTADO · %ds · 🦠",
		hud_bombs = "💣 %d bombas",
		btn_capture = "🎲 CAPTURAR",
		btn_steal = "🥷 ROUBAR\nperto",
		btn_infect = "💣 INFECTAR\nperto",
		btn_rebirth = "RENASCER",
		btn_redeem = "RESGATAR",
		btn_claim = "RECLAMAR",
		btn_done = "✓ FEITO",
		btn_locked = "BLOQUEADO",
		tab_shop = "🛒 Loja",
		tab_inventory = "🧠 Lab",
		tab_quests = "📋 Missões",
		tab_achievements = "🏅 Conquistas",
		tab_trade = "🤝 Troca",
		tab_codes = "🎟 Códigos",
		tab_daily = "🎁 Diário",
		tab_pass = "🎖 Passe",
		tab_global = "🌍 Global",
		tab_leaderboard = "🏆 Top",
		toast_invalid_code = "Código inválido: %s",
		toast_code_expired = "Código expirado: %s",
		toast_already_claimed = "Já resgatado hoje.",
		toast_inventory_full = "Inventário cheio — venda alguns brainrots primeiro.",
		toast_grace = "Alvo em período de proteção.",
		toast_cooldown = "Espera: %ds",
	},
}

local function detectLocale(): string
	if RunService:IsServer() then return "en" end
	local lp = Players.LocalPlayer
	if not lp then return "en" end
	local code = string.lower(string.sub(lp.LocaleId or "en", 1, 2))
	if strings[code] then return code end
	return "en"
end

local clientLocale: string? = nil

function LocalizationService.Get(key: string, ...): string
	local locale = clientLocale or detectLocale()
	clientLocale = locale
	local table_ = strings[locale] or strings.en
	local template = table_[key] or strings.en[key] or key
	local args = { ... }
	if #args > 0 then
		local ok, formatted = pcall(string.format, template, ...)
		if ok then return formatted end
	end
	return template
end

function LocalizationService.SetLocale(code: string)
	clientLocale = code
end

return LocalizationService
