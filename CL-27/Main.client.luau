-- Ponto de entrada independente. O projeto original não é carregado neste place.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local modules = ReplicatedStorage:WaitForChild("CL27")
local Scope = require(modules.Animations.Scope)
local UI = require(modules.Components.UI)
local Avatar = require(modules.Components.Avatar)
local Audio = require(modules.Components.Audio)
local data = require(modules.Data.Career)

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local previous = playerGui:FindFirstChild("CL27")
if previous then previous:Destroy() end
local state = {
	selectedPlayerId = "p11", squadFilter = "Todos", formation = "4-3-3", mentality = "Equilibrada",
	lineup = {}, training = {}, calendarMonth = 7, selectedFixtureId = "f01", competition = "Liga Aurora",
	transferQuery = "", transferFilter = "Todos", selectedMarketId = "m01", shortlist = {}, offers = {},
	identity = { primary = Color3.fromRGB(185,242,78), secondary = Color3.fromRGB(19,30,35), crest = "Escudo", kit = "Faixa" },
	settings = { reducedMotion = false, quality = "Alta", textScale = 1, menuVolume = 0.3 },
}
for index=1,11 do state.lineup[index]=data.players[index].id end

local appScope = Scope.new(state.settings)
Audio.start(appScope,state.settings)
local ui = UI.newContext(appScope,state.settings)
local c = ui.theme
local gui = ui.new("ScreenGui",{Name="CL27",ResetOnSpawn=false,IgnoreGuiInset=false,DisplayOrder=20,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},playerGui)
local root = ui.new("Frame",{Name="Aplicativo",Size=UDim2.fromScale(1,1),BackgroundColor3=c.bg},gui)
ui.new("UIGradient",{Color=ColorSequence.new(c.panel,c.bg),Rotation=35},root)
local screenList = {
	{"Home","Início","01"},{"Overview","Visão geral","02"},{"Squad","Elenco","03"},
	{"Tactics","Táticas","04"},{"Calendar","Calendário","05"},{"Transfers","Transferências","06"},
	{"Finance","Finanças","07"},{"Development","Desenvolvimento","08"},
	{"Competitions","Competições","09"},{"Customization","Personalização","10"},{"Settings","Configurações","11"},
}
local screens = {}
for _, screen in ipairs(screenList) do screens[screen[1]]=require(modules.Screens[screen[1]]) end

local current, history = "Home", {}
local pageScope, chromeScope, chrome, page, scroller, compact
local activeNavButton
local render, navigate
local toastLabel = ui.label(root,"",13,c.bg,54)
toastLabel.Size = UDim2.new(1,-48,0,54)
toastLabel.Position = UDim2.new(0,24,1,-68)
toastLabel.BackgroundColor3 = c.accent
toastLabel.BackgroundTransparency = 0
toastLabel.TextXAlignment = Enum.TextXAlignment.Center
toastLabel.ZIndex = 100
toastLabel.Visible = false
ui.round(toastLabel,8)
local toastId = 0
local function toast(message)
	toastId += 1
	local id = toastId
	toastLabel.Text = message
	toastLabel.Visible = true
	task.delay(3.5,function() if appScope.alive and id==toastId then toastLabel.Visible=false end end)
end

local function applySettings()
	Audio.apply(state.settings)
	for _, descendant in ipairs(gui:GetDescendants()) do
		local base = descendant:GetAttribute("CL27TextSize")
		if base then descendant.TextSize = base * state.settings.textScale end
	end
end

