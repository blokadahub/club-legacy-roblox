-- Dados editoriais fictícios do CL 27. Nenhuma simulação, compra ou persistência.
local Career = {}

Career.club = {
	name = "Aurora FC", short = "AUR", city = "Belo Horizonte",
	stadium = "Arena Horizonte", founded = 2027,
}
Career.today = { day = 21, month = 7, year = 2027 }
Career.positionNames = {
	GOL = "Goleiro", ZAG = "Zagueiro", LAT = "Lateral", VOL = "Volante",
	MEI = "Meia", PON = "Ponta", ATA = "Atacante",
}

local skins = {
	Color3.fromRGB(179, 119, 80), Color3.fromRGB(226, 174, 133),
	Color3.fromRGB(110, 72, 51), Color3.fromRGB(199, 145, 103),
}
local hairs = {
	Color3.fromRGB(30, 24, 22), Color3.fromRGB(67, 43, 28),
	Color3.fromRGB(26, 22, 20), Color3.fromRGB(111, 81, 43),
}
local function player(id, name, number, position, overall, potential, age, nation, height, foot, value, wage, attributes, palette)
	return {
		id = id, name = name, number = number, position = position,
		overall = overall, potential = potential, age = age, nation = nation,
		height = height, foot = foot, value = value, wage = wage,
		fitness = 86 + (number % 15), skin = skins[palette], hair = hairs[palette],
		attributes = {
			pace = attributes[1], shooting = attributes[2], passing = attributes[3],
			dribbling = attributes[4], defending = attributes[5], physical = attributes[6],
		},
	}
end

Career.players = {
	player("p01", "Gabriel Nascimento", 1, "GOL", 81, 84, 28, "Brasil", "1,92 m", "Direito", 9500000, 35000, {45, 22, 63, 38, 83, 79}, 3),
	player("p02", "Caio Tavares", 2, "LAT", 77, 83, 23, "Brasil", "1,78 m", "Direito", 6200000, 24000, {84, 49, 73, 75, 74, 71}, 2),
	player("p03", "Davi Monteiro", 4, "ZAG", 80, 85, 25, "Brasil", "1,89 m", "Direito", 8500000, 27000, {65, 38, 65, 52, 84, 86}, 1),
	player("p04", "Miguel Salcedo", 3, "ZAG", 79, 82, 27, "Uruguai", "1,87 m", "Esquerdo", 7400000, 26000, {62, 34, 68, 55, 82, 84}, 2),
	player("p05", "Ícaro Farias", 6, "LAT", 78, 86, 22, "Brasil", "1,80 m", "Esquerdo", 8000000, 25000, {87, 54, 76, 78, 72, 73}, 3),
	player("p06", "Enzo Duarte", 5, "VOL", 80, 85, 24, "Argentina", "1,83 m", "Direito", 9600000, 26000, {68, 58, 80, 72, 82, 81}, 2),
	player("p07", "Rafael Amaro", 8, "MEI", 82, 88, 23, "Brasil", "1,77 m", "Direito", 14500000, 30000, {78, 76, 86, 85, 58, 67}, 1),
	player("p08", "Tomás Villar", 10, "MEI", 81, 87, 24, "Chile", "1,79 m", "Esquerdo", 12800000, 28000, {76, 80, 84, 84, 46, 65}, 2),
	player("p09", "Levi Santos", 7, "PON", 82, 89, 21, "Brasil", "1,75 m", "Direito", 16800000, 30000, {92, 79, 76, 87, 35, 66}, 3),
	player("p10", "Nicolas Paiva", 9, "ATA", 84, 90, 22, "Brasil", "1,85 m", "Direito", 22500000, 40000, {84, 88, 70, 82, 37, 84}, 1),
	player("p11", "André Lemos", 11, "PON", 81, 86, 24, "Portugal", "1,81 m", "Esquerdo", 11900000, 32000, {88, 77, 80, 85, 39, 70}, 4),
	player("p12", "Otávio Reis", 12, "GOL", 74, 81, 21, "Brasil", "1,90 m", "Direito", 2600000, 12000, {43, 19, 55, 34, 76, 74}, 2),
	player("p13", "Samuel Costa", 14, "ZAG", 75, 83, 22, "Brasil", "1,88 m", "Direito", 3900000, 14000, {61, 30, 62, 48, 78, 80}, 3),
	player("p14", "Luís Moura", 16, "LAT", 74, 79, 26, "Brasil", "1,76 m", "Esquerdo", 2700000, 13000, {80, 45, 69, 70, 71, 68}, 1),
	player("p15", "Bruno Matos", 18, "VOL", 76, 82, 24, "Brasil", "1,82 m", "Direito", 4500000, 16000, {66, 54, 75, 66, 77, 79}, 2),
	player("p16", "Theo Vidal", 20, "MEI", 75, 86, 19, "Brasil", "1,74 m", "Direito", 5800000, 15000, {78, 69, 78, 82, 42, 58}, 4),
	player("p17", "João Esteves", 21, "PON", 72, 84, 18, "Brasil", "1,78 m", "Direito", 3100000, 8000, {87, 66, 64, 79, 32, 59}, 3),
	player("p18", "Pedro Lira", 19, "ATA", 73, 81, 20, "Brasil", "1,86 m", "Esquerdo", 2900000, 9000, {74, 76, 53, 67, 30, 77}, 1),
}

