--!strict
local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local StarterGui=game:GetService("StarterGui")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Data=require(ReplicatedStorage.CL27.Data)
local Theme=require(ReplicatedStorage.CL27.Theme)
local UI=require(script.Parent.UI)
local Scope=require(script.Parent.Scope)
local Scene=require(script.Parent.Scene)
local Soundtrack=require(script.Parent.Soundtrack)
local HomeHUD=require(script.Parent.HomeHUD)
local SettingsHUD=require(script.Parent.SettingsHUD)
local TransitionFX=require(script.Parent.TransitionFX)
local App={}
App.routes={"HomeInterior","HomeTraining","Overview","Squad","Tactics","Assignments","Calendar","Transfers","Finance","Development","Competitions","Customization","Settings","Clubs","Kits"}
local labels={HomeInterior="Menu • galeria",HomeTraining="Menu • treinamento",Overview="Visão geral",Squad="Elenco",Tactics="Táticas",Assignments="Atribuições",Calendar="Calendário",Transfers="Transferências",Finance="Finanças",Development="Desenvolvimento",Competitions="Competições",Customization="Personalização",Settings="Configurações",Clubs="Seleção de clubes",Kits="Seleção de uniformes"}
local screens={}
for _,id in ipairs(App.routes) do
	screens[id]=require(script.Parent.Screens[if id=="HomeInterior" or id=="HomeTraining" then "Home" else id])
