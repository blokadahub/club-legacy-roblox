-- CL 27 · Prancheta visual com escalação e trocas locais. Não simula partidas.
local function playerById(data, id)
	for _, player in ipairs(data.players) do
		if player.id == id then
			return player
		end
	end
	return nil
end

local function line(ui, parent, position, size, color, transparency)
	return ui.new("Frame", {
		BackgroundColor3 = color,
		BackgroundTransparency = transparency or 0.5,
		BorderSizePixel = 0,
		Position = position,
		Size = size,
	}, parent)
end

return function(ctx)
	local ui, data, state = ctx.ui, ctx.data, ctx.state
	local colors = ui.theme
	state.formation = state.formation or "4-3-3"
	state.mentality = state.mentality or "Equilibrada"
	state.tacticsSlot = math.clamp(state.tacticsSlot or 1, 1, 11)
	state.lineup = state.lineup or {}
	for index = 1, math.min(11, #data.players) do
		state.lineup[index] = state.lineup[index] or data.players[index].id
	end
	local formation = data.formations[state.formation] or data.formations["4-3-3"]
	ui.section(ctx.parent, "LABORATÓRIO TÁTICO", "Dê forma à sua ideia.", "Escolha a formação, selecione uma posição no campo e ajuste a escalação.")
	local controls = ui.row(ctx.parent, 48)
	local formations = { "4-3-3", "4-4-2", "4-2-3-1" }
	for index, name in ipairs(formations) do
		local button = ui.button(controls, name, function()
			state.formation = name
			ctx.refresh()
		end, { selected = state.formation == name })
		button.Size = UDim2.new(1 / 3, -6, 0, 44)
		button.Position = UDim2.fromScale((index - 1) / 3, 0)
	end

	local pitch = ui.panel(ctx.parent, 594, Color3.fromRGB(16, 45, 40))
	pitch.ClipsDescendants = true
	ui.new("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(28, 62, 54), Color3.fromRGB(10, 27, 31)),
		Rotation = 90,
	}, pitch)
	for index = 0, 7 do
		line(ui, pitch, UDim2.fromScale(0.04, 0.07 + index * 0.106), UDim2.fromScale(0.92, 0.053), colors.text, 0.985)
	end
	local boundary = ui.new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.04, 0.07),
		Size = UDim2.fromScale(0.92, 0.85),
	}, pitch)
	ui.stroke(boundary, colors.text, 0.69)
	line(ui, boundary, UDim2.fromScale(0, 0.5), UDim2.new(1, 0, 0, 1), colors.text, 0.69)
	local circle = ui.new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(106, 106),
	}, boundary)
	ui.round(circle, 100)
	ui.stroke(circle, colors.text, 0.69)
	for _, y in ipairs({ 0, 0.78 }) do
		local penalty = ui.new("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.26, y),
			Size = UDim2.fromScale(0.48, 0.22),
		}, boundary)
		ui.stroke(penalty, colors.text, 0.69)
	end
	local direction = ui.label(pitch, "▲  DIREÇÃO DO ATAQUE", 10, colors.muted, 20)
	direction.Position = UDim2.fromScale(0.3, 0.01)
	direction.Size = UDim2.fromScale(0.4, 0.04)
	direction.TextXAlignment = Enum.TextXAlignment.Center
	local lineupRating = 0
	for index, slot in ipairs(formation.slots) do
		local player = playerById(data, state.lineup[index]) or data.players[index]
		lineupRating += player.overall
		local selected = state.tacticsSlot == index
		local marker = ui.button(pitch, "", function()
			state.tacticsSlot = index
			state.selectedPlayerId = player.id
			ctx.refresh()
		end, { selected = selected })
		marker.AnchorPoint = Vector2.new(0.5, 0.5)
		marker.Position = UDim2.fromScale(0.07 + slot.x * 0.86, 0.12 + slot.y * 0.73)
		marker.Size = UDim2.new(ctx.compact and 0.22 or 0.17, 0, 0, 75)
		marker.BackgroundColor3 = selected and colors.accent or colors.panel
		marker.BackgroundTransparency = selected and 0 or 0.14
		local ink = selected and colors.bg or colors.text
		local role = ui.label(marker, tostring(player.number) .. "   " .. slot.role, 11, selected and colors.bg or colors.accent, 19)
		role.Position = UDim2.fromOffset(5, 3)
		role.Size = UDim2.new(1, -10, 0, 19)
		role.TextXAlignment = Enum.TextXAlignment.Center
		local surname = player.name:match("%S+$") or player.name
		local name = ui.label(marker, surname, ctx.compact and 11 or 13, ink, 23)
		name.Position = UDim2.fromOffset(4, 24)
		name.Size = UDim2.new(1, -8, 0, 23)
		name.TextXAlignment = Enum.TextXAlignment.Center
		name.Font = Enum.Font.GothamBold
		local rating = ui.label(marker, tostring(player.overall), 13, ink, 20)
		rating.Position = UDim2.fromOffset(4, 49)
		rating.Size = UDim2.new(1, -8, 0, 20)
		rating.TextXAlignment = Enum.TextXAlignment.Center
	end
	local caption = ui.label(pitch, state.formation .. "    /    GERAL " .. tostring(math.floor(lineupRating / 11 + 0.5)), 12, colors.text, 28)
	caption.Position = UDim2.fromScale(0.05, 0.94)
	caption.Size = UDim2.fromScale(0.9, 0.05)

	local mindset = ui.panel(ctx.parent, 132)
	local title = ui.label(mindset, "MENTALIDADE", 11, colors.accent, 24)
	title.Position = UDim2.fromOffset(16, 12)
	title.Size = UDim2.new(1, -32, 0, 24)
	for index, name in ipairs({ "Defensiva", "Equilibrada", "Ofensiva" }) do
		local button = ui.button(mindset, name, function()
			state.mentality = name
			ctx.toast("Identidade tática: " .. name .. ".")
			ctx.refresh()
		end, { selected = state.mentality == name })
		button.Position = UDim2.new((index - 1) / 3, 8, 0, 46)
		button.Size = UDim2.new(1 / 3, -16, 0, 44)
	end
	local note = ui.label(mindset, "Configuração visual local · não altera resultados de partidas.", 11, colors.muted, 26)
	note.Position = UDim2.fromOffset(16, 96)
	note.Size = UDim2.new(1, -32, 0, 26)

	local slot = formation.slots[state.tacticsSlot]
	local current = playerById(data, state.lineup[state.tacticsSlot]) or data.players[1]
	ui.section(ctx.parent, "ESCALAÇÃO", "Posição selecionada: " .. slot.role, current.name .. " ocupa esta posição. Escolha outro jogador para trocar; titulares trocam de lugar.")
	local grid = ui.grid(ctx.parent, 220, 144)
	for _, player in ipairs(data.players) do
		ui.playerCard(grid, player, function()
			local target = state.tacticsSlot
			local previousId = state.lineup[target]
			local sourceIndex = table.find(state.lineup, player.id)
			if sourceIndex and sourceIndex ~= target then
				state.lineup[sourceIndex] = previousId
			end
			state.lineup[target] = player.id
			state.selectedPlayerId = player.id
			ctx.toast(player.name .. " selecionado para " .. slot.role .. ".")
			ctx.refresh()
		end, player.id == current.id)
	end
end