Career.market = {
	player("m01", "Vicente Prado", 9, "ATA", 83, 89, 22, "Brasil", "1,84 m", "Direito", 18500000, 38000, {83, 86, 68, 80, 35, 82}, 2),
	player("m02", "Gael Benítez", 10, "MEI", 80, 88, 21, "Argentina", "1,76 m", "Esquerdo", 13700000, 28000, {76, 75, 85, 86, 44, 63}, 1),
	player("m03", "Arthur Neves", 4, "ZAG", 81, 86, 24, "Brasil", "1,91 m", "Direito", 11200000, 30000, {67, 37, 68, 54, 85, 87}, 3),
	player("m04", "Mateo Rivas", 7, "PON", 79, 90, 19, "Uruguai", "1,74 m", "Direito", 14900000, 22000, {91, 72, 73, 85, 30, 62}, 2),
	player("m05", "Henrique Valença", 1, "GOL", 82, 85, 27, "Brasil", "1,94 m", "Direito", 10400000, 32000, {46, 21, 65, 40, 85, 82}, 4),
	player("m06", "Danilo Assunção", 6, "LAT", 78, 85, 22, "Brasil", "1,79 m", "Esquerdo", 8100000, 21000, {86, 52, 76, 77, 73, 73}, 3),
	player("m07", "Sebastián Cordero", 5, "VOL", 80, 84, 26, "Chile", "1,85 m", "Direito", 9700000, 27000, {69, 60, 79, 70, 81, 83}, 1),
	player("m08", "Bento Azevedo", 8, "MEI", 76, 89, 18, "Brasil", "1,73 m", "Direito", 9300000, 14000, {79, 67, 80, 83, 41, 55}, 4),
	player("m09", "Lorenzo Pires", 11, "PON", 81, 87, 23, "Portugal", "1,80 m", "Esquerdo", 12600000, 29000, {89, 78, 76, 84, 37, 69}, 2),
	player("m10", "Felipe Serrat", 3, "ZAG", 77, 82, 25, "Brasil", "1,87 m", "Esquerdo", 6200000, 20000, {63, 33, 65, 51, 80, 82}, 1),
	player("m11", "Ruan Alcântara", 2, "LAT", 75, 87, 20, "Brasil", "1,77 m", "Direito", 6400000, 16000, {88, 46, 71, 78, 69, 67}, 3),
	player("m12", "César Antunes", 18, "ATA", 79, 82, 28, "Brasil", "1,88 m", "Direito", 7800000, 25000, {73, 83, 62, 73, 36, 85}, 2),
}

