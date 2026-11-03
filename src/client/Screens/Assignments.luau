local UI = require(script.Parent.Parent.UI)
local Data = require(game:GetService("ReplicatedStorage").CL27.Data)

local WHITE = Color3.fromRGB(241, 248, 248)
local MUTED = Color3.fromRGB(149, 176, 187)
local ACCENT = Color3.fromRGB(67, 241, 202)
local PANEL = Color3.fromRGB(17, 34, 51)
local ROLES = {
	{ key = "captain", title = "Capitão", symbol = "C", attribute = "passing", default = 1, description = "A referência de liderança do elenco." },
	{ key = "penalties", title = "Pênaltis", symbol = "11", attribute = "shooting", default = 11, description = "Precisão e serenidade na marca da cal." },
	{ key = "shortFreeKicks", title = "Faltas curtas", symbol = "↗", attribute = "shooting", default = 8, description = "Técnica para cobranças perto da área." },
	{ key = "longFreeKicks", title = "Faltas longas", symbol = "↗", attribute = "passing", default = 6, description = "Distribuição e alcance em bolas paradas." },
	{ key = "leftCorners", title = "Escanteios à esquerda", symbol = "L", attribute = "passing", default = 7, description = "Qualidade no cruzamento pelo lado esquerdo." },
	{ key = "rightCorners", title = "Escanteios à direita", symbol = "R", attribute = "passing", default = 8, description = "Qualidade no cruzamento pelo lado direito." },
}

return function(root, ctx)
	local state, scope = ctx.state, ctx.scope
	state.assignments = state.assignments or {}
	state.assignmentRole = math.clamp(state.assignmentRole or 1, 1, #ROLES)
	for _, role in ipairs(ROLES) do
		state.assignments[role.key] = math.clamp(state.assignments[role.key] or role.default, 1, #Data.players)
	end
	local role = ROLES[state.assignmentRole]
	local assignedIndex = state.assignments[role.key]
	local assigned = Data.players[assignedIndex]
	local club = Data.clubs[state.homeClub or 1]
	UI.header(root, "GERENCIAMENTO DE EQUIPE", "RESPONSABILIDADES", {
		{ label = "Elenco", callback = function() ctx.go("Squad") end },
		{ label = "Táticas", callback = function() ctx.go("Tactics") end },
		{ label = "Atribuições", selected = true, callback = function() end },
	})
	UI.text(root, "CADA DETALHE DEFINE UM LEGADO.", 74, 139, 1000, 35, 27, WHITE, Enum.Font.GothamBold)
	UI.text(root, "Escolha uma responsabilidade e indique o atleta.", 74, 182, 1000, 25, 15, MUTED)
	local rolePanel = UI.panel(root, 74, 241, 464, 572, PANEL, 0.12)
	UI.text(rolePanel, "RESPONSABILIDADES", 23, 19, 410, 25, 12, MUTED, Enum.Font.GothamBold)
	for index, item in ipairs(ROLES) do
		local player = Data.players[state.assignments[item.key]]
		local y = 65 + (index - 1) * 80
		local button = UI.button(rolePanel, "", 15, y, 433, 70, function()
			state.assignmentRole = index
			ctx.rerender()
		end, scope, { selected = state.assignmentRole == index, quiet = true })
		UI.text(button, item.symbol, 14, 13, 40, 31, 23, if state.assignmentRole == index then ACCENT else MUTED, Enum.Font.GothamBold)
		UI.text(button, item.title, 67, 9, 345, 25, 16, WHITE, Enum.Font.GothamBold)
		UI.text(button, player.name, 67, 38, 345, 21, 12, MUTED)
	end
	local hero = UI.panel(root, 560, 241, 380, 572, PANEL, 0.45)
	UI.text(hero, "RESPONSÁVEL ATUAL", 25, 19, 333, 25, 12, ACCENT, Enum.Font.GothamBold)
	UI.portrait(hero, assigned, club, 32, 65, 317, 290, scope)
	UI.text(hero, tostring(assigned.overall), 275, 76, 86, 59, 43, WHITE, Enum.Font.GothamBold)
	UI.line(hero, 25, 372, 355, 372, MUTED, 1).BackgroundTransparency = 0.75
	UI.text(hero, string.upper(assigned.shortName or assigned.name), 25, 392, 332, 36, 27, WHITE, Enum.Font.GothamBold)
	UI.text(hero, assigned.position .. "  •  " .. tostring(assigned.number), 25, 437, 332, 25, 15, MUTED)
	UI.text(hero, role.title, 25, 483, 332, 26, 17, ACCENT, Enum.Font.GothamBold)
	local description = UI.text(hero, role.description, 25, 521, 332, 36, 12, MUTED)
	description.TextWrapped = true
	local list = UI.panel(root, 963, 241, 573, 572, PANEL, 0.1)
	UI.text(list, "SELECIONAR RESPONSÁVEL", 23, 19, 405, 25, 12, MUTED, Enum.Font.GothamBold)
	UI.text(list, if role.attribute == "passing" then "PASSE" else "FINALIZ.", 458, 20, 92, 24, 11, MUTED, Enum.Font.GothamBold)
	local scroll = UI.new("ScrollingFrame", {
		Name = "AtletasParaAtribuicao", Position = UDim2.fromOffset(15, 61), Size = UDim2.fromOffset(544, 493),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = MUTED,
		CanvasSize = UDim2.fromOffset(0, #Data.players * 54), ScrollingDirection = Enum.ScrollingDirection.Y,
	}, list)
	for index, p in ipairs(Data.players) do
		local button = UI.button(scroll, "", 0, (index - 1) * 54, 529, 48, function()
			state.assignments[role.key] = index
			ctx.rerender()
			ctx.notify(p.shortName .. " agora é responsável por " .. string.lower(role.title) .. ".")
		end, scope, { selected = assignedIndex == index, quiet = true })
		UI.text(button, p.position, 11, 12, 56, 25, 12, MUTED, Enum.Font.GothamBold)
		UI.text(button, p.name, 75, 10, 335, 27, 15, WHITE, Enum.Font.GothamMedium)
		UI.text(button, tostring(p.attributes[role.attribute]), 448, 9, 61, 29, 21, if assignedIndex == index then ACCENT else WHITE, Enum.Font.GothamBold)
	end
	UI.keepScroll(scroll,state,"assignmentScrollY",scope)
end
