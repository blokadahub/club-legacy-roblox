-- Identidade do clube aplicada aos menus e ao uniforme do personagem.
return function(ctx)
	local ui, state, data = ctx.ui, ctx.state, ctx.data
	local theme = ui.theme
	local compact = ctx.compact == true
	local identity = state.identity
	local function apply()
		ctx.applyIdentity()
		ctx.refresh()
	end
	ui.section(ctx.parent, "ATELIÊ DO CLUBE", "Uma identidade. O seu legado.", "Escudo, cores e uniforme em uma apresentação integrada.")

	local preview = ui.panel(ctx.parent, compact and 650 or 354)
	local emblem = ui.new("Frame", {
		BackgroundColor3 = identity.primary, BorderSizePixel = 0,
		Position = UDim2.fromOffset(30, 32), Size = UDim2.fromOffset(124, 138),
	}, preview)
	ui.round(emblem, identity.crest == "Círculo" and 70 or (identity.crest == "Escudo" and 26 or 6))
	ui.stroke(emblem, identity.secondary, 0)
	if identity.crest == "Escudo" then
		local tip = ui.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.88, 0),
			Size = UDim2.fromOffset(56, 56), Rotation = 45,
			BackgroundColor3 = identity.primary, BorderSizePixel = 0, ZIndex = 1,
		}, emblem)
		ui.round(tip, 9)
	end
	local initials = ui.label(emblem, identity.crest == "Monograma" and "A" or "AUR", identity.crest == "Monograma" and 70 or 31, identity.secondary, 68)
	initials.Position = UDim2.new(0, 0, 0.5, -34)
	initials.TextXAlignment = Enum.TextXAlignment.Center
	initials.Font = Enum.Font.GothamBlack
	initials.ZIndex = 3
	local clubName = ui.label(preview, data.club.name, 31, theme.text, 48)
	clubName.Position = UDim2.fromOffset(30, 205)
	clubName.Size = UDim2.new(compact and 1 or 0.56, -60, 0, 48)
	local location = ui.label(preview, data.club.city .. "  •  " .. tostring(data.club.founded or 2027), 13, theme.muted, 32)
	location.Position = UDim2.fromOffset(30, 257)
	location.Size = UDim2.new(compact and 1 or 0.56, -60, 0, 32)
	local kitLabel = ui.label(preview, "UNIFORME TITULAR  /  " .. string.upper(identity.kit), 11, theme.accent, 28)
	kitLabel.Position = UDim2.fromOffset(30, 307)
	kitLabel.Size = UDim2.new(compact and 1 or 0.56, -60, 0, 28)
	local representative = data.players and (data.players[11] or data.players[1]) or data.market[1]
	if representative then
		local avatar = ctx.avatar(preview, representative, { fullBody = true, interactive = true })
		avatar.Position = compact and UDim2.fromOffset(0, 350) or UDim2.new(0.57, 0, 0, 0)
		avatar.Size = compact and UDim2.new(1, 0, 0, 300) or UDim2.new(0.43, 0, 1, 0)
	end

	ui.label(ctx.parent, "01  /  ASSINATURA DO ESCUDO", 12, theme.muted, 30)
	local crestRow = ui.row(ctx.parent, 66)
	for index, crest in ipairs({ "Escudo", "Círculo", "Monograma" }) do
		local button = ui.button(crestRow, crest, function()
			identity.crest = crest
			apply()
		end, { width = UDim2.new(1 / 3, -8, 1, 0), selected = identity.crest == crest })
		button.Position = UDim2.new((index - 1) / 3, 0, 0, 0)
		if compact then
			button.TextSize = 13 * state.settings.textScale
			button:SetAttribute("CL27TextSize", 13)
		end
	end

	ui.label(ctx.parent, "02  /  PALETA PRINCIPAL", 12, theme.muted, 30)
	local palettes = {
		{ name = "Lima", color = Color3.fromRGB(185, 242, 78) },
		{ name = "Safira", color = Color3.fromRGB(91, 169, 255) },
		{ name = "Coral", color = Color3.fromRGB(255, 121, 103) },
		{ name = "Âmbar", color = Color3.fromRGB(246, 197, 89) },
		{ name = "Pérola", color = Color3.fromRGB(226, 233, 227) },
	}
	local primaryRow = ui.row(ctx.parent, 74)
	for index, palette in ipairs(palettes) do
		local button = ui.button(primaryRow, palette.name, function()
			identity.primary = palette.color
			apply()
		end, { width = UDim2.new(1 / #palettes, -8, 1, 0), selected = identity.primary == palette.color })
		button.Position = UDim2.new((index - 1) / #palettes, 0, 0, 0)
		local swatch = ui.new("Frame", {
			Position = UDim2.new(0, 10, 1, -10), Size = UDim2.new(1, -20, 0, 4),
			BackgroundColor3 = palette.color, BorderSizePixel = 0,
		}, button)
		ui.round(swatch, 2)
	end

	ui.label(ctx.parent, "03  /  CONTRASTE DO UNIFORME", 12, theme.muted, 30)
	local secondaryRow = ui.row(ctx.parent, 64)
	local contrasts = {
		{ name = "Petróleo", color = Color3.fromRGB(19, 30, 35) },
		{ name = "Noite", color = Color3.fromRGB(17, 19, 26) },
		{ name = "Gelo", color = Color3.fromRGB(225, 231, 227) },
	}
	for index, contrast in ipairs(contrasts) do
		local button = ui.button(secondaryRow, contrast.name, function()
			identity.secondary = contrast.color
			apply()
		end, { width = UDim2.new(1 / 3, -8, 1, 0), selected = identity.secondary == contrast.color })
		button.Position = UDim2.new((index - 1) / 3, 0, 0, 0)
	end

	ui.label(ctx.parent, "04  /  DESENHO DA CAMISA", 12, theme.muted, 30)
	local kits = ui.row(ctx.parent, 68)
	for index, kit in ipairs({ "Faixa", "Listras", "Liso" }) do
		local button = ui.button(kits, kit, function()
			identity.kit = kit
			apply()
		end, { width = UDim2.new(1 / 3, -8, 1, 0), selected = identity.kit == kit })
		button.Position = UDim2.new((index - 1) / 3, 0, 0, 0)
	end
	local footnote = ui.label(ctx.parent, "As escolhas ficam ativas durante esta sessão e aparecem nos personagens e na identidade dos menus.", 13, theme.muted, 44)
	footnote.TextWrapped = true
	ui.button(ctx.parent, "Restaurar identidade Aurora", function()
		state.identity = {
			primary = Color3.fromRGB(185, 242, 78), secondary = Color3.fromRGB(19, 30, 35),
			crest = "Escudo", kit = "Faixa",
		}
		ctx.toast("Identidade original restaurada.")
		apply()
	end, { height = 46 })
end
