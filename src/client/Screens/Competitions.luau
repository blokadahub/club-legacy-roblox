local UI = require(script.Parent.Parent.UI)
local M = require(script.Parent.ManagementUI)
local Data = require(game:GetService("ReplicatedStorage"):WaitForChild("CL27"):WaitForChild("Data"))
local function standings()
	local rows = {}
	if Data["table"] and #Data["table"] > 0 then return Data["table"] end
	for index = 1, #Data.clubs do
		table.insert(rows, {club = index, played = 11, won = math.max(1, 9 - index), drawn = 2, lost = math.min(8, index), gf = 28 - index, ga = 9 + index, points = math.max(5, 29 - index * 3)})
	end
	return rows
end

return function(root, ctx)
	local state = ctx.state
	state.competitionTab = state.competitionTab or 1
	state.competitionClub = state.competitionClub or state.homeClub
	local competition = Data.standingsCompetition or "Circuito Legado"
	UI.header(root, "Competições", "TEMPORADA 2026 / 27", M.tabs({competition, "Copa Legado"}, state.competitionTab, function(i) state.competitionTab = i; ctx.rerender() end))
	local selectedClub = M.club(Data, state.competitionClub)
	M.title(root, state.competitionTab == 1 and "CLASSIFICAÇÃO GERAL" or "FASE ELIMINATÓRIA", state.competitionTab == 1 and competition or "Copa Legado", 65, 145, 1035)
	UI.text(root, state.competitionTab == 1 and "Rodada 12 de 14  /  Circuito internacional de clubes convidados" or "Quartas de final  /  Confrontos de ida e volta", 67, 246, 1040, 28, 17, M.c.muted)
	if state.competitionTab == 1 then
		local cols = {{"CLUBE", 115, 438}, {"J", 590, 62}, {"V", 677, 62}, {"E", 764, 62}, {"D", 851, 62}, {"SG", 938, 65}, {"PTS", 1025, 70}}
		for _, col in ipairs(cols) do UI.text(root, col[1], col[2], 309, col[3], 25, 12, M.c.muted, Enum.Font.GothamBold) end
		M.divider(root, 65, 350, 1050)
		for rank, row in ipairs(standings()) do
			local club = M.club(Data, row.club)
			local y = 365 + (rank - 1) * 54
			local selected = state.competitionClub == row.club
			local item = UI.button(root, "", 65, y, 1050, 48, function() state.competitionClub = row.club; ctx.rerender() end, ctx.scope, {selected = selected})
			UI.text(item, string.format("%02d", rank), 15, 11, 38, 25, 17, rank < 4 and M.c.accent or M.c.muted, Enum.Font.GothamBold)
			UI.badge(item, club, 61, 7, 34)
			UI.text(item, club.name, 112, 11, 390, 29, 19, M.c.white, Enum.Font.GothamBold)
			local values = {row.played, row.won, row.drawn, row.lost, row.gf - row.ga, row.points}
			for index, value in ipairs(values) do UI.text(item, tostring(value), 525 + (index - 1) * 87, 10, 67, 28, 19, index == 6 and M.c.accent or M.c.muted, index == 6 and Enum.Font.GothamBold or Enum.Font.Gotham) end
		end
		UI.text(root, "01–03  Classificação continental     /     04–06  Fase preliminar", 65, 813, 1035, 25, 13, M.c.muted)
	else
		for tie = 1, 4 do
			local y = 330 + (tie - 1) * 111
			local a, b = tie, 9 - tie
			local clubA, clubB = M.club(Data, a), M.club(Data, b)
			UI.text(root, string.format("CONFRONTO %02d", tie), 65, y - 9, 1040, 23, 12, M.c.muted, Enum.Font.GothamBold)
			UI.button(root, "", 65, y + 23, 480, 65, function() state.competitionClub = a; ctx.rerender() end, ctx.scope, {selected = state.competitionClub == a})
			UI.badge(root, clubA, 81, y + 32, 44)
			UI.text(root, clubA.name, 144, y + 39, 375, 30, 21, M.c.white, Enum.Font.GothamBold)
			UI.text(root, "×", 554, y + 38, 52, 32, 23, M.c.accent)
			UI.button(root, "", 624, y + 23, 490, 65, function() state.competitionClub = b; ctx.rerender() end, ctx.scope, {selected = state.competitionClub == b})
			UI.badge(root, clubB, 640, y + 32, 44)
			UI.text(root, clubB.name, 704, y + 39, 389, 30, 21, M.c.white, Enum.Font.GothamBold)
		end
		UI.text(root, "Chaveamento demonstrativo  /  Resultados ainda não definidos", 65, 813, 1040, 25, 13, M.c.muted)
	end
	UI.panel(root, 1175, 147, 360, 658, M.c.panel, 0.18)
	UI.text(root, "EM DESTAQUE", 1205, 187, 300, 25, 13, M.c.accent, Enum.Font.GothamBold)
	UI.badge(root, selectedClub, 1240, 257, 220)
	M.wrap(root, selectedClub.name, 1205, 512, 300, 79, 31, M.c.white, Enum.Font.GothamBold)
	UI.text(root, selectedClub.country or "Brasil", 1205, 609, 300, 28, 18, M.c.muted)
	M.divider(root, 1205, 662, 300)
	M.wrap(root, selectedClub.league or "Liga Horizonte", 1205, 695, 300, 58, 20, M.c.white)
end