local function slots(points, roles)
	local result = {}
	for i, point in ipairs(points) do
		result[i] = { x = point[1], y = point[2], role = roles[i] }
	end
	return result
end
Career.formations = {
	["4-3-3"] = { slots = slots({{.5,.88},{.15,.69},{.38,.72},{.62,.72},{.85,.69},{.5,.53},{.3,.4},{.7,.4},{.17,.2},{.5,.14},{.83,.2}}, {"GOL","LAT","ZAG","ZAG","LAT","VOL","MEI","MEI","PON","ATA","PON"}) },
	["4-4-2"] = { slots = slots({{.5,.88},{.15,.69},{.38,.72},{.62,.72},{.85,.69},{.14,.43},{.38,.48},{.62,.48},{.86,.43},{.34,.18},{.66,.18}}, {"GOL","LAT","ZAG","ZAG","LAT","PON","VOL","MEI","PON","ATA","ATA"}) },
	["4-2-3-1"] = { slots = slots({{.5,.88},{.15,.69},{.38,.72},{.62,.72},{.85,.69},{.35,.53},{.65,.53},{.16,.31},{.5,.34},{.84,.31},{.5,.13}}, {"GOL","LAT","ZAG","ZAG","LAT","VOL","VOL","PON","MEI","PON","ATA"}) },
}

