--!strict
-- HUD CRITICO: interface persistente em ScreenGui propria, independente do
-- cenario 3D, do ViewportFrame e do renderizador de paginas do CL 27.
-- Nunca depender do carregamento do avatar ou da iluminacao para exibir o menu.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
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
	local group = element("Frame", parent, {
		Name = "FumacaVerde",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -34, 0, offset - 17),
		Size = UDim2.new(1, 42, 0, 82),
		ClipsDescendants = false,
		ZIndex = 2,
		Visible = false,
	})
	-- Suporte visual opcional: mesmo sem textura, a lista continua visivel.
	for index = 1, 3 do
		element("ImageLabel", group, {
			Name = "Nuvem" .. tostring(index),
			BackgroundTransparency = 1,
			Image = SMOKE,
			ImageColor3 = if index == 2 then Color3.fromRGB(42, 146, 90) else Color3.fromRGB(31, 108, 76),
			ImageTransparency = 0.53 + index * 0.09,
			Position = UDim2.new(0, (index - 1) * 86 - 18, 0, index % 2 * 7 - 1),
			Size = UDim2.new(0, 230, 0, 70),
			Rotation = (index - 2) * 8,
			ZIndex = 2,
		})
	end
	return group
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
	for index, caption in ipairs(ITEMS) do
		local y = 8 + (index - 1) * 77
		local fog = smoke(list, y)
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
		rows[index] = {button = button, fog = fog}
	end

	local function repaint()
		if not alive then return end
		for index, row in ipairs(rows) do
			local active = index == current or index == hovered
			row.button.TextColor3 = if active then WHITE else GRAY
			row.button.TextTransparency = if active then 0 else 0.32
			row.button.Font = if active then Enum.Font.GothamBold else Enum.Font.GothamMedium
			row.button.TextSize = if active then 30 else 26
			row.fog.Visible = active
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
		table.insert(connections, row.button.Activated:Connect(function()
			current = index
			hovered = nil
			state.homeFocus = index
			repaint()
		end))
	end

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
	repaint()

	return {
		gui = gui,
		SetVisible = function(_, visible: boolean)
			if alive then gui.Enabled = visible end
		end,
		Destroy = function()
			if not alive then return end
			alive = false
			for _, connection in ipairs(connections) do connection:Disconnect() end
			gui:Destroy()
		end,
	}
end

return HomeHUD
