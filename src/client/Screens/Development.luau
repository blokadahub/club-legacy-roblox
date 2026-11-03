local UI = require(script.Parent.Parent.UI)
local M = require(script.Parent.ManagementUI)
local Data = require(game:GetService("ReplicatedStorage"):WaitForChild("CL27"):WaitForChild("Data"))
local plans = {
	{name = "Equilibrado", description = "Fortalece a base técnica e física do atleta com foco no desenvolvimento completo.", focus = {"Controle de bola", "Leitura de jogo", "Resistência"}, attribute = "dribbling"},
	{name = "Construção", description = "Aprimora circulação de bola, visão e execução de passes entre setores.", focus = {"Passe curto", "Visão de jogo", "Controle orientado"}, attribute = "passing"},
	{name = "Finalização", description = "Prioriza posicionamento ofensivo, precisão e técnica de conclusão.", focus = {"Precisão", "Movimentação", "Força do chute"}, attribute = "shooting"},
	{name = "Proteção", description = "Desenvolve posicionamento, antecipação e consistência nas ações defensivas.", focus = {"Antecipação", "Marcação", "Força"}, attribute = "defending"},
}

return function(root, ctx)
	local state = ctx.state
	state.training = state.training or {}
	state.selectedPlayer = math.clamp(state.selectedPlayer or 1, 1, #Data.players)
	state.developmentPlan = state.developmentPlan or 1
	local player = M.player(Data, state.selectedPlayer)
	if state.developmentPlayer ~= player.id then
		state.developmentPlan = state.training[player.id] or 1
		state.developmentPlayer = player.id
	end
	local club = M.club(Data, state.homeClub)
	UI.header(root, "Desenvolvimento", "CENTRO DE PERFORMANCE")
	UI.text(root, "Talento encontra direção.", 65, 141, 1100, 60, 42, M.c.white, Enum.Font.GothamBold)
	UI.text(root, "Planos individuais  /  Comissão técnica CL 27", 67, 210, 1000, 30, 17, M.c.muted)
	UI.section(root, "SELECIONAR ATLETA", 65, 282, 360)
	local scroll = UI.new("ScrollingFrame", {
		Name = "AtletasEmDesenvolvimento", Position = UDim2.fromOffset(65, 329), Size = UDim2.fromOffset(365, 459),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = M.c.accent,
		CanvasSize = UDim2.fromOffset(0, #Data.players * 66), ScrollingDirection = Enum.ScrollingDirection.Y,
	}, root)
	for index, item in ipairs(Data.players) do
		local b = UI.button(scroll, "", 0, (index - 1) * 66, 345, 59, function()
			state.selectedPlayer = index
			state.developmentPlan = state.training[item.id] or 1
			ctx.rerender()
		end, ctx.scope, {selected = state.selectedPlayer == index})
		UI.text(b, item.position, 14, 17, 51, 23, 12, M.c.accent, Enum.Font.GothamBold)
		UI.text(b, item.shortName or item.name, 77, 15, 209, 29, 17, M.c.white, Enum.Font.GothamBold)
		UI.text(b, tostring(item.overall), 292, 14, 42, 30, 22, M.c.white, Enum.Font.GothamBold)
	end
	UI.keepScroll(scroll,state,"developmentScrollY",ctx.scope)
	UI.line(root, 466, 286, 466, 790, M.c.line, 1)
	UI.portrait(root, player, club, 493, 282, 240, 265, ctx.scope)
	UI.text(root, player.name, 760, 293, 700, 49, 36, M.c.white, Enum.Font.GothamBold)
	UI.text(root, player.position .. "  •  " .. player.age .. " anos", 763, 351, 650, 29, 19, M.c.muted)
	M.meta(root, "GERAL", player.overall, 764, 419, 160)
	M.meta(root, "POTENCIAL", player.potential, 956, 419, 200)
	M.meta(root, "MARGEM DE EVOLUÇÃO", "+" .. (player.potential - player.overall), 1194, 419, 315)
	M.divider(root, 504, 562, 1030)
	UI.section(root, "PLANO INDIVIDUAL", 504, 591, 1015)
	for index, plan in ipairs(plans) do
		UI.button(root, plan.name, 504 + (index - 1) * 257, 637, 240, 46, function() state.developmentPlan = index; ctx.rerender() end, ctx.scope, {selected = state.developmentPlan == index})
	end
	local plan = plans[state.developmentPlan]
	M.wrap(root, plan.description, 504, 709, 700, 67, 17, M.c.muted)
	UI.button(root, state.training[player.id] == state.developmentPlan and "Plano selecionado  ✓" or "Definir plano  →", 1230, 713, 304, 60, function()
		state.training[player.id] = state.developmentPlan
		ctx.notify("Plano de " .. string.lower(plan.name) .. " definido para " .. player.name .. ".")
		ctx.rerender()
	end, ctx.scope, {primary = true})
	UI.text(root, "FOCO  /  " .. table.concat(plan.focus, "  •  "), 505, 801, 1025, 28, 13, M.c.accent, Enum.Font.GothamBold)
end
