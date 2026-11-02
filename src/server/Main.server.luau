--[[
	CL - Club Legacy 0.1
	Caminho: src/server/Main.server.luau
	Tipo: Script (ServerScriptService)

	Servidor autoritativo: carreira, liga, calendário, simulação de partidas,
	escalação, táticas, mercado, finanças, desenvolvimento de jogadores,
	temporadas e salvamento (DataStoreService).
	O cliente apenas envia pedidos; todas as regras são validadas aqui.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local TextService = game:GetService("TextService")

-- O jogo é totalmente baseado em interface; não há personagem no mapa.
Players.CharacterAutoLoads = false

local function loadConfig()
	local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 15)
	local module = sharedFolder and sharedFolder:FindFirstChild("Config")
	if not module then
		module = ReplicatedStorage:FindFirstChild("Config", true)
	end
	assert(module and module:IsA("ModuleScript"), "[CL] ModuleScript Config não encontrado em ReplicatedStorage")
	return require(module)
end

local Config = loadConfig()

---------------------------------------------------------------------
-- CONSTANTES
---------------------------------------------------------------------
local FORMATIONS = Config.FORMATIONS
local STRATEGIES = Config.STRATEGIES
local POS_ORDER = Config.POSITIONS
local MARKET = "MKT"
local SQUAD_MIN = Config.SQUAD_MIN
local SQUAD_MAX = Config.SQUAD_MAX
local MAX_OVR = Config.MAX_OVR
local MIN_OVR = 40
local FIT_MIN = 40
local FIT_RECOVERY = 9
local BASE_GOALS = 1.3
local HOME_ADVANTAGE = 0.2
local GOAL_FACTOR = 0.07
local MIN_SAVE_INTERVAL = 8
local AUTOSAVE_INTERVAL = 45
local SELL_RATE = 0.85
local TV_MONEY = 1500000
local SEASON_PRIZES = { 4000000, 3200000, 2600000, 2100000, 1700000, 1400000, 1100000, 800000 }
local MAX_LOG = 40
local MAX_HISTORY = 30
local NO_CAREER = "Nenhuma carreira ativa. Crie uma nova carreira."

local POS_INDEX = {}
for i, pos in ipairs(POS_ORDER) do
	POS_INDEX[pos] = i
end

local ROLE = { GOL = "GK", ZAG = "DEF", LAT = "DEF", VOL = "MID", MEI = "MID", PON = "ATT", ATA = "ATT" }
local SCORER_WEIGHT = { GK = 0, DEF = 1, MID = 3, ATT = 6 }

-- Fator de rendimento: RELATED[posição do slot][posição do jogador]
local RELATED = {
	ZAG = { LAT = 0.88, VOL = 0.85 },
	LAT = { ZAG = 0.88, PON = 0.84, VOL = 0.8 },
	VOL = { MEI = 0.92, ZAG = 0.85, LAT = 0.8 },
	MEI = { VOL = 0.9, PON = 0.86, ATA = 0.84 },
	PON = { ATA = 0.9, MEI = 0.86, LAT = 0.8 },
	ATA = { PON = 0.9, MEI = 0.84 },
}

local SQUAD_TEMPLATE = { GOL = 2, ZAG = 4, LAT = 3, VOL = 2, MEI = 3, PON = 2, ATA = 2 }
local MARKET_POS_POOL = { "GOL", "ZAG", "ZAG", "LAT", "LAT", "VOL", "MEI", "MEI", "PON", "PON", "ATA", "ATA" }

local CLUB_TEMPLATES = {
	{ id = "c1", name = "Atlético Aurora", short = "AUR", level = 74, color = { 220, 60, 70 }, budget = 9000000, formation = "4-3-3", strategy = "Ofensiva" },
	{ id = "c2", name = "Real Monte Verde", short = "RMV", level = 72, color = { 40, 170, 90 }, budget = 8000000, formation = "4-2-3-1", strategy = "Equilibrada" },
	{ id = "c3", name = "Sporting Vale Azul", short = "SVA", level = 70, color = { 50, 120, 230 }, budget = 7000000, formation = "4-4-2", strategy = "Equilibrada" },
	{ id = "c4", name = "União Porto Alto", short = "UPA", level = 68, color = { 245, 170, 40 }, budget = 6000000, formation = "4-3-3", strategy = "Equilibrada" },
	{ id = "c5", name = "Estrela do Norte FC", short = "EDN", level = 66, color = { 150, 90, 220 }, budget = 5000000, formation = "4-2-3-1", strategy = "Defensiva" },
	{ id = "c6", name = "Leões da Serra", short = "LDS", level = 65, color = { 200, 120, 60 }, budget = 4500000, formation = "4-4-2", strategy = "Ofensiva" },
	{ id = "c7", name = "Dínamo Costa Sul", short = "DCS", level = 63, color = { 30, 190, 200 }, budget = 4000000, formation = "4-4-2", strategy = "Defensiva" },
	{ id = "c8", name = "Fênix Clube", short = "FNX", level = 61, color = { 240, 90, 150 }, budget = 3500000, formation = "4-3-3", strategy = "Equilibrada" },
}
local TOTAL_ROUNDS = (#CLUB_TEMPLATES - 1) * 2

local FIRST_NAMES = {
	"Lucas", "Mateus", "Rafael", "Thiago", "Bruno", "Diego", "Caio", "Vitor", "Igor", "Renan",
	"Leandro", "Felipe", "Gustavo", "Henrique", "André", "Murilo", "Otávio", "Samuel", "Davi", "Enzo",
	"Nicolas", "Pedro", "João", "Arthur", "Kauã", "Ruan", "Wesley", "Alan", "Marcos", "Daniel",
	"Tomás", "Iago", "Luan", "Breno", "Elias", "Yuri", "Hugo", "Ivan", "Rodrigo", "Fábio",
}
local LAST_NAMES = {
	"Silva", "Costa", "Moura", "Teixeira", "Rocha", "Almeida", "Barros", "Cardoso", "Duarte", "Farias",
	"Gomes", "Lacerda", "Macedo", "Nogueira", "Pires", "Queiroz", "Ribeiro", "Sampaio", "Tavares", "Vieira",
	"Xavier", "Prado", "Lima", "Fontes", "Brandão", "Coelho", "Dias", "Esteves", "Freitas", "Guedes",
	"Holanda", "Leal", "Matos", "Neves", "Paiva", "Rezende", "Salgado", "Torres", "Valente", "Zanetti",
}

local rng = Random.new()

---------------------------------------------------------------------
-- UTILITÁRIOS
---------------------------------------------------------------------
local function clamp(v, lo, hi)
	if v < lo then
		return lo
	end
	if v > hi then
		return hi
	end
	return v
end

local function round1(v)
	return math.floor(v * 10 + 0.5) / 10
end

local function trim(s)
	return (string.match(s, "^%s*(.-)%s*$")) or ""
end

local function shuffle(list)
	for i = #list, 2, -1 do
		local j = rng:NextInteger(1, i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

local function deepCopy(v)
	if type(v) ~= "table" then
		return v
	end
	local t = {}
	for k, x in pairs(v) do
		t[k] = deepCopy(x)
	end
	return t
end

local function randomName()
	return FIRST_NAMES[rng:NextInteger(1, #FIRST_NAMES)] .. " " .. LAST_NAMES[rng:NextInteger(1, #LAST_NAMES)]
end

local function makeShort(name)
	local clean = string.upper((string.gsub(name, "[^%a]", "")))
	local short = string.sub(clean, 1, 3)
	if #short < 3 then
		short = "CLB"
	end
	return short
end

---------------------------------------------------------------------
-- JOGADORES
---------------------------------------------------------------------
local function computeValue(p)
	local base = math.max(p.ovr - 40, 1)
	local v = (base ^ 2.2) * 1200
	local ageF
	if p.age <= 21 then
		ageF = 1.35
	elseif p.age <= 25 then
		ageF = 1.2
	elseif p.age <= 29 then
		ageF = 1.0
	elseif p.age <= 32 then
		ageF = 0.7
	else
		ageF = 0.45
	end
	local potF = 1 + math.max(p.pot - p.ovr, 0) * 0.025
	v = v * ageF * potF
	return math.max(math.floor(v / 1000 + 0.5) * 1000, 10000)
end

local function computeWage(value)
	return math.max(math.floor(value * 0.004 / 100 + 0.5) * 100, 500)
end

local function sellPrice(p)
	return math.max(math.floor(p.value * SELL_RATE / 1000) * 1000, 5000)
end

local function createPlayer(career, pos, level, clubId, opts)
	opts = opts or {}
	career.nextPlayerId = (career.nextPlayerId or 0) + 1
	local id = "p" .. tostring(career.nextPlayerId)
	local age = opts.age or rng:NextInteger(18, 33)
	local ovr = opts.ovr or (level + rng:NextInteger(-7, 6))
	ovr = clamp(math.floor(ovr), 45, MAX_OVR - 4)
	local bonus = 0
	if age <= 20 then
		bonus = rng:NextInteger(8, 20)
	elseif age <= 23 then
		bonus = rng:NextInteger(4, 12)
	elseif age <= 27 then
		bonus = rng:NextInteger(0, 5)
	end
	local p = {
		id = id,
		name = randomName(),
		age = age,
		pos = pos,
		ovr = ovr,
		pot = clamp(ovr + bonus, ovr, MAX_OVR),
		fit = 100,
		clubId = clubId,
		apps = 0,
		goals = 0,
		seasonStartOvr = ovr,
		value = 0,
		wage = 0,
	}
	p.value = computeValue(p)
	p.wage = computeWage(p.value)
	career.players[id] = p
	return p
end

local function getSquad(career, clubId)
	local list = {}
	for _, p in pairs(career.players) do
		if p.clubId == clubId then
			table.insert(list, p)
		end
	end
	table.sort(list, function(a, b)
		local ia, ib = POS_INDEX[a.pos] or 99, POS_INDEX[b.pos] or 99
		if ia ~= ib then
			return ia < ib
		end
		if a.ovr ~= b.ovr then
			return a.ovr > b.ovr
		end
		return a.id < b.id
	end)
	return list
end

local function countPos(squad, pos)
	local n = 0
	for _, p in ipairs(squad) do
		if p.pos == pos then
			n += 1
		end
	end
	return n
end

local function posFactor(playerPos, slotPos)
	if playerPos == slotPos then
		return 1
	end
	if playerPos == "GOL" or slotPos == "GOL" then
		return 0.35
	end
	local r = RELATED[slotPos] and RELATED[slotPos][playerPos]
	return r or 0.72
end

local function effectiveRating(p, slotPos)
	return p.ovr * posFactor(p.pos, slotPos) * (0.7 + 0.3 * clamp(p.fit, 0, 100) / 100)
end

---------------------------------------------------------------------
-- ESCALAÇÃO
---------------------------------------------------------------------
-- Distribui uma lista de ids nos slots: primeiro posição exata,
-- depois respeitando goleiro/linha, por fim qualquer jogador.
local function assignSlots(career, ids, slots)
	local result = {}
	local used = {}
	for i = 1, #slots do
		result[i] = false
	end
	local function pass(filter)
		for i, slotPos in ipairs(slots) do
			if result[i] == false then
				local bestId, bestR = nil, -1
				for _, id in ipairs(ids) do
					local p = career.players[id]
					if p and not used[id] and filter(p, slotPos) then
						local r = effectiveRating(p, slotPos)
						if r > bestR then
							bestId, bestR = id, r
						end
					end
				end
				if bestId then
					result[i] = bestId
					used[bestId] = true
				end
			end
		end
	end
	pass(function(p, slotPos)
		return p.pos == slotPos
	end)
	pass(function(p, slotPos)
		return (p.pos == "GOL") == (slotPos == "GOL")
	end)
	pass(function()
		return true
	end)
	return result
end

local function autoLineup(career, clubId, formation)
	local ids = {}
	for _, p in ipairs(getSquad(career, clubId)) do
		table.insert(ids, p.id)
	end
	return assignSlots(career, ids, FORMATIONS[formation].slots)
end

local function bestAvailable(career, clubId, slotPos, used, exactOnly)
	local best, bestR = nil, -1
	for id, p in pairs(career.players) do
		if p.clubId == clubId and not used[id] and (not exactOnly or p.pos == slotPos) then
			local r = effectiveRating(p, slotPos)
			if r > bestR then
				best, bestR = p, r
			end
		end
	end
	return best
end

-- Garante 11 titulares válidos, únicos, do clube, com goleiro no slot 1.
local function repairLineup(career)
	local lu = career.userLineup
	local clubId = career.userClubId
	if not FORMATIONS[lu.formation] then
		lu.formation = "4-3-3"
	end
	if not STRATEGIES[lu.strategy] then
		lu.strategy = "Equilibrada"
	end
	local slots = FORMATIONS[lu.formation].slots
	local used = {}
	local starters = {}
	for i = 1, #slots do
		local id = lu.starters and lu.starters[i]
		local p = (type(id) == "string") and career.players[id] or nil
		if p and p.clubId == clubId and not used[id] then
			starters[i] = id
			used[id] = true
		else
			starters[i] = false
		end
	end
	for i, slotPos in ipairs(slots) do
		if starters[i] == false then
			local best = bestAvailable(career, clubId, slotPos, used, false)
			if best then
				starters[i] = best.id
				used[best.id] = true
			end
		end
	end
	local gk = starters[1] and career.players[starters[1]]
	if not gk or gk.pos ~= "GOL" then
		local swapIdx = nil
		for i = 2, #slots do
			local p = starters[i] and career.players[starters[i]]
			if p and p.pos == "GOL" then
				swapIdx = i
				break
			end
		end
		if swapIdx then
			starters[1], starters[swapIdx] = starters[swapIdx], starters[1]
		else
			local bestGk = bestAvailable(career, clubId, "GOL", used, true)
			if bestGk then
				starters[1] = bestGk.id
			end
		end
	end
	lu.starters = starters
end

local function reassignToFormation(career, formation)
	local lu = career.userLineup
	local ids = {}
	for i = 1, 11 do
		local id = lu.starters[i]
		if type(id) == "string" and career.players[id] then
			table.insert(ids, id)
		end
	end
	lu.formation = formation
	lu.starters = assignSlots(career, ids, FORMATIONS[formation].slots)
	repairLineup(career)
end

---------------------------------------------------------------------
-- SIMULAÇÃO
---------------------------------------------------------------------
local function teamStrength(career, starters, formation, strategy)
	local slots = FORMATIONS[formation].slots
	local sums = { GK = 0, DEF = 0, MID = 0, ATT = 0 }
	local counts = { GK = 0, DEF = 0, MID = 0, ATT = 0 }
	for i, slotPos in ipairs(slots) do
		local id = starters[i]
		local p = id and career.players[id]
		local r = p and effectiveRating(p, slotPos) or 30
		local role = ROLE[slotPos]
		sums[role] += r
		counts[role] += 1
	end
	local function avg(k)
		return counts[k] > 0 and sums[k] / counts[k] or 40
	end
	local att = avg("ATT") * 0.5 + avg("MID") * 0.35 + avg("DEF") * 0.15
	local def = avg("DEF") * 0.45 + avg("MID") * 0.25 + avg("GK") * 0.3
	local f = FORMATIONS[formation]
	local s = STRATEGIES[strategy] or STRATEGIES.Equilibrada
	return att + f.att + s.att, def + f.def + s.def
end

local function poisson(lambda)
	local L = math.exp(-lambda)
	local k = 0
	local p = 1
	repeat
		k += 1
		p *= rng:NextNumber()
	until p <= L
	return math.min(k - 1, 9)
end

local function getMatchSetup(career, clubId)
	if clubId == career.userClubId then
		local lu = career.userLineup
		return lu.starters, lu.formation, lu.strategy
	end
	local club = career.clubs[clubId]
	return autoLineup(career, clubId, club.formation), club.formation, club.strategy
end

local function pickScorer(career, starters, formation)
	local slots = FORMATIONS[formation].slots
	local pool, total = {}, 0
	for i, slotPos in ipairs(slots) do
		local id = starters[i]
		local p = id and career.players[id]
		if p then
			local w = SCORER_WEIGHT[ROLE[slotPos]] * (p.ovr / 70)
			if w > 0 then
				total += w
				table.insert(pool, { p = p, w = w })
			end
		end
	end
	if total <= 0 then
		return nil
	end
	local roll = rng:NextNumber() * total
	for _, e in ipairs(pool) do
		roll -= e.w
		if roll <= 0 then
			return e.p
		end
	end
	return pool[#pool].p
end

local function randomStarter(career, starters)
	local list = {}
	for _, id in ipairs(starters) do
		local p = id and career.players[id]
		if p then
			table.insert(list, p)
		end
	end
	if #list == 0 then
		return nil
	end
	return list[rng:NextInteger(1, #list)]
end

local function simulateFixture(career, fx, started)
	local hS, hF, hSt = getMatchSetup(career, fx.home)
	local aS, aF, aSt = getMatchSetup(career, fx.away)
	local hAtt, hDef = teamStrength(career, hS, hF, hSt)
	local aAtt, aDef = teamStrength(career, aS, aF, aSt)
	local hl = clamp(BASE_GOALS + HOME_ADVANTAGE + (hAtt - aDef) * GOAL_FACTOR, 0.15, 4.2)
	local al = clamp(BASE_GOALS + (aAtt - hDef) * GOAL_FACTOR, 0.15, 4.2)
	local hg, ag = poisson(hl), poisson(al)
	local events = {}

	local function addGoals(n, starters, formation, side)
		for _ = 1, n do
			local p = pickScorer(career, starters, formation)
			if p then
				p.goals = (p.goals or 0) + 1
			end
			table.insert(events, { min = rng:NextInteger(1, 90), side = side, kind = "goal", text = "GOL! " .. (p and p.name or "Jogador") })
		end
	end
	local function addCards(starters, side)
		for _ = 1, rng:NextInteger(0, 2) do
			local p = randomStarter(career, starters)
			if p then
				table.insert(events, { min = rng:NextInteger(1, 90), side = side, kind = "card", text = "Cartão amarelo: " .. p.name })
			end
		end
	end
	addGoals(hg, hS, hF, "home")
	addGoals(ag, aS, aF, "away")
	addCards(hS, "home")
	addCards(aS, "away")
	table.sort(events, function(a, b)
		return a.min < b.min
	end)

	local function wear(starters, strategy)
		local extra = (STRATEGIES[strategy] and STRATEGIES[strategy].wear) or 0
		for _, id in ipairs(starters) do
			local p = id and career.players[id]
			if p then
				p.apps = (p.apps or 0) + 1
				p.fit = math.max(FIT_MIN, p.fit - rng:NextInteger(12, 18) - extra)
				started[p.id] = true
			end
		end
	end
	wear(hS, hSt)
	wear(aS, aSt)
	return { hg = hg, ag = ag, hl = hl, al = al, events = events }
end

---------------------------------------------------------------------
-- LIGA
---------------------------------------------------------------------
local function resetStandings(career)
	career.standings = {}
	for _, t in ipairs(CLUB_TEMPLATES) do
		career.standings[t.id] = { played = 0, w = 0, d = 0, l = 0, gf = 0, ga = 0, pts = 0 }
	end
end

local function generateFixtures(career)
	local ids = {}
	for _, t in ipairs(CLUB_TEMPLATES) do
		table.insert(ids, t.id)
	end
	shuffle(ids)
	local n = #ids
	local firstHalf = {}
	for r = 1, n - 1 do
		local matches = {}
		for i = 1, n / 2 do
			local home, away = ids[i], ids[n + 1 - i]
			if (i == 1 and r % 2 == 0) or (i > 1 and i % 2 == 0) then
				home, away = away, home
			end
			table.insert(matches, { home = home, away = away, hg = 0, ag = 0, played = false })
		end
		firstHalf[r] = matches
		local last = table.remove(ids, n)
		table.insert(ids, 2, last)
	end
	local fixtures = {}
	for r = 1, n - 1 do
		fixtures[r] = firstHalf[r]
		local mirrored = {}
		for _, m in ipairs(firstHalf[r]) do
			table.insert(mirrored, { home = m.away, away = m.home, hg = 0, ag = 0, played = false })
		end
		fixtures[r + n - 1] = mirrored
	end
	career.fixtures = fixtures
end

local function applyResult(career, fx)
	local h = career.standings[fx.home]
	local a = career.standings[fx.away]
	h.played += 1
	a.played += 1
	h.gf += fx.hg
	h.ga += fx.ag
	a.gf += fx.ag
	a.ga += fx.hg
	if fx.hg > fx.ag then
		h.w += 1
		h.pts += 3
		a.l += 1
	elseif fx.hg < fx.ag then
		a.w += 1
		a.pts += 3
		h.l += 1
	else
		h.d += 1
		a.d += 1
		h.pts += 1
		a.pts += 1
	end
end

local function sortedStandings(career)
	local rows = {}
	for id, s in pairs(career.standings) do
		local club = career.clubs[id]
		table.insert(rows, {
			id = id,
			name = club and club.name or id,
			played = s.played,
			w = s.w,
			d = s.d,
			l = s.l,
			gf = s.gf,
			ga = s.ga,
			gd = s.gf - s.ga,
			pts = s.pts,
		})
	end
	table.sort(rows, function(a, b)
		if a.pts ~= b.pts then
			return a.pts > b.pts
		end
		if a.gd ~= b.gd then
			return a.gd > b.gd
		end
		if a.gf ~= b.gf then
			return a.gf > b.gf
		end
		if a.w ~= b.w then
			return a.w > b.w
		end
		return a.name < b.name
	end)
	return rows
end

---------------------------------------------------------------------
-- FINANÇAS
---------------------------------------------------------------------
local function addFinance(career, desc, amount)
	local club = career.clubs[career.userClubId]
	club.budget = math.floor(club.budget + amount)
	table.insert(career.financeLog, { season = career.season, round = career.round, desc = desc, amount = amount })
	while #career.financeLog > MAX_LOG do
		table.remove(career.financeLog, 1)
	end
end

local function wagesPerRound(career)
	local total = 0
	for _, p in pairs(career.players) do
		if p.clubId == career.userClubId then
			total += p.wage
		end
	end
	return total
end

local function homeGate(career)
	local club = career.clubs[career.userClubId]
	return 80000 + math.max(club.level - 55, 0) * 9000
end

---------------------------------------------------------------------
-- MERCADO E TEMPORADAS
---------------------------------------------------------------------
local function generateMarket(career)
	for i = 1, Config.MARKET_SIZE do
		local pos = MARKET_POS_POOL[rng:NextInteger(1, #MARKET_POS_POOL)]
		if i <= 6 then
			createPlayer(career, pos, 0, MARKET, { age = rng:NextInteger(17, 20), ovr = rng:NextInteger(52, 64) })
		else
			createPlayer(career, pos, rng:NextInteger(58, 79), MARKET)
		end
	end
end

local function developPlayers(career, started)
	for _, p in pairs(career.players) do
		if p.clubId ~= MARKET then
			local old = p.ovr
			local gap = p.pot - p.ovr
			local didStart = started[p.id] == true
			if p.age <= 23 and gap > 0 then
				local chance = 0.06 + (didStart and 0.14 or 0.03) + math.min(gap, 20) * 0.006
				if rng:NextNumber() < chance then
					p.ovr += 1
				end
			elseif p.age <= 29 and gap > 0 then
				local chance = 0.03 + (didStart and 0.06 or 0)
				if rng:NextNumber() < chance then
					p.ovr += 1
				end
			elseif p.age >= 31 then
				local chance = 0.015 + (p.age - 30) * 0.012
				if rng:NextNumber() < chance then
					p.ovr -= 1
				end
			end
			p.ovr = clamp(p.ovr, MIN_OVR, MAX_OVR)
			if p.pot < p.ovr then
				p.pot = p.ovr
			end
			if p.ovr ~= old then
				p.value = computeValue(p)
			end
		end
	end
end

local function finishSeason(career)
	career.seasonOver = true
	local rows = sortedStandings(career)
	local userPos, userPts = 0, 0
	for i, row in ipairs(rows) do
		local prize = SEASON_PRIZES[i] or 500000
		if row.id == career.userClubId then
			userPos, userPts = i, row.pts
			addFinance(career, string.format("Premiação: %dº lugar", i), prize)
			addFinance(career, "Cotas de TV da temporada", TV_MONEY)
		else
			local club = career.clubs[row.id]
			club.budget += prize + TV_MONEY
		end
	end
	local champ = career.clubs[rows[1].id]
	career.lastSeasonSummary = {
		season = career.season,
		champion = champ.name,
		userPos = userPos,
		userPts = userPts,
		prize = (SEASON_PRIZES[userPos] or 0) + TV_MONEY,
	}
	table.insert(career.history, {
		season = career.season,
		champion = champ.name,
		userClub = career.clubs[career.userClubId].name,
		userPos = userPos,
		userPts = userPts,
	})
	while #career.history > MAX_HISTORY do
		table.remove(career.history, 1)
	end
end

local function playRound(career)
	if career.seasonOver then
		return false, "A temporada já terminou. Inicie a próxima temporada."
	end
	local r = career.round + 1
	local fixtures = career.fixtures[r]
	if not fixtures then
		return false, "Rodada inexistente"
	end
	repairLineup(career)
	local started = {}
	local userReport = nil
	local others = {}
	for _, fx in ipairs(fixtures) do
		if not fx.played then
			local res = simulateFixture(career, fx, started)
			fx.hg, fx.ag, fx.played = res.hg, res.ag, true
			applyResult(career, fx)
			if fx.home == career.userClubId or fx.away == career.userClubId then
				userReport = {
					round = r,
					home = fx.home,
					away = fx.away,
					hg = fx.hg,
					ag = fx.ag,
					xgH = round1(res.hl),
					xgA = round1(res.al),
					events = res.events,
				}
			else
				table.insert(others, { home = fx.home, away = fx.away, hg = fx.hg, ag = fx.ag })
			end
		end
	end
	career.round = r

	for _, p in pairs(career.players) do
		if p.clubId ~= MARKET then
			p.fit = math.min(100, p.fit + FIT_RECOVERY)
		end
	end
	developPlayers(career, started)

	addFinance(career, string.format("Salários - rodada %d", r), -wagesPerRound(career))
	if userReport and userReport.home == career.userClubId then
		addFinance(career, string.format("Bilheteria - rodada %d", r), homeGate(career))
	end

	local msg = "Rodada " .. r .. " concluída"
	if userReport then
		userReport.others = others
		career.lastReport = userReport
		msg = string.format("%s %d x %d %s", career.clubs[userReport.home].short, userReport.hg, userReport.ag, career.clubs[userReport.away].short)
	end
	if r >= TOTAL_ROUNDS then
		finishSeason(career)
		msg = msg .. "  |  Temporada encerrada!"
	end
	return true, msg
end

local function updateClubLevel(career, clubId)
	local squad = getSquad(career, clubId)
	table.sort(squad, function(a, b)
		return a.ovr > b.ovr
	end)
	local sum, n = 0, 0
	for i = 1, math.min(16, #squad) do
		sum += squad[i].ovr
		n += 1
	end
	if n > 0 then
		career.clubs[clubId].level = math.floor(sum / n + 0.5)
	end
end

local function fillClubSquad(career, clubId, isUser)
	local club = career.clubs[clubId]
	local squad = getSquad(career, clubId)
	local counts = {}
	for _, pos in ipairs(POS_ORDER) do
		counts[pos] = 0
	end
	for _, p in ipairs(squad) do
		counts[p.pos] = (counts[p.pos] or 0) + 1
	end
	local total = #squad
	local added = 0
	local function addYouth(pos, offset)
		createPlayer(career, pos, 0, clubId, { age = rng:NextInteger(17, 19), ovr = club.level - offset })
		counts[pos] += 1
		total += 1
		added += 1
	end
	while counts.GOL < 2 and total < SQUAD_MAX do
		addYouth("GOL", rng:NextInteger(4, 10))
	end
	if not isUser then
		for _, pos in ipairs(POS_ORDER) do
			while counts[pos] < SQUAD_TEMPLATE[pos] and total < SQUAD_MAX do
				createPlayer(career, pos, club.level, clubId)
				counts[pos] += 1
				total += 1
			end
		end
	end
	while total < SQUAD_MIN do
		local bestPos, bestDef = "MEI", -math.huge
		for _, pos in ipairs(POS_ORDER) do
			local d = SQUAD_TEMPLATE[pos] - counts[pos]
			if d > bestDef then
				bestPos, bestDef = pos, d
			end
		end
		addYouth(bestPos, rng:NextInteger(4, 10))
	end
	local cap = isUser and SQUAD_MAX or 22
	if total < cap then
		addYouth(POS_ORDER[rng:NextInteger(1, #POS_ORDER)], rng:NextInteger(8, 14))
	end
	return added
end

local function startNewSeason(career)
	if not career.seasonOver then
		return false, "A temporada atual ainda não terminou"
	end
	career.season += 1
	career.round = 0
	career.seasonOver = false
	career.lastReport = nil
	career.lastSeasonSummary = nil

	local retired = 0
	for id, p in pairs(career.players) do
		if p.clubId == MARKET then
			career.players[id] = nil
		else
			p.age += 1
			if p.age >= 37 then
				if p.clubId == career.userClubId then
					retired += 1
				end
				career.players[id] = nil
			else
				if p.pot < p.ovr then
					p.pot = p.ovr
				end
				p.value = computeValue(p)
			end
		end
	end

	local youth = 0
	for _, t in ipairs(CLUB_TEMPLATES) do
		updateClubLevel(career, t.id)
		local added = fillClubSquad(career, t.id, t.id == career.userClubId)
		if t.id == career.userClubId then
			youth = added
		end
	end

	for _, p in pairs(career.players) do
		p.fit = 100
		p.apps = 0
		p.goals = 0
		p.seasonStartOvr = p.ovr
	end

	generateMarket(career)
	resetStandings(career)
	generateFixtures(career)
	repairLineup(career)
	addFinance(career, "Início da temporada " .. career.season, 0)

	local msg = "Temporada " .. career.season .. " iniciada!"
	if retired > 0 then
		msg ..= string.format(" %d jogador(es) se aposentaram.", retired)
	end
	if youth > 0 then
		msg ..= string.format(" %d jovem(ns) da base promovido(s).", youth)
	end
	return true, msg
end

local function createCareer(player, clubIndex, customName)
	local template = CLUB_TEMPLATES[clubIndex]
	local career = {
		dataVersion = Config.DATA_VERSION,
		saveRevision = 0,
		createdAt = os.time(),
		managerName = player.DisplayName,
		season = 1,
		round = 0,
		seasonOver = false,
		nextPlayerId = 0,
		clubs = {},
		players = {},
		fixtures = {},
		standings = {},
		financeLog = {},
		history = {},
		userClubId = template.id,
	}
	for _, t in ipairs(CLUB_TEMPLATES) do
		career.clubs[t.id] = {
			id = t.id,
			name = t.name,
			short = t.short,
			level = t.level,
			color = { t.color[1], t.color[2], t.color[3] },
			budget = t.budget,
			formation = t.formation,
			strategy = t.strategy,
		}
		for _, pos in ipairs(POS_ORDER) do
			for _ = 1, SQUAD_TEMPLATE[pos] do
				createPlayer(career, pos, t.level, t.id)
			end
		end
	end
	local userClub = career.clubs[career.userClubId]
	if customName then
		userClub.name = customName
		userClub.short = makeShort(customName)
	end
	generateMarket(career)
	resetStandings(career)
	generateFixtures(career)
	career.userLineup = { formation = userClub.formation, strategy = "Equilibrada", starters = {} }
	career.userLineup.starters = autoLineup(career, career.userClubId, userClub.formation)
	repairLineup(career)
	addFinance(career, "Início da carreira (verba " .. Config.formatMoney(userClub.budget) .. ")", 0)
	return career
end

local function isCareerValid(c)
	if type(c) ~= "table" then
		return false
	end
	if type(c.clubs) ~= "table" or type(c.players) ~= "table" then
		return false
	end
	if type(c.fixtures) ~= "table" or type(c.standings) ~= "table" then
		return false
	end
	if type(c.userClubId) ~= "string" or type(c.clubs[c.userClubId]) ~= "table" then
		return false
	end
	if type(c.userLineup) ~= "table" or type(c.userLineup.starters) ~= "table" then
		return false
	end
	if #c.fixtures ~= TOTAL_ROUNDS then
		return false
	end
	if type(c.season) ~= "number" or type(c.round) ~= "number" then
		return false
	end
	local count = 0
	for _, p in pairs(c.players) do
		if type(p) == "table" and p.clubId == c.userClubId then
			count += 1
		end
	end
	return count >= 11
end

local function normalizeCareer(c)
	c.financeLog = type(c.financeLog) == "table" and c.financeLog or {}
	c.history = type(c.history) == "table" and c.history or {}
	c.nextPlayerId = tonumber(c.nextPlayerId) or 100000
	c.seasonOver = c.seasonOver == true
	for _, p in pairs(c.players) do
		p.fit = tonumber(p.fit) or 100
		p.apps = tonumber(p.apps) or 0
		p.goals = tonumber(p.goals) or 0
		p.seasonStartOvr = tonumber(p.seasonStartOvr) or p.ovr
	end
	repairLineup(c)
end

---------------------------------------------------------------------
-- ESTADO ENVIADO AO CLIENTE (somente leitura)
---------------------------------------------------------------------
local function clubName(career, id)
	local c = career.clubs[id]
	return c and c.name or "?"
end

local function clubShort(career, id)
	local c = career.clubs[id]
	return c and c.short or "?"
end

local function playerView(p, starterSlot)
	return {
		id = p.id,
		name = p.name,
		age = p.age,
		pos = p.pos,
		ovr = p.ovr,
		pot = p.pot,
		value = p.value,
		wage = p.wage,
		fit = math.floor(p.fit + 0.5),
		apps = p.apps or 0,
		goals = p.goals or 0,
		delta = p.ovr - (p.seasonStartOvr or p.ovr),
		starterSlot = starterSlot,
		sellPrice = sellPrice(p),
	}
end

local function buildCareerState(career)
	local userId = career.userClubId
	local club = career.clubs[userId]
	local lu = career.userLineup

	local slotOf = {}
	for i = 1, 11 do
		local id = lu.starters[i]
		if type(id) == "string" then
			slotOf[id] = i
		end
	end

	local squadList = getSquad(career, userId)
	local squad = {}
	local tired = 0
	for _, p in ipairs(squadList) do
		table.insert(squad, playerView(p, slotOf[p.id]))
		if slotOf[p.id] and p.fit < 70 then
			tired += 1
		end
	end

	local slots = FORMATIONS[lu.formation].slots
	local lineupSlots = {}
	for i, slotPos in ipairs(slots) do
		local id = lu.starters[i]
		local p = id and career.players[id]
		table.insert(lineupSlots, {
			slot = i,
			pos = slotPos,
			playerId = p and p.id or nil,
			factor = p and posFactor(p.pos, slotPos) or 0,
		})
	end
	local att, def = teamStrength(career, lu.starters, lu.formation, lu.strategy)

	local nextMatch = nil
	if not career.seasonOver then
		local fixtures = career.fixtures[career.round + 1]
		if fixtures then
			for _, fx in ipairs(fixtures) do
				if fx.home == userId or fx.away == userId then
					local oppId = fx.home == userId and fx.away or fx.home
					local opp = career.clubs[oppId]
					local oppStarters = autoLineup(career, oppId, opp.formation)
					local oAtt, oDef = teamStrength(career, oppStarters, opp.formation, opp.strategy)
					local sum, n = 0, 0
					for _, id in ipairs(oppStarters) do
						local p = id and career.players[id]
						if p then
							sum += p.ovr
							n += 1
						end
					end
					nextMatch = {
						round = career.round + 1,
						isHome = fx.home == userId,
						homeName = clubName(career, fx.home),
						awayName = clubName(career, fx.away),
						oppName = opp.name,
						oppShort = opp.short,
						oppFormation = opp.formation,
						oppStrategy = opp.strategy,
						oppAtt = round1(oAtt),
						oppDef = round1(oDef),
						oppAvg = n > 0 and round1(sum / n) or 0,
					}
					break
				end
			end
		end
	end

	local standings = {}
	local userPos, userPts = 0, 0
	for i, row in ipairs(sortedStandings(career)) do
		local c = career.clubs[row.id]
		table.insert(standings, {
			pos = i,
			name = row.name,
			short = c.short,
			color = c.color,
			played = row.played,
			w = row.w,
			d = row.d,
			l = row.l,
			gf = row.gf,
			ga = row.ga,
			gd = row.gd,
			pts = row.pts,
			isUser = row.id == userId,
		})
		if row.id == userId then
			userPos, userPts = i, row.pts
		end
	end

	local fixturesView = {}
	for r, list in ipairs(career.fixtures) do
		local matches = {}
		for _, fx in ipairs(list) do
			table.insert(matches, {
				home = clubName(career, fx.home),
				away = clubName(career, fx.away),
				hg = fx.hg,
				ag = fx.ag,
				played = fx.played,
				isUser = fx.home == userId or fx.away == userId,
			})
		end
		table.insert(fixturesView, { round = r, matches = matches })
	end

	local market = {}
	for _, p in pairs(career.players) do
		if p.clubId == MARKET then
			table.insert(market, playerView(p, nil))
		end
	end
	table.sort(market, function(a, b)
		if a.ovr ~= b.ovr then
			return a.ovr > b.ovr
		end
		return a.id < b.id
	end)

	local squadValue = 0
	for _, p in ipairs(squadList) do
		squadValue += p.value
	end
	local log = {}
	for i = #career.financeLog, 1, -1 do
		table.insert(log, career.financeLog[i])
	end
	local history = {}
	for i = #career.history, 1, -1 do
		table.insert(history, career.history[i])
	end

	local report = nil
	local lr = career.lastReport
	if lr then
		local others = {}
		for _, o in ipairs(lr.others or {}) do
			table.insert(others, { homeName = clubName(career, o.home), awayName = clubName(career, o.away), hg = o.hg, ag = o.ag })
		end
		report = {
			round = lr.round,
			homeName = clubName(career, lr.home),
			awayName = clubName(career, lr.away),
			homeShort = clubShort(career, lr.home),
			awayShort = clubShort(career, lr.away),
			hg = lr.hg,
			ag = lr.ag,
			xgH = lr.xgH or 0,
			xgA = lr.xgA or 0,
			events = lr.events or {},
			others = others,
			userIsHome = lr.home == userId,
		}
	end

	return {
		managerName = career.managerName,
		season = career.season,
		round = career.round,
		totalRounds = TOTAL_ROUNDS,
		seasonOver = career.seasonOver,
		seasonSummary = career.lastSeasonSummary,
		club = { id = club.id, name = club.name, short = club.short, color = club.color, budget = club.budget, level = club.level },
		squad = squad,
		squadCount = #squad,
		squadMin = SQUAD_MIN,
		squadMax = SQUAD_MAX,
		tiredStarters = tired,
		lineup = { formation = lu.formation, strategy = lu.strategy, slots = lineupSlots },
		strength = { att = round1(att), def = round1(def) },
		nextMatch = nextMatch,
		standings = standings,
		userPos = userPos,
		userPts = userPts,
		fixtures = fixturesView,
		market = market,
		finance = {
			budget = club.budget,
			wages = wagesPerRound(career),
			gate = homeGate(career),
			tv = TV_MONEY,
			squadValue = squadValue,
			log = log,
			history = history,
		},
		lastReport = report,
	}
end

local function buildState(session)
	local s = {
		version = Config.VERSION,
		hasCareer = session.career ~= nil,
		saveBlocked = session.saveBlocked,
		saveMsg = session.saveMsg,
		lastSave = session.lastSave,
		unsaved = session.changeCounter > session.savedCounter,
		clubTemplates = {},
		formations = {},
		strategies = {},
	}
	for i, t in ipairs(CLUB_TEMPLATES) do
		table.insert(s.clubTemplates, { index = i, name = t.name, short = t.short, level = t.level, budget = t.budget, color = t.color })
	end
	for _, name in ipairs(Config.FORMATION_ORDER) do
		local f = FORMATIONS[name]
		table.insert(s.formations, { name = name, desc = f.desc, att = f.att, def = f.def })
	end
	for _, name in ipairs(Config.STRATEGY_ORDER) do
		local st = STRATEGIES[name]
		table.insert(s.strategies, { name = name, desc = st.desc, att = st.att, def = st.def })
	end
	if session.career then
		s.career = buildCareerState(session.career)
	end
	return s
end

---------------------------------------------------------------------
-- SALVAMENTO (DataStoreService)
---------------------------------------------------------------------
local careerStore = nil
do
	local ok, err = pcall(function()
		careerStore = DataStoreService:GetDataStore(Config.DATASTORE_NAME)
	end)
	if not ok then
		careerStore = nil
		warn("[CL] DataStore indisponível:", err)
	end
end

local sessions = {}
local activeSaves = 0

local function markDirty(session)
	session.changeCounter += 1
end

local function saveSession(session, force)
	if not careerStore then
		return false, "DataStore indisponível neste servidor. O progresso não foi salvo."
	end
	if session.saveBlocked then
		return false, session.saveMsg
	end
	local career = session.career
	if not career then
		return false, "Nenhuma carreira para salvar"
	end
	if not force and session.changeCounter <= session.savedCounter then
		return true, "Nenhuma alteração pendente"
	end
	if not isCareerValid(career) then
		return false, "Dados da carreira inválidos; salvamento cancelado para proteger o progresso"
	end
	if session.saving then
		return false, "Salvamento já em andamento"
	end
	session.saving = true
	activeSaves += 1
	session.lastSaveAttempt = os.clock()

	local counterAtSnapshot = session.changeCounter
	local snapshot = deepCopy(career)
	snapshot.savedAt = os.time()
	local key = Config.SAVE_KEY_PREFIX .. tostring(session.userId)
	local conflict, newRevision = false, nil
	local success, err = false, nil
	for attempt = 1, 3 do
		success, err = pcall(function()
			careerStore:UpdateAsync(key, function(old)
				conflict = false
				local oldRev = 0
				if type(old) == "table" then
					oldRev = tonumber(old.saveRevision) or 0
				end
				if oldRev > session.revision then
					conflict = true
					return nil
				end
				snapshot.saveRevision = oldRev + 1
				newRevision = oldRev + 1
				return snapshot
			end)
		end)
		if success then
			break
		end
		task.wait(attempt * 2)
	end
	session.saving = false
	activeSaves -= 1

	if not success then
		session.saveMsg = "Falha ao salvar (" .. tostring(err) .. "). Nova tentativa automática em breve."
		return false, session.saveMsg
	end
	if conflict then
		session.saveBlocked = true
		session.saveMsg = "Existe um salvamento mais recente feito em outro servidor. Salvamento desativado nesta sessão para não sobrescrevê-lo. Reentre no jogo."
		return false, session.saveMsg
	end
	session.revision = newRevision
	if session.career then
		session.career.saveRevision = newRevision
	end
	session.savedCounter = math.max(session.savedCounter, counterAtSnapshot)
	session.lastSave = snapshot.savedAt
	session.saveMsg = "Carreira salva com sucesso"
	return true, session.saveMsg
end

local function requestSave(session)
	if session.saveBlocked or session.saving or not careerStore then
		return
	end
	if os.clock() - session.lastSaveAttempt >= MIN_SAVE_INTERVAL then
		task.spawn(saveSession, session, false)
	end
end

local function loadSession(player)
	local session = {
		userId = player.UserId,
		loaded = false,
		saveBlocked = false,
		career = nil,
		revision = 0,
		busy = false,
		saving = false,
		changeCounter = 0,
		savedCounter = 0,
		lastSave = 0,
		lastSaveAttempt = -math.huge,
		lastManualSave = -math.huge,
		lastRequest = 0,
		saveMsg = "Nenhum salvamento nesta sessão ainda",
	}
	sessions[player] = session

	if not careerStore then
		session.saveBlocked = true
		session.saveMsg = "DataStore indisponível. Você pode jogar, mas o progresso NÃO será salvo."
		session.loaded = true
		return
	end

	local key = Config.SAVE_KEY_PREFIX .. tostring(player.UserId)
	local data, ok, err = nil, false, nil
	for attempt = 1, 3 do
		ok, err = pcall(function()
			data = careerStore:GetAsync(key)
		end)
		if ok then
			break
		end
		task.wait(attempt * 2)
	end

	if not ok then
		session.saveBlocked = true
		session.saveMsg = "Não foi possível carregar seus dados. Para proteger seu progresso, o salvamento está desativado nesta sessão. Reentre mais tarde."
		warn("[CL] Falha no GetAsync:", err)
	elseif data == nil then
		session.saveMsg = "Nenhuma carreira salva encontrada"
	elseif isCareerValid(data) and data.dataVersion == Config.DATA_VERSION then
		local nOk, nErr = pcall(normalizeCareer, data)
		if nOk then
			session.career = data
			session.revision = tonumber(data.saveRevision) or 0
			session.lastSave = tonumber(data.savedAt) or 0
			session.saveMsg = "Carreira carregada"
		else
			session.saveBlocked = true
			session.saveMsg = "Erro ao preparar a carreira salva. Salvamento desativado para não sobrescrevê-la."
			warn("[CL] normalizeCareer:", nErr)
		end
	else
		session.saveBlocked = true
		session.saveMsg = "Os dados salvos estão em formato incompatível. Salvamento desativado para não sobrescrevê-los."
	end
	session.loaded = true
end

local function waitForSession(player)
	local t0 = os.clock()
	while os.clock() - t0 < 20 do
		local s = sessions[player]
		if s and s.loaded then
			return s
		end
		if not player.Parent then
			return nil
		end
		task.wait(0.2)
	end
	return nil
end

---------------------------------------------------------------------
-- FILTRO DE NOME
---------------------------------------------------------------------
local function filterClubName(player, raw)
	local name = trim(raw)
	name = (string.gsub(name, "%s+", " "))
	local len = utf8.len(name)
	if not len then
		return nil, "Nome com caracteres inválidos"
	end
	if len < 3 or len > 24 then
		return nil, "O nome do clube deve ter entre 3 e 24 caracteres"
	end
	if string.find(name, "%c") then
		return nil, "Nome com caracteres inválidos"
	end
	local ok, result = pcall(function()
		local filtered = TextService:FilterStringAsync(name, player.UserId, Enum.TextFilterContext.PublicChat)
		return filtered:GetNonChatStringForBroadcastAsync()
	end)
	if not ok then
		return nil, "Não foi possível verificar o nome agora. Tente novamente ou deixe o campo vazio."
	end
	if result ~= name then
		return nil, "Este nome foi bloqueado pelo filtro do Roblox"
	end
	return name
end

---------------------------------------------------------------------
-- AÇÕES (validadas no servidor)
---------------------------------------------------------------------
local handlers = {}

handlers.getState = function()
	return true, nil
end

handlers.newCareer = function(player, session, payload)
	local idx = tonumber(payload.clubIndex)
	if not idx or idx % 1 ~= 0 or idx < 1 or idx > #CLUB_TEMPLATES then
		return false, "Clube inválido"
	end
	if session.career and payload.confirm ~= true then
		return false, "Confirme para substituir a carreira atual"
	end
	local customName = nil
	if typeof(payload.customName) == "string" and trim(payload.customName) ~= "" then
		local name, err = filterClubName(player, payload.customName)
		if not name then
			return false, err
		end
		customName = name
	end
	session.career = createCareer(player, idx, customName)
	markDirty(session)
	requestSave(session)
	return true, "Carreira criada! Bem-vindo ao " .. session.career.clubs[session.career.userClubId].name
end

handlers.swapLineup = function(_, session, payload)
	local career = session.career
	if not career then
		return false, NO_CAREER
	end
	local slot = tonumber(payload.slot)
	local pid = payload.playerId
	if not slot or slot % 1 ~= 0 or slot < 1 or slot > 11 then
		return false, "Posição inválida"
	end
	if typeof(pid) ~= "string" then
		return false, "Jogador inválido"
	end
	local p = career.players[pid]
	if not p or p.clubId ~= career.userClubId then
		return false, "Este jogador não pertence ao seu clube"
	end
	repairLineup(career)
	local starters = career.userLineup.starters
	local currentIdx = nil
	for i = 1, 11 do
		if starters[i] == pid then
			currentIdx = i
			break
		end
	end
	if currentIdx == slot then
		return true, "Sem alterações"
	end
	if slot == 1 and p.pos ~= "GOL" then
		return false, "Apenas goleiros podem ocupar a posição GOL"
	end
	if currentIdx then
		local other = starters[slot]
		local op = other and career.players[other]
		if currentIdx == 1 and (not op or op.pos ~= "GOL") then
			return false, "O goleiro titular só pode ser trocado por outro goleiro"
		end
		starters[slot], starters[currentIdx] = pid, other
	else
		starters[slot] = pid
	end
	repairLineup(career)
	markDirty(session)
	return true, p.name .. " escalado"
end

handlers.autoLineup = function(_, session)
	local career = session.career
	if not career then
		return false, NO_CAREER
	end
	local lu = career.userLineup
	lu.starters = autoLineup(career, career.userClubId, lu.formation)
	repairLineup(career)
	markDirty(session)
	return true, "Escalação automática aplicada"
end

handlers.setFormation = function(_, session, payload)
	local career = session.career
	if not career then
		return false, NO_CAREER
	end
	local f = payload.formation
	if typeof(f) ~= "string" or not FORMATIONS[f] then
		return false, "Formação inválida"
	end
	reassignToFormation(career, f)
	markDirty(session)
	return true, "Formação alterada para " .. f
end

handlers.setStrategy = function(_, session, payload)
	local career = session.career
	if not career then
		return false, NO_CAREER
	end
	local s = payload.strategy
	if typeof(s) ~= "string" or not STRATEGIES[s] then
		return false, "Estratégia inválida"
	end
	career.userLineup.strategy = s
	markDirty(session)
	return true, "Estratégia: " .. s
end

handlers.playRound = function(_, session, payload)
	local career = session.career
	if not career then
		return false, NO_CAREER
	end
	local expected = tonumber(payload.expectedRound)
	if expected ~= career.round + 1 then
		return false, "Esta rodada já foi processada. Tela atualizada."
	end
	local ok, msg = playRound(career)
	if ok then
		markDirty(session)
		requestSave(session)
	end
	return ok, msg
end

handlers.buyPlayer = function(_, session, payload)
	local career = session.career
	if not career then
		return false, NO_CAREER
	end
	local id = payload.playerId
	if typeof(id) ~= "string" then
		return false, "Jogador inválido"
	end
	local p = career.players[id]
	if not p then
		return false, "Jogador inexistente"
	end
	if p.clubId ~= MARKET then
		return false, "Este jogador não está disponível no mercado"
	end
	local squadSize = #getSquad(career, career.userClubId)
	if squadSize >= SQUAD_MAX then
		return false, string.format("Elenco cheio (máximo %d jogadores)", SQUAD_MAX)
	end
	local club = career.clubs[career.userClubId]
	local price = p.value
	if club.budget < price then
		return false, "Orçamento insuficiente para esta contratação"
	end
	p.clubId = career.userClubId
	p.seasonStartOvr = p.ovr
	addFinance(career, "Contratação: " .. p.name, -price)
	markDirty(session)
	requestSave(session)
	return true, string.format("%s contratado por %s", p.name, Config.formatMoney(price))
end

handlers.sellPlayer = function(_, session, payload)
	local career = session.career
	if not career then
		return false, NO_CAREER
	end
	local id = payload.playerId
	if typeof(id) ~= "string" then
		return false, "Jogador inválido"
	end
	local p = career.players[id]
	if not p then
		return false, "Jogador inexistente"
	end
	if p.clubId ~= career.userClubId then
		return false, "Este jogador não pertence ao seu clube"
	end
	local squad = getSquad(career, career.userClubId)
	if #squad <= SQUAD_MIN then
		return false, string.format("Seu elenco precisa ter pelo menos %d jogadores", SQUAD_MIN)
	end
	if p.pos == "GOL" and countPos(squad, "GOL") <= 1 then
		return false, "Você precisa manter pelo menos um goleiro"
	end
	local price = sellPrice(p)
	p.clubId = MARKET
	addFinance(career, "Venda: " .. p.name, price)
	repairLineup(career)
	markDirty(session)
	requestSave(session)
	return true, string.format("%s vendido por %s", p.name, Config.formatMoney(price))
end

handlers.newSeason = function(_, session)
	local career = session.career
	if not career then
		return false, NO_CAREER
	end
	local ok, msg = startNewSeason(career)
	if ok then
		markDirty(session)
		requestSave(session)
	end
	return ok, msg
end

handlers.saveNow = function(_, session)
	if not session.career then
		return false, NO_CAREER
	end
	if os.clock() - session.lastManualSave < 15 then
		return false, "Aguarde alguns segundos antes de salvar novamente"
	end
	session.lastManualSave = os.clock()
	return saveSession(session, true)
end

---------------------------------------------------------------------
-- REMOTES
---------------------------------------------------------------------
local remoteFolder = ReplicatedStorage:FindFirstChild(Config.REMOTE_FOLDER)
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = Config.REMOTE_FOLDER
	remoteFolder.Parent = ReplicatedStorage
end
local requestFn = remoteFolder:FindFirstChild(Config.REQUEST_FUNCTION)
if not requestFn then
	requestFn = Instance.new("RemoteFunction")
	requestFn.Name = Config.REQUEST_FUNCTION
	requestFn.Parent = remoteFolder
end

requestFn.OnServerInvoke = function(player, action, payload)
	if typeof(action) ~= "string" then
		return { ok = false, msg = "Ação inválida" }
	end
	if typeof(payload) ~= "table" then
		payload = {}
	end
	local session = waitForSession(player)
	if not session then
		return { ok = false, msg = "Seus dados ainda estão carregando. Tente novamente." }
	end
	local handler = handlers[action]
	if not handler then
		return { ok = false, msg = "Ação desconhecida", state = buildState(session) }
	end
	if session.busy then
		return { ok = false, msg = "Processando a ação anterior, aguarde.", state = buildState(session) }
	end
	if os.clock() - session.lastRequest < 0.1 then
		return { ok = false, msg = "Muitas ações seguidas, aguarde um instante.", state = buildState(session) }
	end
	session.lastRequest = os.clock()
	session.busy = true
	local success, ok, msg = pcall(handler, player, session, payload)
	session.busy = false
	if not success then
		warn("[CL] Erro na ação", action, ok)
		return { ok = false, msg = "Erro interno no servidor. Nada foi alterado de forma intencional.", state = buildState(session) }
	end
	return { ok = ok == true, msg = msg, state = buildState(session) }
end

---------------------------------------------------------------------
-- CICLO DE VIDA
---------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	loadSession(player)
end)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(loadSession, player)
end

Players.PlayerRemoving:Connect(function(player)
	local session = sessions[player]
	if not session then
		return
	end
	local t0 = os.clock()
	while (session.saving or session.busy) and os.clock() - t0 < 15 do
		task.wait(0.25)
	end
	if session.career and not session.saveBlocked and session.changeCounter > session.savedCounter then
		saveSession(session, false)
	end
	sessions[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for _, session in pairs(sessions) do
			if session.loaded and session.career and not session.saveBlocked and not session.saving
				and session.changeCounter > session.savedCounter
				and os.clock() - session.lastSaveAttempt >= 30 then
				task.spawn(saveSession, session, false)
			end
		end
	end
end)

game:BindToClose(function()
	local pendingCount = 0
	for _, session in pairs(sessions) do
		pendingCount += 1
		task.spawn(function()
			local t0 = os.clock()
			while session.saving and os.clock() - t0 < 10 do
				task.wait(0.25)
			end
			if session.career and not session.saveBlocked and session.changeCounter > session.savedCounter then
				saveSession(session, false)
			end
			pendingCount -= 1
		end)
	end
	local t0 = os.clock()
	while (pendingCount > 0 or activeSaves > 0) and os.clock() - t0 < 25 do
		task.wait(0.25)
	end
end)

print("[CL] " .. Config.GAME_NAME .. " " .. Config.VERSION .. " - servidor iniciado")
