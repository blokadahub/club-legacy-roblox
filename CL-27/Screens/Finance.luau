-- Indicadores financeiros derivados exclusivamente do conjunto de dados editorial.
return function(ctx)
	local ui, data, state, T = ctx.ui, ctx.data, ctx.state, ctx.ui.theme
	local finance = data.finance
	local function sum(items)
		local total = 0
		for _, item in ipairs(items) do total += item.amount end
		return total
	end
	local function text(parent, value, size, color, pos, dim)
		local l = ui.label(parent, value, size, color, dim.Y.Offset)
		l.Position, l.Size = pos, dim
		return l
	end
	local income, expense = sum(finance.income), sum(finance.expenses)
	ui.section(ctx.parent, "GESTÃO FINANCEIRA", "CRESCER COM EQUILÍBRIO", "Julho de 2027 · valores fictícios em reais · planejamento sem movimentações reais.")
	local metrics = ui.row(ctx.parent, ctx.compact and 336 or 112)
	local values = {
		{"VERBA DISPONÍVEL", data.money(finance.budget), "Orçamento para planejamento"},
		{"SALDO DE JULHO", data.money(income-expense), "Receitas menos despesas"},
		{"FOLHA SEMANAL", data.money(finance.weeklyWages), "Limite " .. data.money(finance.wageBudget)},
	}
	for i, v in ipairs(values) do
		local m = ui.metric(metrics, v[1], v[2], v[3])
		if ctx.compact then
			m.Size, m.Position = UDim2.new(1, 0, 0, 104), UDim2.fromOffset(0, (i-1)*112)
		else
			m.Size, m.Position = UDim2.new(1/3, -8, 1, 0), UDim2.new((i-1)/3, 4, 0, 0)
		end
	end
	local usage = ui.bar(ctx.parent, "TETO SALARIAL UTILIZADO (%)", math.floor(finance.weeklyWages / math.max(1, finance.wageBudget) * 100 + 0.5), 100, T.accent)
	usage.Size = UDim2.new(1, 0, 0, 48)
	local chart = ui.panel(ctx.parent, 300)
	text(chart, "FLUXO DE CAIXA", 18, T.text, UDim2.fromOffset(22, 16), UDim2.new(0.6, 0, 0, 28))
	text(chart, "RECEITAS  /  DESPESAS", 11, T.muted, UDim2.new(0.6, 0, 0, 19), UDim2.new(0.4, -20, 0, 24))
	local maxAmount = 1
	for _, m in ipairs(finance.months) do maxAmount = math.max(maxAmount, m.income, m.expense) end
	local plot = ui.new("Frame", {BackgroundTransparency = 1, Position = UDim2.fromOffset(22, 62), Size = UDim2.new(1, -44, 0, 212)}, chart)
	for line = 0, 3 do
		ui.new("Frame", {BorderSizePixel = 0, BackgroundColor3 = T.line, BackgroundTransparency = 0.5, Position = UDim2.new(0, 0, 0, line*52), Size = UDim2.new(1, 0, 0, 1)}, plot)
	end
	for i, m in ipairs(finance.months) do
		local group = ui.new("Frame", {BackgroundTransparency = 1, Position = UDim2.new((i-1)/#finance.months, 0, 0, 0), Size = UDim2.new(1/#finance.months, 0, 1, 0)}, plot)
		local h1, h2 = math.max(2, m.income/maxAmount*150), math.max(2, m.expense/maxAmount*150)
		local revenueBar = ui.new("Frame", {BorderSizePixel = 0, BackgroundColor3 = T.accent, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.35, 0, 0, 158), Size = UDim2.new(0.22, 0, 0, h1)}, group)
		local expenseBar = ui.new("Frame", {BorderSizePixel = 0, BackgroundColor3 = T.muted, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.65, 0, 0, 158), Size = UDim2.new(0.22, 0, 0, h2)}, group)
		ui.round(revenueBar, 4); ui.round(expenseBar, 4)
		local monthLabel = text(group, m.label, 12, T.muted, UDim2.fromOffset(0, 168), UDim2.new(1, 0, 0, 22))
		monthLabel.TextXAlignment = Enum.TextXAlignment.Center
	end
	local tabs = ui.row(ctx.parent, 48)
	local tabNames = {"Resumo", "Receitas", "Despesas"}
	state.financeView = state.financeView or "Resumo"
	for i, name in ipairs(tabNames) do
		local b = ui.button(tabs, name, function() state.financeView = name; ctx.refresh() end, {selected = state.financeView == name})
		b.Size, b.Position = UDim2.new(1/3, -8, 0, 44), UDim2.new((i-1)/3, 4, 0, 0)
	end
	local function ledger(title, list, total, color)
		ui.section(ctx.parent, "BALANÇO DE JULHO", title, "Total: " .. data.money(total))
		for _, entry in ipairs(list) do
			local p = ui.panel(ctx.parent, ctx.compact and 104 or 76)
			text(p, entry.label, 16, T.text, UDim2.fromOffset(20, 10), UDim2.new(ctx.compact and 1 or 0.62, ctx.compact and -40 or -20, 0, 28))
			text(p, data.money(entry.amount), 18, color, ctx.compact and UDim2.fromOffset(20, 40) or UDim2.new(0.62, 0, 0, 10), UDim2.new(ctx.compact and 1 or 0.38, ctx.compact and -40 or -20, 0, 28))
			local track = ui.new("Frame", {BorderSizePixel = 0, BackgroundColor3 = T.line, Position = UDim2.fromOffset(20, ctx.compact and 84 or 52), Size = UDim2.new(1, -40, 0, 4)}, p)
			ui.new("Frame", {BorderSizePixel = 0, BackgroundColor3 = color, Size = UDim2.new(total > 0 and entry.amount/total or 0, 0, 1, 0)}, track)
		end
	end
	if state.financeView ~= "Despesas" then ledger("ORIGEM DAS RECEITAS", finance.income, income, T.accent) end
	if state.financeView ~= "Receitas" then ledger("DISTRIBUIÇÃO DAS DESPESAS", finance.expenses, expense, T.gold) end
end
