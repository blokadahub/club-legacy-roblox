--!strict
-- HUD CRITICO: interface persistente em ScreenGui propria, independente do
-- cenario 3D, do ViewportFrame e do renderizador de paginas do CL 27.
-- Nunca depender do carregamento do avatar ou da iluminacao para exibir o menu.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local HomeHUD = {}
local ITEMS = {"CL News", "Modo Manager", "Kick Off", "Clubes", "Sessões"}
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
		Position = UDim2.new(0, -43, 0, offset - 22),
		Size = UDim2.new(1, 95, 0, 97),
		ClipsDescendants = false,
		ZIndex = 2,
		Visible = true,
	})
	local clouds = {}
	for index = 1, 4 do
		local x = (index - 1) * 91 - 42
		local y = if index % 2 == 0 then 8 else -5
		local image = element("ImageLabel", group, {
			Name = "Nuvem" .. tostring(index),
			BackgroundTransparency = 1,
			Image = SMOKE,
			ImageColor3 = if index % 2 == 0
				then Color3.fromRGB(32, 158, 100)
				else Color3.fromRGB(22, 105, 71),
			ImageTransparency = 0.43 + index * 0.045,
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(212 + (index % 2) * 42, 88 + (index % 3) * 13),
			Rotation = (index - 2.5) * 9,
			ZIndex = 2,
		})
		element("UIGradient", image, {
			Rotation = if index % 2 == 0 then 0 else 180,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.18, 0.33),
				NumberSequenceKeypoint.new(0.53, 0.04),
				NumberSequenceKeypoint.new(0.83, 0.42),
				NumberSequenceKeypoint.new(1, 1),
			}),
		})
		clouds[index] = {
			image = image, x = x, y = y, phase = index * 1.73,
			rotation = (index - 2.5) * 9,
			opacity = 0.43 + index * 0.045,
		}
	end
	return group, clouds
end

local function icon(parent: Instance, name: string, text: string, x: number, y: number)
	return element("TextButton", parent, {
		Name = name,
		Text = text,
		Font = Enum.Font.GothamMedium,
		TextSize = 27,
		TextColor3 = WHITE,
		TextTransparency = 0.28,
		TextXAlignment = Enum.TextXAlignment.Center,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Selectable = false,
		Position = UDim2.new(x, 0, y, 0),
		Size = UDim2.new(0, 44, 0, 44),
		ZIndex = 8,
	})
end

function HomeHUD.start(playerGui: Instance, state)
	local player = Players.LocalPlayer
	local connections: {RBXScriptConnection} = {}
	local alive = true
	local current = math.clamp(state.homeFocus or 3, 1, #ITEMS)
	local hovered: number? = nil

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

	-- Icones continuam decorativos, como solicitado.
	icon(root, "Configuracoes", "⚙", 0.034, 0.046)
	icon(root, "Acessibilidade", "♿", 0.034, 0.112)
	element("TextLabel", root, {
		Name = "MarcaCL27",
		Text = "CL 27",
		Font = Enum.Font.GothamBlack,
		TextSize = 37,
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
		CanvasSize = UDim2.new(0, 0, 0, 405),
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

	for index, caption in ipairs(ITEMS) do
		local y = 8 + (index - 1) * 77
		local fog, clouds = smoke(list, y)
		fog.Name = "FumacaVerde_" .. tostring(index)
		local button = element("TextButton", list, {
			Name = "Opcao_" .. tostring(index),
			Text = caption,
			Font = Enum.Font.GothamMedium,
			TextSize = 26,
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
		rows[index] = {button = button, fog = fog, clouds = clouds, scale = pressScale, y = y, visual = -1}
	end

	local function repaint(instant: boolean?)
		if not alive then return end
		for index, row in ipairs(rows) do
			local mode = if index == current then 2 elseif index == hovered then 1 else 0
			if instant or row.visual ~= mode then
				row.visual = mode
				local active = mode > 0
				-- Prioriza leitura, não transforma cada item em uma caixa.
				row.button.Font = if active then Enum.Font.GothamBold else Enum.Font.GothamMedium
				animate(row.button, {
					TextColor3 = if active then WHITE else GRAY,
					TextTransparency = if active then 0 else 0.32,
					TextSize = if mode == 2 then 30 elseif mode == 1 then 29 else 26,
					Position = UDim2.new(0, if active then 14 else 6, 0, row.y),
				}, if instant then 0 else 0.3, Enum.EasingStyle.Quart)
				-- Dissolve a névoa ao mudar a seleção; sem trocar Visible
				-- instantaneamente. O brilho selecionado é um pouco mais presente.
				animate(row.fog, {
					GroupTransparency = if mode == 2 then 0.18 elseif mode == 1 then 0.36 else 1,
				}, if instant then 0 else 0.44, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			end
		end
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
			-- Nenhuma seção é aberta. Só altera o foco da apresentação.
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
		for _, row in ipairs(rows) do
			if row.fog.GroupTransparency < 0.96 then
				for index, cloud in ipairs(row.clouds) do
					local time = elapsed * (0.44 + index * 0.09) + cloud.phase
					local horizontal = math.sin(time) * (9 + index * 2)
					local vertical = math.sin(time * 0.68 + cloud.phase) * (3 + index)
					cloud.image.Position = UDim2.fromOffset(cloud.x + horizontal, cloud.y + vertical)
					cloud.image.Rotation = cloud.rotation + math.sin(time * 0.72) * 4
					cloud.image.ImageTransparency = math.clamp(
						cloud.opacity + math.sin(time * 1.13) * 0.055, 0, 1
					)
				end
			end
		end
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
		SetVisible = function(_, visible: boolean)
			if alive then
				gui.Enabled = visible
				if visible then repaint(true) end
			end
		end,
		Destroy = function()
			if not alive then return end
			alive = false
			for _, connection in ipairs(connections) do connection:Disconnect() end
			for _, tween in pairs(tweens) do tween:Cancel() end
			table.clear(tweens)
			gui:Destroy()
		end,
	}
end

return HomeHUD
