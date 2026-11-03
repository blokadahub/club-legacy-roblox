local UI = require(script.Parent.Parent.UI)
local M = require(script.Parent.ManagementUI)
local Data = require(game:GetService("ReplicatedStorage"):WaitForChild("CL27"):WaitForChild("Data"))
local months = {"Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"}
local weekdays = {"SEG", "TER", "QUA", "QUI", "SEX", "SÁB", "DOM"}
local function daysInMonth(month, year)
	if month == 2 then return (year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)) and 29 or 28 end
	return ({31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31})[month]
end
local function mondayOffset(month, year)
	local offsets = {0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4}
	local y = year - (month < 3 and 1 or 0)
	local sunday = (y + math.floor(y / 4) - math.floor(y / 100) + math.floor(y / 400) + offsets[month] + 1) % 7
	return (sunday + 6) % 7
end

return function(root, ctx)
	local state = ctx.state
	state.month = state.month or 11
	state.year = state.year or 2026
	state.calendarDay = math.clamp(state.calendarDay or 3, 1, daysInMonth(state.month, state.year))
	local fixtures = {}
	for _, original in ipairs(Data.fixtures or {}) do
		local fixture = M.fixture(Data, original, state.homeClub)
		if fixture.month == state.month and state.year == (Data.fixtureYear or 2026) then fixtures[fixture.day] = fixture end
	end
	UI.header(root, "Calendário", "PLANEJAMENTO DA TEMPORADA")
	UI.text(root, months[state.month] .. " " .. state.year, 65, 143, 880, 60, 42, M.c.white, Enum.Font.GothamBold)
	local function move(delta)
		state.month += delta
		if state.month == 0 then state.month = 12; state.year -= 1 end
		if state.month == 13 then state.month = 1; state.year += 1 end
		ctx.rerender()
	end
	UI.button(root, "‹", 869, 146, 48, 48, function() move(-1) end, ctx.scope)
	UI.button(root, "›", 930, 146, 48, 48, function() move(1) end, ctx.scope)
	for col, label in ipairs(weekdays) do UI.text(root, label, 65 + (col - 1) * 133, 232, 120, 30, 13, M.c.muted, Enum.Font.GothamBold) end
	local offset = mondayOffset(state.month, state.year)
	local count = daysInMonth(state.month, state.year)
	for day = 1, count do
		local cell = offset + day - 1
		local x, y = 65 + (cell % 7) * 133, 278 + math.floor(cell / 7) * 87
		local selected = state.calendarDay == day
		local button = UI.button(root, "", x, y, 119, 75, function() state.calendarDay = day; ctx.rerender() end, ctx.scope, {selected = selected})
		UI.text(button, tostring(day), 13, 7, 65, 29, 24, selected and M.c.accent or M.c.white, Enum.Font.GothamBold)
		if fixtures[day] then
			UI.frame(button, 13, 56, 4, 4, M.c.accent)
			UI.text(button, "COMPETIÇÃO", 24, 50, 90, 15, 9, M.c.accent, Enum.Font.GothamBold)
		elseif day % 7 ~= 0 then
			UI.text(button, day % 3 == 0 and "RECUPERAÇÃO" or "TREINAMENTO", 13, 50, 102, 15, 9, M.c.muted)
		end
	end
	UI.frame(root, 66, 815, 6, 6, M.c.accent)
	UI.text(root, "Competição", 85, 806, 165, 23, 12, M.c.muted)
	UI.text(root, "Selecione um dia para consultar a agenda", 315, 806, 670, 23, 12, M.c.muted)
	UI.panel(root, 1040, 145, 495, 656, M.c.panel, 0.13)
	UI.text(root, "AGENDA DO DIA", 1075, 181, 415, 25, 13, M.c.accent, Enum.Font.GothamBold)
	UI.text(root, string.format("%02d", state.calendarDay), 1075, 232, 390, 100, 86, M.c.white, Enum.Font.GothamBold)
	UI.text(root, months[state.month] .. " de " .. state.year, 1078, 337, 390, 35, 22, M.c.muted)
	M.divider(root, 1075, 395, 425)
	local fixture = fixtures[state.calendarDay]
	if fixture then
		UI.text(root, fixture.competition or "Liga Horizonte", 1075, 430, 425, 28, 18, M.c.accent, Enum.Font.GothamBold)
		M.wrap(root, M.clubName(Data, fixture.opponent), 1075, 475, 425, 78, 31, M.c.white, Enum.Font.GothamBold)
		UI.text(root, (fixture.home and "Mandante" or "Visitante") .. "  •  " .. (fixture.time or "19:30"), 1075, 574, 425, 28, 17, M.c.muted)
		UI.button(root, "Consultar equipe  →", 1075, 691, 425, 60, function() ctx.go("Squad") end, ctx.scope, {primary = true})
	else
		local recovery = state.calendarDay % 3 == 0
		M.wrap(root, recovery and "Recuperação ativa" or "Treinamento do elenco", 1075, 430, 425, 80, 31, M.c.white, Enum.Font.GothamBold)
		M.wrap(root, recovery and "Sessão leve, mobilidade e acompanhamento da condição física." or "Controle de bola, organização coletiva e desenvolvimento individual.", 1075, 539, 420, 90, 18, M.c.muted)
		UI.button(root, "Ver desenvolvimento  →", 1075, 691, 425, 60, function() ctx.go("Development") end, ctx.scope, {primary = true})
	end
end