local function rebuildChrome()
	if chromeScope then chromeScope:destroy() end
	if chrome then chrome:Destroy() end
	chromeScope = Scope.new(state.settings)
	local chromeUi = UI.newContext(chromeScope,state.settings)
	chrome = chromeUi.new("Frame",{Name="Navegacao",BackgroundTransparency=1,Size=UDim2.fromScale(1,1)},root)
	local header = chromeUi.new("Frame",{Size=UDim2.new(1,0,0,compact and 64 or 76),BackgroundColor3=c.bg,BackgroundTransparency=0.08},chrome)
	local brand = chromeUi.label(header,"CL 27",compact and 25 or 32,c.text,44)
	brand.Font = Enum.Font.GothamBlack
	brand.Position = UDim2.fromOffset(20,10)
	brand.Size = UDim2.fromOffset(120,44)
	local brandAccent = chromeUi.new("Frame",{Position=UDim2.fromOffset(20,compact and 52 or 60),Size=UDim2.fromOffset(30,3),BackgroundColor3=c.accent},header)
	brandAccent.Name = "Assinatura"
	local club = chromeUi.label(header,"AUR  /  "..(compact and "TEMP. 2027" or "AURORA FC  ·  TEMPORADA 2027"),11,c.muted,40)
	club.Position = UDim2.new(1,compact and -190 or -330,0,14)
	club.Size = UDim2.fromOffset(compact and 166 or 304,40)
	club.TextXAlignment = Enum.TextXAlignment.Right
	local badge = chromeUi.new("Frame",{BackgroundColor3=state.identity.primary,Position=UDim2.new(1,-16,0,58),AnchorPoint=Vector2.new(1,0),Size=UDim2.fromOffset(34,3)},header)
	badge.Name="CorDoClube"
	local nav = chromeUi.new("ScrollingFrame",{
		Name="Destinos",BackgroundTransparency=1,ScrollBarThickness=compact and 2 or 0,
		ScrollBarImageColor3=c.accent,BorderSizePixel=0,CanvasSize=UDim2.fromOffset(0,0),
		AutomaticCanvasSize=compact and Enum.AutomaticSize.X or Enum.AutomaticSize.Y,
		ScrollingDirection=compact and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y,
		Position=UDim2.fromOffset(compact and 12 or 16,compact and 72 or 108),
		Size=compact and UDim2.new(1,-24,0,48) or UDim2.new(0,206,1,-172),
	},chrome)
	chromeUi.stack(nav,compact and 8 or 6,compact)
	for _, screen in ipairs(screenList) do
		local active = current==screen[1]
		local b=chromeUi.button(nav,(compact and "" or screen[3].."   ")..screen[2],function() navigate(screen[1]) end,{selected=active,height=44})
		if compact then b.Size=UDim2.fromOffset(screen[1]=="Development" and 172 or 140,44) end
		b.Name=screen[1]
		if not compact then b.TextXAlignment=Enum.TextXAlignment.Left; chromeUi.pad(b,12) end
		if active then
			activeNavButton=b
			task.defer(function()
				if not chromeScope.alive or not b.Parent then return end
				if compact then nav.CanvasPosition=Vector2.new(math.max(0,b.AbsolutePosition.X-nav.AbsolutePosition.X+nav.CanvasPosition.X-8),0) end
			end)
		end
	end
	if not compact then
		local foot=chromeUi.label(chrome,"CLUBE LOCAL\n21 JUL 2027  /  TEMPORADA",10,c.muted,44)
		foot.Position=UDim2.new(0,22,1,-62)
		foot.Size=UDim2.fromOffset(200,44)
	end
	local hint=chromeUi.label(chrome,UserInputService.GamepadEnabled and "LB / RB   Navegar     A   Selecionar     B   Voltar" or (UserInputService.TouchEnabled and "Toque para selecionar  ·  Arraste o atleta para girar" or "Q / E   Navegar    Backspace   Voltar    Arraste o atleta para girar"),10,c.muted,26)
	hint.Position=UDim2.new(0,compact and 16 or 248,1,-29)
	hint.Size=UDim2.new(1,compact and -32 or -272,0,26)
	return chromeUi
end

