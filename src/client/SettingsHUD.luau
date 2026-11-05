--!strict
-- HUD separado do Canvas de transição. O menu de Configurações continua
-- acessível mesmo que o cenário 3D ou a animação de troca falhe.
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local UI = require(script.Parent.UI)
local Scope = require(script.Parent.Scope)
local SettingsScreen = require(script.Parent.Screens.Settings)

local SettingsHUD = {}

local function fallback(root: Instance, scope, navigate, playClick)
	-- Segurança: se uma propriedade de UI falhar no dispositivo, ainda haverá
	-- um menu visual utilizável e um botão para retornar ao lobby.
	local grid = UI.new("Frame", {
		Name = "GradeConfiguracoes", BackgroundTransparency = 1,
		Position = UDim2.fromOffset(243, 232),
		Size = UDim2.fromOffset(1115, 493),
	}, root)
	local titles = {
		"Configurações", "Perfil", "Configurações Online", "Tempo de Jogo",
		"Editar Equipes", "Escalações", "Criar Jogador", "CL 27 SPORTS™ Music",
	}
	local active = 2
	local cards = {}
	local function update()
		for index, card in ipairs(cards) do
			card.BackgroundColor3 = if index == active then Color3.fromRGB(248, 249, 250) else Color3.fromRGB(14, 17, 19)
			card.TextColor3 = if index == active then Color3.fromRGB(10, 12, 14) else Color3.fromRGB(245, 248, 249)
		end
	end
	for index, title in ipairs(titles) do
		local col, row = (index - 1) % 4, math.floor((index - 1) / 4)
		local card = UI.new("TextButton", {
			Name = "Cartao_" .. tostring(index), Text = title,
			TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Font = Enum.Font.GothamBold, TextSize = 26,
			BackgroundColor3 = Color3.fromRGB(14, 17, 19),
			BorderSizePixel = 0, AutoButtonColor = false,
			Position = UDim2.fromOffset(col * 281, row * 251),
			Size = UDim2.fromOffset(272, 242),
		}, grid)
		UI.new("UICorner", {CornerRadius = UDim.new(0, 8)}, card)
		table.insert(cards, card)
		scope:Connect(card.Activated, function(input)
			playClick(input)
			active = index
			update()
		end)
	end
	update()
	local back = UI.new("TextButton", {
		Name = "FecharConfiguracoes", Text = "VOLTAR",
		Position = UDim2.fromOffset(1228, 165),
		Size = UDim2.fromOffset(130, 48),
		Font = Enum.Font.GothamBold, TextSize = 19,
		TextColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
	}, root)
	scope:Connect(back.Activated, function(input)
		playClick(input)
		navigate("HomeInterior")
	end)
end

function SettingsHUD.start(playerGui: Instance, state)
	local alive = true
	local scope = Scope.new()
	local navigate = function(_route: string) end

	-- Audio local exclusivo da tela de Configuracoes. A intro e o lobby
	-- conservam seus efeitos e controladores independentes.
	local clickFolder = UI.new("Folder", {Name = "CL27_SettingsClickAudio"}, SoundService)
	scope:Add(clickFolder)
	local clickVoices = {}
	for i = 1, 6 do
		clickVoices[i] = UI.new("Sound", {
			Name = "CyberClick_" .. tostring(i),
			SoundId = "rbxassetid://135026594552200",
			Volume = 0.75,
			Looped = false,
			PlayOnRemove = false,
		}, clickFolder)
	end
	-- Pre-carregar sem bloquear a abertura do menu.
	task.defer(function()
		local ok, err = pcall(function()
			ContentProvider:PreloadAsync(clickVoices)
		end)
		if alive and not ok then
			warn("[CL27 Configuracoes] Falha ao carregar Cyber Click: " .. tostring(err))
		end
	end)
	local nextVoice = 0
	local function playClick(input: InputObject?)
		if not alive then return end
		-- Apenas clique/toque: foco, mouse hover, teclado e gamepad ficam silenciosos.
		if input and input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local chosen = nil
		for offset = 1, #clickVoices do
			local index = (nextVoice + offset - 1) % #clickVoices + 1
			if not clickVoices[index].Playing then chosen = index; break end
		end
		-- Um novo clique nao interrompe os anteriores enquanto houver voz livre.
		if not chosen then chosen = nextVoice % #clickVoices + 1 end
		nextVoice = chosen
		local sound = clickVoices[chosen]
		local ok, err = pcall(function()
			if sound.Playing then sound:Stop() end
			sound.TimePosition = 0
			sound:Play()
		end)
		if not ok then
			warn("[CL27 Configuracoes] Falha ao tocar Cyber Click: " .. tostring(err))
		end
	end

	local screen = UI.new("ScreenGui", {
		Name = "CL27_SettingsHUD", DisplayOrder = 85,
		IgnoreGuiInset = true, ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false,
	}, playerGui)

	local canvas = UI.new("Frame", {
		Name = "SettingsCanvas", BorderSizePixel = 0, BackgroundTransparency = 1,
		Size = UDim2.fromOffset(1600, 900),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
	}, screen)
	local scaling = UI.new("UIScale", {Scale = 1}, canvas)
	local page = UI.new("CanvasGroup", {
		Name = "Settings", Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, GroupTransparency = 0,
	}, canvas)

	-- Criar todos os cartões antes de o jogador clicar na engrenagem.
	-- Não aguarda cena, iluminação, renderização da página ou transição.
	local success, err = pcall(function()
		SettingsScreen(page, {
			scope = scope,
			state = state,
			playClick = playClick,
			go = function(route)
				if alive then navigate(route) end
			end,
			rerender = function() end,
			notify = function() end,
		})
	end)
	if not success then
		warn("[CL27] Settings HUD principal falhou ao montar: " .. tostring(err))
		page:ClearAllChildren()
		fallback(page, scope, function(route) if alive then navigate(route) end end, playClick)
	end

	local cameraConnection: RBXScriptConnection? = nil
	local function resize()
		if not alive then return end
		local camera = Workspace.CurrentCamera
		if not camera then return end
		local viewport = camera.ViewportSize
		local topLeft, bottomRight = GuiService:GetGuiInset()
		local margin = 12
		local available = viewport - topLeft - bottomRight - Vector2.new(margin * 2, margin * 2)
		scaling.Scale = math.max(0.1, math.min(available.X / 1600, available.Y / 900))
		canvas.Position = UDim2.fromOffset(topLeft.X + margin + available.X / 2, topLeft.Y + margin + available.Y / 2)
	end
	local function watchCamera()
		if cameraConnection then cameraConnection:Disconnect() end
		local camera = Workspace.CurrentCamera
		if camera then cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
		resize()
	end
	watchCamera()
	scope:Connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), watchCamera)
	scope:Add(function() if cameraConnection then cameraConnection:Disconnect() end end)

	return {
		gui = screen,
		page = page,
		SetNavigation = function(_, callback: (string) -> ())
			navigate = callback
		end,
		SetVisible = function(_, visible: boolean)
			if not alive then return end
			if screen.Enabled == visible then return end
			screen.Enabled = visible
			if visible then
				page.GroupTransparency = 1
				if state.settings and state.settings.reducedMotion then
					page.GroupTransparency = 0
				else
					TweenService:Create(page, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
						{GroupTransparency = 0}):Play()
				end
			end
		end,
		Destroy = function()
			if not alive then return end
			alive = false
			scope:Destroy()
			screen:Destroy()
		end,
	}
end

return SettingsHUD
