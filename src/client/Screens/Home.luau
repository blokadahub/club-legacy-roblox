--!strict
-- Menu inicial, inspirado na estrutura da referência: cinco entradas, sem rotas
-- enquanto as páginas correspondentes não existirem. Os outros módulos do CL27
-- não são afetados.
local Players = game:GetService("Players")
local UI = require(script.Parent.Parent.UI)
local Theme = require(game:GetService("ReplicatedStorage").CL27.Theme)

local ITEMS = {"CL News", "Modo Manager", "Kick Off", "Clubes", "Sessões"}
local SMOKE_IMAGE = "rbxasset://textures/particles/smoke_main.dds"
local ACTIVE = Color3.fromRGB(251, 255, 253)
local INACTIVE = Color3.fromRGB(191, 198, 199)
local SMOKE_GREEN = Color3.fromRGB(37, 160, 104)

local function getLevel(player: Player): string
	-- Roblox não oferece um nível universal de perfil. Só exibe um valor
	-- realmente fornecido por um sistema de progresso do próprio jogo.
	for _, name in ipairs({"Level", "Nivel", "Nível"}) do
		local value = player:GetAttribute(name)
		if typeof(value) == "number" and value >= 0 then
			return tostring(math.floor(value))
		end
	end
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		for _, name in ipairs({"Level", "Nivel", "Nível"}) do
			local value = stats:FindFirstChild(name)
			if value and (value:IsA("IntValue") or value:IsA("NumberValue")) then
				return tostring(math.max(0, math.floor(value.Value)))
			end
		end
	end
	return "—"
end