render = function(preserveScroll)
	if not appScope.alive then return end
	local position = preserveScroll and scroller and scroller.CanvasPosition or Vector2.zero
	local selected=GuiService.SelectedObject
	local focusKey=preserveScroll and selected and selected:GetAttribute("CL27FocusKey")
	if pageScope then pageScope:destroy() end
	if page then page:Destroy() end
	compact=root.AbsoluteSize.X<900
	rebuildChrome()
	pageScope=Scope.new(state.settings)
	local pageUi=UI.newContext(pageScope,state.settings,compact,"Page")
	local left,top=compact and 12 or 246,compact and 132 or 98
	page=pageUi.new("CanvasGroup",{Name="Tela"..current,BackgroundTransparency=1,Position=UDim2.fromOffset(left,top+8),Size=UDim2.new(1,-left-(compact and 12 or 24),1,-top-38),GroupTransparency=state.settings.reducedMotion and 0 or 1},root)
	scroller=pageUi.new("ScrollingFrame",{Name="Conteudo",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ScrollBarThickness=3,ScrollBarImageColor3=c.accent,CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,BorderSizePixel=0,ClipsDescendants=true},page)
	pageUi.pad(scroller,compact and 6 or 10)
	pageUi.stack(scroller,14)
	local ctx={parent=scroller,ui=pageUi,state=state,data=data,scope=pageScope,navigate=navigate,toast=toast,compact=compact,width=root.AbsoluteSize.X-left-36}
	ctx.refresh=function() render(true) end
	ctx.applySettings=applySettings
	ctx.audioStatus=function() return Audio.status end
	ctx.testAudio=function()
		if not Audio.play() then toast(state.settings.menuVolume==0 and "Aumente o volume para testar o som." or Audio.status) end
	end
	ctx.applyIdentity=function()
		local header = chrome and chrome:FindFirstChild("CorDoClube",true)
		if header then header.BackgroundColor3=state.identity.primary end
	end
	ctx.avatar=function(parent,player,options) return Avatar.mount(parent,player,options,ctx) end
	screens[current](ctx)
	scroller.CanvasPosition=position
	pageScope:tween(page,{GroupTransparency=0,Position=UDim2.fromOffset(left,top)},0.28)
	applySettings()
	local thisScope=pageScope
	task.defer(function()
		if not thisScope.alive or not UserInputService.GamepadEnabled then return end
		local target=activeNavButton
		if focusKey then
			for _,candidate in ipairs(root:GetDescendants()) do
				if candidate:GetAttribute("CL27FocusKey")==focusKey then target=candidate; break end
			end
		end
		GuiService.SelectedObject=target
	end)
end

navigate=function(destination)
	if not screens[destination] then return end
	if destination~=current then
		table.insert(history,current)
		if #history>64 then table.remove(history,1) end
		current=destination
	end
	render(false)
end

local function back()
	if #history>0 then current=table.remove(history); render(false) elseif current~="Home" then navigate("Home") end
end

ContextActionService:BindActionAtPriority("CL27Navigation",function(_,inputState,input)
	if GuiService.MenuIsOpen or UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
	if inputState~=Enum.UserInputState.Begin then return Enum.ContextActionResult.Sink end
	local key=input.KeyCode
	if key==Enum.KeyCode.Backspace or key==Enum.KeyCode.ButtonB then back(); return Enum.ContextActionResult.Sink end
	local direction=(key==Enum.KeyCode.E or key==Enum.KeyCode.ButtonR1) and 1 or ((key==Enum.KeyCode.Q or key==Enum.KeyCode.ButtonL1) and -1 or 0)
	if direction~=0 then
		for index,screen in ipairs(screenList) do
			if screen[1]==current then navigate(screenList[(index-1+direction)%#screenList+1][1]); break end
		end
	end
	return Enum.ContextActionResult.Sink
end,false,2100,Enum.KeyCode.Q,Enum.KeyCode.E,Enum.KeyCode.Backspace,Enum.KeyCode.ButtonB,Enum.KeyCode.ButtonL1,Enum.KeyCode.ButtonR1)
appScope:add(function() ContextActionService:UnbindAction("CL27Navigation") end)

local resizeId=0
appScope:connect(root:GetPropertyChangedSignal("AbsoluteSize"),function()
	resizeId+=1
	local id=resizeId
	task.delay(0.15,function() if appScope.alive and resizeId==id then render(true) end end)
end)
gui.Destroying:Connect(function()
	appScope:destroy()
	if pageScope then pageScope:destroy() end
	if chromeScope then chromeScope:destroy() end
end)
render(false)
