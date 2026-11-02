-- Classificação e estatísticas coerentes com a liga fictícia.
return function(ctx)
	local ui, data, state, T = ctx.ui, ctx.data, ctx.state, ctx.ui.theme
	local function labelAt(parent, value, x, width, color, size)
		local l = ui.label(parent, tostring(value), size or 14, color or T.text, 46)
		l.Position, l.Size = UDim2.new(x, 6, 0, 0), UDim2.new(width, -12, 1, 0)
		return l
	end
	ui.section(ctx.parent, "COMPETIÇÕES", "O TOPO É O DESTINO", "Liga Aurora · oito clubes · temporada editorial 2027.")
	local view = state.competitionView or "Classificação"
	local tabs = ui.row(ctx.parent, 48)
	for i, name in ipairs({"Classificação", "Estatísticas", "Confrontos"}) do
		local b = ui.button(tabs, name, function() state.competitionView = name; ctx.refresh() end, {selected = view == name})
		b.Size, b.Position = UDim2.new(1/3, -8, 0, 44), UDim2.new((i-1)/3, 4, 0, 0)
	end
	if view == "Classificação" then
		local columns = {{"#",0,0.06},{"CLUBE",0.06,0.34},{"J",0.4,0.08},{"V",0.48,0.08},{"E",0.56,0.08},{"D",0.64,0.08},{"SG",0.72,0.13},{"PTS",0.85,0.15}}
		local header = ui.row(ctx.parent, 36)
		for _, c in ipairs(columns) do labelAt(header, c[1], c[2], c[3], T.muted, 11) end
		for index, club in ipairs(data.standings) do
			local selected = state.selectedClub == club.club
			local button = ui.button(ctx.parent, "", function() state.selectedClub = club.club; ctx.refresh() end, {height = 54, selected = selected})
			local ownClub = club.club == data.club.name or club.short == data.club.short
			local values = {index, ctx.compact and club.short or club.club, club.played, club.wins, club.draws, club.losses, club.gf-club.ga, club.points}
			for col, c in ipairs(columns) do
				labelAt(button, values[col], c[2], c[3], selected and T.bg or (ownClub and T.accent or T.text), col == 8 and 18 or (ctx.compact and 12 or 14))
			end
		end
		local selectedClub = data.standings[1]
		for _, club in ipairs(data.standings) do
			if club.club == (state.selectedClub or data.club.name) then selectedClub = club end
		end
		local details = ui.panel(ctx.parent, ctx.compact and 190 or 136)
		local name = ui.label(details, selectedClub.club .. " · RAIO-X DA CAMPANHA", 18, T.accent, 32)
		name.Position, name.Size = UDim2.fromOffset(20, 16), UDim2.new(1, -40, 0, ctx.compact and 44 or 32)
		local yield = selectedClub.played > 0 and math.floor(selectedClub.points/(selectedClub.played*3)*100+0.5) or 0
		local info = ui.label(details, string.format("%d gols marcados  ·  %d sofridos  ·  %d%% de aproveitamento", selectedClub.gf, selectedClub.ga, yield), 15, T.text, 40)
		info.Position, info.Size = UDim2.fromOffset(20, 66), UDim2.new(1, -40, 0, ctx.compact and 56 or 40)
		local note = ui.label(details, "Critérios: pontos, saldo de gols e gols marcados. Toque em um clube para inspecionar.", 12, T.muted, 24)
		note.Position, note.Size = UDim2.fromOffset(20, ctx.compact and 128 or 103), UDim2.new(1, -40, 0, ctx.compact and 48 or 24)
	elseif view == "Estatísticas" then
		local goals, games, bestAttack, bestDefense = 0, 0, data.standings[1], data.standings[1]
		for _, c in ipairs(data.standings) do
			goals += c.gf; games += c.played
			if c.gf > bestAttack.gf then bestAttack = c end
			if c.ga < bestDefense.ga then bestDefense = c end
		end
		local average = games > 0 and goals/(games/2) or 0
		ui.metric(ctx.parent, "GOLS NA LIGA", tostring(goals), string.format("Média de %.2f por confronto", average))
		ui.metric(ctx.parent, "MELHOR ATAQUE", bestAttack.club, tostring(bestAttack.gf) .. " gols marcados")
		ui.metric(ctx.parent, "MELHOR DEFESA", bestDefense.club, tostring(bestDefense.ga) .. " gols sofridos")
		local maxGoals = math.max(1, bestAttack.gf)
		ui.section(ctx.parent, "PODER OFENSIVO", "GOLS POR CLUBE", "Comparação baseada na classificação atual.")
		for _, c in ipairs(data.standings) do ui.bar(ctx.parent, c.club, c.gf, maxGoals, c.club == data.club.name and T.accent or T.muted) end
	else
		ui.section(ctx.parent, "LIGA AURORA", "AGENDA E RESULTADOS", "Abra um confronto para consultar o calendário completo.")
		for _, f in ipairs(data.fixtures) do
			if f.competition == "Liga Aurora" then
				local result = f.status == "Encerrado" and (f.homeScore .. " × " .. f.awayScore) or f.time
				local b = ui.button(ctx.parent, string.format("%02d/%02d   %s × %s   ·   %s", f.day, f.month, f.home, f.away, result), function()
					state.calendarMonth, state.calendarDay, state.selectedFixtureId = f.month, f.day, f.id
					ctx.navigate("Calendar")
				end, {height = 64})
				b.TextSize = 14
			end
		end
	end
end
