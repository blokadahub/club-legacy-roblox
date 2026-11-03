--!strict
-- Personalizar / CL 27. Grade visual 4x2 fiel ao conceito da referência.
-- Os cartões não executam ações: somente o foco visual muda.
local UI = require(script.Parent.Parent.UI)
local Icons = require(script.Parent.Parent.SettingsIcons)

local Settings = {}
local OPTIONS = {
	{label = "Configurações", icon = "settings"},
	{label = "Perfil", icon = "profile"},
	{label = "Configurações\nOnline", icon = "online"},
	{label = "Tempo de Jogo", icon = "playtime"},
	{label = "Editar Equipes", icon = "edit"},
	{label = "Escalações", icon = "sheets"},
	{label = "Criar Jogador", icon = "create"},
	{label = "CL 27 SPORTS™\nMusic", icon = "music"},
}
Settings.options = OPTIONS
local DARK = Color3.fromRGB(11, 14, 16)
local WHITE = Color3.fromRGB(248, 249, 250)
local BLACK = Color3.fromRGB(12, 14, 16)
local ICON_MUTED = Color3.fromRGB(83, 88, 91)
local SELECTED = Color3.fromRGB(18, 20, 22)

local function element(kind: string, parent: Instance, props)
	return UI.new(kind, props, parent)
end

function Settings.mount(root: Instance, ctx)
	local scope = ctx.scope
	local state = ctx.state
	local selected = math.clamp(state.settingsCard or 2, 1, #OPTIONS)
	local focus = selected
	-- Um véu leve mantém o ambiente cinematográfico visível.
	element("Frame", root, {
		Name = "EscurecimentoSutil", Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(2, 8, 10),
		BackgroundTransparency = 0.88, BorderSizePixel = 0, ZIndex = 1,
	})

	element("TextLabel", root, {
		Name = "SecaoPersonalizar",
		Text = "PERSONALIZAR",
		Font = Enum.Font.GothamBold, TextSize = 17,
		TextColor3 = Color3.fromRGB(221, 231, 232),
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(293, 192),
		Size = UDim2.fromOffset(450, 30),
		ZIndex = 4,
	})

	local close = element("TextButton", root, {
		Name = "FecharConfiguracoes",
		Text = "VOLTAR",
		Font = Enum.Font.GothamBold, TextSize = 14,
		TextColor3 = Color3.fromRGB(224, 234, 233),
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Position = UDim2.fromOffset(1202, 186),
		Size = UDim2.fromOffset(103, 44),
		Selectable = true, ZIndex = 6,
	})
	scope:Connect(close.Activated, function()
		ctx.go(if state.homeEnvironment == "Training" then "HomeTraining" else "HomeInterior")
	end)

	local grid = element("Frame", root, {
		Name = "GradeConfiguracoes",
		Position = UDim2.fromOffset(291, 260),
		Size = UDim2.fromOffset(1018, 456),
		BackgroundTransparency = 1, ZIndex = 3,
	})
	local CARD_WIDTH, CARD_HEIGHT, GAP = 249, 222, 7
	local cards = {}
	for i, item in ipairs(OPTIONS) do
		local col = (i - 1) % 4
		local row = math.floor((i - 1) / 4)
		local card = element("TextButton", grid, {
			Name = "Cartao_" .. tostring(i),
			Text = "", AutoButtonColor = false,
			BorderSizePixel = 0,
			BackgroundColor3 = if selected == i then WHITE else DARK,
			BackgroundTransparency = if selected == i then 0 else 0.18,
			Position = UDim2.fromOffset(col * (CARD_WIDTH + GAP), row * (CARD_HEIGHT + GAP)),
			Size = UDim2.fromOffset(CARD_WIDTH, CARD_HEIGHT),
			Selectable = true, ZIndex = 4,
		})
		element("UICorner", card, {CornerRadius = UDim.new(0, 8)})
		local title = element("TextLabel", card, {
			Name = "TituloCartao",
			Text = item.label,
			Font = Enum.Font.GothamBold,
			TextSize = if i == 8 then 22 else 25,
			TextColor3 = if selected == i then BLACK else WHITE,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(15, 14),
			Size = UDim2.fromOffset(CARD_WIDTH - 26, 73),
			ZIndex = 5,
		})
		local image, iconParts = Icons.create(card, item.icon, if selected == i then SELECTED else ICON_MUTED)
		image.Position = UDim2.fromOffset(143, 109)
		image.ZIndex = 5
		cards[i] = {card = card, title = title, iconParts = iconParts}

		scope:Connect(card.Activated, function()
			selected = i
			focus = i
			state.settingsCard = i
			for n, entry in ipairs(cards) do
				local active = n == selected
				scope:Tween(entry.card, {
					BackgroundColor3 = if active then WHITE else DARK,
					BackgroundTransparency = if active then 0 else 0.18,
				}, 0.22)
				scope:Tween(entry.title, {
					TextColor3 = if active then BLACK else WHITE,
				}, 0.2)
				Icons.tint(entry.iconParts, if active then SELECTED else ICON_MUTED, scope, 0.2)
			end
		end)

		-- Passar o mouse não cria segundo cartão branco. Apenas realce discreto.
		scope:Connect(card.MouseEnter, function()
			if i ~= selected then
				scope:Tween(card, {BackgroundTransparency = 0.09}, 0.13)
			end
		end)
		scope:Connect(card.MouseLeave, function()
			if i ~= selected then
				scope:Tween(card, {BackgroundTransparency = 0.18}, 0.16)
			end
		end)
		-- Navegação de controle mantém um único selecionado por vez.
		scope:Connect(card.SelectionGained, function()
			focus = i
		end)
	end

	-- Dois indicadores pequenos existentes na linguagem do menu de referência.
	for _, x in ipairs({812, 1066}) do
		local dot = element("Frame", root, {
			Name = "IndicadorDePagina",
			Position = UDim2.fromOffset(x, 729), Size = UDim2.fromOffset(7, 7),
			BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 5,
		})
		element("UICorner", dot, {CornerRadius = UDim.new(1, 0)})
	end

	local left = element("TextLabel", root, {
		Name = "InstrucoesInferiores",
		Text = "SELECIONAR      VOLTAR",
		Font = Enum.Font.GothamMedium,
		TextSize = 13, TextColor3 = Color3.fromRGB(214, 222, 222),
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(293, 818),
		Size = UDim2.fromOffset(370, 30), ZIndex = 5,
	})
	local right = element("TextLabel", root, {
		Name = "StatusDecorativo",
		Text = "CL 27   /   01",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(216, 231, 223),
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(1083, 818),
		Size = UDim2.fromOffset(226, 30), ZIndex = 5,
	})
	return grid
end

return function(root, ctx)
	return Settings.mount(root, ctx)
end