-- As imagens de fumaça são o recurso nativo do Roblox, e não um retângulo neon.
-- Pequenas sobreposições de diferentes tamanhos simulam uma névoa irregular.
local function smoke(parent: Instance, y: number)
	local group = UI.new("CanvasGroup", {
		Name = "FumacaVerde",
		Position = UDim2.fromOffset(-26, y - 12),
		Size = UDim2.fromOffset(450, 78),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		ZIndex = 2,
	}, parent)
	local aura = UI.new("Frame", {
		Position = UDim2.fromOffset(30, 20),
		Size = UDim2.fromOffset(310, 39),
		BackgroundColor3 = SMOKE_GREEN,
		BackgroundTransparency = 0.93,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, group)
	UI.new("UICorner", {CornerRadius = UDim.new(1, 0)}, aura)
	local auraGradient = UI.gradient(aura, {
		Color3.fromRGB(8, 88, 67), SMOKE_GREEN, Color3.fromRGB(4, 66, 50),
	}, 0)
	auraGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.28, 0.12),
		NumberSequenceKeypoint.new(0.64, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	for i = 1, 5 do
		local p = i - 1
		UI.new("ImageLabel", {
			Name = "Vapor" .. tostring(i),
			Image = SMOKE_IMAGE,
			ImageColor3 = if i % 2 == 0 then Color3.fromRGB(63, 170, 123) else Color3.fromRGB(25, 113, 84),
			ImageTransparency = 0.51 + i * 0.065,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(2 + p * 44, (p % 3) * 7 - 6),
			Size = UDim2.fromOffset(155 + (i % 2) * 85, 84 - (i % 2) * 11),
			Rotation = (i - 3) * 9,
			ZIndex = 3,
		}, group)
	end
	return group
end

local function icon(parent: Instance, name: string, character: string, x: number, y: number)
	-- Somente representação visual. Nenhuma rota ou menu é aberto por esses ícones.
	return UI.new("TextButton", {
		Name = name,
		Text = character,
		Font = Enum.Font.GothamMedium,
		TextSize = 27,
		TextColor3 = Color3.fromRGB(212, 221, 221),
		TextTransparency = 0.18,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Selectable = false,
		Active = false,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(42, 42),
		ZIndex = 7,
	}, parent)
end

return function(root, ctx)
	local player = Players.LocalPlayer
	local scope = ctx.scope
	local selected = math.clamp(ctx.state.homeFocus or 3, 1, #ITEMS)
	local hovered: number? = nil

	-- Degradê escurece somente o lado do menu, sem criar um segundo telão.
	local shade = UI.frame(root, 0, 0, 735, 900, Color3.fromRGB(4, 9, 13), 0.14)
	shade.Name = "VignetteMenuEsquerdo"
	shade.ZIndex = 1
	local gradient = UI.gradient(shade, {
		Color3.fromRGB(4, 9, 13),
		Color3.fromRGB(4, 10, 13),
		Color3.fromRGB(4, 9, 13),
	}, 0)
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.47, 0.16),
		NumberSequenceKeypoint.new(0.76, 0.68),
		NumberSequenceKeypoint.new(1, 1),
	})

	icon(root, "Configuracoes", "⚙", 53, 38)
	icon(root, "Acessibilidade", "♿", 53, 87)
	UI.logo(root, 131, 42, 0.9)

	local list = UI.new("ScrollingFrame", {
		Name = "MenuPrincipalFC",
		Position = UDim2.fromOffset(117, 177),
		Size = UDim2.fromOffset(495, 435),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 435),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 0,
		ClipsDescendants = true,
		Active = true,
		ZIndex = 3,
	}, root)

	local rows = {}
	for index, labelText in ipairs(ITEMS) do
		local y = (index - 1) * 80 + 3
		local fog = smoke(list, y)
		local label = UI.text(list, labelText, 17, y, 407, 57,
			if selected == index then 27 else 22,
			if selected == index then ACTIVE else INACTIVE,
			if selected == index then Enum.Font.GothamBold else Enum.Font.GothamMedium)
		label.Name = "Texto_" .. tostring(index)
		label.TextTransparency = if selected == index then 0 else 0.36
		label.ZIndex = 6

		local button = UI.new("TextButton", {
			Name = "Opcao_" .. tostring(index),
			Text = "",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Position = UDim2.fromOffset(0, y),
			Size = UDim2.fromOffset(450, 58),
			Selectable = true,
			ZIndex = 7,
		}, list)
		fog.GroupTransparency = if index == selected then 0.22 else 1
		table.insert(rows, {fog = fog, label = label, button = button})

		local function paint(instant: boolean?)
			for j, item in ipairs(rows) do
				local active = j == selected or j == hovered
				local goals = {
					TextColor3 = if active then ACTIVE else INACTIVE,
					TextTransparency = if active then 0 else 0.36,
					TextSize = if active then 27 else 22,
				}
				item.label.Font = if active then Enum.Font.GothamBold else Enum.Font.GothamMedium
				if instant then
					for k, v in pairs(goals) do item.label[k] = v end
					item.fog.GroupTransparency = if active then 0.22 else 1
				else
					scope:Tween(item.label, goals, 0.2)
					scope:Tween(item.fog, {GroupTransparency = if active then 0.22 else 1}, 0.32)
				end
			end
		end

		scope:Connect(button.MouseEnter, function()
			hovered = index
			paint(false)
		end)
		scope:Connect(button.MouseLeave, function()
			if hovered == index then hovered = nil end
			paint(false)
		end)
		scope:Connect(button.SelectionGained, function()
			hovered = index
			paint(false)
		end)
		scope:Connect(button.SelectionLost, function()
			if hovered == index then hovered = nil end
			paint(false)
		end)
		scope:Connect(button.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				hovered = index
				paint(false)
			end
		end)
		scope:Connect(button.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.Touch and hovered == index then
				hovered = nil
				paint(false)
			end
		end)
		scope:Connect(button.Activated, function()
			-- Por enquanto só altera a seleção; nenhuma seção é aberta.
			selected = index
			ctx.state.homeFocus = index
			hovered = nil
			paint(false)
		end)
	end

	-- Dados verdadeiros da conta; não usa os exemplos fictícios da referência.
	local name = UI.text(root, player.Name, 1078, 36, 460, 35, 21, ACTIVE, Enum.Font.GothamBold)
	name.Name = "NomeRealJogador"
	name.TextXAlignment = Enum.TextXAlignment.Right
	name.ZIndex = 8
	local level = UI.text(root, "Nível " .. getLevel(player), 1138, 71, 400, 25, 15, Color3.fromRGB(201, 213, 216))
	level.Name = "NivelRealJogador"
	level.TextXAlignment = Enum.TextXAlignment.Right
	level.ZIndex = 8

	-- Se um sistema de nível for inicializado enquanto o menu já estiver aberto,
	-- seus dados podem atualizar sem precisar recriar a página.
	local function updateLevel()
		if level.Parent then level.Text = "Nível " .. getLevel(player) end
	end
	for _, key in ipairs({"Level", "Nivel", "Nível"}) do
		local ok, signal = pcall(function() return player:GetAttributeChangedSignal(key) end)
		if ok and signal then scope:Connect(signal, updateLevel) end
	end
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		scope:Connect(stats.ChildAdded, updateLevel)
		for _, stat in ipairs(stats:GetChildren()) do
			if stat:IsA("IntValue") or stat:IsA("NumberValue") then
				scope:Connect(stat:GetPropertyChangedSignal("Value"), updateLevel)
			end
		end
	end

	-- Um eventual sistema de nível adicionado depois ainda é detectado.
	scope:Connect(player.ChildAdded, function(child)
		if child.Name ~= "leaderstats" then return end
		updateLevel()
		scope:Connect(child.ChildAdded, function(stat)
			updateLevel()
			if stat:IsA("IntValue") or stat:IsA("NumberValue") then
				scope:Connect(stat:GetPropertyChangedSignal("Value"), updateLevel)
			end
		end)
	end)
end
