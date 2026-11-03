--!strict
-- HUD CRITICO: interface persistente em ScreenGui propria, independente do
-- cenario 3D, do ViewportFrame e do renderizador de paginas do CL 27.
-- Nunca depender do carregamento do avatar ou da iluminacao para exibir o menu.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HomeShowcase = require(script.Parent.HomeShowcase)

local HomeHUD = {}
local ITEMS = {"Notícias do CL", "Clubs", "Jogo Rápido", "Aprenda a Jogar", "Upgrade"}
local WHITE = Color3.fromRGB(252, 255, 253)
local GRAY = Color3.fromRGB(184, 195, 196)
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local function element(className: string, parent: Instance, properties)
	local object = Instance.new(className)
	for key, value in pairs(properties) do
		object[key] = value
	end
	object.Parent = parent
	return object
end

local function levelOf(player: Player): string
	for _, key in ipairs({"Level", "Nivel", "Nível"}) do
		local value = player:GetAttribute(key)
		if typeof(value) == "number" and value >= 0 then
			return tostring(math.floor(value))
		end
	end
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		for _, key in ipairs({"Level", "Nivel", "Nível"}) do
			local stat = stats:FindFirstChild(key)
			if stat and (stat:IsA("IntValue") or stat:IsA("NumberValue")) then
				return tostring(math.max(0, math.floor(stat.Value)))
			end
		end
	end
	return "—"
end