Career.fixtures = {
	{id="f01", day=24, month=7, home="Aurora FC", away="Estrela do Sul", competition="Liga Aurora", status="Agendado", venue="Arena Horizonte", time="19:30"},
	{id="f02", day=28, month=7, home="Vale Verde", away="Aurora FC", competition="Copa Horizonte", status="Agendado", venue="Estádio das Palmeiras", time="20:00"},
	{id="f03", day=2, month=8, home="Capital Atlético", away="Aurora FC", competition="Liga Aurora", status="Agendado", venue="Parque Central", time="16:00"},
	{id="f04", day=9, month=8, home="Aurora FC", away="Porto Azul", competition="Liga Aurora", status="Agendado", venue="Arena Horizonte", time="18:30"},
	{id="f05", day=16, month=8, home="Serrano EC", away="Aurora FC", competition="Liga Aurora", status="Agendado", venue="Estádio da Serra", time="16:00"},
	{id="f06", day=23, month=8, home="Aurora FC", away="União Leste", competition="Liga Aurora", status="Agendado", venue="Arena Horizonte", time="19:30"},
	{id="f07", day=2, month=9, home="Aurora FC", away="Vale Verde", competition="Copa Horizonte", status="Agendado", venue="Arena Horizonte", time="20:00"},
	{id="f08", day=9, month=9, home="Aurora FC", away="Capital Atlético", competition="Liga Aurora", status="Agendado", venue="Arena Horizonte", time="19:30"},
	{id="f09", day=2, month=7, home="Aurora FC", away="Vale Verde", competition="Liga Aurora", status="Encerrado", homeScore=2, awayScore=1, venue="Arena Horizonte", time="19:30"},
	{id="f10", day=5, month=7, home="Estrela do Sul", away="Aurora FC", competition="Liga Aurora", status="Encerrado", homeScore=2, awayScore=1, venue="Estádio Estelar", time="16:00"},
	{id="f11", day=9, month=7, home="Aurora FC", away="Capital Atlético", competition="Liga Aurora", status="Encerrado", homeScore=3, awayScore=1, venue="Arena Horizonte", time="19:30"},
	{id="f12", day=12, month=7, home="Porto Azul", away="Aurora FC", competition="Liga Aurora", status="Encerrado", homeScore=0, awayScore=2, venue="Arena do Porto", time="16:00"},
	{id="f13", day=16, month=7, home="Aurora FC", away="Serrano EC", competition="Liga Aurora", status="Encerrado", homeScore=2, awayScore=2, venue="Arena Horizonte", time="19:30"},
	{id="f14", day=19, month=7, home="União Leste", away="Aurora FC", competition="Liga Aurora", status="Encerrado", homeScore=1, awayScore=2, venue="Estádio da União", time="16:00"},
}
Career.standings = {
	{club="Aurora FC", short="AUR", played=6, wins=4, draws=1, losses=1, gf=12, ga=7, points=13},
	{club="Estrela do Sul", short="EST", played=6, wins=4, draws=0, losses=2, gf=11, ga=8, points=12},
	{club="Vale Verde", short="VAL", played=6, wins=3, draws=2, losses=1, gf=10, ga=6, points=11},
	{club="União Leste", short="UNI", played=6, wins=3, draws=1, losses=2, gf=9, ga=8, points=10},
	{club="Real Horizonte", short="REA", played=6, wins=2, draws=2, losses=2, gf=8, ga=9, points=8},
	{club="Porto Azul", short="POR", played=6, wins=2, draws=1, losses=3, gf=7, ga=10, points=7},
	{club="Serrano EC", short="SER", played=6, wins=1, draws=1, losses=4, gf=6, ga=10, points=4},
	{club="Capital Atlético", short="CAP", played=6, wins=1, draws=0, losses=5, gf=5, ga=10, points=3},
}
Career.news = {
	{category="DESTAQUE DA SEMANA", title="Uma nova geração. O mesmo horizonte.", body="Nicolas Paiva e Levi Santos lideram o ataque do Aurora. O próximo compromisso é em casa, diante do Estrela do Sul."},
	{category="BASTIDORES", title="A base ganha espaço", body="Theo Vidal e João Esteves passam a integrar o grupo principal na identidade de formação do clube."},
	{category="CLUBE", title="Arena pronta para receber a torcida", body="A Arena Horizonte recebe a próxima rodada da Liga Aurora em 24 de julho, às 19h30."},
}
Career.objectives = {
	{title="Construir uma campanha de topo", detail="Pontuação de referência da diretoria", current=13, target=30},
	{title="Valorizar a formação", detail="Atletas de até 21 anos no elenco principal", current=5, target=6},
	{title="Equilibrar a folha salarial", detail="Folha semanal dentro do teto de R$ 650 mil", current=410000, target=650000},
}
Career.finance = {
	budget=48000000, wageBudget=650000, weeklyWages=410000,
	months={
		{label="Fev",income=6200000,expense=3100000}, {label="Mar",income=7100000,expense=3300000},
		{label="Abr",income=6800000,expense=3200000}, {label="Mai",income=8200000,expense=3350000},
		{label="Jun",income=8900000,expense=3400000}, {label="Jul",income=10000000,expense=3400000},
	},
	income={{label="Patrocínios",amount=6000000},{label="Bilheteria",amount=2400000},{label="Loja do clube",amount=1200000},{label="Premiações",amount=400000}},
	expenses={{label="Salários · 4 semanas",amount=1640000},{label="Operação do clube",amount=1100000},{label="Centro de treinamento",amount=360000},{label="Categorias de base",amount=300000}},
}

local function decimal(value, digits)
	local formatted = string.format("%." .. tostring(digits) .. "f", value)
	formatted = string.gsub(formatted, "0+$", "")
	formatted = string.gsub(formatted, "%.$", "")
	return string.gsub(formatted, "%.", ",")
end

function Career.money(value)
	local absolute = math.abs(value)
	local sign = value < 0 and "−" or ""
	if absolute >= 1000000 then
		return sign .. "R$ " .. decimal(absolute / 1000000, 2) .. " mi"
	elseif absolute >= 1000 then
		return sign .. "R$ " .. decimal(absolute / 1000, 1) .. " mil"
	end
	return sign .. "R$ " .. tostring(math.floor(absolute))
end

return Career
