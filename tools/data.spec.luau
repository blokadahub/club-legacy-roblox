-- Testes de domínio dos dados reais, executados no runtime oficial Luau.
-- O teste recebe Data para dispensar APIs Roblox e não simular a interface.
return function(data)
	local checks = 0
	local function check(condition, message)
		assert(condition, message)
		checks += 1
	end
	local function nonempty(value)
		return type(value) == "string" and #value > 0
	end
	local function color(value)
		return type(value) == "table" and value.R >= 0 and value.R <= 1
			and value.G >= 0 and value.G <= 1 and value.B >= 0 and value.B <= 1
	end
	check(#data.clubs >= 8, "A seleção precisa oferecer pelo menos oito clubes")
	check(#data.players >= 22, "Elenco precisa conter titulares e reservas")
	local clubIDs, playerIDs, numbers = {}, {}, {}
	for _, club in data.clubs do
		check(not clubIDs[club.id], "ID de clube duplicado")
		clubIDs[club.id] = true
		check(nonempty(club.name) and nonempty(club.shortName), "Identidade de clube incompleta")
		check(nonempty(club.country) and nonempty(club.league), "Competição ou país ausente")
		check(color(club.primary) and color(club.secondary), "Paleta de clube inválida")
		for _, rating in {club.attack, club.midfield, club.defense} do
			check(rating >= 0 and rating <= 99, "Atributo de clube fora do intervalo")
		end
		check(club.stars >= 0 and club.stars <= 5 and club.stars * 2 % 1 == 0, "Classificação por estrelas inválida")
		check(#club.kits >= 2, "Clube sem uniforme visitante")
		for _, kit in club.kits do
			check(nonempty(kit.name), "Uniforme sem nome")
			for _, component in {"shirt", "shorts", "socks", "accent"} do
				check(color(kit[component]), "Cor de uniforme inválida: " .. component)
			end
		end
	end
	for _, player in data.players do
		check(not playerIDs[player.id], "ID de atleta duplicado")
		playerIDs[player.id] = true
		check(not numbers[player.number], "Número de camisa duplicado no elenco")
		numbers[player.number] = true
		check(nonempty(player.name) and nonempty(player.shortName) and nonempty(player.position), "Identificação de atleta incompleta")
		check(player.overall >= 1 and player.overall <= 99, "Overall inválido")
		check(player.potential >= player.overall and player.potential <= 99, "Potencial incoerente")
		check(player.fitness >= 0 and player.fitness <= 100, "Condição inválida")
		check(player.age >= 18 and player.height >= 150 and player.height <= 220, "Dados físicos inválidos")
		check(color(player.skin) and color(player.hair), "Aparência inválida")
		for _, key in {"pace", "shooting", "passing", "dribbling", "defending", "physical"} do
			check(type(player.attributes[key]) == "number" and player.attributes[key] >= 0 and player.attributes[key] <= 99,
				"Atributo de atleta inválido: " .. key)
		end
	end
	check(data.players[1].position == "GOL", "Índice inicial da formação precisa ser o goleiro")
	check(#data.formations >= 3, "Faltam alternativas de formação")
	for _, formation in data.formations do
		check(nonempty(formation.name), "Formação sem nome")
		check(#formation.positions == 11, "Formação deve conter exatamente onze posições")
		local occupied = {}
		for _, point in formation.positions do
			check(point.x > 0 and point.x < 1 and point.y > 0 and point.y < 1, "Posição fora do campo")
			local key = tostring(point.x) .. ":" .. tostring(point.y)
			check(not occupied[key], "Duas posições ocupam o mesmo ponto")
			occupied[key] = true
		end
		check(formation.positions[1].y > 0.8, "Goleiro deve ficar próximo da base do campo")
		for playerIndex, player in ipairs(data.players) do
			if playerIndex > 11 then break end
			local point = formation.positions[playerIndex]
			if player.position == "LD" or player.position == "PD" then
				check(point.x > 0.5, "Jogador do lado direito foi colocado à esquerda: " .. formation.name)
			elseif player.position == "LE" or player.position == "PE" then
				check(point.x < 0.5, "Jogador do lado esquerdo foi colocado à direita: " .. formation.name)
			elseif player.position == "ATA" then
				check(point.y < 0.2, "Atacante precisa ocupar a linha ofensiva: " .. formation.name)
			end
		end
	end
	check(data.formations[2].positions[10].x == 0.5, "O atacante do 4–2–3–1 deve ficar centralizado")
	for _, fixture in data.fixtures do
		check(data.clubs[fixture.opponent] ~= nil, "Adversário inexistente")
		check(fixture.month >= 1 and fixture.month <= 12 and fixture.day >= 1 and fixture.day <= 31, "Data inválida")
		check(type(fixture.home) == "boolean" and nonempty(fixture.competition), "Dados do calendário incompletos")
	end
	local tableClubs, scored, conceded, wins, losses, draws, previousPoints = {}, 0, 0, 0, 0, 0, math.huge
	for _, row in data.table do
		check(data.clubs[row.club] ~= nil and not tableClubs[row.club], "Clube inexistente ou repetido na classificação")
		tableClubs[row.club] = true
		check(row.played == row.won + row.drawn + row.lost, "Total de partidas incoerente")
		check(row.points == row.won * 3 + row.drawn, "Pontuação incoerente")
		check(row.points <= previousPoints, "Classificação fora de ordem por pontos")
		previousPoints = row.points
		wins += row.won
		losses += row.lost
		draws += row.drawn
		scored += row.gf
		conceded += row.ga
	end
	check(scored == conceded, "Gols pró e contra da classificação não fecham")
	check(wins == losses and draws % 2 == 0, "Resultados agregados da competição não fecham")
	print(string.format("Dados: %d verificações aprovadas; %d clubes, %d atletas, %d formações.", checks, #data.clubs, #data.players, #data.formations))
end