local function smoke(parent: Instance, offset: number)
	-- Névoa VIVA: quatro camadas com velocidades/fases distintas, bordas
	-- dissolvidas e respiração luminosa. Sem retângulo verde ou peça de cenário.
	local group = element("CanvasGroup", parent, {
		Name = "FumacaVerde",
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		-- Névoa compacta que termina suavemente abaixo do texto.
		Position = UDim2.new(0, -24, 0, offset - 21),
		Size = UDim2.fromOffset(296, 108),
		ClipsDescendants = false,
		ZIndex = 2,
		Visible = true,
	})
	local clouds = {}
	for index = 1, 4 do
		local x = (index - 1) * 48 - 20
		local y = if index % 2 == 0 then 12 else 3
		local image = element("ImageLabel", group, {
			Name = "Nuvem" .. tostring(index),
			BackgroundTransparency = 1,
			Image = SMOKE,
			ImageColor3 = if index % 2 == 0
				then Color3.fromRGB(57, 206, 119)
				else Color3.fromRGB(34, 161, 93),
			ImageTransparency = 0.32 + index * 0.042,
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(142 + (index % 2) * 30, 78 + (index % 3) * 9),
			Rotation = (index - 2.5) * 9,
			ZIndex = 2,
		})
		element("UIGradient", image, {
			-- Dissolução vertical: sem linha reta no limite inferior.
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.18, 0.4),
				NumberSequenceKeypoint.new(0.53, 0.01),
				NumberSequenceKeypoint.new(0.83, 0.49),
				NumberSequenceKeypoint.new(1, 1),
			}),
		})
		clouds[index] = {
			image = image, x = x, y = y, phase = index * 1.73,
			rotation = (index - 2.5) * 9,
			opacity = 0.32 + index * 0.042,
		}
	end
	-- Uma onda verde responde à seleção sem alterar a névoa permanente.
	local impulse = element("ImageLabel", group, {
		Name = "PulsoSelecao",
		Image = SMOKE, ImageColor3 = Color3.fromRGB(95, 240, 138),
		ImageTransparency = 1, BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 4),
		Size = UDim2.fromOffset(234, 86),
		ZIndex = 4,
	})
	element("UIGradient", impulse, {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 0.26),
			NumberSequenceKeypoint.new(0.62, 0.07),
			NumberSequenceKeypoint.new(1, 1),
		}),
	})
	return group, clouds, impulse
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
		for i = 0, 7 do
			local angle = i * math.pi / 4
			strokeSegment(4.5, 9, 23 + math.sin(angle) * 14, 25 - math.cos(angle) * 14, i * 45)
		end
		local ring = element("Frame", button, {
			Position = UDim2.fromOffset(12, 14), Size = UDim2.fromOffset(22, 22),
			BackgroundTransparency = 1, ZIndex = 9,
		})
		element("UICorner", ring, {CornerRadius = UDim.new(1, 0)})
		element("UIStroke", ring, {Color = ink, Transparency = 0.11, Thickness = 4})
		local hole = element("Frame", button, {
			Position = UDim2.fromOffset(19, 21), Size = UDim2.fromOffset(8, 8),
			BackgroundColor3 = Color3.fromRGB(14, 30, 30),
			BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 10,
		})
		element("UICorner", hole, {CornerRadius = UDim.new(1, 0)})
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

	-- Alinhados horizontalmente com CL News; sempre acessíveis por toque.
	local settingsButton, settingsGleam = icon(root, "Configuracoes", "gear", 0.018, 0.192)
	local accessibilityButton, accessibilityGleam = icon(root, "Acessibilidade", "access", 0.018, 0.286)
	for _, entry in ipairs({
		{button = settingsButton, glow = settingsGleam, tab = 1},
		{button = accessibilityButton, glow = accessibilityGleam, tab = 2},
	}) do
		table.insert(connections, entry.button.Activated:Connect(function()
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
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.103, 0.048),
		Size = UDim2.fromScale(0.24, 0.079),
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
		if navigatePrimary then navigatePrimary(index, lesson) end
	end, reducedMotion)
	for index, caption in ipairs(ITEMS) do
		local y = 8 + (index - 1) * 72 + (if current == 4 and index > 4 then 144 else 0)
		local fog, clouds, impulse = smoke(list, y)
		fog.Name = "FumacaVerde_" .. tostring(index)
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
		rows[index] = {button = button, fog = fog, clouds = clouds, impulse = impulse, scale = pressScale, y = y, visual = -1}
	end

	-- Submenu recuado para os quatro destinos de Aprenda a Jogar.
	local lessons = {"Centro de Treinamento", "Rush", "Jogos de Habilidade", "Arena de Treino"}
	local selectedLesson = math.clamp(state.homeLesson or 1, 1, #lessons)
	local learnGroup = element("CanvasGroup", list, {
		Name = "SubmenuAprenda", Position = UDim2.fromOffset(25, 8 + 3 * 72 + 56),
		Size = UDim2.fromOffset(350, 138),
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
			Size = UDim2.fromOffset(316, 32),
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

	-- A névoa recebe um impulso de luz rápido e desce à intensidade habitual.
	-- Não é um retângulo neon nem uma escala elástica.
	local function strike(row)
		if reducedMotion then return end
		row.impulse.ImageTransparency = 0.15
		row.impulse.Size = UDim2.fromOffset(226, 82)
		row.impulse.Position = UDim2.fromOffset(20, 7)
		animate(row.impulse, {
			ImageTransparency = 1,
			Size = UDim2.fromOffset(256, 102),
			Position = UDim2.fromOffset(6, -3),
		}, 0.58, Enum.EasingStyle.Quart)
	end

	local function repaint(instant: boolean?)
		if not alive then return end
		local expanded = current == 4
		learnGroup.Visible = expanded
		animate(learnGroup, {
			GroupTransparency = if expanded then 0 else 1,
		}, if instant then 0 else 0.26, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		list.CanvasSize = UDim2.new(0, 0, 0, if expanded then 540 else 420)
		for index, row in ipairs(rows) do
			local focused = hovered or current
			local mode = if index == focused then (if index == current then 2 else 1) else 0
			local nextY = 8 + (index - 1) * 72 + (if expanded and index > 4 then 144 else 0)
			local moved = nextY ~= row.y
			row.y = nextY
			if moved then
				animate(row.fog, {
					Position = UDim2.new(0, -24, 0, nextY - 21),
				}, if instant then 0 else 0.27, Enum.EasingStyle.Quart)
			end
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
				animate(row.fog, {
					GroupTransparency = if mode == 2 then 0.035 elseif mode == 1 then 0.07 else 1,
				}, if instant then 0 else 0.42, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				if active and not instant then strike(row) end
			end
		end
		local focused = hovered or current
		showcase:Show(focused, instant, if focused == 4 then selectedLesson else nil)
	end
	for i, button in ipairs(lessonButtons) do
		table.insert(connections, button.Activated:Connect(function()
			if current ~= 4 then return end
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
			hovered = index
			repaint()
		end))
		table.insert(connections, row.button.MouseLeave:Connect(function()
			if hovered == index then hovered = nil end
			repaint()
		end))
		table.insert(connections, row.button.SelectionGained:Connect(function()
			hovered = index
			repaint()
		end))
		table.insert(connections, row.button.SelectionLost:Connect(function()
			if hovered == index then hovered = nil end
			repaint()
		end))
		table.insert(connections, row.button.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1 then
				hovered = index
				repaint()
			end
		end))
		table.insert(connections, row.button.InputEnded:Connect(function(input)
			if (input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1) and hovered == index then
				hovered = nil
				repaint()
			end
		end))
		table.insert(connections, row.button.Activated:Connect(function()
			current = index
			hovered = nil
			state.homeFocus = index
			repaint()
			pulse(row)
			strike(row)
			-- O botão principal abre as rotas existentes, sem inventar sistemas.
		end))
	end

	-- Um único loop leve, limitado a 30 Hz, move APENAS a névoa que está
	-- aparecendo. Em segundo plano não atualiza nada. Preserva o desempenho
	-- do celular e não cria 20 loops/tweens infinitos concorrentes.
	local elapsed, accumulator = 0, 0
	table.insert(connections, RunService.Heartbeat:Connect(function(dt)
		if not alive or not gui.Enabled or reducedMotion then return end
		accumulator += math.min(dt, 0.1)
		if accumulator < (1 / 30) then return end
		elapsed += accumulator
		accumulator = 0
		showcase:Step(elapsed)
		for _, row in ipairs(rows) do
			if row.fog.GroupTransparency < 0.96 then
				for index, cloud in ipairs(row.clouds) do
					local time = elapsed * (0.44 + index * 0.09) + cloud.phase
					local horizontal = math.sin(time) * (5 + index * 1.25)
					local vertical = math.sin(time * 0.68 + cloud.phase) * (4 + index * 1.2)
					cloud.image.Position = UDim2.fromOffset(cloud.x + horizontal, cloud.y + vertical)
					cloud.image.Rotation = cloud.rotation + math.sin(time * 0.72) * 4
					cloud.image.ImageTransparency = math.clamp(
						cloud.opacity + math.sin(time * 1.13) * 0.055, 0, 1
					)
				end
			end
		end
	end))

	element("TextLabel", root, {
		Name = "AjudaInferior", Text = "A   SELECIONAR        B   VOLTAR",
		Font = Enum.Font.GothamMedium, TextSize = 12,
		TextColor3 = Color3.fromRGB(180, 196, 192),
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.087, 0.933),
		Size = UDim2.fromScale(0.35, 0.033), ZIndex = 7,
	})
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
	local level = element("TextLabel", root, {
		Name = "NivelRealJogador",
		Text = "Nível " .. levelOf(player),
		TextColor3 = Color3.fromRGB(202, 215, 216),
		Font = Enum.Font.GothamMedium,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.74, 0.101),
		Size = UDim2.fromScale(0.23, 0.038),
		ZIndex = 7,
	})

	local function syncLevel()
		if alive then level.Text = "Nível " .. levelOf(player) end
	end
	for _, key in ipairs({"Level", "Nivel", "Nível"}) do
		table.insert(connections, player:GetAttributeChangedSignal(key):Connect(syncLevel))
	end
	local function hookStats(stats)
		if not stats then return end
		for _, stat in ipairs(stats:GetChildren()) do
			if stat:IsA("IntValue") or stat:IsA("NumberValue") then
				table.insert(connections, stat:GetPropertyChangedSignal("Value"):Connect(syncLevel))
			end
		end
		table.insert(connections, stats.ChildAdded:Connect(function(stat)
			if stat:IsA("IntValue") or stat:IsA("NumberValue") then
				table.insert(connections, stat:GetPropertyChangedSignal("Value"):Connect(syncLevel))
			end
			syncLevel()
		end))
		syncLevel()
	end
	hookStats(player:FindFirstChild("leaderstats"))
	table.insert(connections, player.ChildAdded:Connect(function(child)
		if child.Name == "leaderstats" then hookStats(child) end
	end))
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