end
function App.start()
	UI.inputLocked=false
	local player=Players.LocalPlayer
	local playerGui=player:WaitForChild("PlayerGui")
	local previous=playerGui:FindFirstChild("CL27")
	if previous then previous:Destroy() end
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All,false) end)
	local gui=UI.new("ScreenGui",{Name="CL27",ResetOnSpawn=false,IgnoreGuiInset=true,
		ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=20},playerGui)
	local lifetime=Scope.new()
	local soundtrack=Soundtrack.start(gui)
	lifetime:Add(function() soundtrack.destroy() end)
	local state={screen="HomeInterior",homeFocus=3,homeClub=1,awayClub=2,homeKit=1,awayKit=2,activeSide="home",
		homeReady=false,awayReady=false,selectedPlayer=10,formation=1,assignments={},month=11,year=2026,
		shortlist={},training={},accent="Turquesa",menuInputLocked=false,settings={reducedMotion=false,quality="Alta",highContrast=false,showHints=true}}
	-- HUD nasce ANTES do cenário e do render das páginas: uma falha no 3D
	-- nunca pode deixar o jogador diante de uma tela sem menu.
	local homeHud=HomeHUD.start(playerGui,state)
	lifetime:Add(function() homeHud:Destroy() end)
	-- A grade de personalização nasce antes do cenário, em ScreenGui próprio.
	-- DisplayOrder 85 supera o wipe do ScreenGui principal (DisplayOrder 20).
	local settingsHud=SettingsHUD.start(playerGui,state)
	lifetime:Add(function() settingsHud:Destroy() end)
	local scene=Scene.new(state.settings)
	lifetime:Add(function() scene:Destroy() end)
	local canvas=UI.frame(gui,0,0,1600,900,Theme.background,1)
	canvas.Name="Canvas"
	canvas.AnchorPoint=Vector2.new(.5,.5)
	canvas.Position=UDim2.fromScale(.5,.5)
	local scale=UI.new("UIScale",{Scale=1},canvas)
	local function resize()
		local camera=workspace.CurrentCamera
		if not camera then return end
		local viewport=camera.ViewportSize
		local topLeft,bottomRight=GuiService:GetGuiInset()
		local margin=12
		local available=viewport-topLeft-bottomRight-Vector2.new(margin*2,margin*2)
		scale.Scale=math.max(.1,math.min(available.X/1600,available.Y/900))
		scene.canvasHeight=900*scale.Scale
		canvas.Position=UDim2.fromOffset(topLeft.X+margin+available.X/2,topLeft.Y+margin+available.Y/2)
	end
	local cameraConnection=nil
	local function watchCamera()
		if cameraConnection then cameraConnection:Disconnect() end
		if workspace.CurrentCamera then cameraConnection=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
		resize()
	end
	watchCamera()
	lifetime:Connect(workspace:GetPropertyChangedSignal("CurrentCamera"),watchCamera)
	lifetime:Add(function() if cameraConnection then cameraConnection:Disconnect() end end)
	local pageScope=nil
	local page=nil
	local trayScope=nil
	local tray=nil
	local selectedBeforeTray=nil
	local history={}
	local busy=false
	local pending=nil
	local mode=nil
	local render,go
	-- Carregamento CL neon: sobreposicao leve independente do cenario,
	-- respeita toque, gamepad e visualizacao em celular horizontal.
	local transitionFx=TransitionFX.start(playerGui)
	lifetime:Add(function() transitionFx:Destroy() end)
	local transition=transitionFx.layer
	local MINIMUM_LOAD_SECONDS=TransitionFX.MINIMUM_SECONDS
	local function lockNavigation()
		busy=true
		UI.inputLocked=true
		state.menuInputLocked=true
		if pageScope then pageScope.inputsPaused=true end
	end
	local function unlockNavigation()
		busy=false
		UI.inputLocked=false
		state.menuInputLocked=false
		if pageScope then pageScope.inputsPaused=false end
	end
	local toast=UI.panel(canvas,490,786,620,48,Theme.background,.05)
	toast.ZIndex=120
	toast.Visible=false
	local toastText=UI.text(toast,"",18,0,584,48,17,Theme.white)
	toastText.TextXAlignment=Enum.TextXAlignment.Center
	local toastVersion=0
	local function notify(message)
		toastVersion+=1
		local token=toastVersion
		toastText.Text=tostring(message)
		toast.Visible=true
		lifetime:Delay(3,function() if token==toastVersion then toast.Visible=false end end)
	end
	local function closeTray()
		local wasOpen=tray~=nil
		if trayScope then trayScope:Destroy();trayScope=nil end
		if tray then tray:Destroy();tray=nil end
		if pageScope then pageScope.inputsPaused=busy end
		UI.inputLocked=busy
		if wasOpen then
			GuiService.SelectedObject=if selectedBeforeTray and selectedBeforeTray.Parent then selectedBeforeTray else nil
			selectedBeforeTray=nil
		end
	end
	local function focusPage(preferredOrdinal)
		if not UserInputService.GamepadEnabled or not page then return end
		local first=nil
		local ordinal=0
		for _,object in ipairs(page:GetDescendants()) do
			if object:IsA("GuiButton") and object.Visible then
				ordinal+=1
				first=first or object
				if ordinal==preferredOrdinal then GuiService.SelectedObject=object;return end
			end
		end
		GuiService.SelectedObject=first
	end
	local function toggleTray()
		if busy then return end
		if tray then closeTray();return end
		selectedBeforeTray=GuiService.SelectedObject
		if pageScope then pageScope.inputsPaused=true end
		UI.inputLocked=true
		trayScope=Scope.new()
		tray=UI.frame(canvas,0,0,1600,900,Theme.background,.15)
		tray.Active=true
		tray.ZIndex=80
		local panel=UI.panel(tray,55,112,650,695,Theme.background,0)
		UI.text(panel,"CENTRAL DO CLUBE",28,20,470,44,28,Theme.white,Enum.Font.GothamBold)
		UI.button(panel,"×",564,20,55,45,closeTray,trayScope,{quiet=true,textSize=30})
		for i,id in ipairs(App.routes) do
			local col=if i>8 then 1 else 0
			local row=(i-1)%8
			UI.button(panel,labels[id],28+col*306,90+row*69,284,51,function() closeTray();go(id) end,trayScope,{selected=id==state.screen,quiet=true,textSize=17})
		end
		if UserInputService.GamepadEnabled then
			for _,object in ipairs(panel:GetDescendants()) do if object:IsA("GuiButton") then GuiService.SelectedObject=object;break end end
		end
	end
	local function rerender()
		if busy then return end
		render()
	end
	render=function()
		closeTray()
		local focusOrdinal=nil
		-- A detail/option update on the same route must preserve controller focus.
		-- A covered navigation handoff starts with the first control of its new page.
		if not busy and page and GuiService.SelectedObject then
			local ordinal=0
			for _,object in ipairs(page:GetDescendants()) do
				if object:IsA("GuiButton") and object.Visible then
					ordinal+=1
					if object==GuiService.SelectedObject then focusOrdinal=ordinal;break end
				end
			end
		end
		if pageScope then pageScope:Destroy() end
		if page then page:Destroy() end
		GuiService.SelectedObject=nil
		pageScope=Scope.new()
		pageScope.inputsPaused=busy
		UI.accent=if state.accent=="Esmeralda" then Color3.fromRGB(94,240,154) elseif state.accent=="Azul" then Color3.fromRGB(115,193,255) else Theme.accent
		UI.highContrast=state.settings.highContrast==true
		UI.reducedMotion=state.settings.reducedMotion
		page=UI.new("CanvasGroup",{Name=state.screen,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),GroupTransparency=0},canvas)
		-- A UI de Settings fica em outro ScreenGui, nunca sob Transicao.
		settingsHud:SetVisible(state.screen=="Settings")
		local wanted=if state.screen=="HomeInterior" then "Interior" elseif state.screen=="HomeTraining" then "Training" elseif state.screen=="Kits" then "Kits" else "Arena"
		homeHud:SetVisible(wanted=="Interior" or wanted=="Training")
		if wanted~=mode then scene:Show(wanted,Data.clubs[state.homeClub],Data.clubs[state.awayClub],state.homeKit,state.awayKit);mode=wanted
		else scene:UpdateClubs(Data.clubs[state.homeClub],Data.clubs[state.awayClub],state.homeKit,state.awayKit) end
		scene:ApplySettings(state.settings)
		-- Neons são decorativos; falhas de geometria não podem prender o
		-- jogador no wipe nem bloquear o menu de personalização.
		local neonOK, neonError=pcall(function()
			scene:SetSettingsAtmosphere(state.screen=="Settings")
		end)
		if not neonOK then warn("[CL27] Neon opcional de Settings: "..tostring(neonError)) end
		-- A galeria de Settings usa a arena 3D existente; sem as fitas
		-- e sem o véu de UI de outras rotas.
		if wanted=="Arena" and state.screen~="Settings" then
			local backdrop=UI.frame(page,0,0,1600,900,Color3.new(1,1,1),if state.screen=="Clubs" then .72 else .15)
			UI.gradient(backdrop,{Theme.blue,Color3.fromRGB(6,62,65),Theme.background},26)
			for i=1,3 do
				local shape=UI.frame(backdrop,720+i*190,220+i*180,1550,185,Color3.fromRGB(12,136,120),.93)
				shape.Rotation=-29
			end
			UI.line(backdrop,760,890,1560,135,UI.accent,1).BackgroundTransparency=.9
		end
		local ctx={state=state,scope=pageScope,go=go,rerender=rerender,notify=notify,scene=scene}
		-- A HOME é desenhada no ScreenGui independente CL27_HomeHUD, não aqui.
		-- O ScreenGui do menu não depende da cena 3D para inicializar.
		if wanted~="Interior" and wanted~="Training" and state.screen~="Settings" then
			screens[state.screen](page,ctx)
		end
		-- A tela inicial da referência possui só cinco opções e os ícones decorativos.
		-- O rodapé de navegação continua disponível nas outras páginas.
		if wanted~="Interior" and wanted~="Training" and state.screen~="Settings" then
			local footer=UI.frame(page,0,839,1600,61,Theme.background,.3)
			UI.line(footer,44,0,1556,0,Theme.muted,1).BackgroundTransparency=.8
			UI.button(footer,"≡  CENTRAL",44,10,165,40,toggleTray,pageScope,{quiet=true,textSize=14})
			UI.button(footer,"‹  VOLTAR",230,10,144,40,function()
				local target=table.remove(history) or "HomeInterior"
				go(target,true)
			end,pageScope,{quiet=true,textSize=14})
			UI.button(footer,"⌂  INÍCIO",391,10,130,40,function() go(if state.homeEnvironment=="Training" then "HomeTraining" else "HomeInterior") end,pageScope,{quiet=true,textSize=14})
			if state.settings.showHints then UI.text(footer,"CLIQUE / A  Selecionar    •    M / Y  Central    •    B  Voltar",566,17,640,25,12,Theme.muted) end
			UI.text(footer,"CL 27  /  APRESENTAÇÃO VISUAL",1240,17,314,25,10,Theme.muted).TextXAlignment=Enum.TextXAlignment.Right
		end
		if not busy then focusPage(focusOrdinal) end
		if not busy and not state.settings.reducedMotion then
			page.GroupTransparency=0.22
			pageScope:Tween(page,{GroupTransparency=0},0.18)
		end
	end
	-- 2,5 s completos em qualquer mudanca do lobby, Configuracoes ou modo
	-- de jogo. Navegacao entre paineis internos que nao sao esses modos nao
	-- apresenta carregamento artificial.
	local function shouldLoad(from: string, to: string): boolean
		local critical = {
			HomeInterior=true, HomeTraining=true, Settings=true, Clubs=true, Kits=true,
		}
		return critical[from] == true or critical[to] == true
	end

	local function finishLoading()
		if not lifetime.alive then return end
		transitionFx:Finish()
		unlockNavigation()
		if pending then
			local nextRoute=pending
			pending=nil
			go(nextRoute[1],nextRoute[2])
		else
			focusPage()
		end
	end

	go=function(id,back)
		if not lifetime.alive then return end
		if not screens[id] then notify("Esta seção não está disponível.");return end
		if busy then pending={id,back};return end
		if id==state.screen then closeTray();return end
		local original=state.screen
		closeTray()
		lockNavigation()
		pending=nil
		local needsLoader=shouldLoad(original,id)
		local function handoff()
			if not lifetime.alive then return end
			if not back then table.insert(history,original) end
			state.screen=id
			-- O indicador continua por cima mesmo se uma tela falhar.
			local ok, errorMessage=xpcall(render,function(err)
				return tostring(err)..(debug and debug.traceback and "\n"..debug.traceback() or "")
			end)
			if not ok then
				warn("[CL27] Erro ao abrir "..tostring(id)..": "..tostring(errorMessage))
				settingsHud:SetVisible(id=="Settings")
				homeHud:SetVisible(id=="HomeInterior" or id=="HomeTraining")
			end
			return ok
		end
		if not needsLoader then
			local ok=handoff()
			unlockNavigation()
			if ok then focusPage() end
			return
		end

		local enter=transitionFx:Cover(state.settings.reducedMotion)
		local exitDuration=if state.settings.reducedMotion then 0.15 else TransitionFX.EXIT_SECONDS
		local revealStart=MINIMUM_LOAD_SECONDS-exitDuration
		-- Trocar a rota perto do fim: durante a maior parte do carregamento
		-- permanece visivel a tela de origem, como solicitado.
		local handoffAt=math.max(enter,revealStart-0.20)
		lifetime:Delay(handoffAt,function()
			if not lifetime.alive then return end
			handoff()
			lifetime:Delay(revealStart-handoffAt,function()
				if not lifetime.alive then return end
				local exit=transitionFx:Reveal(state.settings.reducedMotion)
				lifetime:Delay(exit,finishLoading)
			end)
		end)
	end

	-- Apenas a engrenagem abre Configurações. Seleções laterais são
	-- imediatas e não disparam uma tela artificial de carregamento.
	homeHud:SetNavigation(function(tab)
		state.settingsTab = tab
		go("Settings")
	end)
	-- Só as rotas já implementadas são acionadas. Notícias e Upgrade
	-- permanecem apresentações, sem compra ou sistemas fictícios.
	homeHud:SetPrimaryNavigation(function(index, lesson)
		if index==2 or index==3 then
			go("Clubs")
		elseif index==4 then
			if not lesson or lesson==1 or lesson==4 then
				go("HomeTraining")
			else
				notify(if lesson==2 then "Rush está em desenvolvimento." else "Jogos de habilidade estão em desenvolvimento.")
			end
		elseif index==1 then
			notify("Notícias do CL: novidades em desenvolvimento.")
		elseif index==5 then
			notify("Upgrade: novidades em desenvolvimento.")
		end
	end)
	settingsHud:SetNavigation(function(target)
		go(target)
	end)
	lifetime:Connect(UserInputService.InputBegan,function(input,processed)
		if busy or processed or UserInputService:GetFocusedTextBox() then return end
		if input.KeyCode==Enum.KeyCode.M or input.KeyCode==Enum.KeyCode.ButtonY then toggleTray()
		elseif input.KeyCode==Enum.KeyCode.B or input.KeyCode==Enum.KeyCode.ButtonB then
			if tray then closeTray() elseif not busy then go(table.remove(history) or "HomeInterior",true) end
		end
	end)
	lifetime:Connect(gui.Destroying,function()
		closeTray()
		if pageScope then pageScope:Destroy() end
		lifetime:Destroy()
		pending=nil
		busy=false
		UI.inputLocked=false
		state.menuInputLocked=false
	end)
	render()
	return {state=state,go=go,destroy=function() gui:Destroy() end}
end
return App
