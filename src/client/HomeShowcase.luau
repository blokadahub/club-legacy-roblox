--!strict
-- Conteúdo central do lobby CL 27. Composição de interface, não cenário 3D.
-- Símbolos geométricos próprios: não depende de logos/arquivos da EA SPORTS.
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local UI = require(script.Parent.UI)

local Showcase = {}
local GREEN = Color3.fromRGB(129, 223, 135)
local WHITE = Color3.fromRGB(236, 240, 239)
local MUTED = Color3.fromRGB(189, 201, 200)
local SECTIONS = {
	{title = "NOTÍCIAS DO CL", subtitle = "Acompanhe novidades e atualizações do Club Legacy.", action = "Ver notícias", symbol = "news"},
	{title = "CLUBS", subtitle = "Escolha seu clube e prepare a próxima partida.", action = "Entrar em Clubs", symbol = "clubs"},
	{title = "JOGO RÁPIDO", subtitle = "Selecione as equipes e entre no clima de jogo.", action = "Selecionar equipes", symbol = "quick"},
	{title = "APRENDA A JOGAR", subtitle = "Modos indisponíveis temporariamente. Aguarde uma atualização.", action = "EM ATUALIZAÇÃO", symbol = "learn"},
	{title = "UPGRADE", subtitle = "Descubra a identidade e as próximas novidades do CL 27.", action = "Ver melhorias", symbol = "upgrade"},
}
local function item(className: string, parent: Instance, props)
	local object = Instance.new(className)
	for key, value in pairs(props) do
		(object :: any)[key] = value
	end
	object.Parent = parent
	return object
end

local function strip(parent: Instance, name: string, x: number, y: number, w: number, h: number, rotation: number, color: Color3)
	return item("Frame", parent, {
		Name = name, BackgroundColor3 = color, BorderSizePixel = 0,
		Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
		Rotation = rotation, ZIndex = 6,
	})
end

local function label(parent: Instance, name: string, text: string, size: number, position: UDim2, bounds: UDim2, color: Color3, font)
	return item("TextLabel", parent, {
		Name = name, Text = text, Font = font or Enum.Font.GothamBold,
		TextSize = size, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center,
		TextColor3 = color, BackgroundTransparency = 1,
		Position = position, Size = bounds, ZIndex = 7,
	})
end

local function makeSymbol(parent: Instance, kind: string): Frame
	local frame = item("Frame", parent, {
		Name = "Simbolo_" .. kind, BackgroundTransparency = 1,
		Size = UDim2.fromOffset(204, 132),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Visible = false, ZIndex = 6,
	})
	item("UIScale", frame, {Name = "EscalaSimbolo", Scale = 1})
	local ink = WHITE
	if kind == "news" then
		-- Insígnia dourada própria, facetada em diagonais.
		local gold = Color3.fromRGB(227, 184, 83)
		local light = Color3.fromRGB(255, 219, 127)
		strip(frame, "FacetaEsquerda", 57, 26, 19, 82, -32, gold)
		strip(frame, "FacetaCentral", 92, 16, 25, 97, 23, light)
		strip(frame, "FacetaDireita", 127, 29, 19, 77, -34, gold)
		strip(frame, "Apoio", 60, 111, 89, 7, 0, Color3.fromRGB(121, 91, 44))
		label(frame, "MarcaNews", "CL", 23, UDim2.fromOffset(70, 36), UDim2.fromOffset(65, 56), Color3.fromRGB(35, 28, 20), Enum.Font.GothamBlack)
	elseif kind == "clubs" then
		-- Escudo angular monocolor, feito de cinco traços e monograma CL.
		strip(frame, "BordaSuperior", 65, 24, 74, 5, 0, ink)
		strip(frame, "BordaEsquerda", 59, 35, 5, 57, -9, ink)
		strip(frame, "BordaDireita", 139, 35, 5, 57, 9, ink)
		strip(frame, "PontaEsquerda", 74, 97, 50, 5, 37, ink)
		strip(frame, "PontaDireita", 112, 97, 50, 5, -37, ink)
		label(frame, "MonogramaClub", "CL", 37, UDim2.fromOffset(62, 40), UDim2.fromOffset(80, 57), ink, Enum.Font.GothamBlack)
	elseif kind == "quick" then
		-- Emblema esportivo inclinado; três placas independentes.
		strip(frame, "LinhaVelozUm", 45, 50, 99, 13, -24, ink)
		strip(frame, "LinhaVelozDois", 78, 77, 95, 13, -24, ink)
		strip(frame, "LinhaVelozTres", 71, 25, 75, 13, -24, ink)
		strip(frame, "Corte", 125, 16, 10, 100, 22, Color3.fromRGB(15, 30, 30))
	elseif kind == "learn" then
		strip(frame, "Haste", 69, 17, 17, 91, -14, ink)
		strip(frame, "Base", 80, 92, 77, 17, 0, ink)
		strip(frame, "Diagonal", 112, 39, 17, 70, 39, ink)
	elseif kind == "upgrade" then
		strip(frame, "AnguloEsquerdo", 19, 27, 12, 76, -19, ink)
		strip(frame, "AnguloDireito", 173, 27, 12, 76, 19, ink)
		label(frame, "MarcaUpgrade", "CL 27", 47, UDim2.fromOffset(22, 31), UDim2.fromOffset(160, 71), ink, Enum.Font.GothamBlack)
	end
	return frame
