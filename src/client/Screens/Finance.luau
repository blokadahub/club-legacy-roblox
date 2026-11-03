local UI = require(script.Parent.Parent.UI)
local M = require(script.Parent.ManagementUI)
local months = {"JUL", "AGO", "SET", "OUT", "NOV", "DEZ"}
local income = {18.3, 23.6, 20.1, 26.8, 29.4, 24.9}
local expenses = {16.1, 17.5, 19.2, 18.7, 21.3, 20.4}
local categories = {
	{label = "Patrocínios e parcerias", value = 12.6, share = 43, detail = "Acordos comerciais originais, contratos institucionais e exposição da marca do clube."},
	{label = "Direitos de transmissão", value = 8.4, share = 29, detail = "Distribuição centralizada da competição e participação nas transmissões da temporada."},
	{label = "Bilheteria e associados", value = 5.1, share = 17, detail = "Ingressos, programas de associação e experiências da arena no mês selecionado."},
	{label = "Produtos do clube", value = 3.3, share = 11, detail = "Licenciamento original, uniformes e produtos da identidade Club Legacy."},
}

return function(root, ctx)
	local state = ctx.state
	state.financeTab = state.financeTab or 1
	state.financeCategory = state.financeCategory or 1
	UI.header(root, "Finanças", "GESTÃO DO CLUBE", M.tabs({"Mensal", "Temporada"}, state.financeTab, function(i) state.financeTab = i; ctx.rerender() end))
	M.title(root, state.financeTab == 1 and "NOVEMBRO DE 2026" or "TEMPORADA 2026 / 27", "Crescer com equilíbrio.", 65, 145, 1000)
	UI.text(root, "Indicadores demonstrativos  /  Valores em milhões de reais", 67, 246, 1000, 27, 17, M.c.muted)
	local revenue, cost = 29.4, 21.3
	if state.financeTab == 2 then
		revenue, cost = 0, 0
		for index, amount in ipairs(income) do revenue += amount; cost += expenses[index] end
	end
	local factor = revenue / 29.4
	UI.stat(root, "RECEITAS", M.money(revenue), 65, 315, 310)
	UI.stat(root, "DESPESAS", M.money(cost), 427, 315, 310)
	UI.stat(root, "RESULTADO", "+ " .. M.money(revenue - cost), 790, 315, 310)
	UI.section(root, "FLUXO FINANCEIRO", 65, 448, 955)
	local baseline = 733
	for axis = 0, 3 do
		local y = baseline - axis * 65
		UI.line(root, 102, y, 1005, y, M.c.line, 1)
		UI.text(root, tostring(axis * 10), 65, y - 11, 30, 22, 11, M.c.muted)
	end
	for i, label in ipairs(months) do
		local x = 149 + (i - 1) * 146
		local amount = income[i] * 6.5
		UI.frame(root, x, baseline - amount, 35, amount, M.c.accent, i == 5 and 0 or 0.45)
		local cost = expenses[i] * 6.5
		UI.frame(root, x + 40, baseline - cost, 35, cost, M.c.blue, 0.22)
		UI.text(root, label, x - 4, baseline + 18, 93, 24, 12, i == 5 and M.c.white or M.c.muted, Enum.Font.GothamBold)
	end
	UI.frame(root, 66, 805, 7, 7, M.c.accent)
	UI.text(root, "Receitas", 86, 797, 130, 25, 13, M.c.muted)
	UI.frame(root, 232, 805, 7, 7, M.c.blue)
	UI.text(root, "Despesas", 252, 797, 130, 25, 13, M.c.muted)
	UI.text(root, "Segundo semestre  /  Dezembro projetado", 442, 797, 570, 25, 13, M.c.muted)
	UI.panel(root, 1080, 145, 455, 670, M.c.panel, 0.18)
	UI.section(root, "ORIGEM DAS RECEITAS", 1110, 183, 390)
	for i, item in ipairs(categories) do
		local y = 243 + (i - 1) * 84
		local selected = state.financeCategory == i
		UI.button(root, "", 1097, y - 8, 420, 76, function() state.financeCategory = i; ctx.rerender() end, ctx.scope, {selected = selected, quiet = not selected})
		UI.text(root, item.label, 1112, y, 370, 27, 16, M.c.white, Enum.Font.GothamBold)
		UI.text(root, M.money(item.value * factor), 1112, y + 33, 220, 24, 16, selected and M.c.accent or M.c.muted)
		UI.text(root, item.share .. "%", 1430, y + 33, 65, 24, 16, M.c.muted)
	end
	M.divider(root, 1110, 599, 390)
	local selected = categories[state.financeCategory]
	M.wrap(root, selected.label, 1110, 629, 390, 47, 22, M.c.white, Enum.Font.GothamBold)
	M.wrap(root, selected.detail, 1110, 689, 390, 93, 16, M.c.muted)
end
