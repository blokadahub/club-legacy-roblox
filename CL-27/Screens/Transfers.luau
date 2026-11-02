-- Mercado editorial e negociação visual. Nenhuma contratação é enviada ao servidor.
return function(ctx)
	local ui, state, data = ctx.ui, ctx.state, ctx.data
	local theme = ui.theme
	local compact = ctx.compact == true
	state.shortlist = state.shortlist or {}
	state.offers = state.offers or {}
	state.negotiationAmount = state.negotiationAmount or {}
	state.transferQuery = state.transferQuery or ""
	state.transferFilter = state.transferFilter or "Todos"
	ui.section(ctx.parent, "OBSERVAÇÃO • JANELA DE JULHO", "O próximo nome do seu clube.", "Compare perfis, monte uma lista e prepare uma proposta visual.")

	local searchRow = ui.row(ctx.parent, 50)
	local search = ui.new("TextBox", {
		BackgroundColor3 = theme.panelAlt, BorderSizePixel = 0,
		Size = UDim2.new(1, -152, 1, 0), ClearTextOnFocus = false,
		Text = state.transferQuery, PlaceholderText = "Pesquisar jogador ou nacionalidade…",
		TextColor3 = theme.text, PlaceholderColor3 = theme.muted,
		Font = Enum.Font.Gotham, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left,
	}, searchRow)
	ui.round(search, 8)
	ui.pad(search, 14)
	ctx.scope:connect(search:GetPropertyChangedSignal("Text"), function()
		state.transferQuery = search.Text
	end)
	ctx.scope:connect(search.FocusLost, function(enterPressed)
		if enterPressed then ctx.refresh() end
	end)
	local searchButton = ui.button(searchRow, "Pesquisar", function() ctx.refresh() end, { width = 140, height = 50, primary = true })
	searchButton.Position = UDim2.new(1, -140, 0, 0)

	local filters = { "Todos", "Goleiros", "Defensores", "Meio-campo", "Atacantes", "Favoritos" }
	local filterRow = ui.row(ctx.parent, compact and 98 or 44)
	for index, name in ipairs(filters) do
		local columns = compact and 3 or #filters
		local button = ui.button(filterRow, name, function()
			state.transferFilter = name
			ctx.refresh()
		end, { width = UDim2.new(1 / columns, -6, 0, 44), selected = state.transferFilter == name })
		button.Position = UDim2.new(((index - 1) % columns) / columns, 0, 0, math.floor((index - 1) / columns) * 52)
		button.TextSize = 12 * state.settings.textScale
		button:SetAttribute("CL27TextSize", 12)
	end

	local filtered = {}
	local positionGroup = { GOL = "Goleiros", LAT = "Defensores", ZAG = "Defensores", VOL = "Meio-campo", MEI = "Meio-campo", PON = "Atacantes", ATA = "Atacantes" }
	local selected
	for _, player in ipairs(data.market) do
		if player.id == state.selectedMarketId then selected = player end
		local query = string.lower(state.transferQuery)
		local matchesText = query == "" or string.find(string.lower(player.name .. " " .. player.nation), query, 1, true) ~= nil
		local matchesPosition = state.transferFilter == "Todos" or positionGroup[player.position] == state.transferFilter
		if state.transferFilter == "Favoritos" then matchesPosition = state.shortlist[player.id] == true end
		if matchesText and matchesPosition then table.insert(filtered, player) end
	end
	selected = selected or filtered[1] or data.market[1]
	if selected then
		state.selectedMarketId = selected.id
		local hero = ui.panel(ctx.parent, compact and 630 or 340)
		local info = ui.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(24, 22), Size = compact and UDim2.new(1, -48, 0, 296) or UDim2.new(0.59, -32, 1, -44) }, hero)
		local eyebrow = ui.label(info, "DOSSIÊ DO JOGADOR  /  " .. selected.position, 12, theme.accent, 24)
		eyebrow.Position = UDim2.fromOffset(0, 0)
		local name = ui.label(info, selected.name, 29, theme.text, 62)
		name.TextWrapped = true
		name.Position = UDim2.fromOffset(0, 30)
		local profile = ui.label(info, string.format("%s  •  %d anos  •  %d GER", selected.nation, selected.age, selected.overall), 14, theme.muted, 28)
		profile.Position = UDim2.fromOffset(0, 96)
		local value = ui.label(info, data.money(selected.value), 32, theme.text, 42)
		value.Position = UDim2.fromOffset(0, 138)
		local wage = ui.label(info, "Valor estimado • salário " .. data.money(selected.wage) .. "/semana", 12, theme.muted, 34)
		wage.Position = UDim2.fromOffset(0, 183)
		wage.TextWrapped = true
		local watch = ui.button(info, state.shortlist[selected.id] and "★ Na lista de observação" or "☆ Adicionar à observação", function()
			state.shortlist[selected.id] = not state.shortlist[selected.id]
			ctx.toast(state.shortlist[selected.id] and "Jogador adicionado à lista." or "Jogador removido da lista.")
			ctx.refresh()
		end, { height = 48, selected = state.shortlist[selected.id] == true })
		watch.Position = UDim2.new(0, 0, 1, -48)
		local avatar = ctx.avatar(hero, selected, { fullBody = true, interactive = true })
		avatar.Position = compact and UDim2.fromOffset(0, 330) or UDim2.new(0.62, 0, 0, 0)
		avatar.Size = compact and UDim2.new(1, 0, 0, 300) or UDim2.new(0.38, 0, 1, 0)
	end

	ui.label(ctx.parent, string.format("MERCADO SELECIONADO  /  %02d PERFIS", #filtered), 12, theme.muted, 28)
	if #filtered == 0 then
		local empty = ui.panel(ctx.parent, 142)
		local title = ui.label(empty, "Nenhum perfil encontrado.", 21, theme.text, 42)
		title.Position = UDim2.fromOffset(20, 12)
		local reset = ui.button(empty, "Limpar pesquisa e filtros", function()
			state.transferQuery, state.transferFilter = "", "Todos"
			ctx.refresh()
		end, { width = 250, height = 44 })
		reset.Position = UDim2.fromOffset(20, 76)
	else
		local cards = ui.grid(ctx.parent, 220, 144)
		for _, player in ipairs(filtered) do
			ui.playerCard(cards, player, function()
				state.selectedMarketId = player.id
				ctx.refresh()
			end, selected and selected.id == player.id)
		end
	end

	if not selected then return end
	local negotiation = ui.panel(ctx.parent, compact and 390 or 318)
	local title = ui.label(negotiation, "MESA DE NEGOCIAÇÃO", 13, theme.accent, 24)
	title.Position = UDim2.fromOffset(24, 18)
	local subtitle = ui.label(negotiation, "Uma proposta começa com informação.", 24, theme.text, 36)
	subtitle.Position = UDim2.fromOffset(24, 50)
	subtitle.Size = UDim2.new(1, -48, 0, 36)
	subtitle.TextSize = (compact and 19 or 24) * state.settings.textScale
	subtitle:SetAttribute("CL27TextSize", compact and 19 or 24)
	local note = ui.label(negotiation, "Rascunho local: nenhum jogador é contratado e nenhum orçamento é debitado.", 13, theme.muted, 44)
	note.Position = UDim2.fromOffset(24, 92)
	note.Size = UDim2.new(1, -48, 0, 44)
	note.TextWrapped = true
	local step = math.max(10000, math.floor(selected.value * 0.05 / 10000) * 10000)
	local amount = state.negotiationAmount[selected.id] or selected.value
	local offer = ui.label(negotiation, data.money(amount), 30, theme.text, 48)
	offer.Position = UDim2.fromOffset(82, 147)
	offer.Size = compact and UDim2.new(1, -164, 0, 48) or UDim2.new(0.5, -110, 0, 48)
	offer.TextSize = (compact and 24 or 30) * state.settings.textScale
	offer:SetAttribute("CL27TextSize", compact and 24 or 30)
	local lower = ui.button(negotiation, "−", function()
		state.negotiationAmount[selected.id] = math.max(step, amount - step)
		ctx.refresh()
	end, { width = 46, height = 46 })
	lower.Position = UDim2.fromOffset(24, 148)
	local increase = ui.button(negotiation, "+", function()
		state.negotiationAmount[selected.id] = math.min(selected.value * 2, amount + step)
		ctx.refresh()
	end, { width = 46, height = 46 })
	increase.Position = compact and UDim2.new(1, -70, 0, 148) or UDim2.new(0.5, -20, 0, 148)
	local save = ui.button(negotiation, "Salvar rascunho", function()
		state.offers[selected.id] = amount
		ctx.toast("Rascunho de " .. data.money(amount) .. " salvo nesta sessão.")
		ctx.refresh()
	end, { width = compact and UDim2.new(1, -48, 0, 46) or UDim2.new(0.42, -24, 0, 46), primary = true })
	save.Position = compact and UDim2.fromOffset(24, 208) or UDim2.new(0.58, 0, 0, 148)
	local saved = state.offers[selected.id]
	local status = ui.label(negotiation, saved and ("Último rascunho: " .. data.money(saved) .. "  •  " .. selected.name) or "Ajuste o valor em passos de 5% e salve para comparar depois.", 13, theme.muted, 46)
	status.Position = UDim2.fromOffset(24, compact and 270 or 212)
	status.Size = UDim2.new(1, -48, 0, 46)
	status.TextWrapped = true
	if saved then
		local remove = ui.button(negotiation, "Descartar rascunho", function()
			state.offers[selected.id] = nil
			ctx.toast("Rascunho descartado.")
			ctx.refresh()
		end, { width = 210, height = 36 })
		remove.Position = UDim2.fromOffset(24, compact and 336 or 266)
	end
end
