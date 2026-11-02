-- Calendário de 2027 com seleção de dias, resultados editoriais e detalhes dos confrontos.
local MONTHS = {[7] = "JULHO", [8] = "AGOSTO", [9] = "SETEMBRO"}
local DAYS = {[7] = 31, [8] = 31, [9] = 30}
local WEEKDAYS = {"SEG", "TER", "QUA", "QUI", "SEX", "SÁB", "DOM"}
local function mondayOffset(year, month)
	local offsets = {0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4}
	if month < 3 then year -= 1 end
	local sundayIndex = (year + math.floor(year/4) - math.floor(year/100) + math.floor(year/400) + offsets[month] + 1) % 7
	return (sundayIndex + 6) % 7
end
return function(ctx)
	local ui, state, data, T = ctx.ui, ctx.state, ctx.data, ctx.ui.theme
	local month = math.clamp(state.calendarMonth or 7, 7, 9)
	state.calendarMonth = month
	local function text(parent, value, size, color, x, y, width, height)
		local l = ui.label(parent, value, size, color, height or 26)
		l.Position, l.Size = UDim2.fromOffset(x, y), UDim2.new(width or 1, width and 0 or -40, 0, height or 26)
		return l
	end
	ui.section(ctx.parent, "TEMPORADA 2027", "CADA DATA, UM NOVO CAPÍTULO", "Consulte a agenda e os resultados fictícios. A seleção não simula partidas.")
	local monthFixtures, selected = {}, nil
	for _, f in ipairs(data.fixtures) do
		if f.month == month then
			table.insert(monthFixtures, f)
			if f.id == state.selectedFixtureId then selected = f end
		end
	end
	table.sort(monthFixtures, function(a, b) return a.day < b.day end)
	local selectedDay = state.calendarDay or (selected and selected.day) or 1
	local header = ui.row(ctx.parent, ctx.compact and 100 or 52)
	text(header, MONTHS[month] .. " 2027", 25, T.text, 0, 3, ctx.compact and 1 or 0.55, 44)
	local back = ui.button(header, "‹ MÊS", function()
		state.calendarMonth = month == 7 and 9 or month - 1
		state.calendarDay, state.selectedFixtureId = 1, nil
		ctx.refresh()
	end, {width = 104})
	back.Position = ctx.compact and UDim2.fromOffset(0, 52) or UDim2.new(1, -220, 0, 0)
	local forward = ui.button(header, "MÊS ›", function()
		state.calendarMonth = month == 9 and 7 or month + 1
		state.calendarDay, state.selectedFixtureId = 1, nil
		ctx.refresh()
	end, {width = 104})
	forward.Position = ctx.compact and UDim2.fromOffset(116, 52) or UDim2.new(1, -104, 0, 0)
	local weekdays = ui.row(ctx.parent, 24)
	for i, day in ipairs(WEEKDAYS) do
		local l = ui.label(weekdays, day, 12, T.muted, 24)
		l.Size, l.Position, l.TextXAlignment = UDim2.new(1/7, -6, 0, 24), UDim2.new((i-1)/7, 3, 0, 0), Enum.TextXAlignment.Center
	end
	local offset = mondayOffset(2027, month)
	local weeks = math.ceil((DAYS[month] + offset)/7)
	local grid = ui.row(ctx.parent, weeks * 78)
	for day = 1, DAYS[month] do
		local cellIndex = offset + day - 1
		local fixtures = {}
		for _, f in ipairs(monthFixtures) do if f.day == day then table.insert(fixtures, f) end end
		local title = tostring(day)
		if #fixtures > 0 then
			local f = fixtures[1]
			title ..= "\n" .. (f.status == "Encerrado" and (tostring(f.homeScore) .. " × " .. tostring(f.awayScore)) or "JOGO")
		end
		local b = ui.button(grid, title, function()
			state.calendarDay = day
			state.selectedFixtureId = fixtures[1] and fixtures[1].id or nil
			ctx.refresh()
		end, {selected = day == selectedDay})
		b.Position = UDim2.new((cellIndex % 7)/7, 3, 0, math.floor(cellIndex/7)*78)
		b.Size, b.TextSize = UDim2.new(1/7, -6, 0, 70), 14
		if #fixtures > 0 and day ~= selectedDay then b.TextColor3 = T.accent end
	end
	local detail = ui.panel(ctx.parent, ctx.compact and 238 or 186)
	text(detail, string.format("%02d DE %s", selectedDay, MONTHS[month]), 12, T.accent, 20, 15)
	local dayFixtures = {}
	for _, f in ipairs(monthFixtures) do if f.day == selectedDay then table.insert(dayFixtures, f) end end
	local fixture = selected or dayFixtures[1]
	if fixture then
		text(detail, fixture.home .. "  ×  " .. fixture.away, 25, T.text, 20, 44, nil, ctx.compact and 80 or 44)
		local result = fixture.status == "Encerrado" and ("Resultado: " .. fixture.homeScore .. " × " .. fixture.awayScore) or ("Início às " .. fixture.time)
		text(detail, fixture.competition .. " · " .. result, 15, T.muted, 20, ctx.compact and 134 or 94)
		text(detail, fixture.venue .. " · " .. fixture.status, 14, T.muted, 20, ctx.compact and 178 or 128)
	else
		text(detail, "SEM COMPROMISSOS", 23, T.text, 20, 48, nil, 40)
		text(detail, "Dia reservado para a rotina do clube. Selecione uma data marcada para consultar uma partida.", 14, T.muted, 20, 96, nil, 56)
	end
	ui.section(ctx.parent, "AGENDA DO MÊS", "CONFRONTOS", tostring(#monthFixtures) .. " partidas em " .. string.lower(MONTHS[month]) .. ".")
	for _, f in ipairs(monthFixtures) do
		local score = f.status == "Encerrado" and (f.homeScore .. " × " .. f.awayScore) or f.time
		local b = ui.button(ctx.parent, string.format("%02d/%02d   %s × %s   ·   %s   ·   %s", f.day, f.month, f.home, f.away, score, f.competition), function()
			state.calendarDay, state.selectedFixtureId = f.day, f.id
			ctx.refresh()
		end, {height = 64, selected = f.id == state.selectedFixtureId})
		b.TextSize = 14
	end
end
