-- CL 27 · Planos visuais de desenvolvimento, sem simulação ou progressão temporal.
local plans = {
	{ id = "equilibrado", name = "Completo", description = "Fundamentos em todas as áreas", focus = { "passing", "dribbling", "physical" }, color = "accent" },
	{ id = "tecnico", name = "Técnico", description = "Controle, criação e último passe", focus = { "passing", "dribbling", "shooting" }, color = "gold" },
	{ id = "fisico", name = "Atlético", description = "Explosão, resistência e força", focus = { "pace", "physical", "defending" }, color = "accent" },
	{ id = "defensivo", name = "Defensivo", description = "Leitura, recuperação e saída", focus = { "defending", "physical", "passing" }, color = "gold" },
}

local attributes = {
	{ "pace", "Ritmo" }, { "shooting", "Finalização" }, { "passing", "Passe" },
	{ "dribbling", "Condução" }, { "defending", "Defesa" }, { "physical", "Físico" },
}

return function(ctx)
	local ui, data, state = ctx.ui, ctx.data, ctx.state
	local colors = ui.theme
	state.training = state.training or {}
	local selected = data.players[1]
	for _, player in ipairs(data.players) do
		if player.id == state.selectedPlayerId then
			selected = player
			break
		end
	end
	state.selectedPlayerId = selected.id
	local selectedPlanId = state.training[selected.id] or "equilibrado"
	local selectedPlan = plans[1]
	for _, plan in ipairs(plans) do
		if plan.id == selectedPlanId then
			selectedPlan = plan
		end
	end

	ui.section(ctx.parent, "CENTRO DE PERFORMANCE", "O próximo nível começa aqui.", "Defina a direção do treinamento e acompanhe o perfil técnico do seu elenco.")
	local hero = ui.panel(ctx.parent, ctx.compact and 552 or 292)
	local identity = ui.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(ctx.compact and 1 or 0.60, 0, 0, 292) }, hero)
	ui.pad(identity, 22)
	ui.stack(identity, 5)
	ui.label(identity, "DESENVOLVIMENTO INDIVIDUAL", 11, colors.accent, 25)
	local name = ui.label(identity, selected.name, 27, colors.text, 42)
	name.Font = Enum.Font.GothamBold
	ui.label(identity, tostring(selected.age) .. " anos  /  " .. selected.position .. "  /  " .. selected.nation, 13, colors.muted, 25)
	ui.label(identity, tostring(selected.overall) .. "  →  " .. tostring(selected.potential), 36, colors.accent, 53)
	ui.label(identity, "GERAL ATUAL                  POTENCIAL", 10, colors.muted, 22)
	ui.label(identity, "Plano ativo: " .. selectedPlan.name, 15, colors.text, 29)
	local portrait = ctx.avatar(hero, selected, { fullBody = true, interactive = true })
	if portrait then
		portrait.Position = ctx.compact and UDim2.fromOffset(0, 292) or UDim2.fromScale(0.61, 0.02)
		portrait.Size = ctx.compact and UDim2.new(1, 0, 0, 260) or UDim2.fromScale(0.38, 0.96)
	end

	ui.section(ctx.parent, "DIREÇÃO TÉCNICA", "Escolha um plano", "A escolha fica salva nesta sessão de interface. Não altera atributos nem simula treino.")
	local planGrid = ui.grid(ctx.parent, 220, 154)
	for _, plan in ipairs(plans) do
		local card = ui.button(planGrid, "", function()
			state.training[selected.id] = plan.id
			ctx.toast("Plano " .. plan.name .. " atribuído a " .. selected.name .. ".")
			ctx.refresh()
		end, { selected = plan.id == selectedPlanId })
		card.Size = UDim2.fromOffset(220, 154)
		local title = ui.label(card, plan.name, 23, colors.text, 30)
		title.Position = UDim2.fromOffset(16, 14)
		title.Size = UDim2.new(1, -32, 0, 30)
		title.Font = Enum.Font.GothamBold
		local desc = ui.label(card, plan.description, 13, colors.muted, 44)
		desc.Position = UDim2.fromOffset(16, 48)
		desc.Size = UDim2.new(1, -32, 0, 44)
		desc.TextWrapped = true
		local status = ui.label(card, plan.id == selectedPlanId and "● PLANO ATIVO" or "ATRIBUIR PLANO  →", 10, colors[plan.color], 25)
		status.Position = UDim2.fromOffset(16, 116)
		status.Size = UDim2.new(1, -32, 0, 25)
	end

	local detail = ui.panel(ctx.parent, 540)
	ui.pad(detail, 20)
	ui.stack(detail, 5)
	ui.label(detail, "PERFIL TÉCNICO", 13, colors.accent, 28)
	for _, attribute in ipairs(attributes) do
		local focused = table.find(selectedPlan.focus, attribute[1]) ~= nil
		ui.bar(detail, attribute[2] .. (focused and "  ·  foco do plano" or ""), selected.attributes[attribute[1]], 99, focused and colors.accent or colors.muted)
	end
	ui.label(detail, "As barras mostram atributos atuais do conjunto fictício; foco não representa evolução já conquistada.", 11, colors.muted, 38)

	ui.section(ctx.parent, "GESTÃO DO GRUPO", "Trabalhe o potencial de cada jogador", "Toque em um jogador para editar seu plano individual.")
	local grid = ui.grid(ctx.parent, 220, 144)
	for _, player in ipairs(data.players) do
		ui.playerCard(grid, player, function()
			state.selectedPlayerId = player.id
			ctx.refresh()
		end, player.id == selected.id)
	end
end
