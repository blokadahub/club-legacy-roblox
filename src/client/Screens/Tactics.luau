--!nonstrict
local GuiService=game:GetService("GuiService")
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
	local selected,phase,tab="gk","without_ball","team"
	local lastFormation=nil
	local scale,compact=1,false
	local refresh,resize,openDetail,closeDetail
	local mode,focusBefore=nil,nil
	local mainButtons,modalRows={},{}
	local function button(parent,name,callback,primary)
		local b=Controls.button(parent,name,callback,scope,primary)
		table.insert(mainButtons,b)
		return b
	end
	local function scroll(name,parent)
		return UI.new("ScrollingFrame",{Name=name,BackgroundTransparency=1,BorderSizePixel=0,
			ScrollBarThickness=3,ScrollBarImageColor3=C.muted,CanvasSize=UDim2.fromOffset(0,0),
			CanvasPosition=Vector2.new(),ScrollingDirection=Enum.ScrollingDirection.Y,
			ClipsDescendants=true,Active=true},parent)
	end
	local function label(parent,value,x,y,w,h,size,color,bold)
		return Controls.text(parent,value,x,y,w,h,size,color,bold)
	end
	local background=UI.frame(root,0,0,1600,839,Color3.new(1,1,1),0)
	UI.gradient(background,{C.ink,Color3.fromRGB(22,27,26),C.ink},20)
	for i=1,3 do
		local light=UI.frame(background,640+i*225,-70,50,380,C.white,.98);light.Rotation=32
	end
	UI.logo(root,56,39,.65)
	local pageHeading=label(root,"EDITOR DE TÁTICAS",228,36,660,36,28,C.white,true)
	local pageSubtitle=label(root,"CLUB LEGACY 27  /  PLANO DE JOGO",230,74,660,24,15,C.muted)
	local squad=button(root,"AbrirElenco",function() ctx.go("Squad") end)
	squad.Position=UDim2.fromOffset(1282,36)
	local squadLabel=label(squad,"ELENCO  ›",12,0,238,58,22,C.white,true)
	squadLabel.TextXAlignment=Enum.TextXAlignment.Center
	UI.line(root,56,112,1544,112,C.border,1)
	local title=label(root,"Tática 1",56,127,524,48,39,C.white,true)
	local active=label(root,"",56,172,524,28,18,C.green);active.Name="TaticaAtiva"
	local withBall=button(root,"FaseComBola",function() phase="with_ball";refresh(true) end)
	local withoutBall=button(root,"FaseSemBola",function() phase="without_ball";refresh(true) end)
	local withLabel=label(withBall,"COM A BOLA",10,0,430,56,23,C.white,true)
	local withoutLabel=label(withoutBall,"SEM A BOLA",10,0,430,56,23,C.white,true)
	withLabel.TextXAlignment=Enum.TextXAlignment.Center;withoutLabel.TextXAlignment=Enum.TextXAlignment.Center
	local presetButton=button(root,"Predefinicao",function()
		local current=Model.preset(session.draft).id
		local index=0
		for i,p in ipairs(Catalog.presets) do if p.id==current then index=i end end
		session:preset(Catalog.presets[index%#Catalog.presets+1].id);refresh()
	end)
	presetButton.BackgroundColor3=C.white
	local presetCaption=label(presetButton,"PREDEFINIÇÃO TÁTICA",20,12,470,24,17,C.ink,true)
	local presetName=label(presetButton,"",20,43,450,44,31,C.ink,true)
	local presetDescription=label(presetButton,"",20,95,350,88,20,Color3.fromRGB(57,65,59))
	local presetBadge=UI.badge(presetButton,Data.clubs[state.homeClub or 1],416,107,66)
	local presetArrow=label(presetButton,"›",477,43,28,44,34,C.ink,true)
	local teamTab=button(root,"AbaEquipe",function() tab="team";refresh() end)
	local playerTab=button(root,"AbaAtleta",function() tab="player";refresh() end)
	local teamTabText=label(teamTab,"EQUIPE",0,0,254,56,22,C.white,true)
	local playerTabText=label(playerTab,"ATLETA",0,0,254,56,22,C.white,true)
	teamTabText.TextXAlignment=Enum.TextXAlignment.Center;playerTabText.TextXAlignment=Enum.TextXAlignment.Center
	local teamScroll=scroll("ControlesColetivos",root)
	local playerScroll=scroll("InstrucoesIndividuais",root)
	-- The board fits as a whole. Text details move to a large picker on phones.
	local pitchScroll=scroll("CampoTaticoRolavel",root);pitchScroll.ScrollingEnabled=false
	local pitchContent=UI.new("CanvasGroup",{Name="ConteudoCampoTatico",BackgroundTransparency=1,
		Position=UDim2.fromOffset(0,0),Size=UDim2.fromOffset(920,510),GroupTransparency=0},pitchScroll)
	local pitchScale=UI.new("UIScale",{Scale=1},pitchContent)
	local pitch=PitchView.create(pitchContent,scope,function(id)
		selected=id;tab="player";playerScroll.CanvasPosition=Vector2.new();refresh()
	end,Data.clubs[state.homeClub or 1])
	for _,card in ipairs(pitch.cards) do table.insert(mainButtons,card.button) end
	local openPitch=button(root,"AbrirAtletasCompacto",function() openDetail("roster") end)
	openPitch.BackgroundTransparency=1
	local pitchHint=label(openPitch,"ESCOLHER ATLETA  ›",0,0,932,48,22,C.white,true)
	pitchHint.TextXAlignment=Enum.TextXAlignment.Center
	local rows={}
	local function cycleFormation()
		local index=table.find(Catalog.formationOrder,session.draft.formationId) or 1
		local changed=false
		for step=1,#Catalog.formationOrder-1 do
			if session:formation(Catalog.formationOrder[(index+step-1)%#Catalog.formationOrder+1]) then changed=true;break end
		end
		if not changed then ctx.notify("Nenhuma outra formação é compatível com o elenco disponível.");return end
		if not session.draft.positions[selected] then selected="gk" end
		refresh()
	end
	rows[1]=Controls.row(teamScroll,"SelecionarFormacao","FORMAÇÃO",cycleFormation,scope)
	for _,entry in ipairs({{"buildUp","CONSTRUÇÃO"},{"pressure","PRESSÃO"},{"mentality","MENTALIDADE"}}) do
		local key,caption=entry[1],entry[2]
		table.insert(rows,Controls.row(teamScroll,"Estrategia_"..key,caption,function()
			local values=Catalog.options[key]
			for i,value in ipairs(values) do
				if value.id==session.draft[key] then session:strategy(key,values[i%#values+1].id);break end
			end
			refresh()
		end,scope))
	end
	for _,entry in ipairs({{"width","AMPLITUDE"},{"line","ALTURA DA LINHA"}}) do
		local key,caption=entry[1],entry[2]
		local row=Controls.row(teamScroll,"Estrategia_"..key,caption,function()
			session:strategy(key,math.min(90,session.draft[key]+5));refresh()
		end,scope)
		row.key=key
		row.minus=button(teamScroll,"Diminuir_"..key,function()
			session:strategy(key,math.max(10,session.draft[key]-5));refresh()
		end)
		row.sign=label(row.minus,"−",0,0,70,70,30,C.white,true);row.sign.TextXAlignment=Enum.TextXAlignment.Center
		row.track=UI.frame(row.button,12,68,380,2,C.border,.4)
		row.fill=UI.frame(row.track,0,0,1,2,C.green,0);row.fill.Name="ValorTatico"
		table.insert(rows,row)
	end
	for _,row in ipairs(rows) do table.insert(mainButtons,row.button) end
	local playerName=label(playerScroll,"",8,0,500,64,27,C.white,true);playerName.Name="AtletaSelecionado"
	local roleRow=Controls.row(playerScroll,"SelecionarFuncao","FUNÇÃO",function()
		local slot=Model.slot(session.draft,selected)
		local options=Catalog.groupRoles[slot.group]
		local current=session.draft.positions[selected].roleId
		session:role(selected,options[(table.find(options,current) or 1)%#options+1]);refresh()
	end,scope)
	local behaviorRow=Controls.row(playerScroll,"SelecionarComportamento","COMPORTAMENTO",function()
		local entry=session.draft.positions[selected]
		local options=Catalog.roles[entry.roleId].behaviors
		session:behavior(selected,options[(table.find(options,entry.behaviorId) or 1)%#options+1]);refresh()
	end,scope)
	table.insert(mainButtons,roleRow.button);table.insert(mainButtons,behaviorRow.button)
	local individualHint=label(playerScroll,"",12,300,490,110,22,C.muted)
	local save=button(root,"SalvarTatica",function()
		local ok,message=session:save()
		ctx.notify(if ok then "Tática confirmada nesta sessão." else message);refresh()
	end,true)
	local saveLabel=label(save,"SALVAR ALTERAÇÕES",8,0,314,64,23,C.ink,true);saveLabel.TextXAlignment=Enum.TextXAlignment.Center
	local cancel=button(root,"CancelarTatica",function() session:cancel();selected="gk";refresh();ctx.notify("Alterações canceladas.") end)
	local cancelLabel=label(cancel,"CANCELAR",6,0,170,64,21,C.white,true);cancelLabel.TextXAlignment=Enum.TextXAlignment.Center
	local hint=label(root,"Prévia de organização • sem simulação de partida",612,114,650,22,16,C.muted)
	local analysis=scroll("AnaliseTatica",root)
	local advantagesTitle=label(analysis,"PONTOS FORTES",8,4,430,27,18,C.green,true)
	local risksTitle=label(analysis,"PONTOS DE ATENÇÃO",476,4,348,27,18,C.warning,true)
	local advantageLabels,riskLabels={},{ }
	for i=1,8 do
		advantageLabels[i]=label(analysis,"",8,36+(i-1)*48,430,46,19,C.white)
		riskLabels[i]=label(analysis,"",476,36+(i-1)*48,348,46,19,C.muted)
	end
	local analysisButton=button(root,"AbrirAnalise",function() openDetail("analysis") end)
	local analysisLabel=label(analysisButton,"",18,0,896,64,23,C.white,true)
	-- Reusable contextual layer, kept inside the safe canvas. No page rebuild.
	local overlay=UI.new("CanvasGroup",{Name="FichaTatica",Visible=false,Active=true,
		BackgroundColor3=C.ink,BackgroundTransparency=.02,BorderSizePixel=0,GroupTransparency=0,
		Position=UDim2.fromOffset(56,132),Size=UDim2.fromOffset(1488,694),ZIndex=20},root)
	UI.stroke(overlay,C.border,.15,1)
	UI.frame(overlay,24,0,1440,2,C.green,.25)
	local detailTitle=label(overlay,"",24,16,1050,56,32,C.white,true)
	local close=Controls.button(overlay,"FecharFichaTatica",function() closeDetail() end,scope)
	local closeLabel=label(close,"VOLTAR",0,0,330,56,23,C.white,true);closeLabel.TextXAlignment=Enum.TextXAlignment.Center
	local detailScroll=scroll("ConteudoFichaTatica",overlay)
	for i=1,11 do
		local row={}
		row.button=Controls.button(detailScroll,"EscolherAtleta_"..i,function()
			selected=row.slotId;tab="player";playerScroll.CanvasPosition=Vector2.new();closeDetail();refresh()
			GuiService.SelectedObject=roleRow.button
		end,scope)
		row.name=label(row.button,"",20,0,650,60,25,C.white,true)
		row.role=label(row.button,"",690,0,690,60,22,C.muted)
		row.button.BackgroundTransparency=1;row.button:SetAttribute("QuietOutline",true)
		UI.frame(row.button,12,0,1370,1,C.border,.5)
		Controls.reveal(detailScroll,row.button,nil,scope)
		modalRows[i]=row
	end
	local detailAnalysis=label(detailScroll,"",20,0,1364,600,26,C.white)
	detailAnalysis.Name="RelatorioTatico";detailAnalysis.TextYAlignment=Enum.TextYAlignment.Top
	local indicators=Model.indicators(session.draft)
	local function syncButtons()
		for _,b in ipairs(mainButtons) do b.Active=not mode;b.Selectable=not mode end
		for _,card in ipairs(pitch.cards) do card.button.Active=not mode and not compact;card.button.Selectable=card.button.Active end
		openPitch.Active=not mode and compact;openPitch.Selectable=openPitch.Active
		for _,row in ipairs(rows) do
			if row.key then
				row.button.Active=not mode and session.draft[row.key]<90;row.button.Selectable=row.button.Active
				row.minus.Active=not mode and session.draft[row.key]>10;row.minus.Selectable=row.minus.Active
				row.sign.TextColor3=if row.minus.Active then C.white else C.muted
			end
		end
	end
	openDetail=function(nextMode)
		if not mode then focusBefore=GuiService.SelectedObject end
		mode=nextMode;detailScroll.CanvasPosition=Vector2.new()
		Controls.present(overlay,scope,true);refresh()
		GuiService.SelectedObject=if mode=="roster" then modalRows[1].button else close
	end
	closeDetail=function()
		mode=nil;Controls.present(overlay,scope,false);refresh()
		if focusBefore and focusBefore.Parent and focusBefore.Selectable then GuiService.SelectedObject=focusBefore
		else GuiService.SelectedObject=if compact then openPitch else pitch.cards[1].button end
	end
	resize=function()
		local fitted=root.Parent and root.Parent:FindFirstChild("UIScale")
		scale=if fitted then math.max(.2,fitted.Scale) else 1;compact=scale<.65
		local touch=math.max(56,44/scale)
		local rowHeight=math.max(82,44/scale+8)
		local actionHeight=math.max(64,44/scale)
		pageHeading.TextSize=math.max(28,12/scale);pageHeading.Size=UDim2.fromOffset(660,math.max(36,15/scale))
		pageSubtitle.Visible=not compact
		squad.Size=UDim2.fromOffset(262,touch);squadLabel.Size=UDim2.fromOffset(238,touch);squadLabel.TextSize=math.max(22,12/scale)
		active.Visible=not compact
		title.Visible=not compact
		presetCaption.Text=if compact then "TÁTICA 1 / PREDEFINIÇÃO" else "PREDEFINIÇÃO TÁTICA"
		local presetY=if compact then 140 else 212
		local presetHeight=if compact then math.max(144,touch) else 200
		presetButton.Position=UDim2.fromOffset(56,presetY);presetButton.Size=UDim2.fromOffset(524,presetHeight)
		presetCaption.TextSize=math.max(17,9/scale);presetCaption.Size=UDim2.fromOffset(470,if compact then presetHeight*.28-8 else 24)
		presetName.TextSize=math.max(31,12/scale);presetName.Position=UDim2.fromOffset(20,if compact then presetHeight*.28+8 else 43)
		presetName.Size=UDim2.fromOffset(450,if compact then presetHeight*.66 else 44)
		presetArrow.Position=UDim2.fromOffset(477,if compact then presetHeight*.28+8 else 43);presetArrow.Size=UDim2.fromOffset(28,if compact then presetHeight*.66 else 44)
		presetDescription.Visible=not compact;presetBadge.Visible=not compact
		local tabsY=presetY+presetHeight+12
		teamTab.Position=UDim2.fromOffset(56,tabsY);teamTab.Size=UDim2.fromOffset(254,touch)
		playerTab.Position=UDim2.fromOffset(326,tabsY);playerTab.Size=UDim2.fromOffset(254,touch)
		teamTabText.Size=UDim2.fromOffset(254,touch);playerTabText.Size=UDim2.fromOffset(254,touch)
		local phaseY=math.max(140,48+touch)
		withBall.Position=UDim2.fromOffset(612,phaseY);withBall.Size=UDim2.fromOffset(454,touch)
		withoutBall.Position=UDim2.fromOffset(1082,phaseY);withoutBall.Size=UDim2.fromOffset(462,touch)
		withLabel.Size=UDim2.fromOffset(434,touch);withoutLabel.Size=UDim2.fromOffset(442,touch)
		for _,text in ipairs({teamTabText,playerTabText,withLabel,withoutLabel}) do text.TextSize=math.max(22,12/scale) end
		save.Position=UDim2.fromOffset(56,826-actionHeight);save.Size=UDim2.fromOffset(330,actionHeight)
		cancel.Position=UDim2.fromOffset(398,826-actionHeight);cancel.Size=UDim2.fromOffset(182,actionHeight)
		saveLabel.Size=UDim2.fromOffset(314,actionHeight);cancelLabel.Size=UDim2.fromOffset(170,actionHeight)
		saveLabel.TextSize=math.max(23,11/scale);cancelLabel.TextSize=math.max(21,11/scale)
		local controlsY=tabsY+touch+8
		for _,sc in ipairs({teamScroll,playerScroll}) do sc.Position=UDim2.fromOffset(56,controlsY);sc.Size=UDim2.fromOffset(524,826-actionHeight-controlsY-12) end
		for i,row in ipairs(rows) do
			local minusWidth=if row.minus then math.max(70,44/scale) else 0
			local width=if row.minus then 508-minusWidth else 516
			Controls.rowSize(row,(i-1)*rowHeight,rowHeight,scale,width)
			if row.minus then
				row.arrow.Visible=false
				row.minus.Position=UDim2.fromOffset(516-minusWidth,(i-1)*rowHeight);row.minus.Size=UDim2.fromOffset(minusWidth,rowHeight-8)
				row.sign.Size=UDim2.fromOffset(minusWidth,rowHeight-8)
				row.track.Position=UDim2.fromOffset(12,rowHeight-13);row.track.Size=UDim2.fromOffset(width-24,2)
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
		local fieldY=phaseY+14+touch
		local analysisHeight=if compact then touch else 152
		local analysisY=826-analysisHeight
		local fieldHeight=analysisY-fieldY-12
		local boardHeight=fieldHeight-(if compact then math.max(48,14/scale) else 0)
		local fit=math.min(932/920,boardHeight/510)
		pitchScale.Scale=fit
		pitchScroll.Position=UDim2.fromOffset(612,fieldY);pitchScroll.Size=UDim2.fromOffset(932,fieldHeight)
		pitchContent.Position=UDim2.fromOffset((932-920*fit)/2,(if compact then math.max(48,14/scale) else 0))
		pitchScroll.CanvasSize=UDim2.fromOffset(0,0);pitchScroll.CanvasPosition=Vector2.new()
		pitch:compact(compact,scale*fit)
		openPitch.Visible=compact;openPitch.Position=pitchScroll.Position;openPitch.Size=pitchScroll.Size
		pitchHint.Size=UDim2.fromOffset(932,math.max(48,14/scale));pitchHint.TextSize=math.max(22,12/scale)
		hint.Visible=not compact
		analysis.Position=UDim2.fromOffset(612,analysisY);analysis.Size=UDim2.fromOffset(932,analysisHeight);analysis.Visible=not compact
		analysis.CanvasSize=UDim2.fromOffset(0,36+math.max(#indicators.advantages,#indicators.risks)*48)
		analysisButton.Position=if compact then analysis.Position else UDim2.fromOffset(1440,analysisY)
		analysisButton.Size=if compact then analysis.Size else UDim2.fromOffset(104,touch)
		analysisLabel.Position=UDim2.fromOffset(if compact then 18 else 4,0)
		analysisLabel.Size=if compact then UDim2.fromOffset(896,analysisHeight) else UDim2.fromOffset(96,touch)
		analysisLabel.TextSize=if compact then math.max(23,12/scale) else math.max(15,11/scale)
		analysisLabel.TextXAlignment=if compact then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
		analysisLabel.Text=if compact then "ANÁLISE TÁTICA  •  "..#indicators.advantages.." apoios / "..#indicators.risks.." riscos  ›" else "VER\nANÁLISE"
		close.Position=UDim2.fromOffset(1134,12);close.Size=UDim2.fromOffset(330,touch)
		closeLabel.Size=close.Size;closeLabel.TextSize=math.max(23,12/scale)
		detailTitle.TextSize=math.max(32,13/scale);detailTitle.Size=UDim2.fromOffset(1080,touch)
		detailScroll.Position=UDim2.fromOffset(24,24+touch);detailScroll.Size=UDim2.fromOffset(1440,658-touch)
		local detailRowHeight=math.max(76,52/scale)
		for i,row in ipairs(modalRows) do
			row.button.Position=UDim2.fromOffset(0,(i-1)*detailRowHeight);row.button.Size=UDim2.fromOffset(1410,detailRowHeight-8)
			row.name.Size=UDim2.fromOffset(650,detailRowHeight-8);row.name.TextSize=math.max(25,13/scale)
			row.role.Size=UDim2.fromOffset(690,detailRowHeight-8);row.role.TextSize=math.max(22,12/scale)
		end
		detailAnalysis.TextSize=math.max(26,12/scale)
		local reportHeight=(#indicators.advantages+#indicators.risks)*math.max(82,40/scale)+math.max(180,90/scale)
		detailAnalysis.Size=UDim2.fromOffset(1364,reportHeight)
		detailScroll.CanvasSize=UDim2.fromOffset(0,if mode=="roster" then 11*detailRowHeight else reportHeight)
		for _,sc in ipairs({teamScroll,playerScroll,analysis,detailScroll}) do
			sc.CanvasPosition=Vector2.new(0,math.clamp(sc.CanvasPosition.Y,0,math.max(0,sc.CanvasSize.Y.Offset-sc.Size.Y.Offset)))
		end
		syncButtons()
		if compact and not mode and GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(pitch.host) then GuiService.SelectedObject=openPitch end
		close.NextSelectionDown=if mode=="roster" then modalRows[1].button else close
		local target=if compact then openPitch else pitch.cards[1].button
		analysisButton.NextSelectionUp=target
		withBall.NextSelectionDown=target;withoutBall.NextSelectionDown=target
		for _,row in ipairs(rows) do row.button.NextSelectionRight=row.minus or target;if row.minus then row.minus.NextSelectionRight=target end end
	end
	refresh=function(animate)
		local draft=session.draft
		local preset=Model.preset(draft)
		presetName.Text=preset.label;presetDescription.Text=preset.description
		active.Text=Catalog.formations[session.store.active.formationId].label.."  •  "..(if session:dirty() then "ALTERAÇÕES PENDENTES" else "ATIVA NESTA SESSÃO")
		saveLabel.Text=if session:dirty() then "SALVAR ALTERAÇÕES" else "TÁTICA CONFIRMADA"
		rows[1].value.Text=Catalog.formations[draft.formationId].label
		for i,key in ipairs({"buildUp","pressure","mentality"}) do rows[i+1].value.Text=Model.option(key,draft[key]).label end
		for i,key in ipairs({"width","line"}) do
			rows[i+4].value.Text=tostring(draft[key]).." / 100  +"
			rows[i+4].fill.Size=UDim2.new(draft[key]/100,0,0,2)
		end
		teamScroll.Visible=tab=="team";playerScroll.Visible=tab=="player"
		for _,entry in ipairs({{teamTab,tab=="team"},{playerTab,tab=="player"},{withBall,phase=="with_ball"},{withoutBall,phase=="without_ball"}}) do
			entry[1].BackgroundColor3=if entry[2] then Color3.fromRGB(35,42,36) else C.ink;Controls.select(entry[1],entry[2])
		end
		withLabel.TextColor3=if phase=="with_ball" then C.green elseif UI.highContrast then C.white else C.muted
		withoutLabel.TextColor3=if phase=="without_ball" then C.green elseif UI.highContrast then C.white else C.muted
		local entry=draft.positions[selected]
		local player=Model.player(roster,entry.playerId)
		playerName.Text=player.shortName.."  /  "..Model.slot(draft,selected).label
		roleRow.value.Text=Catalog.roles[entry.roleId].label;behaviorRow.value.Text=Catalog.behaviors[entry.behaviorId].label
		individualHint.Text="A função define avanço, corredores e pressão. O comportamento ajusta o apoio. Compare as duas fases no campo."
		pitch:update(draft,phase,selected,animate==true)
		if lastFormation and lastFormation~=draft.formationId then Controls.present(pitchContent,scope,true) end
		lastFormation=draft.formationId
		for _,card in ipairs(pitch.cards) do
			card.button.NextSelectionLeft=card.button.NextSelectionLeft or (if tab=="team" then rows[1].button else roleRow.button)
			card.button.NextSelectionUp=card.button.NextSelectionUp or withBall
			card.button.NextSelectionDown=card.button.NextSelectionDown or analysisButton
		end
		indicators=Model.indicators(draft)
		for i=1,8 do
			advantageLabels[i].Visible=indicators.advantages[i]~=nil;riskLabels[i].Visible=indicators.risks[i]~=nil
			advantageLabels[i].Text=if indicators.advantages[i] then "+  "..indicators.advantages[i].text else ""
			riskLabels[i].Text=if indicators.risks[i] then "!  "..indicators.risks[i].text else ""
		end
		detailTitle.Text=if mode=="roster" then "ONZE TITULARES  /  ESCOLHER ATLETA" else "ANÁLISE DO PLANO DE JOGO"
		local report={"PONTOS FORTES"}
		for _,item in ipairs(indicators.advantages) do table.insert(report,"+  "..item.text) end
		table.insert(report,"\nPONTOS DE ATENÇÃO")
		for _,item in ipairs(indicators.risks) do table.insert(report,"!  "..item.text) end
		detailAnalysis.Text=table.concat(report,"\n\n");detailAnalysis.Visible=mode=="analysis"
		for i,slot in ipairs(Catalog.formations[draft.formationId].slots) do
			local row=modalRows[i];local assignment=draft.positions[slot.id];local athlete=Model.player(roster,assignment.playerId)
			row.slotId=slot.id;row.button.Visible=mode=="roster";row.button.Active=mode=="roster";row.button.Selectable=mode=="roster"
			row.name.Text=slot.label.."  /  "..athlete.shortName
			row.role.Text=Catalog.roles[assignment.roleId].label.." • "..Catalog.behaviors[assignment.behaviorId].label
			Controls.select(row.button,slot.id==selected)
		end
		save.NextSelectionUp=if tab=="team" then rows[#rows].button else behaviorRow.button;cancel.NextSelectionUp=save.NextSelectionUp
		resize()
	end
	local canvasScale=root.Parent and root.Parent:FindFirstChild("UIScale")
	if canvasScale then scope:Add(canvasScale:GetPropertyChangedSignal("Scale"):Connect(function() if scope.alive then resize() end end)) end
	scope:Add(function() if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(root) then GuiService.SelectedObject=nil end end)
	for i,row in ipairs(rows) do
		Controls.reveal(teamScroll,row.button,nil,scope)
		row.button.NextSelectionUp=if i==1 then teamTab else rows[i-1].button
		row.button.NextSelectionDown=if i==#rows then save else rows[i+1].button
		if row.minus then
			Controls.reveal(teamScroll,row.minus,nil,scope)
			row.minus.NextSelectionLeft=row.button;row.minus.NextSelectionUp=row.button.NextSelectionUp;row.minus.NextSelectionDown=row.button.NextSelectionDown
		end
	end
	Controls.reveal(playerScroll,roleRow.button,nil,scope);Controls.reveal(playerScroll,behaviorRow.button,nil,scope)
	teamTab.NextSelectionDown=rows[1].button;playerTab.NextSelectionDown=roleRow.button
	teamTab.NextSelectionUp=presetButton;playerTab.NextSelectionUp=presetButton
	teamTab.NextSelectionRight=playerTab;playerTab.NextSelectionLeft=teamTab
	presetButton.NextSelectionDown=teamTab;presetButton.NextSelectionUp=squad;presetButton.NextSelectionRight=withBall
	squad.NextSelectionDown=withoutBall;squad.NextSelectionLeft=presetButton
	withBall.NextSelectionLeft=teamTab;withBall.NextSelectionRight=withoutBall;withoutBall.NextSelectionLeft=withBall
	roleRow.button.NextSelectionUp=playerTab;roleRow.button.NextSelectionDown=behaviorRow.button
	behaviorRow.button.NextSelectionUp=roleRow.button;behaviorRow.button.NextSelectionDown=save
	save.NextSelectionRight=cancel;cancel.NextSelectionLeft=save
	openPitch.NextSelectionDown=analysisButton;openPitch.NextSelectionUp=withBall;openPitch.NextSelectionLeft=playerTab
	analysisButton.NextSelectionUp=openPitch;analysisButton.NextSelectionLeft=save
	close.NextSelectionDown=modalRows[1].button
	for i,row in ipairs(modalRows) do
		row.button.NextSelectionUp=if i==1 then close else modalRows[i-1].button
		row.button.NextSelectionDown=if i==11 then close else modalRows[i+1].button
		row.button.NextSelectionRight=close
	end
	refresh()
end
