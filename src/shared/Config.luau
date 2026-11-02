--[[
	CL - Club Legacy 0.1
	Caminho: src/shared/Config.luau
	Tipo: ModuleScript (ReplicatedStorage/Shared/Config)
	Configurações compartilhadas entre servidor e cliente.
]]

local Config = {}

Config.GAME_NAME = "CL - Club Legacy"
Config.VERSION = "0.1"

Config.REMOTE_FOLDER = "CLRemotes"
Config.REQUEST_FUNCTION = "CLRequest"

Config.DATASTORE_NAME = "CLClubLegacy_Careers_v1"
Config.SAVE_KEY_PREFIX = "career_"
Config.DATA_VERSION = 1

Config.SQUAD_MIN = 16
Config.SQUAD_MAX = 26
Config.MARKET_SIZE = 24
Config.MAX_OVR = 94

Config.POSITIONS = { "GOL", "ZAG", "LAT", "VOL", "MEI", "PON", "ATA" }
Config.POSITION_NAMES = {
	GOL = "Goleiro",
	ZAG = "Zagueiro",
	LAT = "Lateral",
	VOL = "Volante",
	MEI = "Meio-campista",
	PON = "Ponta",
	ATA = "Atacante",
}

Config.FORMATION_ORDER = { "4-3-3", "4-4-2", "4-2-3-1" }
Config.FORMATIONS = {
	["4-3-3"] = {
		slots = { "GOL", "LAT", "ZAG", "ZAG", "LAT", "VOL", "MEI", "MEI", "PON", "ATA", "PON" },
		att = 2,
		def = 0,
		desc = "Três atacantes: +2 no ataque. Pressão pelos lados.",
	},
	["4-4-2"] = {
		slots = { "GOL", "LAT", "ZAG", "ZAG", "LAT", "PON", "VOL", "MEI", "PON", "ATA", "ATA" },
		att = 1,
		def = 1,
		desc = "Duas linhas de quatro: +1 no ataque e +1 na defesa.",
	},
	["4-2-3-1"] = {
		slots = { "GOL", "LAT", "ZAG", "ZAG", "LAT", "VOL", "VOL", "PON", "MEI", "PON", "ATA" },
		att = 0,
		def = 2,
		desc = "Dois volantes protegem a zaga: +2 na defesa.",
	},
}

Config.STRATEGY_ORDER = { "Defensiva", "Equilibrada", "Ofensiva" }
Config.STRATEGIES = {
	Defensiva = { att = -4, def = 4, wear = -2, desc = "-4 ataque, +4 defesa e menos desgaste físico." },
	Equilibrada = { att = 0, def = 0, wear = 0, desc = "Sem bônus nem penalidades." },
	Ofensiva = { att = 4, def = -4, wear = 2, desc = "+4 ataque, -4 defesa e mais desgaste físico." },
}

function Config.formatMoney(n)
	n = tonumber(n) or 0
	local neg = n < 0
	local a = math.abs(n)
	local s
	if a >= 1000000 then
		s = string.format("%.2fM", a / 1000000)
	elseif a >= 1000 then
		s = string.format("%.0fK", a / 1000)
	else
		s = tostring(math.floor(a))
	end
	return (neg and "-$" or "$") .. s
end

return Config
