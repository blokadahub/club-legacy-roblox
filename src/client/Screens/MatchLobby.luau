--!nonstrict
local Players=game:GetService("Players")
local GuiService=game:GetService("GuiService")
local UI=require(script.Parent.Parent.UI)
local Controls=require(script.Parent.TacticsControls)
local PitchView=require(script.Parent.MatchLobbyPitch)
local Data=require(game:GetService("ReplicatedStorage").CL27.Data)
local Catalog=require(game:GetService("ReplicatedStorage").CL27.TacticsCatalog)
local T=require(game:GetService("ReplicatedStorage").CL27.TacticsModel)
local Registration=require(game:GetService("ReplicatedStorage").CL27.MatchLobbyModel)
local C=Controls.colors

return function(root,ctx)
	local state,scope=ctx.state,ctx.scope
	local session,err=Registration.new(state,Data.players)
	if not session then
		Controls.text(root,err,70,260,1050,120,32,C.white,true)
		UI.button(root,"ABRIR TÁTICAS",70,410,380,90,function() ctx.go("Tactics") end,scope,{primary=true})
		UI.button(root,"VOLTAR AO MENU",70,520,380,90,function() ctx.go("HomeInterior") end,scope)
		return
	end
	if ctx.playerGui then
		local old=ctx.playerGui.ScreenOrientation
		ctx.playerGui.ScreenOrientation=Enum.ScreenOrientation.LandscapeSensor
		scope:Add(function() ctx.playerGui.ScreenOrientation=old end)
	end
	local scale,zoom=1,1
	local selected,selectedBench="gk",nil
	local refresh,resize,openDetail,closeDetail
	local mode,choiceIndex,choices=nil,1,{}
	local focusBefore=nil
	local mainButtons,tabButtons,benchCards,tabRules={},{},{},{}
	local function text(parent,value,x,y,w,h,size,color,bold) return Controls.text(parent,value,x,y,w,h,size,color,bold) end
	local function button(parent,id,label,callback,primary)
		local b
		b=Controls.button(parent,id,function() if b.Active then callback() end end,scope,primary)
		b.Text=label;b.TextSize=20;b.Font=Enum.Font.GothamBold
		b.TextColor3=if primary then C.ink else C.white
		b.TextXAlignment=Enum.TextXAlignment.Center
		b.TextWrapped=true;b.TextTruncate=Enum.TextTruncate.None
		return b
	end
	local function scroll(parent,name)
		return UI.new("ScrollingFrame",{Name=name,BackgroundTransparency=1,BorderSizePixel=0,
			ScrollBarThickness=3,ScrollBarImageColor3=C.muted,CanvasSize=UDim2.fromOffset(0,0),
			CanvasPosition=Vector2.new(),ClipsDescendants=true,Active=true,ScrollingDirection=Enum.ScrollingDirection.Y},parent)
	end
	-- Only edge readability layers: the main tunnel and character remain Workspace.
	local top=UI.frame(root,0,0,1600,205,C.ink,.12)
	UI.new("UIGradient",{Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.05),NumberSequenceKeypoint.new(1,1)})},top)
	UI.logo(root,54,48,.65)
	local heading=text(root,"PREPARAÇÃO PRÉ-PARTIDA",250,42,760,52,24,C.white,true)
	local subtitle=text(root,"CARREIRA INDIVIDUAL  /  CLUB LEGACY 27",250,92,820,30,16,C.muted)
	local account=Players.LocalPlayer
	local identity=text(root,account and (account.DisplayName or account.Name) or "Conta indisponível",1244,44,300,46,25,C.white,true)
	identity.Name="IdentidadeReal"
	local username=text(root,account and "@"..account.Name or "",1244,92,300,32,17,C.muted)
	local nav=scroll(root,"AbasPrePartida");nav.ScrollingDirection=Enum.ScrollingDirection.X
	local routes={{"PRÉ-PARTIDA",nil},{"ELENCO","Squad"},{"TÁTICAS","Tactics"},{"INSTRUÇÕES","help"},{"CONFIGURAÇÕES","Settings"}}
	for i,entry in ipairs(routes) do
		local b=button(nav,"AbaLobby_"..i,entry[1],function()
			if entry[2]=="help" then openDetail("help")
			elseif entry[2] then ctx.go(entry[2])
			elseif mode then closeDetail() else ctx.notify("Selecione um titular ou reserva para preparar sua equipe.") end
		end)
		b.BackgroundTransparency=1
		b:SetAttribute("QuietOutline",true);Controls.select(b,false)
		b.TextColor3=if i==1 then C.white else (UI.highContrast and C.white or C.muted)
		local rule=UI.frame(b,16,60,178,2,C.green,0)
		rule.Name="AbaAtiva";rule.Visible=i==1;tabRules[i]=rule
		tabButtons[i]=b;table.insert(mainButtons,b)
		Controls.reveal(nav,b,nil,scope)
	end
	local club=Data.clubs[state.homeClub or 1]
	local badge=UI.badge(root,club,336,216,58)
	local clubName=text(root,club.name,412,211,775,42,33,C.white,true)
	local formation=text(root,"",413,253,750,30,19,C.muted)
	local benchTitle=text(root,"BANCO DE RESERVAS",54,219,242,56,21,C.white,true)
	local benchRule=UI.frame(root,54,278,242,1,C.border,.4)
	local bench=scroll(root,"ReservasInscritos")
	for i=1,5 do
		local card={}
		card.button=button(bench,"Reserva_"..i,"",function() selectedBench=i;openDetail("reserve") end)
		card.button:SetAttribute("QuietOutline",true)
		card.shade=UI.gradient(card.button,{Color3.fromRGB(31,39,36),Color3.fromRGB(14,20,19)},90)
		card.shade.Name="CardShading"
		card.name=text(card.button,"",16,8,208,32,22,C.white,true);card.name.Name="NomeReserva"
		card.info=text(card.button,"",16,43,208,28,18,C.muted);card.info.Name="CondicaoReserva"
		card.track=UI.frame(card.button,16,78,204,2,C.border,.6)
		card.track.Name="CondicaoFisica"
		card.fill=UI.frame(card.track,0,0,204,2,C.green,.25)
		card.fill.Name="ValorCondicao"
		card.button.BackgroundTransparency=.08
		benchCards[i]=card;table.insert(mainButtons,card.button)
		Controls.reveal(bench,card.button,nil,scope)
	end
	local pitchScroll=scroll(root,"CampoPrePartida");pitchScroll.ScrollingDirection=Enum.ScrollingDirection.XY
	local pitch=PitchView.create(pitchScroll,scope,Data.players,function(id) if not mode then selected=id;openDetail("starter") end end)
	local pitchScale=UI.new("UIScale",{Scale=1},pitch.host)
	-- Small displays keep all eleven positions visible. The whole board is one
	-- generous touch target; the sheet exposes names/roles and a starter selector.
	local openPitch=button(root,"AbrirTitularesCompacto","",function() openDetail("starter") end)
	openPitch.BackgroundTransparency=1;openPitch.Visible=false
	local pitchHint=text(openPitch,"VER TITULARES  ›",0,0,896,44,20,C.white,true)
	pitchHint.TextXAlignment=Enum.TextXAlignment.Center
	table.insert(mainButtons,openPitch)
	for _,card in ipairs(pitch.cards) do
		table.insert(mainButtons,card.button)
		Controls.reveal(pitchScroll,card.button,function() return zoom end,scope)
	end
	local avatarTitle=text(root,"SEU AVATAR • TÉCNICO",1244,161,300,50,19,C.white,true)
	local avatarMessage=text(root,"Carregando seu avatar…",1244,713,300,70,18,C.muted)
	avatarMessage.Name="EstadoAvatar"
	local retry=button(root,"RecarregarAvatar","TENTAR NOVAMENTE",function()
		local scene=ctx.scene.matchLobby
		if scene then scene:RetryAvatar() end
	end)
	table.insert(mainButtons,retry);retry.Visible=false
	local scene=ctx.scene.matchLobby
	if scene then
		local function avatarStatus()
			local status=scene.model:GetAttribute("AvatarStatus")
			avatarMessage.Text=if status=="ready" then (scene.model:GetAttribute("AvatarOutfit") or "Seu avatar • técnico do clube") else (scene.model:GetAttribute("AvatarMessage") or "Carregando seu avatar…")
			if status=="ready" and (scene.model:GetAttribute("AvatarWarning") or "")~="" then avatarMessage.Text="Avatar parcialmente carregado" end
			retry.Visible=status=="error"
			if resize then resize() end
		end
		-- Loading may finish under a navigation/input lock; still update status.
		scope:Add(scene.model:GetAttributeChangedSignal("AvatarStatus"):Connect(function() if scope.alive then avatarStatus() end end))
		avatarStatus()
	end
	local footer=UI.frame(root,38,734,1182,166,C.ink,.1);footer.Name="BaseAcoes"
	UI.new("UIGradient",{Rotation=90,Transparency=NumberSequence.new({
		NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.35,.12),NumberSequenceKeypoint.new(1,0)})},footer)
	local status=text(root,"",54,760,1140,44,22,C.green,true);status.Name="EstadoEscalacao"
	local confirm=button(root,"ConfirmarEscalacao","CONFIRMAR ESCALAÇÃO",function()
		local ok,reason=session:confirm()
		refresh()
		if ok then ctx.notify("Escalação confirmada nesta sessão.")
		else status.Text=reason;status.TextColor3=C.warning end
	end,true)
	local cancel=button(root,"CancelarEscalacao","CANCELAR",function() session:cancel();refresh() end)
	local central=button(root,"CentralPrePartida","CENTRAL",function()
		if ctx.openCentral then ctx.openCentral() else ctx.go("Overview") end
	end)
	local home=button(root,"SairPrePartida","VOLTAR",function() ctx.go("HomeInterior") end)
	for _,b in ipairs({confirm,cancel,central,home}) do table.insert(mainButtons,b) end
	local future=text(root,"SIMULAÇÃO DE PARTIDAS\nEm desenvolvimento",1244,811,300,66,19,C.muted)
	-- Contextual sheet leaves the real avatar visible; no new scene or portraits.
	local overlay=UI.frame(root,38,202,1182,590,C.ink,.02)
	overlay.Name="FichaPrePartida";overlay.Visible=false;overlay.Active=true
	UI.stroke(overlay,C.border,.15,1)
	local sheetRule=UI.frame(overlay,24,0,1134,2,C.green,.3);sheetRule.Name="ReguaFicha"
	local body=scroll(overlay,"DetalhesRolaveis")
	local title=text(body,"",24,16,1086,60,34,C.white,true);title.Name="AtletaSelecionado"
	local details=text(body,"",24,86,1086,138,24,C.muted);details.Name="DadosSelecionados"
	local candidate=button(body,"EscolherCandidato","",function()
		if #choices>0 then choiceIndex=choiceIndex%#choices+1;refresh() end
	end)
	local operation=button(body,"ModoSubstituicao","TROCAR COM UM TITULAR",function()
		if mode=="starter" then
			local slots=Catalog.formations[session.tactic.formationId].slots
			for i,slot in ipairs(slots) do if slot.id==selected then selected=slots[i%#slots+1].id;break end end
			openDetail("starter")
		else openDetail(if mode=="swapReserve" then "reserve" else "swapReserve") end
	end)
	local proposal=button(overlay,"ProporAlteracao","PROPOR TROCA",function()
		local choice=choices[choiceIndex]
		if not choice then ctx.notify("Nenhum atleta elegível para esta alteração.");return end
		local ok,reason
		if mode=="starter" then ok,reason=session:swap(selected,choice.index)
		elseif mode=="swapReserve" then ok,reason=session:swap(choice.id,selectedBench)
		else ok,reason=session:register(selectedBench,choice.id) end
		if ok then closeDetail();refresh() else ctx.notify(reason) end
	end,true)
	local dismiss=button(overlay,"FecharFicha","VOLTAR",function() closeDetail() end)
	local function makeChoices()
		choices={};choiceIndex=1
		if mode=="starter" then
			local slot=T.slot(session.tactic,selected)
			for i,id in ipairs(session.benchIds) do
				local p=T.player(Data.players,id)
				if T.compatible(p,slot) then table.insert(choices,{id=id,index=i,label=p.shortName.." • "..p.position}) end
			end
		elseif mode=="swapReserve" then
			local p=T.player(Data.players,session.benchIds[selectedBench])
			for _,slot in ipairs(Catalog.formations[session.tactic.formationId].slots) do
				if T.compatible(p,slot) then
					local current=T.player(Data.players,session.tactic.positions[slot.id].playerId)
					table.insert(choices,{id=slot.id,label=current.shortName.." • "..slot.label})
				end
			end
		elseif mode=="reserve" then
			for _,p in ipairs(session:candidates()) do table.insert(choices,{id=p.id,label=p.shortName.." • "..p.position}) end
		end
	end
	openDetail=function(nextMode)
		if nextMode=="starter" then selectedBench=nil end
		if not mode then focusBefore=GuiService.SelectedObject end
		mode=nextMode;overlay.Visible=true;body.CanvasPosition=Vector2.new()
		makeChoices()
		for _,b in ipairs(mainButtons) do b.Selectable=false;b.Active=false end
		refresh();GuiService.SelectedObject=if #choices>0 then candidate else dismiss
	end
	closeDetail=function()
		mode=nil;overlay.Visible=false
		for _,b in ipairs(mainButtons) do b.Selectable=true;b.Active=true end
		if focusBefore and focusBefore.Parent then GuiService.SelectedObject=focusBefore end
		refresh()
	end
	refresh=function()
		pitch:update(session.tactic,if selectedBench then nil else selected)
		for _,card in ipairs(pitch.cards) do
			local b=card.button
			b.NextSelectionLeft=b.NextSelectionLeft or benchCards[1].button
			b.NextSelectionRight=b.NextSelectionRight or confirm
			b.NextSelectionUp=b.NextSelectionUp or tabButtons[3]
			b.NextSelectionDown=b.NextSelectionDown or confirm
		end
		formation.Text=Catalog.formations[session.tactic.formationId].label.."  /  COM A BOLA"
		for i,card in ipairs(benchCards) do
			local p=T.player(Data.players,session.benchIds[i])
			card.name.Text=if p then p.shortName else "VAGA LIVRE"
			card.info.Text=if p then p.position.."  •  "..tostring(p.fitness).."%" else "Selecionar atleta"
			card.button:SetAttribute("PlayerId",p and p.id or nil)
			local chosen=selectedBench==i
			card.button.BackgroundColor3=if chosen then C.white else Color3.new(1,1,1)
			card.shade.Enabled=not chosen
			card.name.TextColor3=if chosen then C.ink else C.white
			card.info.TextColor3=if chosen then C.panel elseif UI.highContrast then C.white else C.muted
			card.fill.BackgroundColor3=if chosen then Color3.fromRGB(39,102,62) else C.green
			card.fill.Size=UDim2.new(math.clamp(p and p.fitness or 0,0,100)/100,0,1,0)
			Controls.select(card.button,chosen)
		end
		local valid,reason=Registration.validate(session.tactic,session.benchIds,Data.players)
		status.Text=if not valid then reason elseif session:dirty() then "ALTERAÇÕES PENDENTES • confirme ou cancele"
			elseif Registration.ready(state,Data.players) then "ESCALAÇÃO CONFIRMADA • 11 titulares + 5 reservas"
			else "11 TITULARES + 5 RESERVAS • aguardando confirmação"
		status.TextColor3=if valid then C.green else C.warning
		cancel.Text=if session:dirty() then "CANCELAR ALTERAÇÕES" else "RESTAURAR LISTA"
		if mode then
			local help=mode=="help"
			candidate.Visible=not help;proposal.Visible=not help
			operation.Visible=not help
			candidate.NextSelectionDown=if operation.Visible then operation else proposal
			proposal.NextSelectionUp=if operation.Visible then operation else candidate
			if help then
				title.Text="PREPARE SUA EQUIPE"
				details.Text="1. Selecione um titular para consultar sua função e propor uma troca compatível.\n2. Selecione um reserva para mudar sua inscrição ou colocá-lo no time.\n3. Confirme a escalação para salvar os 16 atletas nesta sessão.\n\nTáticas e Elenco compartilham a mesma equipe confirmada. Sair descarta alterações pendentes. Seu avatar representa o técnico; os atletas são fictícios. A simulação de partidas está em desenvolvimento."
			else
				local p=if mode=="starter" then T.player(Data.players,session.tactic.positions[selected].playerId) else T.player(Data.players,session.benchIds[selectedBench])
				title.Text=if p then p.name else "INSCRIÇÃO DE RESERVA"
				local instruction=if mode=="starter" then session.tactic.positions[selected] else nil
				details.Text=if p then p.position.." • Condição "..tostring(p.fitness).."% • Atleta fictício do clube\n"..
					(if instruction then Catalog.roles[instruction.roleId].label.." / "..Catalog.behaviors[instruction.behaviorId].label.."\n" else "Reserva inscrito nesta preparação\n")..
					"Passe "..p.attributes.passing.."  •  Defesa "..p.attributes.defending.."  •  Finalização "..p.attributes.shooting
					else "Escolha um atleta disponível do elenco do clube."
				candidate.Text=if #choices>0 then "ESCOLHER  ›  "..choices[choiceIndex].label else "Nenhum atleta compatível disponível"
				proposal.Text=if #choices==0 then "SEM OPÇÃO COMPATÍVEL" else (if mode=="reserve" then "INSCREVER: " else "TROCAR POR: ")..choices[choiceIndex].label
				operation.Text=if mode=="starter" then "OUTRO TITULAR  ›" elseif mode=="swapReserve" then "ALTERAR INSCRIÇÃO DO BANCO" else "TROCAR COM UM TITULAR"
			end
		end
		if resize then resize() end
	end
	resize=function()
		local uiScale=root.Parent and root.Parent:FindFirstChildOfClass("UIScale")
		scale=uiScale and uiScale.Scale or 1
		local h=math.max(64,44/math.max(.2,scale))
		local font=math.max(20,12/math.max(.2,scale))
		local compact=scale<.65
		heading.Text=if compact then "PRÉ-PARTIDA" else "PREPARAÇÃO PRÉ-PARTIDA"
		heading.TextSize=math.max(24,font);subtitle.Visible=not compact
		nav.Position=UDim2.fromOffset(54,132);nav.Size=UDim2.fromOffset(1140,h)
		local tabW=math.max(210,84/math.max(.2,scale))
		for i,b in ipairs(tabButtons) do
			b.Position=UDim2.fromOffset((i-1)*(tabW+8),0);b.Size=UDim2.fromOffset(tabW,h);b.TextSize=font
			tabRules[i].Position=UDim2.fromOffset(16,h-3);tabRules[i].Size=UDim2.fromOffset(tabW-32,2)
		end
		nav.CanvasSize=UDim2.fromOffset(#tabButtons*(tabW+8),0)
		local headingY=math.max(214,140+h)
		benchTitle.Position=UDim2.fromOffset(54,headingY);benchTitle.TextSize=font;benchTitle.Size=UDim2.fromOffset(242,compact and 88 or 56)
		badge.Position=UDim2.fromOffset(336,headingY)
		clubName.Position=UDim2.fromOffset(412,headingY);clubName.TextSize=math.max(30,font)
		formation.Position=UDim2.fromOffset(413,headingY+46);formation.TextSize=font;formation.Size=UDim2.fromOffset(750,math.max(30,font*1.3))
		local actionY=880-h
		for i,b in ipairs({confirm,cancel,central,home}) do
			local xs={54,558,838,1034};local widths={488,264,180,160}
			b.Position=UDim2.fromOffset(xs[i],actionY);b.Size=UDim2.fromOffset(widths[i],h);b.TextSize=font
		end
		local statusHeight=math.max(54,font*2.5)
		local statusY=actionY-statusHeight-8
		status.Position=UDim2.fromOffset(54,statusY);status.Size=UDim2.fromOffset(1140,statusHeight);status.TextSize=font
		footer.Position=UDim2.fromOffset(38,statusY-18);footer.Size=UDim2.fromOffset(1182,900-statusY+18)
		future.Position=UDim2.fromOffset(1244,848);future.Size=UDim2.fromOffset(300,44);future.TextSize=16;future.Visible=not compact
		local y=headingY+90;local available=math.max(220,statusY-10-y)
		benchRule.Position=UDim2.fromOffset(54,y-6);benchRule.Visible=not compact
		bench.Position=UDim2.fromOffset(54,y);bench.Size=UDim2.fromOffset(242,available)
		local row=if compact then math.max(h+10,font*3+30) else available/5
		for i,card in ipairs(benchCards) do
			card.button.Position=UDim2.fromOffset(0,(i-1)*row);card.button.Size=UDim2.fromOffset(236,row-6)
			card.name.Size=UDim2.fromOffset(208,row*(compact and .54 or .45));card.name.TextSize=font
			card.info.Position=UDim2.fromOffset(16,row*(compact and .62 or .54));card.info.Size=UDim2.fromOffset(208,font*1.3);card.info.TextSize=font
			card.track.Position=UDim2.fromOffset(16,row-11)
		end
		bench.CanvasSize=UDim2.fromOffset(0,5*row)
		pitchScroll.Position=UDim2.fromOffset(316,y-15);pitchScroll.Size=UDim2.fromOffset(896,available+15)
		zoom=math.min(896/920,(available+15-(compact and 48 or 0))/510)
		pitchScale.Scale=zoom;pitchScroll.CanvasSize=UDim2.fromOffset(0,0)
		pitch.host.Position=UDim2.fromOffset((896-920*zoom)/2,0)
		pitch:compact(compact,scale*zoom)
		openPitch.Visible=compact;openPitch.Selectable=compact and not mode
		openPitch.Position=pitchScroll.Position;openPitch.Size=pitchScroll.Size
		pitchHint.Position=UDim2.fromOffset(0,available-32);pitchHint.TextSize=font
		for _,card in ipairs(pitch.cards) do card.button.Selectable=not compact and not mode;card.button.Active=not compact and not mode end
		avatarTitle.TextSize=font;identity.TextSize=math.max(25,font);username.TextSize=font
		identity.Size=UDim2.fromOffset(300,math.max(70,font*2.5));username.Position=UDim2.fromOffset(1244,118);username.Visible=not compact
		avatarTitle.Position=UDim2.fromOffset(1244,compact and 152 or 161);avatarTitle.Size=UDim2.fromOffset(300,compact and 92 or 50)
		avatarMessage.TextSize=font;avatarMessage.Position=UDim2.fromOffset(1244,773);avatarMessage.Size=UDim2.fromOffset(300,compact and 106 or 68)
		if retry.Visible then avatarMessage.Position=UDim2.fromOffset(1244,380);avatarMessage.Size=UDim2.fromOffset(300,240) end
		retry.Position=UDim2.fromOffset(1244,635);retry.Size=UDim2.fromOffset(300,h);retry.TextSize=font
		local sheetY=if compact then 132 else headingY
		overlay.Position=UDim2.fromOffset(38,sheetY);overlay.Size=UDim2.fromOffset(1182,statusY-sheetY-10)
		body.Position=UDim2.fromOffset(0,0);body.Size=UDim2.fromOffset(1182,overlay.Size.Y.Offset-h-24)
		title.TextSize=math.max(32,font);details.TextSize=math.max(24,font)
		details.Size=UDim2.fromOffset(1086,if mode=="help" then 15*font else 5*font)
		candidate.Position=UDim2.fromOffset(24,100+details.Size.Y.Offset);candidate.Size=UDim2.fromOffset(1086,h)
		operation.Position=UDim2.fromOffset(24,112+details.Size.Y.Offset+h);operation.Size=UDim2.fromOffset(1086,h)
		candidate.TextSize=font;operation.TextSize=font
		body.CanvasSize=UDim2.fromOffset(0,if mode=="help" then 110+details.Size.Y.Offset else 130+details.Size.Y.Offset+2*h)
		proposal.Position=UDim2.fromOffset(24,overlay.Size.Y.Offset-h-12);proposal.Size=UDim2.fromOffset(730,h);proposal.TextSize=font
		dismiss.Position=UDim2.fromOffset(780,overlay.Size.Y.Offset-h-12);dismiss.Size=UDim2.fromOffset(378,h);dismiss.TextSize=font
	end
	Controls.reveal(body,candidate,nil,scope);Controls.reveal(body,operation,nil,scope)
	candidate.NextSelectionDown=operation;operation.NextSelectionDown=proposal;proposal.NextSelectionRight=dismiss;dismiss.NextSelectionLeft=proposal
	local scaler=root.Parent and root.Parent:FindFirstChildOfClass("UIScale")
	if scaler then scope:Add(scaler:GetPropertyChangedSignal("Scale"):Connect(function() if scope.alive then resize() end end)) end
	scope:Add(function() if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(root) then GuiService.SelectedObject=nil end end)
	refresh()
end
