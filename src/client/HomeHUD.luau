--!strict
-- HUD CRITICO: interface persistente em ScreenGui propria, independente do
-- cenario 3D, do ViewportFrame e do renderizador de paginas do CL 27.
-- Nunca depender do carregamento do avatar ou da iluminacao para exibir o menu.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HomeShowcase = require(script.Parent.HomeShowcase)
local RadialGlow = require(script.Parent.RadialGlow)

local HomeHUD = {}
local ITEMS = {"Notícias do CL", "Clubs", "Jogo Rápido", "Aprenda a Jogar", "Upgrade"}
local WHITE = Color3.fromRGB(252, 255, 253)
local GRAY = Color3.fromRGB(184, 195, 196)

local function element(className: string, parent: Instance, properties)
	local object = Instance.new(className)
	for key, value in pairs(properties) do
		object[key] = value
	end
	object.Parent = parent
	return object
end

-- Símbolos vetoriais nativos, sem emoji ou imagem externa.
-- A superfície clicável é maior do que o desenho para funcionar no toque.
local function icon(parent: Instance, name: string, kind: string, x: number, y: number)
	local button = element("TextButton", parent, {
		Name = name, Text = "", BackgroundTransparency = 1, BorderSizePixel = 0,
		AutoButtonColor = false, Selectable = true, Active = true,
		Position = UDim2.new(x, 0, y, 0),
		Size = UDim2.fromOffset(46, 52), ZIndex = 8,
	})
	element("UIScale", button, {Name = "EscalaIcone", Scale = 0.88})
	local ink = Color3.fromRGB(221, 231, 227)
	local function strokeSegment(w, h, px, py, angle)
		local part = element("Frame", button, {
			Size = UDim2.fromOffset(w, h),
			Position = UDim2.fromOffset(px, py),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = ink, BackgroundTransparency = 0.18,
			BorderSizePixel = 0, Rotation = angle or 0, ZIndex = 9,
		})
		element("UICorner", part, {CornerRadius = UDim.new(1, 0)})
		return part
	end
	if kind == "gear" then
		-- Ícone próprio de precisão: aro fino, dentes radiais e miolo vazado.
		-- Construção vetorial com UIStroke, sem emojis ou dependência de asset.
		local ring = element("Frame", button, {
			Name = "EngrenagemVetorial", AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(23, 25),
			Size = UDim2.fromOffset(25, 25),
			BackgroundTransparency = 1, ZIndex = 10,
		})
		element("UICorner", ring, {CornerRadius = UDim.new(1, 0)})
		element("UIStroke", ring, {Color = ink, Transparency = 0.06, Thickness = 2.25})
		local center = element("Frame", ring, {
			Name = "FuroCentral", AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(7.5, 7.5),
			BackgroundTransparency = 1, ZIndex = 11,
		})
		element("UICorner", center, {CornerRadius = UDim.new(1, 0)})
		element("UIStroke", center, {Color = ink, Transparency = 0.04, Thickness = 2})
		for i = 0, 11 do
			local angle = i * math.pi / 6
			local tooth = strokeSegment(
				3.1, 6.0,
				23 + math.sin(angle) * 16.2,
				25 - math.cos(angle) * 16.2,
				i * 30
			)
			tooth.Name = "Dente_" .. tostring(i + 1)
		end
	else
		local head = element("Frame", button, {
			Position = UDim2.fromOffset(19, 8), Size = UDim2.fromOffset(8, 8),
			BackgroundColor3 = ink, BackgroundTransparency = 0.1,
			BorderSizePixel = 0, ZIndex = 9,
		})
		element("UICorner", head, {CornerRadius = UDim.new(1, 0)})
		strokeSegment(31, 3.5, 23, 21, 0)
		strokeSegment(4, 18, 23, 29, 0)
		strokeSegment(4, 15, 18, 40, 25)
		strokeSegment(4, 15, 28, 40, -25)
	end
	local gleam = element("Frame", button, {
		Size = UDim2.new(1, -5, 1, -5), Position = UDim2.fromOffset(2, 2),
		BackgroundColor3 = Color3.fromRGB(20, 107, 83),
		BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 7,
	})
	element("UICorner", gleam, {CornerRadius = UDim.new(0, 8)})
	return button, gleam
