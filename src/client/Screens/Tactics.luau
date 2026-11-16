--!nonstrict
local UI=require(script.Parent.Parent.UI)
local Data=require(game:GetService("ReplicatedStorage").CL27.Data)
local Catalog=require(game:GetService("ReplicatedStorage").CL27.TacticsCatalog)
local Model=require(game:GetService("ReplicatedStorage").CL27.TacticsModel)
local Session=require(game:GetService("ReplicatedStorage").CL27.TacticsSession)
local Controls=require(script.Parent.TacticsControls)
local PitchView=require(script.Parent.TacticsPitch)
local C=Controls.colors

return function(root,ctx)
	local state,scope=ctx.state,ctx.scope
	if ctx.playerGui then
		local previous=ctx.playerGui.ScreenOrientation
		ctx.playerGui.ScreenOrientation=Enum.ScreenOrientation.LandscapeSensor
		scope:Add(function() ctx.playerGui.ScreenOrientation=previous end)
	end
	local roster=Data.players
	local session,err=Session.new(state,roster)
	if not session then ctx.notify(err);return end
	local selected="gk"
	local phase="without_ball"
	local tab="team"
	local refresh,resize
	local scale=1
	local background=UI.frame(root,0,0,1600,839,Color3.new(1,1,1),0)
	UI.gradient(background,{C.ink,Color3.fromRGB(18,26,22),C.ink},20)
	-- Static, restrained stadium light: no imported graphics or repeating FX.
	for i=1,3 do
		local light=UI.frame(background,640+i*225,-70,50,380,C.white,.98)
		light.Rotation=32
	end
	UI.logo(root,56,39,.65)
	Controls.text(root,"EDITOR DE TÁTICAS",228,36,660,36,28,C.white,true)
	Controls.text(root,"CLUB LEGACY 27  /  PLANO DE JOGO",230,74,660,24,15,C.muted)
	local squad=Controls.button(root,"AbrirElenco",function() ctx.go("Squad") end,scope)
	squad.Position=UDim2.fromOffset(1282,36);squad.Size=UDim2.fromOffset(262,58)
	local squadLabel=Controls.text(squad,"ELENCO  ›",12,0,238,58,22,C.white,true)
	squadLabel.TextXAlignment=Enum.TextXAlignment.Center
	UI.line(root,56,112,1544,112,C.border,1)
	Controls.text(root,"Tática 1",56,127,310,48,39,C.white,true)
	local active=Controls.text(root,"",56,172,524,28,18,C.green)
	active.Name="TaticaAtiva"
	local withBall=Controls.button(root,"FaseComBola",function() phase="with_ball";refresh(true) end,scope)
	local withoutBall=Controls.button(root,"FaseSemBola",function() phase="without_ball";refresh(true) end,scope)
	local withLabel=Controls.text(withBall,"COM A BOLA",10,0,430,56,23,C.white,true)
	local withoutLabel=Controls.text(withoutBall,"SEM A BOLA",10,0,430,56,23,C.white,true)
	withLabel.TextXAlignment=Enum.TextXAlignment.Center;withoutLabel.TextXAlignment=Enum.TextXAlignment.Center
	local presetButton=Controls.button(root,"Predefinicao",function()
		local current=Model.preset(session.draft).id
		local index=0
		for i,p in ipairs(Catalog.presets) do if p.id==current then index=i end end
		session:preset(Catalog.presets[index%#Catalog.presets+1].id);refresh()
	end,scope)
	presetButton.Position=UDim2.fromOffset(56,212);presetButton.Size=UDim2.fromOffset(524,144)
	presetButton.BackgroundColor3=C.white
	Controls.text(presetButton,"PREDEFINIÇÃO TÁTICA",18,8,458,24,17,C.ink,true)
	local presetName=Controls.text(presetButton,"",18,34,466,40,29,C.ink,true)
	local presetDescription=Controls.text(presetButton,"",18,77,470,58,20,Color3.fromRGB(57,65,59))
	Controls.text(presetButton,"›",481,33,26,40,33,C.ink,true)
	local teamTab=Controls.button(root,"AbaEquipe",function() tab="team";refresh() end,scope)
	local playerTab=Controls.button(root,"AbaAtleta",function() tab="player";refresh() end,scope)
	local teamTabText=Controls.text(teamTab,"EQUIPE",0,0,254,56,22,C.white,true)
	local playerTabText=Controls.text(playerTab,"ATLETA",0,0,254,56,22,C.white,true)
	teamTabText.TextXAlignment=Enum.TextXAlignment.Center;playerTabText.TextXAlignment=Enum.TextXAlignment.Center
	local function scroll(name,parent)
		return UI.new("ScrollingFrame",{Name=name,BackgroundTransparency=1,BorderSizePixel=0,
			ScrollBarThickness=4,ScrollBarImageColor3=C.green,CanvasSize=UDim2.fromOffset(0,0),
			CanvasPosition=Vector2.new(0,0),ScrollingDirection=Enum.ScrollingDirection.Y,
			ClipsDescendants=true,Active=true},parent)
	end
	local teamScroll=scroll("ControlesColetivos",root)
	local playerScroll=scroll("InstrucoesIndividuais",root)
	local pitchScroll=scroll("CampoTaticoRolavel",root)
	pitchScroll.ScrollingDirection=Enum.ScrollingDirection.XY
	local pitchContent=UI.frame(pitchScroll,0,0,920,730,C.ink,1)
	local pitchScale=UI.new("UIScale",{Scale=1},pitchContent)
	local pitch=PitchView.create(pitchContent,scope,function(id)
		selected=id;tab="player";playerScroll.CanvasPosition=Vector2.new(0,0);refresh()
	end)
	local rows={}
		local function cycleFormation()
		local index=table.find(Catalog.formationOrder,session.draft.formationId) or 1
		local changed=false
		for step=1,#Catalog.formationOrder-1 do
			local id=Catalog.formationOrder[(index+step-1)%#Catalog.formationOrder+1]
			local ok=session:formation(id)
			if ok then changed=true;break end
		end
		if not changed then ctx.notify("Nenhuma outra formação é compatível com o elenco disponível.");return end
		if not session.draft.positions[selected] then selected="gk" end
		refresh()
	end
	rows[1]=Controls.row(teamScroll,"SelecionarFormacao","FORMAÇÃO",cycleFormation,scope)
	for _,entry in ipairs({{"buildUp","CONSTRUÇÃO OFENSIVA"},{"pressure","PRESSÃO DEFENSIVA"},{"mentality","MENTALIDADE"}}) do
		local key,label=entry[1],entry[2]
		table.insert(rows,Controls.row(teamScroll,"Estrategia_"..key,label,function()
			local values=Catalog.options[key]
			for i,value in ipairs(values) do
				if value.id==session.draft[key] then session:strategy(key,values[i%#values+1].id);break end
			end
			refresh()
		end,scope))
	end
	-- Discrete steps have explicit values and can be reached with touch or ButtonA.
	for _,entry in ipairs({{"width","AMPLITUDE"},{"line","ALTURA DA LINHA"}}) do
		local key,label=entry[1],entry[2]
		local row=Controls.row(teamScroll,"Estrategia_"..key,label,function()
			session:strategy(key,math.min(90,session.draft[key]+5));refresh()
		end,scope)
		local minus=Controls.button(teamScroll,"Diminuir_"..key,function()
			session:strategy(key,math.max(10,session.draft[key]-5));refresh()
		end,scope)
		local sign=Controls.text(minus,"−",0,0,70,70,30,C.white,true)
		sign.TextXAlignment=Enum.TextXAlignment.Center
		row.minus=minus;row.sign=sign
		table.insert(rows,row)
	end
	local playerName=Controls.text(playerScroll,"",8,0,500,64,27,C.white,true)
	playerName.Name="AtletaSelecionado"
	local roleRow=Controls.row(playerScroll,"SelecionarFuncao","FUNÇÃO",function()
		local s=Model.slot(session.draft,selected)
		local options=Catalog.groupRoles[s.group]
		local current=session.draft.positions[selected].roleId
		session:role(selected,options[(table.find(options,current) or 1)%#options+1]);refresh()
	end,scope)
	local behaviorRow=Controls.row(playerScroll,"SelecionarComportamento","COMPORTAMENTO",function()
		local e=session.draft.positions[selected]
		local options=Catalog.roles[e.roleId].behaviors
		session:behavior(selected,options[(table.find(options,e.behaviorId) or 1)%#options+1]);refresh()
	end,scope)
	local individualHint=Controls.text(playerScroll,"",12,300,490,110,22,C.muted)
	local save=Controls.button(root,"SalvarTatica",function()
		local ok,message=session:save()
		ctx.notify(if ok then "Tática confirmada nesta sessão." else message)
		refresh()
	end,scope,true)
	local saveLabel=Controls.text(save,"SALVAR ALTERAÇÕES",8,0,320,64,23,C.ink,true)
	saveLabel.TextXAlignment=Enum.TextXAlignment.Center
	local cancel=Controls.button(root,"CancelarTatica",function() session:cancel();selected="gk";refresh();ctx.notify("Alterações canceladas.") end,scope)
	local cancelLabel=Controls.text(cancel,"CANCELAR",6,0,174,64,21,C.white,true)
	cancelLabel.TextXAlignment=Enum.TextXAlignment.Center
	local hint=Controls.text(root,"",612,114,660,22,16,C.muted)
	local advantagesTitle=Controls.text(pitchContent,"PONTOS FORTES",8,522,430,27,20,C.green,true)
	local risksTitle=Controls.text(pitchContent,"PONTOS DE ATENÇÃO",476,522,430,27,20,C.warning,true)
	local advantageLabels,riskLabels={},{}
	for i=1,8 do
		advantageLabels[i]=Controls.text(pitchContent,"",8,550+(i-1)*52,430,50,20,C.white)
		riskLabels[i]=Controls.text(pitchContent,"",476,550+(i-1)*52,430,50,20,C.muted)
	end
	local indicatorCount=1
	local lastTab=tab
	resize=function()
		local canvas=root.Parent
		local fitted=canvas and canvas:FindFirstChild("UIScale")
		scale=if fitted then math.max(.2,fitted.Scale) else 1
		local touch=math.max(56,44/scale)
		local rowHeight=math.max(82,56/scale)
		squad.Size=UDim2.fromOffset(262,touch);squadLabel.Size=UDim2.fromOffset(238,touch)
		squadLabel.TextSize=math.max(22,12/scale)
		active.TextSize=math.max(18,9/scale)
		presetName.TextSize=math.max(29,12/scale)
		presetDescription.TextSize=math.max(20,10/scale)
		presetDescription.Position=UDim2.fromOffset(18,74)
		presetDescription.Size=UDim2.fromOffset(470,66)
		local currentPreset=Model.preset(session.draft)
		presetDescription.Text=if scale<.65 then (currentPreset.shortDescription or "Confira apoios e riscos no campo.") else currentPreset.description
		local phaseY=math.max(140,48+touch)
		teamTab.Position=UDim2.fromOffset(56,368);teamTab.Size=UDim2.fromOffset(254,touch)
		playerTab.Position=UDim2.fromOffset(326,368);playerTab.Size=UDim2.fromOffset(254,touch)
		teamTabText.Size=UDim2.fromOffset(254,touch);playerTabText.Size=UDim2.fromOffset(254,touch)
		withBall.Position=UDim2.fromOffset(612,phaseY);withBall.Size=UDim2.fromOffset(454,touch)
		withoutBall.Position=UDim2.fromOffset(1082,phaseY);withoutBall.Size=UDim2.fromOffset(462,touch)
		withLabel.Size=UDim2.fromOffset(434,touch);withoutLabel.Size=UDim2.fromOffset(442,touch)
		for _,label in ipairs({teamTabText,playerTabText,withLabel,withoutLabel}) do label.TextSize=math.max(22,12/scale) end
		local actionHeight=math.max(64,44/scale)
		save.Position=UDim2.fromOffset(56,826-actionHeight);save.Size=UDim2.fromOffset(330,actionHeight)
		cancel.Position=UDim2.fromOffset(398,826-actionHeight);cancel.Size=UDim2.fromOffset(182,actionHeight)
		saveLabel.Size=UDim2.fromOffset(314,actionHeight);cancelLabel.Size=UDim2.fromOffset(170,actionHeight)
		saveLabel.TextSize=math.max(23,11/scale);cancelLabel.TextSize=math.max(21,11/scale)
		local controlsY=380+touch
		for _,sc in ipairs({teamScroll,playerScroll}) do
			sc.Position=UDim2.fromOffset(56,controlsY)
			sc.Size=UDim2.fromOffset(524,826-actionHeight-controlsY-12)
		end
		for i,row in ipairs(rows) do
			Controls.rowSize(row,(i-1)*rowHeight,rowHeight,scale)
			if row.minus then
				local minusWidth=math.max(70,44/scale)
				row.button.Size=UDim2.fromOffset(508-minusWidth,rowHeight-8)
				row.caption.Size=UDim2.fromOffset(476-minusWidth,(rowHeight-8)*.4)
				row.value.Size=UDim2.fromOffset(476-minusWidth,(rowHeight-8)*.55)
				row.arrow.Visible=false
				row.minus.Position=UDim2.fromOffset(516-minusWidth,(i-1)*rowHeight)
				row.minus.Size=UDim2.fromOffset(minusWidth,rowHeight-8)
				row.sign.Size=UDim2.fromOffset(minusWidth,rowHeight-8)
			end
		end
		teamScroll.CanvasSize=UDim2.fromOffset(0,#rows*rowHeight)
		local nameHeight=math.max(64,35/scale)
		playerName.Size=UDim2.fromOffset(500,nameHeight);playerName.TextSize=math.max(27,12/scale)
		Controls.rowSize(roleRow,nameHeight+8,rowHeight,scale)
		Controls.rowSize(behaviorRow,nameHeight+8+rowHeight,rowHeight,scale)
		individualHint.Position=UDim2.fromOffset(12,nameHeight+18+rowHeight*2)
		individualHint.Size=UDim2.fromOffset(490,math.max(110,80/scale));individualHint.TextSize=math.max(22,12/scale)
		playerScroll.CanvasSize=UDim2.fromOffset(0,nameHeight+28+rowHeight*2+math.max(110,80/scale))
		-- Magnify uniformly on compact Android displays; scroll instead of distorting.
		local zoom=math.max(1,.65/scale)
		pitchScale.Scale=zoom
		local fieldY=phaseY+14+touch
		pitchScroll.Position=UDim2.fromOffset(612,fieldY);pitchScroll.Size=UDim2.fromOffset(932,826-fieldY)
		pitchScroll.CanvasSize=UDim2.fromOffset(920*zoom,(554+indicatorCount*52)*zoom)
		hint.Text=if zoom>1 then "Arraste o campo • toque em um atleta para ajustar" else "Prévia de organização • selecione um atleta • sem simulação de partida"
		-- Clamp after shrinking content on resize or changing strategy.
		for _,sc in ipairs({teamScroll,playerScroll,pitchScroll}) do
			local at=sc.CanvasPosition
			sc.CanvasPosition=Vector2.new(math.clamp(at.X,0,math.max(0,sc.CanvasSize.X.Offset-sc.Size.X.Offset)),
				math.clamp(at.Y,0,math.max(0,sc.CanvasSize.Y.Offset-sc.Size.Y.Offset)))
		end
	end
	refresh=function(animate)
		local draft=session.draft
		local preset=Model.preset(draft)
		presetName.Text=preset.label;presetDescription.Text=preset.description
		active.Text=Catalog.formations[session.store.active.formationId].label.."  •  "..(if session:dirty() then "ALTERAÇÕES PENDENTES" else "ATIVA NESTA SESSÃO")
		rows[1].value.Text=Catalog.formations[draft.formationId].label
		rows[2].value.Text=Model.option("buildUp",draft.buildUp).label
		rows[3].value.Text=Model.option("pressure",draft.pressure).label
		rows[4].value.Text=Model.option("mentality",draft.mentality).label
		rows[5].value.Text=tostring(draft.width).." / 100   •   +5"
		rows[6].value.Text=tostring(draft.line).." / 100   •   +5"
		teamScroll.Visible=tab=="team";playerScroll.Visible=tab=="player"
		save.NextSelectionUp=if tab=="team" then rows[#rows].button else behaviorRow.button
		cancel.NextSelectionUp=save.NextSelectionUp
		teamTab.BackgroundColor3=if tab=="team" then Color3.fromRGB(46,61,41) else C.panel
		playerTab.BackgroundColor3=if tab=="player" then Color3.fromRGB(46,61,41) else C.panel
		withBall.BackgroundColor3=if phase=="with_ball" then Color3.fromRGB(46,61,41) else C.panel
		withoutBall.BackgroundColor3=if phase=="without_ball" then Color3.fromRGB(46,61,41) else C.panel
		withLabel.TextColor3=if phase=="with_ball" then C.green else C.muted
		withoutLabel.TextColor3=if phase=="without_ball" then C.green else C.muted
		if lastTab~=tab then lastTab=tab;playerScroll.CanvasPosition=Vector2.new(0,0) end
		local e=draft.positions[selected]
		local p=Model.player(roster,e.playerId)
		playerName.Text=p.shortName.."  /  "..Model.slot(draft,selected).label
		roleRow.value.Text=Catalog.roles[e.roleId].label
		behaviorRow.value.Text=Catalog.behaviors[e.behaviorId].label
		individualHint.Text="A função define avanço, ocupação dos corredores e pressão. O comportamento ajusta o apoio. Compare as duas fases no campo."
		pitch:update(draft,phase,selected,animate==true)
		for _,card in ipairs(pitch.cards) do
			if not card.button.NextSelectionLeft then card.button.NextSelectionLeft=if tab=="team" then rows[1].button else roleRow.button end
			if not card.button.NextSelectionUp then card.button.NextSelectionUp=withBall end
			if not card.button.NextSelectionDown then card.button.NextSelectionDown=save end
		end
		local indicators=Model.indicators(draft)
		indicatorCount=math.max(#indicators.advantages,#indicators.risks)
		for i=1,8 do
			advantageLabels[i].Visible=indicators.advantages[i]~=nil
			riskLabels[i].Visible=indicators.risks[i]~=nil
			advantageLabels[i].Text=if indicators.advantages[i] then "+  "..indicators.advantages[i].text else ""
			riskLabels[i].Text=if indicators.risks[i] then "!  "..indicators.risks[i].text else ""
		end
		resize()
	end
	local canvasScale=root.Parent and root.Parent:FindFirstChild("UIScale")
	if canvasScale then scope:Connect(canvasScale:GetPropertyChangedSignal("Scale"),resize) end
	for _,row in ipairs(rows) do
		Controls.reveal(teamScroll,row.button,nil,scope)
		if row.minus then Controls.reveal(teamScroll,row.minus,nil,scope) end
	end
	Controls.reveal(playerScroll,roleRow.button,nil,scope)
	Controls.reveal(playerScroll,behaviorRow.button,nil,scope)
	for _,card in ipairs(pitch.cards) do Controls.reveal(pitchScroll,card.button,function() return pitchScale.Scale end,scope) end
	-- Destroying the page abandons this draft. Only Save writes to active.
	refresh()
	for i,row in ipairs(rows) do
		row.button.NextSelectionUp=if i==1 then teamTab else rows[i-1].button
		row.button.NextSelectionDown=if i==#rows then save else rows[i+1].button
		row.button.NextSelectionRight=pitch.cards[1].button
	end
	teamTab.NextSelectionDown=rows[1].button;playerTab.NextSelectionDown=roleRow.button
	teamTab.NextSelectionUp=presetButton;playerTab.NextSelectionUp=presetButton
	teamTab.NextSelectionRight=playerTab;playerTab.NextSelectionLeft=teamTab
	presetButton.NextSelectionDown=teamTab;presetButton.NextSelectionUp=squad
	presetButton.NextSelectionRight=withBall
	squad.NextSelectionDown=withoutBall;squad.NextSelectionLeft=presetButton
	withBall.NextSelectionLeft=teamTab;withBall.NextSelectionRight=withoutBall
	withoutBall.NextSelectionLeft=withBall
	withBall.NextSelectionDown=pitch.cards[1].button;withoutBall.NextSelectionDown=pitch.cards[1].button
	for _,row in ipairs(rows) do
		if not row.minus then continue end
		row.button.NextSelectionRight=row.minus;row.minus.NextSelectionLeft=row.button
		row.minus.NextSelectionUp=row.button.NextSelectionUp;row.minus.NextSelectionDown=row.button.NextSelectionDown
		row.minus.NextSelectionRight=pitch.cards[1].button
	end
	roleRow.button.NextSelectionUp=playerTab;roleRow.button.NextSelectionDown=behaviorRow.button
	behaviorRow.button.NextSelectionUp=roleRow.button;behaviorRow.button.NextSelectionDown=save
	save.NextSelectionRight=cancel;cancel.NextSelectionLeft=save
end