end

function Showcase.new(parent: Instance, actionCallback: (number, number?) -> (), reducedMotion: boolean)
	local stage = item("CanvasGroup", parent, {
		Name = "ConteudoCentral", BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.455, 0.265),
		Size = UDim2.fromScale(0.43, 0.65),
		GroupTransparency = 0, ZIndex = 4,
	})
	local artwork = item("Frame", stage, {
		Name = "Logotipos", BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, 0.02), Size = UDim2.fromScale(1, 0.30), ZIndex = 6,
	})
	local symbols = {}
	for _, section in ipairs(SECTIONS) do
		symbols[section.symbol] = makeSymbol(artwork, section.symbol)
	end
	local title = label(stage, "TituloCentral", "", 36,
		UDim2.fromScale(0.035, 0.35), UDim2.fromScale(0.93, 0.14), WHITE, Enum.Font.GothamBlack)
	local subtitle = label(stage, "DescricaoCentral", "", 18,
		UDim2.fromScale(0.115, 0.495), UDim2.fromScale(0.77, 0.115), MUTED, Enum.Font.GothamMedium)

	local action, capsule = UI.capsule(stage, {
		Name = "AcaoPrincipal", Text = "", AutoButtonColor = false, Selectable = true,
		Active = true, BorderSizePixel = 0, BackgroundColor3 = GREEN,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.677),
		Size = UDim2.new(0.59, 0, 0, 56),
		ClipsDescendants = false, ZIndex = 7,
	})
	item("UISizeConstraint", action, {
		MinSize = Vector2.new(206, 44), MaxSize = Vector2.new(340, 56),
	})
	local border, disc, actionText = capsule.border, capsule.disc, capsule.label
	-- Faixa branca localizada percorre a borda da capsula com halo macio
	-- e rastro gradual. O botao, o circulo X e o texto ficam imoveis.
	local capsuleFX = capsule.fx

	-- Miniaturas tipográficas, exibidas apenas na seção Upgrade.
	local mini = item("Frame", stage, {
		Name = "PrevisoesUpgrade", BackgroundTransparency = 1, Visible = false,
		Position = UDim2.fromScale(0.18, 0.84),
		Size = UDim2.fromScale(0.64, 0.13), ZIndex = 6,
	})
	for i, text in ipairs({"ELENCOS", "EVENTOS", "ESTILO"}) do
		local frame = item("Frame", mini, {
			Name = "Previsao_" .. tostring(i), BackgroundColor3 = Color3.fromRGB(13, 29, 32),
			BackgroundTransparency = 0.20, BorderSizePixel = 0,
			Position = UDim2.fromScale((i - 1) * 0.345, 0),
			Size = UDim2.fromScale(0.315, 1), ZIndex = 6,
		})
		item("UICorner", frame, {CornerRadius = UDim.new(0, 5)})
		strip(frame, "DetalheSuperior", 9, 8, 26, 2, 0, GREEN)
		label(frame, "Legenda", text, 10, UDim2.fromScale(0.07, 0.46),
			UDim2.fromScale(0.86, 0.47), WHITE, Enum.Font.GothamBold)
	end

	-- Mantém logomarca, título e cápsula legíveis em telas móveis baixas,
	-- sem aumentar indevidamente os botões em monitores grandes.
	local viewportConnection: RBXScriptConnection? = nil
	local cameraConnection: RBXScriptConnection? = nil
	local function adapt()
		local camera = Workspace.CurrentCamera
		if not camera then return end
		local compact = camera.ViewportSize.Y < 600
		for _, symbol in pairs(symbols) do
			local scale = symbol:FindFirstChild("EscalaSimbolo")
			if scale and scale:IsA("UIScale") then
				scale.Scale = if compact then 0.61 else 1
			end
		end
		title.TextSize = if compact then 25 else 36
		title.Position = UDim2.fromScale(0.035, if compact then 0.375 else 0.35)
		subtitle.TextSize = if compact then 14 else 18
		subtitle.Position = UDim2.fromScale(0.115, if compact then 0.51 else 0.495)
		subtitle.Size = UDim2.fromScale(0.77, if compact then 0.16 else 0.115)
		action.Position = UDim2.fromScale(0.5, if compact then 0.695 else 0.677)
		action.Size = UDim2.new(0.59, 0, 0, if compact then 44 else 56)
		actionText.TextSize = if compact then 14 else 17
		mini.Position = UDim2.fromScale(0.18, if compact then 0.89 else 0.84)
		mini.Size = UDim2.fromScale(0.64, if compact then 0.11 else 0.13)
	end
	local function watchCamera()
		if viewportConnection then viewportConnection:Disconnect() end
		local camera = Workspace.CurrentCamera
		if camera then
			viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(adapt)
		end
		adapt()
	end
	cameraConnection = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
	watchCamera()

	local selected, lesson, token, fadeTween = 0, nil, 0, nil
	local isReduced = reducedMotion
	capsuleFX:SetReducedMotion(reducedMotion)
	local alive = true
	local function fill(index: number, lessonIndex: number?)
		local section = SECTIONS[index]
		if not section then return end
		for symbol, image in pairs(symbols) do
			image.Visible = symbol == section.symbol
		end
		title.Text = section.title
		subtitle.Text = section.subtitle
		actionText.Text = section.action
		local disabled = index == 4
		action.Active = not disabled
		action.Selectable = not disabled
		action.BackgroundColor3 = if disabled then Color3.fromRGB(105, 112, 114) else GREEN
		disc.Visible = not disabled
		actionText.Position = if disabled then UDim2.fromScale(0, 0) else UDim2.new(0, 47, 0, 0)
		actionText.Size = if disabled then UDim2.fromScale(1, 1) else UDim2.new(1, -52, 1, 0)
		capsuleFX:SetReducedMotion(isReduced or disabled)
		mini.Visible = index == 5
	end
	local function tweenFade(goal: number, duration: number)
		if fadeTween then fadeTween:Cancel() end
		fadeTween = TweenService:Create(stage, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			GroupTransparency = goal,
		})
		fadeTween:Play()
		return fadeTween
	end
	local self = {}
	function self:Show(index: number, instant: boolean?, lessonIndex: number?)
		if not alive then return end
		if selected == index and lesson == lessonIndex then return end
		selected, lesson = index, lessonIndex
		token += 1
		local localToken = token
		if instant or isReduced then
			if fadeTween then fadeTween:Cancel() end
			fill(index, lessonIndex)
			stage.GroupTransparency = 0
			return
		end
		local fadeOut = tweenFade(1, 0.15)
		fadeOut.Completed:Once(function(playback)
			if not alive or localToken ~= token or playback ~= Enum.PlaybackState.Completed then return end
			fill(index, lessonIndex)
			tweenFade(0, 0.27)
		end)
	end
	function self:Step(elapsed: number)
		if not alive or isReduced then return end
		capsuleFX:Step(elapsed)
		border.Transparency = 0.82
	end
	function self:SetReducedMotion(enabled: boolean)
		isReduced = enabled
		capsuleFX:SetReducedMotion(enabled or selected == 4)
		if enabled then
			if fadeTween then fadeTween:Cancel() end
			stage.GroupTransparency = 0
		end
	end
	function self:Destroy()
		if not alive then return end
		alive = false
		if fadeTween then fadeTween:Cancel() end
		if viewportConnection then viewportConnection:Disconnect() end
		if cameraConnection then cameraConnection:Disconnect() end
		capsuleFX:Destroy()
		stage:Destroy()
	end
	action.Activated:Connect(function()
		if alive and selected > 0 and selected ~= 4 then actionCallback(selected, lesson) end
	end)
	action.MouseEnter:Connect(function()
		if alive and selected ~= 4 then
			TweenService:Create(action, TweenInfo.new(0.16), {
				BackgroundColor3 = Color3.fromRGB(161, 243, 166),
			}):Play()
		end
	end)
	action.MouseLeave:Connect(function()
		if alive and selected ~= 4 then
			TweenService:Create(action, TweenInfo.new(0.2), {BackgroundColor3 = GREEN}):Play()
		end
	end)
	return self
end

return Showcase
