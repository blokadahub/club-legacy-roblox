-- Exercita estado e encadeamento entre telas; os doubles não validam renderização.
return function(Harness, screens, data)
	local count = 0
	local function check(condition, message)
		count += 1
		assert(condition, message)
	end
	local function contains(ctx, value)
		for _, object in ipairs(ctx.objects) do
			if object.Text and string.find(object.Text, value, 1, true) then return object end
		end
		return nil
	end
	local function clickCardTitle(ctx, title)
		local label = ctx:find(title, "TextLabel")
		check(label.Parent.ClassName == "TextButton", "Título precisa pertencer ao botão")
		label.Parent.Activated:Fire()
	end
	for _, compact in ipairs({false,true}) do
		local function build(name, state)
			return Harness.build(screens[name], data, {compact=compact, state=state})
		end
		local ctx = build("Home")
		ctx:click("ENTRAR NA CENTRAL   →")
		check(ctx.destination == "Overview", "Menu inicial deve abrir a central")
		ctx = build("Overview")
		ctx:click("VER CALENDÁRIO  →")
		check(ctx.destination == "Calendar" and ctx.state.selectedFixtureId == "f01" and ctx.state.calendarDay == 24, "Central deve abrir confronto selecionado")
		ctx:click("GERENCIAR ELENCO")
		check(ctx.destination == "Squad", "Atalho do elenco")
		ctx:click("AJUSTAR TÁTICAS")
		check(ctx.destination == "Tactics", "Atalho de táticas")
		ctx:click("VER CLASSIFICAÇÃO")
		check(ctx.destination == "Competitions", "Atalho de classificação")

		ctx = build("Squad")
		ctx:click("Defesa")
		check(ctx.state.squadFilter == "Defesa", "Filtro do elenco")
		ctx = build("Squad",ctx.state)
		local visible = 0
		for _, object in ipairs(ctx.objects) do
			if object.playerId then
				visible += 1
				local player
				for _, item in ipairs(data.players) do if item.id == object.playerId then player=item end end
				check(player and (player.position == "ZAG" or player.position == "LAT"), "Filtro não deve mostrar atacante")
			end
		end
		check(visible == 6, "Defesa deve incluir quatro titulares e dois reservas")
		ctx:click(data.players[3].name)
		check(ctx.state.selectedPlayerId == "p03", "Card deve selecionar jogador real")
		ctx:click("Plano de desenvolvimento")
		check(ctx.destination == "Development", "Elenco deve preservar seleção ao navegar")
		ctx = build("Development",ctx.state)
		check(contains(ctx, data.players[3].name) ~= nil, "Desenvolvimento deve usar seleção do elenco")
		clickCardTitle(ctx,"Técnico")
		check(ctx.state.training.p03 == "tecnico", "Plano deve ser associado ao jogador selecionado")
		ctx = build("Development",ctx.state)
		check(contains(ctx,"Plano ativo: Técnico") ~= nil, "Plano escolhido deve permanecer após reconstrução")
		check(data.players[3].overall == 80, "Plano não pode simular evolução")

		ctx = build("Tactics")
		ctx:click("4-4-2")
		check(ctx.state.formation == "4-4-2", "Formação tática")
		ctx.state.tacticsSlot = 2
		ctx = build("Tactics",ctx.state)
		ctx:click(data.players[3].name)
		check(ctx.state.lineup[2] == "p03" and ctx.state.lineup[3] == "p02", "Troca entre titulares precisa preservar os dois atletas")
		ctx = build("Tactics",ctx.state)
		ctx:click(data.players[13].name)
		check(ctx.state.lineup[2] == "p13" and not table.find(ctx.state.lineup,"p03"), "Reserva deve substituir titular selecionado")
		local seen={}
		for _, id in ipairs(ctx.state.lineup) do
			check(not seen[id], "Escalação não pode duplicar jogador")
			seen[id]=true
		end
		check(#ctx.state.lineup == 11, "Trocas devem preservar onze titulares")
		ctx:click("Ofensiva")
		check(ctx.state.mentality == "Ofensiva", "Mentalidade tática")

		ctx = build("Calendar")
		check(math.abs(ctx:find("1","TextButton").Position.X.Scale-3/7)<0.0001, "Julho2027 deve começar na quinta-feira")
		ctx:click("16\n2 × 2")
		check(ctx.state.calendarDay == 16 and ctx.state.selectedFixtureId == "f13", "Data deve selecionar confronto correspondente")
		ctx = build("Calendar",ctx.state)
		check(contains(ctx,"Resultado: 2 × 2") ~= nil, "Resultado deve corresponder ao confronto selecionado")
		ctx:click("MÊS ›")
		check(ctx.state.calendarMonth == 8 and ctx.state.selectedFixtureId == nil and ctx.state.calendarDay == 1, "Avanço de mês deve limpar seleção antiga")
		ctx = build("Calendar",ctx.state)
		check(math.abs(ctx:find("1","TextButton").Position.X.Scale-6/7)<0.0001, "Agosto2027 deve começar no domingo")
		ctx:click("MÊS ›")
		ctx = build("Calendar",ctx.state)
		check(math.abs(ctx:find("1","TextButton").Position.X.Scale-2/7)<0.0001, "Setembro2027 deve começar na quarta-feira")

		ctx = build("Finance")
		ctx:click("Receitas")
		ctx = build("Finance",ctx.state)
		check(contains(ctx,"Patrocínios") ~= nil and contains(ctx,"Operação do clube") == nil, "Receitas devem ocultar despesas")
		ctx:click("Despesas")
		ctx = build("Finance",ctx.state)
		check(contains(ctx,"Operação do clube") ~= nil and contains(ctx,"Patrocínios") == nil, "Despesas devem ocultar receitas")
		check(data.finance.budget == 48000000, "A navegação financeira não pode mover verba")

		ctx = build("Competitions")
		ctx:click("Estatísticas")
		ctx = build("Competitions",ctx.state)
		check(contains(ctx,"GOLS NA LIGA") ~= nil and contains(ctx,"68") ~= nil, "Estatísticas devem usar o total de gols dos clubes")
		ctx:click("Confrontos")
		ctx = build("Competitions",ctx.state)
		local match = contains(ctx,"24/07   Aurora FC × Estrela do Sul")
		check(match ~= nil and match.ClassName == "TextButton", "Confronto deve estar disponível para inspeção")
		match.Activated:Fire()
		check(ctx.destination == "Calendar" and ctx.state.selectedFixtureId == "f01" and ctx.state.calendarMonth == 7 and ctx.state.calendarDay == 24, "Confronto deve abrir o dia correto do calendário")
	end
	print("Screen integration checks passed: " .. count .. " (mock UI, desktop + compact; not Studio)")
end
