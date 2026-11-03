local UI = require(script.Parent.Parent.UI)
local M = require(script.Parent.ManagementUI)
local Data = require(game:GetService("ReplicatedStorage"):WaitForChild("CL27"):WaitForChild("Data"))

return function(root, ctx)
	local club = M.club(Data, ctx.state.homeClub)
	local fixture = M.fixture(Data, (Data.fixtures or {})[1], ctx.state.homeClub)
	local opponent = M.club(Data, fixture and fixture.opponent or ctx.state.awayClub)
	local rank, points = 1, 27
	local averageFitness=0
	for _,player in ipairs(Data.players) do averageFitness+=player.fitness end
	averageFitness=math.floor(averageFitness/#Data.players+0.5)
	for index, row in ipairs(Data["table"] or {}) do
		if row.club == ctx.state.homeClub then rank, points = index, row.points end
	end
	UI.header(root, "Visão geral", "CENTRAL DO CLUBE")
	M.title(root, "TEMPORADA 2026 / 27", "O legado começa aqui.", 65, 142, 880)
	UI.text(root, club.name .. "  /  Centro de gestão", 67, 244, 750, 30, 18, M.c.muted)
	UI.panel(root, 65, 307, 900, 365, M.c.panel, 0.2)
	M.tag(root, "PRÓXIMO COMPROMISSO", 92, 332, 218, true)
	UI.text(root, string.upper(fixture and fixture.competition or "Liga Horizonte") .. "  •  TEMPORADA 2026 / 27", 92, 378, 640, 24, 14, M.c.muted, Enum.Font.GothamBold)
	UI.badge(root, club, 105, 435, 118)
	UI.badge(root, opponent, 717, 435, 118)
	UI.text(root, "×", 434, 456, 75, 66, 52, M.c.muted, Enum.Font.Gotham)
	UI.text(root, club.name, 92, 571, 325, 35, 23, M.c.white, Enum.Font.GothamBold)
	UI.text(root, opponent.name, 613, 571, 325, 35, 23, M.c.white, Enum.Font.GothamBold)
	UI.text(root, string.format("%02d NOV  •  19:30", fixture and fixture.day or 3), 369, 550, 255, 28, 19, M.c.accent, Enum.Font.GothamBold)
	UI.text(root, "Arena Horizonte  /  Mandante", 92, 625, 700, 23, 14, M.c.muted)
	UI.button(root, "Consultar calendário  →", 65, 702, 430, 67, function() ctx.go("Calendar") end, ctx.scope, {primary = true})
	UI.button(root, "Preparar elenco  →", 519, 702, 446, 67, function() ctx.go("Squad") end, ctx.scope)

	UI.line(root, 1005, 146, 1005, 791, M.c.line, 1)
	UI.section(root, "MOMENTO DO CLUBE", 1045, 151, 485)
	M.meta(root, "POSIÇÃO NO CIRCUITO", string.format("%02d", rank), 1045, 207, 215)
	M.meta(root, "PONTOS", tostring(points), 1300, 207, 210)
	M.divider(root, 1045, 286, 485)
	UI.text(root, "Uma equipe em evolução", 1045, 317, 485, 37, 26, M.c.white, Enum.Font.GothamBold)
	M.wrap(root, "A comissão mantém o foco na construção de um grupo equilibrado e preparado para os próximos desafios.", 1045, 366, 470, 89, 18, M.c.muted)
	M.attribute(root, "Condição média do elenco", averageFitness, 1045, 478, 470)
	M.attribute(root, "Confiança da diretoria", 84, 1045, 550, 470, M.c.blue)
	UI.section(root, "NA CENTRAL", 1045, 637, 475)
	UI.button(root, "↗  Relatório de desenvolvimento", 1045, 679, 475, 45, function() ctx.go("Development") end, ctx.scope, {quiet = true})
	UI.button(root, "↗  Balanço financeiro do mês", 1045, 733, 475, 45, function() ctx.go("Finance") end, ctx.scope, {quiet = true})
end
