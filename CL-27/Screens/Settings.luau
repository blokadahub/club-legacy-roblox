-- Preferências locais que afetam realmente o texto, as transições e os viewports.
return function(ctx)
	local ui, state = ctx.ui, ctx.state
	local theme = ui.theme
	local compact = ctx.compact == true
	local settings = state.settings
	if settings.menuVolume == nil then settings.menuVolume = 0.3 end
	local function apply()
		ctx.applySettings()
		ctx.refresh()
	end
	ui.section(ctx.parent, "CENTRAL DE PREFERÊNCIAS", "O jogo no seu ritmo.", "Ajustes da interface aplicados imediatamente nesta sessão.")

	local motion = ui.panel(ctx.parent, 164)
	local motionTitle = ui.label(motion, "MOVIMENTO DA INTERFACE", 12, theme.accent, 24)
	motionTitle.Position = UDim2.fromOffset(24, 18)
	local motionDetail = ui.label(motion, "Transições, entrada de painéis e movimento dos personagens.", 15, theme.text, 40)
	motionDetail.Position = UDim2.fromOffset(24, 48)
	motionDetail.Size = UDim2.new(1, -48, 0, 40)
	motionDetail.TextWrapped = true
	local toggle = ui.button(motion, settings.reducedMotion and "Movimento reduzido: ativado" or "Movimento reduzido: desativado", function()
		settings.reducedMotion = not settings.reducedMotion
		apply()
	end, { width = UDim2.new(1, -48, 0, 44), selected = settings.reducedMotion })
	toggle.Position = UDim2.fromOffset(24, 104)

	ui.label(ctx.parent, "QUALIDADE DA APRESENTAÇÃO 3D", 12, theme.muted, 32)
	local qualityRow = ui.row(ctx.parent, 62)
	for index, quality in ipairs({ "Alta", "Equilibrada", "Econômica" }) do
		local button = ui.button(qualityRow, quality, function()
			settings.quality = quality
			apply()
		end, { width = UDim2.new(1 / 3, -8, 1, 0), selected = settings.quality == quality })
		button.Position = UDim2.new((index - 1) / 3, 0, 0, 0)
		if compact then
			button.TextSize = 12 * settings.textScale
			button:SetAttribute("CL27TextSize", 12)
		end
	end
	local descriptions = {
		Alta = "Alta: apresentação completa e movimento suave dos personagens.",
		Equilibrada = "Equilibrada: reduz a frequência de atualização dos personagens para poupar processamento.",
		["Econômica"] = "Econômica: apresentação estática dos personagens para reduzir o trabalho de renderização.",
	}
	local detail = ui.label(ctx.parent, descriptions[settings.quality] or descriptions.Alta, 13, theme.muted, 46)
	detail.TextWrapped = true

	local typography = ui.panel(ctx.parent, 180)
	local typeTitle = ui.label(typography, "LEITURA E ACESSIBILIDADE", 12, theme.accent, 24)
	typeTitle.Position = UDim2.fromOffset(24, 18)
	local typeText = ui.label(typography, "Escolha o tamanho dos textos da interface.", 16, theme.text, 40)
	typeText.Position = UDim2.fromOffset(24, 52)
	typeText.Size = UDim2.new(1, -48, 0, 40)
	for index, choice in ipairs({ { label = "Padrão · 100%", value = 1 }, { label = "Ampliado · 115%", value = 1.15 } }) do
		local button = ui.button(typography, choice.label, function()
			settings.textScale = choice.value
			apply()
		end, { width = UDim2.new(0.5, -30, 0, 48), selected = settings.textScale == choice.value })
		button.Position = UDim2.new((index - 1) * 0.5, 24, 0, 110)
		if compact then
			button.TextSize = 12 * settings.textScale
			button:SetAttribute("CL27TextSize", 12)
		end
	end

	local audio = ui.panel(ctx.parent, 248)
	local audioTitle = ui.label(audio, "ÁUDIO DOS MENUS", 12, theme.accent, 24)
	audioTitle.Position = UDim2.fromOffset(24, 18)
	local audioDetail = ui.label(audio, "Retorno sonoro curto ao selecionar botões.", 14, theme.text, 36)
	audioDetail.Position = UDim2.fromOffset(24, 50)
	audioDetail.Size = UDim2.new(1, -48, 0, 36)
	for index, choice in ipairs({
		{ label = "Desligado", value = 0 }, { label = "Baixo", value = 0.15 },
		{ label = "Médio", value = 0.3 }, { label = "Alto", value = 0.6 },
	}) do
		local button = ui.button(audio, choice.label, function()
			settings.menuVolume = choice.value
			apply()
		end, { width = UDim2.new(0.25, -14, 0, 44), selected = settings.menuVolume == choice.value })
		button.Position = UDim2.new((index - 1) / 4, 16, 0, 96)
		if compact then
			button.TextSize = 11 * settings.textScale
			button:SetAttribute("CL27TextSize", 11)
		end
	end
	local status = ui.label(audio, ctx.audioStatus() .. " • Recurso nativo do Roblox", 11, theme.muted, 42)
	status.Position = UDim2.fromOffset(24, 148)
	status.Size = UDim2.new(1, -48, 0, 42)
	status.TextWrapped = true
	local test = ui.button(audio, "Testar som do menu", function() ctx.testAudio() end, { width = UDim2.new(1, -48, 0, 40) })
	test.Position = UDim2.fromOffset(24, 194)

	local controls = ui.panel(ctx.parent, 220)
	local controlsTitle = ui.label(controls, "CONTROLES E NAVEGAÇÃO", 12, theme.accent, 24)
	controlsTitle.Position = UDim2.fromOffset(24, 18)
	local lines = {
		{ "TOQUE", "Toque nos cards e botões. Arraste para rolar listas e painéis." },
		{ "MOUSE", "Clique para selecionar. Use a roda para percorrer o conteúdo." },
		{ "CONTROLE", "Use a seleção de interface do Roblox e o botão de confirmação." },
	}
	for index, line in ipairs(lines) do
		local label = ui.label(controls, line[1], 11, theme.accent, 24)
		label.Position = UDim2.fromOffset(24, 58 + (index - 1) * 48)
		label.Size = UDim2.new(0.19, -10, 0, 24)
		local text = ui.label(controls, line[2], 13, theme.text, 40)
		text.Position = UDim2.new(0.19, 0, 0, 54 + (index - 1) * 48)
		text.Size = UDim2.new(0.81, -24, 0, 40)
		text.TextWrapped = true
	end
	local notice = ui.label(ctx.parent, "CL 27 • Interface de gestão com dados fictícios. Preferências e escolhas locais não são gravadas no DataStore.", 13, theme.muted, 48)
	notice.TextWrapped = true
	ui.button(ctx.parent, "Restaurar preferências", function()
		settings.reducedMotion, settings.quality, settings.textScale, settings.menuVolume = false, "Alta", 1, 0.3
		ctx.toast("Preferências restauradas.")
		apply()
	end, { height = 46 })
end