end

function HomeHUD.start(playerGui: Instance, state)
	local player = Players.LocalPlayer
	local connections: {RBXScriptConnection} = {}
	local alive = true
	local current = math.clamp(state.homeFocus or 3, 1, #ITEMS)
	local hovered: number? = nil
	local navigateSettings: ((number) -> ())? = nil
	local navigatePrimary: ((number, number?) -> ())? = nil
	local function locked(): boolean return state.menuInputLocked == true end

	local gui = element("ScreenGui", playerGui, {
		Name = "CL27_HomeHUD",
		DisplayOrder = 70,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Enabled = true,
	})
	local root = element("Frame", gui, {
		Name = "HomeOverlay",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
	})

	-- Sombreado discreto apenas onde o texto aparece, sem telão na parede.
	local shadow = element("Frame", root, {
		Name = "VignetteEsquerda",
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(0.43, 1),
		BackgroundColor3 = Color3.fromRGB(3, 9, 11),
		BackgroundTransparency = 0.42,
		BorderSizePixel = 0,
		ZIndex = 1,
	})
	local fade = element("UIGradient", shadow, {
		Rotation = 0,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.08),
			NumberSequenceKeypoint.new(0.45, 0.31),
			NumberSequenceKeypoint.new(1, 1),
		}),
	})

	-- Configurações é o único atalho lateral. Acessibilidade segue dentro
	-- do menu de Configurações, sem botão redundante no lobby.
	local settingsButton, settingsGleam = icon(root, "Configuracoes", "gear", 0.018, 0.192)
	for _, entry in ipairs({
		{button = settingsButton, glow = settingsGleam, tab = 1},
	}) do
		table.insert(connections, entry.button.Activated:Connect(function()
			if locked() then return end
			if navigateSettings then navigateSettings(entry.tab) end
		end))
		table.insert(connections, entry.button.MouseEnter:Connect(function()
			TweenService:Create(entry.glow, TweenInfo.new(0.2), {BackgroundTransparency = 0.78}):Play()
		end))
		table.insert(connections, entry.button.MouseLeave:Connect(function()
			TweenService:Create(entry.glow, TweenInfo.new(0.24), {BackgroundTransparency = 1}):Play()
		end))
	end
	element("TextLabel", root, {
		Name = "MarcaCL27",
		Text = "CL 27",
		Font = Enum.Font.GothamBlack,
		TextSize = 34,
		TextColor3 = WHITE,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.048),
		Size = UDim2.fromScale(0.28, 0.079),
		ZIndex = 7,
	})

	-- Sem ScrollingFrame com tamanho dependente de outros GUIs. Tudo fica
	-- explicitamente dentro do viewport e a rolagem fica disponivel se preciso.
	local list = element("ScrollingFrame", root, {
		Name = "MenuPrincipalFC",
		Position = UDim2.fromScale(0.085, 0.19),
		Size = UDim2.fromScale(0.37, 0.66),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 540),
		ClipsDescendants = false,
		Active = true,
		ZIndex = 3,
	})

	local rows = {}
	local tweens: {[Instance]: Tween} = {}
	local reducedMotion = state.settings and state.settings.reducedMotion == true
	-- No celular horizontal, 72 px entre opções escondia Upgrade abaixo
	-- do viewport. Preserve 72 px no desktop e compacte só a distância.
	local camera = workspace.CurrentCamera
	local viewportHeight = if camera then camera.ViewportSize.Y else 900
	local rowGap = math.clamp(viewportHeight * 0.125, 50, 72)

	local function animate(object: Instance, goals, duration: number, easing, direction)
		local previous = tweens[object]
		if previous then
			tweens[object] = nil
			previous:Cancel()
		end
		if reducedMotion or duration <= 0 then
			for property, value in pairs(goals) do
				(object :: any)[property] = value
			end
			return nil
		end
		local tween = TweenService:Create(
			object,
			TweenInfo.new(duration, easing or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out),
			goals
		)
		tweens[object] = tween
		tween.Completed:Once(function()
			if tweens[object] == tween then tweens[object] = nil end
		end)
		tween:Play()
		return tween
	end

	local showcase = HomeShowcase.new(root, function(index, lesson)
		if locked() then return end
		if navigatePrimary then navigatePrimary(index, lesson) end
	end, reducedMotion)
	local function glowWidth(index: number): number
		return math.clamp(110 + #ITEMS[index] * 12, 190, 318)
	end
	local selectionGlow, selectionPulse, glowCore = RadialGlow.new(
		list, 8 + (current - 1) * rowGap, glowWidth(current)
	)
	selectionGlow.GroupTransparency = 1
	for index, caption in ipairs(ITEMS) do
		local y = 8 + (index - 1) * rowGap + (if current == 4 and index > 4 then 144 else 0)
		local button = element("TextButton", list, {
			Name = "Opcao_" .. tostring(index),
			Text = caption,
			Font = Enum.Font.GothamMedium,
			TextSize = 23,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = GRAY,
			TextTransparency = 0.32,
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Selectable = true,
			Position = UDim2.new(0, 6, 0, y),
			Size = UDim2.new(1, -15, 0, 53),
			ZIndex = 6,
		})
		-- Pressão curta, seguida de retorno macio, sem ampliar o botão inteiro.
		local pressScale = element("UIScale", button, {Name = "RespostaToque", Scale = 1})
		rows[index] = {button = button, scale = pressScale, y = y, visual = -1}
	end

	-- Submenu recuado para os quatro destinos de Aprenda a Jogar.
	local lessons = {"Centro de Treinamento", "Rush", "Jogos de Habilidade", "Arena de Treino"}
	local selectedLesson = math.clamp(state.homeLesson or 1, 1, #lessons)
	local learnGroup = element("CanvasGroup", list, {
		Name = "SubmenuAprenda", Position = UDim2.fromOffset(25, 8 + 3 * rowGap + 56),
		Size = UDim2.new(1, -25, 0, 138),
		BackgroundTransparency = 1,
		GroupTransparency = if current == 4 then 0 else 1,
		Visible = current == 4, ZIndex = 7,
	})
	local lessonButtons = {}
	for i, name in ipairs(lessons) do
		local button = element("TextButton", learnGroup, {
			Name = "SubOpcao_" .. tostring(i), Text = name,
			TextColor3 = if i == selectedLesson then WHITE else GRAY,
			TextTransparency = if i == selectedLesson then 0 else 0.3,
			Font = if i == selectedLesson then Enum.Font.GothamBold else Enum.Font.GothamMedium,
			TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(20, (i - 1) * 34),
			Size = UDim2.new(1, -24, 0, 32),
			BackgroundTransparency = 1, AutoButtonColor = false,
			Selectable = true, ZIndex = 8,
		})
		lessonButtons[i] = button
	end
	element("Frame", learnGroup, {
		Name = "LinhaSubmenu", Position = UDim2.fromOffset(5, 3),
		Size = UDim2.fromOffset(2, 126), BackgroundColor3 = Color3.fromRGB(75, 121, 102),
		BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 7,
	})
	local learnAccent = element("Frame", learnGroup, {
		Name = "IndicadorSubmenu", Position = UDim2.fromOffset(3, 5 + (selectedLesson - 1) * 34),
		Size = UDim2.fromOffset(6, 25), BackgroundColor3 = Color3.fromRGB(129, 223, 135),
		BorderSizePixel = 0, ZIndex = 8,
	})
	element("UICorner", learnAccent, {CornerRadius = UDim.new(1, 0)})

	-- Impacto único: ao clicar, a opção branca ganha luz intensa,
	-- depois a aura some totalmente em 0,62 s. Sem glow permanente.
	local function strike(index: number)
		if reducedMotion then return end
		local y = 8 + (index - 1) * rowGap
			+ (if current == 4 and index > 4 then 144 else 0)
		selectionGlow.Position = UDim2.fromOffset(-27, y - 21)
		selectionGlow.Size = UDim2.fromOffset(glowWidth(index), 92)
		local prior = tweens[selectionGlow]
		if prior then prior:Cancel();tweens[selectionGlow] = nil end
		selectionGlow.GroupTransparency = 0
		selectionPulse.GroupTransparency = 0.24
		selectionPulse.Size = UDim2.fromScale(0.43, 0.44)
		selectionPulse.Position = UDim2.fromScale(0.285, 0.28)
		animate(selectionGlow, {GroupTransparency = 1}, 0.62, Enum.EasingStyle.Quad)
		animate(selectionPulse, {
			GroupTransparency = 1,
			Size = UDim2.fromScale(0.82, 0.72),
			Position = UDim2.fromScale(0.09, 0.14),
		}, 0.50, Enum.EasingStyle.Quart)
	end

	local lastExpanded = current ~= 4
	local function repaint(instant: boolean?)
		if not alive then return end
		local expanded = current == 4
		if expanded ~= lastExpanded or instant then
			-- Ao abrir as quatro lições, deslocar a área de rolagem para
			-- manter Aprenda e as subopções visíveis mesmo em tela baixa.
			local bottom = 8 + 3 * rowGap + 56 + 138 + 48
			local scroll = if expanded then math.max(0, bottom - viewportHeight * 0.66) else 0
			list.CanvasPosition = Vector2.new(0, scroll)
			lastExpanded = expanded
		end
		if expanded then learnGroup.Visible = true end
		local submenuTween = animate(learnGroup, {
			GroupTransparency = if expanded then 0 else 1,
			Size = UDim2.new(1, -25, 0, if expanded then 138 else 0),
		}, if instant then 0 else 0.26, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		if not expanded then
			if not submenuTween then
				learnGroup.Visible = false
			else
				submenuTween.Completed:Once(function(playback)
					if alive and current ~= 4 and playback == Enum.PlaybackState.Completed then
						learnGroup.Visible = false
					end
				end)
			end
		end
		list.CanvasSize = UDim2.new(0, 0, 0, if expanded then 540 else 420)
		-- O branco indica seleção; o halo verde só é ativado pelo clique.
		local focused = hovered or current
		for index, row in ipairs(rows) do
			local mode = if index == focused then (if index == current then 2 else 1) else 0
			local nextY = 8 + (index - 1) * rowGap + (if expanded and index > 4 then 144 else 0)
			local moved = nextY ~= row.y
			row.y = nextY
			if instant or row.visual ~= mode or moved then
				row.visual = mode
				local active = mode > 0
				row.button.Font = if active then Enum.Font.GothamBold else Enum.Font.GothamMedium
				animate(row.button, {
					TextColor3 = if active then WHITE else GRAY,
					TextTransparency = if active then 0 else 0.32,
					TextSize = if mode == 2 then 27 elseif mode == 1 then 26 else 23,
					Position = UDim2.new(0, if active then 14 else 6, 0, row.y),
				}, if instant then 0 else 0.28, Enum.EasingStyle.Quart)
			end
		end
		local focused = hovered or current
		showcase:Show(focused, instant, if focused == 4 then selectedLesson else nil)
	end
	for i, button in ipairs(lessonButtons) do
		table.insert(connections, button.Activated:Connect(function()
			if locked() or current ~= 4 then return end
			selectedLesson = i
			state.homeLesson = i
			for n, entry in ipairs(lessonButtons) do
				entry.Font = if n == i then Enum.Font.GothamBold else Enum.Font.GothamMedium
				animate(entry, {
					TextColor3 = if n == i then WHITE else GRAY,
					TextTransparency = if n == i then 0 else 0.3,
				}, 0.19)
			end
			animate(learnAccent, {Position = UDim2.fromOffset(3, 5 + (i - 1) * 34)}, 0.22)
			showcase:Show(4, false, selectedLesson)
			strike(4)
		end))
	end

	local function pulse(row)
		if reducedMotion then return end
		local press = animate(row.scale, {Scale = 0.965}, 0.095, Enum.EasingStyle.Quad)
		if press then
			press.Completed:Once(function(state)
				if alive and state == Enum.PlaybackState.Completed then
					animate(row.scale, {Scale = 1}, 0.29, Enum.EasingStyle.Back)
				end
			end)
		end
	end

	for index, row in ipairs(rows) do
		table.insert(connections, row.button.MouseEnter:Connect(function()
			if locked() then return end
			hovered = index
			repaint()
		end))
		table.insert(connections, row.button.MouseLeave:Connect(function()
			if locked() then return end
			if hovered == index then hovered = nil end
			repaint()
		end))
		table.insert(connections, row.button.SelectionGained:Connect(function()
			if locked() then return end
			hovered = index
			repaint()
		end))
		table.insert(connections, row.button.SelectionLost:Connect(function()
			if locked() then return end
			if hovered == index then hovered = nil end
			repaint()
		end))
		table.insert(connections, row.button.InputBegan:Connect(function(input)
			if locked() then return end
			if input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1 then
				hovered = index
				repaint()
			end
		end))
		table.insert(connections, row.button.InputEnded:Connect(function(input)
			if locked() then return end
			if (input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1) and hovered == index then
				hovered = nil
				repaint()
			end
		end))
		table.insert(connections, row.button.Activated:Connect(function()
			if locked() then return end
			current = index
			hovered = nil
			state.homeFocus = index
			repaint()
			pulse(row)
			strike(index)
			-- O botão principal abre as rotas existentes, sem inventar sistemas.
		end))
	end

	-- Um único loop a 30 Hz: respiração leve de UMA camada central.
	-- Nada de partículas em movimento ou dezenas de tweens por opção.
	local elapsed, accumulator = 0, 0
	table.insert(connections, RunService.Heartbeat:Connect(function(dt)
		if not alive or not gui.Enabled or reducedMotion then return end
		accumulator += math.min(dt, 0.1)
		if accumulator < (1 / 30) then return end
		elapsed += accumulator
		accumulator = 0
		showcase:Step(elapsed)
		glowCore.BackgroundTransparency = 0.922 + math.sin(elapsed * 1.15) * 0.012
	end))

	local username = element("TextLabel", root, {
		Name = "NomeRealJogador",
		Text = player.Name,
		TextColor3 = WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 21,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.66, 0.048),
		Size = UDim2.fromScale(0.31, 0.046),
		ZIndex = 7,
	})
	repaint(true)

	return {
		gui = gui,
		SetNavigation = function(_, callback: (number) -> ())
			navigateSettings = callback
		end,
		SetPrimaryNavigation = function(_, callback: (number, number?) -> ())
			navigatePrimary = callback
		end,
		SetVisible = function(_, visible: boolean)
			if alive then
				gui.Enabled = visible
				reducedMotion = state.settings and state.settings.reducedMotion == true
				showcase:SetReducedMotion(reducedMotion)
				if reducedMotion then selectionGlow.GroupTransparency = 1 end
				if visible then
					hovered = nil
					repaint(true)
				end
			end
		end,
		Destroy = function()
			if not alive then return end
			alive = false
			for _, connection in ipairs(connections) do connection:Disconnect() end
			for _, tween in pairs(tweens) do tween:Cancel() end
			table.clear(tweens)
			showcase:Destroy()
			gui:Destroy()
		end,
	}
end

return HomeHUD
