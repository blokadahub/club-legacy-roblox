--!strict
-- Identidade inteiramente fictícia. Nenhuma fotografia ou marca de clube real.
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end
local function club(id, name, shortName, country, league, primary, secondary, ratings, symbol)
	return {
		id = id, name = name, shortName = shortName, country = country, league = league,
		primary = primary, secondary = secondary, attack = ratings[1], midfield = ratings[2], defense = ratings[3],
		stars = math.floor((ratings[1] + ratings[2] + ratings[3]) / 3 / 18 * 2) / 2,
		symbol = symbol, founded = 1927 + id * 3,
		kits = {
			{name = "Mandante", shirt = primary, shorts = primary, socks = secondary, accent = secondary},
			{name = "Visitante", shirt = rgb(232, 240, 237), shorts = secondary, socks = rgb(232, 240, 237), accent = primary},
			{name = "Alternativo", shirt = rgb(20, 29, 43), shorts = rgb(20, 29, 43), socks = primary, accent = secondary},
		},
	}
end
local clubs = {
	club(1, "Atlético Aurora", "AUR", "Brasil", "Liga Horizonte", rgb(10, 108, 91), rgb(98, 246, 210), {85, 84, 82}, "A"),
	club(2, "Porto Celeste", "PCE", "Brasil", "Liga Horizonte", rgb(28, 74, 141), rgb(137, 207, 246), {83, 82, 84}, "P"),
	club(3, "União da Serra", "SER", "Brasil", "Liga Horizonte", rgb(93, 39, 89), rgb(234, 183, 122), {79, 81, 80}, "S"),
	club(4, "Ferroviário Capital", "FCA", "Brasil", "Liga Horizonte", rgb(166, 58, 44), rgb(244, 220, 173), {81, 78, 79}, "F"),
	club(5, "Lusitano do Atlântico", "LDA", "Portugal", "Liga Atlântica", rgb(21, 99, 114), rgb(244, 204, 104), {82, 85, 81}, "L"),
	club(6, "Estrela do Norte", "ENO", "Portugal", "Liga Atlântica", rgb(40, 56, 106), rgb(199, 219, 244), {80, 80, 83}, "E"),
	club(7, "Deportivo Brisa", "DBR", "Argentina", "Liga do Prata", rgb(45, 121, 164), rgb(227, 239, 249), {84, 82, 78}, "B"),
	club(8, "Sporting Valença", "SVA", "Argentina", "Liga do Prata", rgb(123, 63, 43), rgb(224, 173, 84), {78, 79, 82}, "V"),
}
local raw = {
	{"Caio Monteiro", "MONTEIRO", "GOL", 84, 87, 28, 188},
	{"Ícaro Nunes", "NUNES", "LD", 81, 87, 23, 178},
	{"Davi Tavares", "TAVARES", "ZAG", 85, 88, 27, 190},
	{"Noah Ribeiro", "RIBEIRO", "ZAG", 83, 89, 24, 187},
	{"Luan Pires", "PIRES", "LE", 82, 88, 22, 176},
	{"Bento Azevedo", "AZEVEDO", "VOL", 84, 87, 26, 183},
	{"Ravi Duarte", "DUARTE", "MC", 86, 92, 21, 180},
	{"Enzo Vilar", "VILAR", "MEI", 87, 91, 25, 178},
	{"Theo Matos", "MATOS", "PD", 85, 90, 23, 176},
	{"Miguel Solano", "SOLANO", "ATA", 89, 92, 26, 185},
	{"Gael Costa", "COSTA", "PE", 86, 93, 20, 179},
	{"Otávio Reis", "REIS", "GOL", 78, 84, 24, 191},
	{"Pedro Vale", "VALE", "ZAG", 79, 85, 22, 189},
	{"Samuel Leal", "LEAL", "LD", 78, 86, 20, 177},
	{"Yuri Prado", "PRADO", "LE", 77, 84, 21, 175},
	{"Nicolas Luz", "LUZ", "VOL", 80, 85, 24, 182},
	{"Danilo Freire", "FREIRE", "MC", 81, 88, 22, 179},
	{"Arthur Braga", "BRAGA", "MEI", 79, 90, 19, 177},
	{"Lucas Salgado", "SALGADO", "PD", 80, 87, 21, 174},
	{"Vitor Melo", "MELO", "ATA", 82, 88, 23, 186},
	{"João Salles", "SALLES", "PE", 78, 89, 19, 178},
	{"Cauã Marinho", "MARINHO", "MC", 76, 88, 18, 181},
}
local skins = {rgb(133, 83, 56), rgb(207, 157, 115), rgb(94, 58, 41), rgb(227, 180, 143), rgb(171, 118, 79)}
local players = {}
for i, row in ipairs(raw) do
	local overall = row[4]
	local defensive = row[3] == "ZAG" or row[3] == "VOL" or row[3] == "GOL"
	players[i] = {
		id = i, name = row[1], shortName = row[2], position = row[3], overall = overall,
		potential = row[5], age = row[6], height = row[7], foot = if i % 4 == 0 then "Esquerdo" else "Direito",
		number = ({1, 2, 4, 3, 6, 5, 8, 10, 7, 9, 11})[(i - 1) % 11 + 1] + (if i > 11 then 12 else 0),
		skin = skins[(i - 1) % #skins + 1], hair = rgb(26 + i % 4 * 9, 22 + i % 3 * 7, 19 + i % 2 * 6),
		fitness = 89 + i % 11, morale = "Confiante", form = if i % 5 == 0 then "Excelente" else "Boa",
		value = (overall - 65) * (overall - 65) * 95000,
		attributes = {pace = math.clamp(overall + (if defensive then -9 else 3), 40, 95),
			shooting = math.clamp(overall + (if defensive then -24 else 1), 35, 95),
			passing = overall - 3 + i % 4, dribbling = overall + (if defensive then -14 else 2),
			defending = overall + (if defensive then 2 else -32), physical = overall - 4 + i % 7},
	}
end
local function positions(rows, playerOrder)
	local result = {{x = 0.5, y = 0.88}}
	for _, row in ipairs(rows) do
		for _, x in ipairs(row[2]) do table.insert(result, {x = x, y = row[1]}) end
	end
	if not playerOrder then return result end
	local ordered = {}
	for playerIndex, slot in ipairs(playerOrder) do ordered[playerIndex] = result[slot] end
	return ordered
end
return {
	clubs = clubs, players = players,
	standingsCompetition = "Circuito Legado",
	formations = {
		{name = "4–3–3", positions = positions({{0.67, {0.12, 0.37, 0.63, 0.88}}, {0.43, {0.25, 0.5, 0.75}}, {0.16, {0.15, 0.5, 0.85}}}, {1,5,4,3,2,7,8,6,11,10,9})},
		{name = "4–2–3–1", positions = positions({{0.68, {0.12, 0.37, 0.63, 0.88}}, {0.49, {0.34, 0.66}}, {0.29, {0.16, 0.5, 0.84}}, {0.08, {0.5}}}, {1,5,4,3,2,6,7,9,10,11,8})},
		{name = "3–5–2", positions = positions({{0.68, {0.2, 0.5, 0.8}}, {0.43, {0.08, 0.29, 0.5, 0.71, 0.92}}, {0.13, {0.34, 0.66}}}, {1,9,4,3,5,2,8,7,11,10,6})},
	},
	fixtures = {
		{day = 3, month = 11, opponent = 2, competition = "Liga Horizonte", home = true},
		{day = 7, month = 11, opponent = 4, competition = "Copa Legado", home = false},
		{day = 12, month = 11, opponent = 3, competition = "Liga Horizonte", home = true},
		{day = 18, month = 11, opponent = 5, competition = "Taça Continental", home = false},
		{day = 23, month = 11, opponent = 4, competition = "Liga Horizonte", home = true},
		{day = 28, month = 11, opponent = 2, competition = "Liga Horizonte", home = false},
		{day = 4, month = 12, opponent = 7, competition = "Taça Continental", home = true},
		{day = 9, month = 12, opponent = 3, competition = "Liga Horizonte", home = false},
	},
	table = {
		{club=1,played=12,won=8,drawn=3,lost=1,gf=26,ga=11,points=27},
		{club=2,played=12,won=8,drawn=1,lost=3,gf=23,ga=13,points=25},
		{club=3,played=12,won=6,drawn=4,lost=2,gf=20,ga=14,points=22},
		{club=4,played=12,won=5,drawn=3,lost=4,gf=18,ga=17,points=18},
		{club=5,played=12,won=4,drawn=4,lost=4,gf=16,ga=17,points=16},
		{club=6,played=12,won=3,drawn=4,lost=5,gf=15,ga=19,points=13},
		{club=7,played=12,won=2,drawn=3,lost=7,gf=12,ga=22,points=9},
		{club=8,played=12,won=0,drawn=2,lost=10,gf=10,ga=27,points=2},
	},
}
