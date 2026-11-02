-- CL 27 · Central de elenco. Todos os dados são fictícios e locais.
local function findPlayer(data, id)
	for _, player in ipairs(data.players) do
		if player.id == id then
			return player
		end
	end
	return data.players[1]
end

local function smallLabel(ui, parent, text, x, y, width, size, color)
	local label = ui.label(parent, text, size or 14, color or ui.theme.muted, 24)
	label.Position = UDim2.fromScale(x, y)
	label.Size = UDim2.new(width, 0, 0, 24)
	return label
end

return function(ctx)
	local ui, state, data = ctx.ui, ctx.state, ctx.data
	local colors = ui.theme
	local selected = findPlayer(data, state.selectedPlayerId)
	state.selectedPlayerId = selected.id
	ui.section(ctx.parent, "DEPARTAMENTO DE FUTEBOL", "Seu elenco. Seu legado.", "Conheça os jogadores, compare atributos e construa a identidade do time.")

	local hero = ui.panel(ctx.parent, ctx.compact and 610 or 330)
	local identity = ui.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(ctx.compact and 1 or 0.62, 0, 0, 330),
	}, hero)
	local glow = ui.new("Frame", {
		BackgroundColor3 = colors.accent,
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		Position = ctx.compact and UDim2.new(0, 0, 0, 330) or UDim2.fromScale(0.59, 0),
		Size = ctx.compact and UDim2.new(1, 0, 0, 280) or UDim2.fromScale(0.41, 1),
	}, hero)
	ui.round(glow, 12)
	ui.new("UIGradient", {
		Rotation = 30,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) }),
	}, glow)

	smallLabel(ui, identity, "EM DESTAQUE  /  Nº " .. tostring(selected.number), 0.06, 0.07, 0.90, 12, colors.accent)
	local name = smallLabel(ui, identity, selected.name, 0.06, 0.18, 0.90, ctx.compact and 26 or 30, colors.text)
	name.Size = UDim2.new(0.90, 0, 0, 44)
	name.TextWrapped = true
	name.Font = Enum.Font.GothamBold
	smallLabel(ui, identity, (data.positionNames[selected.position] or selected.position) .. "  ·  " .. selected.nation, 0.06, 0.35, 0.90, 14)
	smallLabel(ui, identity, tostring(selected.age) .. " anos  ·  " .. tostring(selected.height) .. "  ·  Pé " .. selected.foot, 0.06, 0.44, 0.90, 13)
	local rating = smallLabel(ui, identity, tostring(selected.overall), 0.06, 0.56, 0.26, 44, colors.accent)
	rating.Size = UDim2.new(0.26, 0, 0, 58)
	rating.Font = Enum.Font.GothamBold
	smallLabel(ui, identity, "GERAL", 0.06, 0.75, 0.24, 11)
	local potential = smallLabel(ui, identity, tostring(selected.potential), 0.35, 0.56, 0.28, 36, colors.text)
	potential.Size = UDim2.new(0.26, 0, 0, 58)
	potential.Font = Enum.Font.GothamBold
	smallLabel(ui, identity, "POTENCIAL", 0.35, 0.75, 0.30, 11)
	smallLabel(ui, identity, data.money(selected.value), 0.66, 0.61, 0.30, 19, colors.gold)
	smallLabel(ui, identity, "VALOR ESTIMADO", 0.66, 0.75, 0.30, 10)

	local portrait = ctx.avatar(hero, selected, { fullBody = true, interactive = true })
	if portrait then
		portrait.Position = ctx.compact and UDim2.new(0, 0, 0, 330) or UDim2.fromScale(0.62, 0.02)
		portrait.Size = ctx.compact and UDim2.new(1, 0, 0, 280) or UDim2.fromScale(0.37, 0.96)
	end

	local attributes = ui.row(ctx.parent, 146)
	local attributeNames = {
		{ "pace", "RITMO" }, { "shooting", "FINALIZAÇÃO" }, { "passing", "PASSE" },
		{ "dribbling", "CONDUÇÃO" }, { "defending", "DEFESA" }, { "physical", "FÍSICO" },
	}
	for index, attribute in ipairs(attributeNames) do
		local card = ui.panel(attributes, 68, colors.panelAlt)
		local column = (index - 1) % 3
		local row = math.floor((index - 1) / 3)
		card.Position = UDim2.new(column / 3, 4, 0, row * 76)
		card.Size = UDim2.new(1 / 3, -8, 0, 68)
		local title = ui.label(card, attribute[2], ctx.compact and 9 or 10, colors.muted, 20)
		title.Position = UDim2.new(0, 12, 0, 7)
		title.Size = UDim2.new(1, -24, 0, 20)
		local value = ui.label(card, tostring(selected.attributes[attribute[1]]), 23, colors.text, 30)
		value.Font = Enum.Font.GothamBold
		value.Position = UDim2.new(0, 12, 0, 29)
		value.Size = UDim2.new(1, -24, 0, 30)
	end

	local actions = ui.row(ctx.parent, ctx.compact and 100 or 48)
	local development = ui.button(actions, "Plano de desenvolvimento", function()
		ctx.navigate("Development")
	end, { primary = true })
	development.Size = ctx.compact and UDim2.new(1, 0, 0, 44) or UDim2.new(0.55, -6, 0, 44)
	local tactics = ui.button(actions, "Abrir táticas", function()
		ctx.navigate("Tactics")
	end)
	tactics.Position = ctx.compact and UDim2.fromOffset(0, 52) or UDim2.fromScale(0.55, 0)
	tactics.Size = ctx.compact and UDim2.new(1, 0, 0, 44) or UDim2.new(0.45, 0, 0, 44)

	ui.section(ctx.parent, "GRUPO PRINCIPAL", tostring(#data.players) .. " jogadores, um só objetivo", "Selecione um card para inspecionar o jogador. A seleção é compartilhada com o desenvolvimento.")
	local filters = { "Todos", "GOL", "Defesa", "Meio", "Ataque" }
	local filtersRow = ui.row(ctx.parent, 48)
	for index, filter in ipairs(filters) do
		local button = ui.button(filtersRow, filter, function()
			state.squadFilter = filter
			ctx.refresh()
		end, { selected = (state.squadFilter or "Todos") == filter })
		button.Size = UDim2.new(0.2, -6, 0, 44)
		button.Position = UDim2.fromScale((index - 1) * 0.2, 0)
	end

	local grid = ui.grid(ctx.parent, 220, 144)
	local filter = state.squadFilter or "Todos"
	local count = 0
	for _, player in ipairs(data.players) do
		local position = player.position
		local visible = filter == "Todos" or filter == position
			or (filter == "Defesa" and (position == "ZAG" or position == "LAT"))
			or (filter == "Meio" and (position == "VOL" or position == "MEI"))
			or (filter == "Ataque" and (position == "PON" or position == "ATA"))
		if visible then
			count += 1
			ui.playerCard(grid, player, function()
				state.selectedPlayerId = player.id
				ctx.refresh()
			end, player.id == selected.id)
		end
	end
	if count == 0 then
		ui.label(ctx.parent, "Nenhum jogador nesta posição.", 15, colors.muted, 44)
	end
end
