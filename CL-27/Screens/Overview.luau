-- Painel da carreira visual. Dados editoriais locais; nenhuma partida é simulada.
return function(ctx)
	local ui, data, state = ctx.ui, ctx.data, ctx.state
	local T = ui.theme
	local function text(parent, value, size, color, pos, dim)
		local l = ui.label(parent, value, size, color, dim.Y.Offset)
		l.Position, l.Size = pos, dim
		return l
	end
	ui.section(ctx.parent, "CENTRAL DO CLUBE", "O SEU LEGADO COMEÇA AQUI", "Temporada 2027 · " .. data.club.name .. " · " .. data.club.city)
	local nextMatch
	for _, fixture in ipairs(data.fixtures) do
		if fixture.status == "Agendado" then nextMatch = fixture; break end
	end
	local hero = ui.panel(ctx.parent, ctx.compact and 272 or 252)
	ui.new("UIGradient", {Color = ColorSequence.new(T.panelAlt, T.panel), Rotation = 20}, hero)
	text(hero, "PRÓXIMO COMPROMISSO", 12, T.accent, UDim2.fromOffset(24, 20), UDim2.new(1, -48, 0, 24))
	if nextMatch then
		text(hero, nextMatch.home .. "  ×  " .. nextMatch.away, ctx.compact and 24 or 29, T.text, UDim2.fromOffset(24, 55), UDim2.new(1, -48, 0, 54))
		text(hero, string.format("%02d/%02d/2027 · %s · %s", nextMatch.day, nextMatch.month, nextMatch.time, nextMatch.competition), 15, T.muted, UDim2.fromOffset(24, 113), UDim2.new(1, -48, 0, ctx.compact and 36 or 28))
		text(hero, nextMatch.venue .. "  •  Agenda fictícia da temporada", 13, T.muted, UDim2.fromOffset(24, ctx.compact and 152 or 143), UDim2.new(1, -48, 0, ctx.compact and 36 or 28))
		local agenda = ui.button(hero, "VER CALENDÁRIO  →", function()
			state.calendarMonth, state.selectedFixtureId, state.calendarDay = nextMatch.month, nextMatch.id, nextMatch.day
			ctx.navigate("Calendar")
		end, {width = 230, primary = true})
		agenda.Position = UDim2.fromOffset(24, ctx.compact and 210 or 190)
	end
	local stats = ui.row(ctx.parent, ctx.compact and 336 or 106)
	local rank, played, points = 0, 0, 0
	for index, club in ipairs(data.standings) do
		if club.club == data.club.name or club.short == data.club.short then rank, played, points = index, club.played, club.points end
	end
	local metrics = {
		{"POSIÇÃO NA LIGA", tostring(rank) .. "º", tostring(points) .. " pontos em " .. tostring(played) .. " jogos"},
		{"ORÇAMENTO", data.money(data.finance.budget), "Planejamento da diretoria"},
		{"ELENCO", tostring(#data.players) .. " atletas", "Conheça seus protagonistas"},
	}
	for i, values in ipairs(metrics) do
		local card = ui.metric(stats, values[1], values[2], values[3])
		if ctx.compact then
			card.Size, card.Position = UDim2.new(1, 0, 0, 104), UDim2.fromOffset(0, (i-1)*112)
		else
			card.Size, card.Position = UDim2.new(1/3, -8, 1, 0), UDim2.new((i-1)/3, 4, 0, 0)
		end
	end
	ui.section(ctx.parent, "O CLUBE EM MOVIMENTO", "DENTRO DO AURORA", "Notícias e objetivos de uma temporada com identidade própria.")
	for _, news in ipairs(data.news) do
		local card = ui.panel(ctx.parent, ctx.compact and 160 or 126)
		text(card, string.upper(news.category), 11, T.accent, UDim2.fromOffset(20, 13), UDim2.new(1, -40, 0, 20))
		text(card, news.title, 21, T.text, UDim2.fromOffset(20, 38), UDim2.new(1, -40, 0, ctx.compact and 48 or 32))
		text(card, news.body, 14, T.muted, UDim2.fromOffset(20, ctx.compact and 90 or 74), UDim2.new(1, -40, 0, ctx.compact and 56 or 40))
	end
	local objectives = ui.panel(ctx.parent, 64 + #data.objectives * 88)
	text(objectives, "OBJETIVOS DA DIRETORIA", 16, T.text, UDim2.fromOffset(20, 14), UDim2.new(1, -40, 0, 30))
	for i, objective in ipairs(data.objectives) do
		local value, target = objective.current, objective.target
		if target > 1000 then value, target = math.floor(value / target * 100 + 0.5), 100 end
		local bar = ui.bar(objectives, objective.title .. (objective.target > 1000 and " (%)" or ""), value, target, T.accent)
		bar.Size, bar.Position = UDim2.new(1, -40, 0, 48), UDim2.fromOffset(20, 52 + (i-1)*88)
		text(objectives, objective.detail, 12, T.muted, UDim2.fromOffset(20, 101 + (i-1)*88), UDim2.new(1, -40, 0, 25))
	end
	local actions = ui.row(ctx.parent, ctx.compact and 156 or 48)
	local buttons = {{"GERENCIAR ELENCO", "Squad"}, {"AJUSTAR TÁTICAS", "Tactics"}, {"VER CLASSIFICAÇÃO", "Competitions"}}
	for i, action in ipairs(buttons) do
		local b = ui.button(actions, action[1], function() ctx.navigate(action[2]) end)
		if ctx.compact then
			b.Size, b.Position = UDim2.new(1, 0, 0, 44), UDim2.fromOffset(0, (i-1)*52)
		else
			b.Size, b.Position = UDim2.new(1/3, -8, 0, 44), UDim2.new((i-1)/3, 4, 0, 0)
		end
	end
end
