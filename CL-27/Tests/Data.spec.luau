-- Recebe o módulo real; pode ser chamado no Studio ou pelo executor CLI.
return function(data)
	local assertions = 0
	local function check(condition, message)
		assertions += 1
		assert(condition, message)
	end
	local function total(rows, key)
		local result = 0
		for _, row in ipairs(rows) do result += row[key] end
		return result
	end
	local ids = {}
	for _, group in ipairs({data.players, data.market}) do
		for _, player in ipairs(group) do
			check(not ids[player.id], "Identificador de jogador repetido: " .. player.id)
			ids[player.id] = true
			check(data.positionNames[player.position] ~= nil, "Posição desconhecida")
			check(player.potential >= player.overall and player.potential <= 99, "Potencial inválido")
			check(player.age >= 18 and player.age <= 45, "Idade inválida")
			check(player.fitness >= 0 and player.fitness <= 100, "Condição inválida")
			check(player.wage > 0 and player.value > 0, "Salário ou valor inválido")
			local attributes = 0
			for _, value in pairs(player.attributes) do
				attributes += 1
				check(value > 0 and value <= 99, "Atributo fora da faixa")
			end
			check(attributes == 6, "Seis atributos esperados")
		end
	end
	check(#data.players == 18 and #data.market == 12, "Elenco ou mercado incompleto")
	check(total(data.players, "wage") == data.finance.weeklyWages, "Folha não corresponde aos salários")
	for name, formation in pairs(data.formations) do
		check(#formation.slots == 11, "Formação incompleta: " .. name)
		local coordinates = {}
		for _, slot in ipairs(formation.slots) do
			check(slot.x >= 0 and slot.x <= 1 and slot.y >= 0 and slot.y <= 1, "Posição fora do campo")
			check(data.positionNames[slot.role] ~= nil, "Função tática desconhecida")
			local key = tostring(slot.x) .. ":" .. tostring(slot.y)
			check(not coordinates[key], "Duas posições sobrepostas")
			coordinates[key] = true
		end
	end
	check(#data.standings == 8, "Liga incompleta")
	local lastPoints = math.huge
	for _, club in ipairs(data.standings) do
		check(club.played == club.wins + club.draws + club.losses, "Total de jogos incoerente")
		check(club.points == club.wins * 3 + club.draws, "Pontuação incoerente")
		check(club.points <= lastPoints, "Classificação desordenada")
		lastPoints = club.points
	end
	check(total(data.standings, "wins") == total(data.standings, "losses"), "Vitórias e derrotas desbalanceadas")
	check(total(data.standings, "gf") == total(data.standings, "ga"), "Gols da liga desbalanceados")
	check(total(data.standings, "draws") % 2 == 0, "Empates desbalanceados")
	local fixtures = {}
	local aurora = {played=0,wins=0,draws=0,losses=0,gf=0,ga=0}
	for _, fixture in ipairs(data.fixtures) do
		check(not fixtures[fixture.id], "Confronto repetido")
		fixtures[fixture.id] = true
		check(fixture.month >= 7 and fixture.month <= 9, "Mês fora do trimestre")
		local days = fixture.month == 9 and 30 or 31
		check(fixture.day >= 1 and fixture.day <= days, "Dia inexistente")
		check(fixture.home ~= fixture.away, "Clube enfrenta a si mesmo")
		if fixture.status == "Encerrado" then
			check(type(fixture.homeScore) == "number" and type(fixture.awayScore) == "number", "Resultado ausente")
			if fixture.competition == "Liga Aurora" and (fixture.home == data.club.name or fixture.away == data.club.name) then
				local gf = fixture.home == data.club.name and fixture.homeScore or fixture.awayScore
				local ga = fixture.home == data.club.name and fixture.awayScore or fixture.homeScore
				aurora.played += 1; aurora.gf += gf; aurora.ga += ga
				if gf > ga then aurora.wins += 1 elseif gf == ga then aurora.draws += 1 else aurora.losses += 1 end
			end
		else
			check(fixture.homeScore == nil and fixture.awayScore == nil, "Confronto futuro já possui resultado")
		end
	end
	for key, value in pairs(aurora) do
		check(data.standings[1][key] == value, "Tabela não corresponde aos resultados do Aurora: " .. key)
	end
	local month = data.finance.months[#data.finance.months]
	check(total(data.finance.income,"amount") == month.income, "Receitas não fecham o mês")
	check(total(data.finance.expenses,"amount") == month.expense, "Despesas não fecham o mês")
	check(data.finance.expenses[1].amount == data.finance.weeklyWages * 4, "Salários mensais inconsistentes")
	check(data.money(18500000) == "R$ 18,5 mi", "Moeda não está em português brasileiro")
	check(data.money(1250000) == "R$ 1,25 mi", "Casas decimais de milhões incorretas")
	check(data.money(22500) == "R$ 22,5 mil", "Casas decimais de milhares incorretas")
	check(data.money(-50000) == "−R$ 50 mil", "Valor negativo incorreto")
	print("CL 27: " .. assertions .. " verificações de dados aprovadas.")
	return assertions
end
