-- Numeric composition, real module construction and disposal on API doubles.
-- Does not execute Roblox physics, streaming, asset services or rendering.
local Layout=require(moduleNodes["src/client/Environments/PenaltyLayout.luau"])
local Preview=require(moduleNodes["src/client/Environments/PenaltyScene.luau"])
local Scene=require(moduleNodes["src/client/Scene.luau"])
local Data=require(moduleNodes["src/shared/Data.luau"])
local MenuAvatar=require(moduleNodes["src/client/MenuAvatar.luau"])
local assertions=0
local function check(value,message) assert(value,message);assertions+=1 end
local function near(a,b,e) return math.abs(a-b)<(e or 0.00001) end
local function vec(t) return Vector3.new(table.unpack(t)) end
local camera=CFrame.lookAt(vec(Layout.Camera.position),vec(Layout.Camera.target))
local function project(position,aspect)
	local p=camera:PointToObjectSpace(position)
	local depth=-p.Z
	local tangent=math.tan(math.rad(Layout.Camera.fov/2))
	return .5+p.X/(2*depth*tangent*(aspect or 16/9)),.5-p.Y/(2*depth*tangent)
end
local u,v=project(vec(Layout.Ball))
check(near(u,.5) and v>.64 and v<.77,"Bola precisa estar visível no centro inferior")
local sx,sy=project(vec(Layout.Striker))
check(sx>.25 and sx<.37 and sy>.78 and sy<.94,"Cobrador deve ocupar a esquerda sem cortar pés")
local gx,gy=project(Vector3.new(Layout.Goal.width/2,0,0))
local _,barY=project(Vector3.new(0,Layout.Goal.height,0))
check(gx>.70 and gx<.78 and gy>.43 and gy<.54 and barY>.16 and barY<.28,"Gol não segue composição frontal da referência")
for _,quality in ipairs({"Baixa","Média","Alta"}) do
	local descriptors=Layout.build(quality)
	local colliders=0
	for _,d in ipairs(descriptors) do
		for _,n in ipairs(d.size) do check(n>0 and n<1000,"Dimensão inválida") end
		for _,n in ipairs(d.position) do check(n==n and math.abs(n)<1000,"Posição não finita") end
		if d.collide then colliders+=1;check(d.name=="PitchGround","Collider decorativo inesperado") end
	end
	check(colliders==1,"O piso deve ser um collider contínuo único")
	check(#descriptors<1900,"Orçamento de peças estáticas ultrapassado")
	print(string.format("PASS Penalty %s: %d architecture parts, one continuous ground collider",quality,#descriptors))
end
check(near(Layout.Pitch.penalty,11*Layout.Scale),"Marca fora dos 11 metros")
check(near(Layout.Goal.width,7.32*Layout.Scale) and near(Layout.Goal.height,2.44*Layout.Scale),"Proporção da baliza incorreta")
-- API fixture only: production sources never call Rig.create for arena actors.
local FixtureRig=require(moduleNodes["src/client/Rig.luau"])
local queryCount,createCount=0,0
services.Players.LocalPlayer.UserId=1337
function services.Players:GetHumanoidDescriptionFromUserIdAsync(userId)
	queryCount+=1
	assert(userId==self.LocalPlayer.UserId,"Wrong account queried")
	if services.avatarQueryFailure then error("Injected appearance service failure") end
	if services.avatarQueryDelay then task.wait(services.avatarQueryDelay) end
	local description=Instance.new("HumanoidDescription")
	description.IdleAnimation=7654321 -- Test-only fake asset, never in production.
	description:SetAttribute("Account",userId)
	return description
end
function services.Players:CreateHumanoidModelFromDescriptionAsync(description,rigType)
	createCount+=1
	assert(rigType==Enum.HumanoidRigType.R15 and description:GetAttribute("Account")==self.LocalPlayer.UserId)
	local model=FixtureRig.create({number=7},{id="test",name="Test avatar"},1)
	local shirt=Instance.new("Shirt");shirt.ShirtTemplate="account-shirt";shirt.Parent=model
	local accessory=Instance.new("Accessory");accessory.Name="AccountHair";accessory.Parent=model
	local handle=Instance.new("Part");handle.Name="Handle";handle.Size=Vector3.new(1,1,1);handle.Parent=accessory
	local weld=Instance.new("Weld");weld.Part0=model.Head;weld.Part1=handle;weld.C0=CFrame.new(0,.5,0);weld.C1=CFrame.identity;weld.Parent=handle
	local script=Instance.new("Script");script.Parent=model
	return model
end
local parent=Instance.new("Folder");parent.Parent=workspace
local lobby=Instance.new("Folder");lobby.Parent=workspace
local originalBall=MenuAvatar.createFallbackBall(lobby,1)
local scene=Preview.new(parent,{quality="Alta"})
local Scope=require(moduleNodes["src/client/Scope.luau"])
local hudScope=Scope.new()
local hudRoot=Instance.new("Frame");hudRoot.Parent=playerGui
require(moduleNodes["src/client/Screens/PenaltyArena.luau"])(hudRoot,{scope=hudScope,scene={penalty=scene},playerGui=playerGui,go=function() end})
local avatarHUD=playerGui:FindFirstChild("CL27_PenaltyHUD")
check(not avatarHUD.PreviaAnimacoes.Kick.Active and not avatarHUD.RecarregarAvatar.Visible,"Controles devem aguardar aparência real")
check(scene.model:FindFirstChild("CobradorR15")==nil,"Avatar foi exposto antes da primeira pose")
advance(.01)
check(scene.model:GetAttribute("AvatarStatus")=="Ready","Avatar não carregou: "..tostring(scene.model:GetAttribute("AvatarMessage")))
check(queryCount==1 and createCount==1,"Cópias não compartilharam uma única aparência")
check(avatarHUD.PreviaAnimacoes.Kick.Active and avatarHUD.EstadoAvatar.Text=="","HUD não refletiu avatar pronto")
local selector=avatarHUD.PreviaAnimacoes
check(selector.Size.X.Offset==334 and selector.Size.Y.Offset==48 and selector.AnchorPoint.X==1,"Controles não permanecem compactos no canto")
local MotionUI=require(moduleNodes["src/client/Environments/PenaltyMotion.luau"])
local dispatched=nil
local originalPreview=scene.PreviewAction
scene.PreviewAction=function(_,action) dispatched=action;return false end
for i,action in ipairs(MotionUI.SaveOrder) do
	check(selector.VerDefesa:GetAttribute("PreviewAction")==action,"Seletor não permite avaliar "..action)
	selector.VerDefesa.Activated:Fire();check(dispatched==action,"Botão não executa a defesa selecionada")
	if i<#MotionUI.SaveOrder then selector.DefesaProxima.Activated:Fire() end
end
selector.DefesaProxima.Activated:Fire()
check(selector.VerDefesa:GetAttribute("PreviewAction")==MotionUI.SaveOrder[1],"Seletor não retorna à primeira defesa")
selector.DefesaAnterior.Activated:Fire()
check(selector.VerDefesa:GetAttribute("PreviewAction")==MotionUI.SaveOrder[6],"Seleção anterior falhou")
scene.PreviewAction=originalPreview
scene.model:SetAttribute("PreviewAction","HighSave")
check(not selector.Kick.Active,"Chute deve aguardar a prévia em execução")
check(not selector.VerDefesa.Active,"Defesas não podem ser sobrepostas pelo HUD")
check(selector.DefesaAnterior.Active and selector.DefesaProxima.Active,"Seleção deve continuar disponível durante a prévia")
scene.model:SetAttribute("PreviewAction",nil)
check(selector.Kick.Active and selector.VerDefesa.Active,"HUD não liberou comandos após a recuperação")
local oldViewport=workspace.CurrentCamera.ViewportSize
for _,width in ipairs({320,640,960}) do
	workspace.CurrentCamera.ViewportSize=Vector2.new(width,360)
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Fire()
	check(selector.Size.X.Offset<=width-24 and selector.Size.Y.Offset==48,"Toolbar encobre/corta tela móvel")
	check(selector.DefesaAnterior.Size.X.Offset>=44 and selector.DefesaProxima.Size.Y.Offset>=44,"Setas móveis pequenas demais")
end
workspace.CurrentCamera.ViewportSize=oldViewport
hudScope:Destroy();hudRoot:Destroy()
local fallback=scene.ball
check(fallback~=originalBall and originalBall.Parent==lobby,"Arena moveu a bola original do lobby")
check(near(fallback:GetPivot().Position.Y,Layout.BallDiameter/2),"Bola flutuando acima da marca")
for _,name in ipairs({"CobradorR15","GoleiroR15"}) do
	local actor=scene.model:FindFirstChild(name)
	check(actor and actor.Humanoid.RigType==Enum.HumanoidRigType.R15,"Avatar R15 ausente")
	check(actor:GetAttribute("AvatarUserId")==1337,"Avatar não pertence à conta local")
	check(actor:FindFirstChild("AccountHair") and actor:FindFirstChildOfClass("Shirt").ShirtTemplate=="account-shirt","Cabelo/roupa perdidos")
	check(not actor:FindFirstChildOfClass("Script"),"Script embutido não removido")
	for _,part in ipairs(actor:GetDescendants()) do
		if part:IsA("BasePart") then check(part.Anchored==(part.Name=="HumanoidRootPart") and not part.CanCollide,"Rig não está articulável") end
	end
	local look=actor.HumanoidRootPart.CFrame.LookVector
	check(name=="CobradorR15" and look.Z<-.8 or name=="GoleiroR15" and look.Z>.95,"Orientação incorreta")
end
check(scene.actors.rigs[1].model~=scene.actors.rigs[2].model,"Instâncias dos avatares não são independentes")
local Motion=require(moduleNodes["src/client/Environments/PenaltyMotion.luau"])
local AvatarRig=require(moduleNodes["src/client/Environments/PenaltyRig.luau"])
local maxFrameMove=0
local maxFrameContext=""
local saveMetrics={}
local armPhaseChecks=0
local maxJointMove=0
local maxJointContext=""
local armMetrics={minForward=math.huge,maxUp=-math.huge,minElbow=math.huge,maxElbow=-math.huge}
for _,rig in ipairs(scene.actors.rigs) do
	local restC0={}
	for name,joint in pairs(rig.joints) do restC0[name]=joint.C0 end
	local actions={"Idle","Kick"};for _,action in ipairs(Motion.SaveOrder) do table.insert(actions,action) end
	for _,action in ipairs(actions) do
		local duration=if action=="Idle" then 7 else Motion.duration(action)
		local previous=nil
		local previousFrames=nil
		local previousState=nil
		local metrics={maxX=0,maxY=-math.huge,minY=math.huge,maxRoll=0,handHeight=-math.huge}
		for sample=0,math.floor(duration*60) do
			local t=sample/60
			local state=Motion.sample(rig.role,t,action=="Idle" and nil or action,t,rig.scale,rig.width,rig.distance)
			rig:Apply(state,false)
			for name,joint in pairs(rig.joints) do
				check(joint.C0==restC0[name],"Animação alterou attachments/C0")
				check(joint.Transform.Position.Magnitude<.012,"IK esticou articulação: "..name.." "..joint.Transform.Position.Magnitude)
			end
			local frames=rig.frames
			if rig.role=="keeper" and action~="Kick" and Motion.duration(action) then
				metrics.maxX=math.max(metrics.maxX,math.abs(state.root.X))
				metrics.maxY=math.max(metrics.maxY,state.root.Y)
				metrics.minY=math.min(metrics.minY,state.root.Y)
				metrics.maxRoll=math.max(metrics.maxRoll,math.abs(state.roll))
				local peak=if action=="LowLeft" then .95 elseif action=="LowRight" then .88 else nil
				if peak and math.abs(t-peak)<.009 then
					for _,side in ipairs({"Left","Right"}) do
						check(frames[rig.model:FindFirstChild(side.."Hand")].Position.Y<1.1,"Rasteira não direcionou ambas as mãos à região inferior")
					end
				end
				for _,side in ipairs({"Left","Right"}) do metrics.handHeight=math.max(metrics.handHeight,frames[rig.model:FindFirstChild(side.."Hand")].Position.Y) end
			end
			if rig.role=="striker" and action=="Kick" and t>=.65 and t<=1.45 then
				local forward=rig.base.LookVector
				for _,side in ipairs({"Left","Right"}) do
					local elbow,wrist=rig.joints[side.."Elbow"],rig.joints[side.."Wrist"]
					local e=(frames[elbow.Part0]*elbow.C0).Position
					local w=(frames[wrist.Part0]*wrist.C0).Position
					local direction=(w-e).Unit
					armMetrics.minForward=math.min(armMetrics.minForward,direction:Dot(forward))
					armMetrics.maxUp=math.max(armMetrics.maxUp,direction.Y)
					local bend=math.deg(math.acos(math.clamp(elbow.Transform:VectorToWorldSpace(Vector3.new(0,-1,0)):Dot(Vector3.new(0,-1,0)),-1,1)))
					armMetrics.minElbow=math.min(armMetrics.minElbow,bend);armMetrics.maxElbow=math.max(armMetrics.maxElbow,bend)
					check(bend>=70 and bend<=100,"Flexão de corrida fora de 70–100 graus")
					check(direction:Dot(forward)>.65 and direction.Y<.18,"Antebraço deixou de apontar à frente/baixo")
				end
				if previousState then
					local nextState=Motion.sample("striker",t,"Kick",t+.001,rig.scale,rig.width,rig.distance)
					local pastState=Motion.sample("striker",t,"Kick",t-.001,rig.scale,rig.width,rig.distance)
					local rightStep=nextState.right.Z-pastState.right.Z
					local leftStep=nextState.left.Z-pastState.left.Z
					local l=state.pose.LeftShoulder:VectorToWorldSpace(Vector3.new(0,-1,0)).Z
					local r=state.pose.RightShoulder:VectorToWorldSpace(Vector3.new(0,-1,0)).Z
					if rightStep<leftStep-.0002 then check(l<r,"Braço esquerdo não se opõe ao passo direito: "..t.." "..rightStep.." "..leftStep);armPhaseChecks+=1
					elseif leftStep<rightStep-.0002 then check(r<l,"Braço direito não se opõe ao passo esquerdo: "..t.." "..rightStep.." "..leftStep);armPhaseChecks+=1 end
				end
				-- Actual FK hands must stay ahead of their respective shoulders.
				for _,side in ipairs({"Left","Right"}) do
					local shoulder=rig.joints[side.."Shoulder"]
					local origin=(frames[shoulder.Part0]*shoulder.C0).Position
					local hand=frames[rig.model:FindFirstChild(side.."Hand")].Position
					check((hand-origin):Dot(forward)>0,"Mão da corrida foi projetada para trás")
				end
			end
			for part,frame in pairs(frames) do
				check(frame.Position.X==frame.Position.X and math.abs(frame.Position.Y)<30,"Pose não finita")
				if part~=rig.root then check(AvatarRig.bottom(frame,part.Size)>=.025,"Corpo atravessou gramado: "..rig.role.." "..action.." "..t.." "..part.Name) end
			end
			if rig.role=="striker" and action=="Kick" or rig.role=="keeper" and action~="Idle" then
				local torso=rig.model:FindFirstChild("UpperTorso")
				for _,side in ipairs({"Left","Right"}) do
					local elbow,wrist=rig.joints[side.."Elbow"],rig.joints[side.."Wrist"]
					local e=(frames[elbow.Part0]*elbow.C0).Position
					local w=(frames[wrist.Part0]*wrist.C0).Position
					local point=frames[torso]:PointToObjectSpace((e+w)/2)
					check(not (math.abs(point.X)<torso.Size.X*.47 and math.abs(point.Y)<torso.Size.Y*.47 and math.abs(point.Z)<torso.Size.Z*.47),"Antebraço atravessou tronco: "..action.." "..t.." "..side)
				end
			end
			if state.grounded then
				for _,side in ipairs({"Left","Right"}) do
					local foot=rig.feet[side].part
					local target=rig:FootTarget(side,state[string.lower(side)],side=="Right" and state.footAngle or 0)
					check((frames[foot].Position-target.Position).Magnitude<.012,"Pé não acompanha alvo plantado")
				end
			end
			if previous then local movement=(rig.root.CFrame.Position-previous).Magnitude;if movement>maxFrameMove then maxFrameMove=movement;maxFrameContext=rig.role.." "..action.." "..t.." deltaY="..(rig.root.CFrame.Position.Y-previous.Y).." deltaZ="..(rig.root.CFrame.Position.Z-previous.Z) end end
			previous=rig.root.CFrame.Position
			if previousFrames then
				for part,frame in pairs(frames) do
					if previousFrames[part] then
						local movement=(frame.Position-previousFrames[part].Position).Magnitude
						if movement>maxJointMove then maxJointMove=movement;maxJointContext=rig.role.." "..action.." "..t.." "..part.Name end
					end
				end
			end
			previousState=state
			previousFrames=frames
		end
		if rig.role=="keeper" and action~="Kick" and Motion.duration(action) then saveMetrics[action]=metrics end
	end
end
check(armPhaseChecks>=40,"Passadas insuficientes para auditar oposição dos braços")
print("Joint maximum displacement",maxJointMove,maxJointContext)
check(maxJointMove<.60,"Salto de articulação entre quadros: "..maxJointContext)
print("Running arms",armMetrics.minForward,armMetrics.maxUp,armMetrics.minElbow,armMetrics.maxElbow)
check(#Motion.SaveOrder==6,"Catálogo de defesas deve incluir seis variações")
for _,action in ipairs(Motion.SaveOrder) do check(saveMetrics[action]~=nil,"Defesa não foi amostrada: "..action) end
check(saveMetrics.LowLeft.maxRoll>83 and saveMetrics.LowRight.maxRoll<84,"Rasteiras não diferem na aterrissagem")
check(saveMetrics.LowLeft.minY<-1.8 and saveMetrics.LowRight.minY<-1.8,"Rasteiras não abaixam o corpo")
check(saveMetrics.MidSave.maxY>saveMetrics.LowLeft.maxY+.4,"Meia altura repete a trajetória rasteira")
check(saveMetrics.HighSave.maxY>1 and saveMetrics.HighSave.handHeight>saveMetrics.MidSave.handHeight+2,"Alta não demonstra alcance superior")
check(saveMetrics.HighSave.maxRoll<40,"Defesa alta ficou acrobática")
check(saveMetrics.CentralSave.maxX<.2 and saveMetrics.CentralSave.minY<-.5 and saveMetrics.CentralSave.maxRoll<5,"Central foi transformada em mergulho")
local stepped=Motion.sample("keeper",.58,"ShuffleSave",.58,1,.4,10)
check(stepped.root.X>1.2 and stepped.ikWeight>.99,"Sexta defesa não tem deslocamento anterior ao mergulho")
for action,m in pairs(saveMetrics) do print("SAVE",action,m.maxX,m.maxY,m.minY,m.maxRoll,m.handHeight) end
check(maxFrameMove<.30,"Movimento descontínuo: "..maxFrameContext)
print("Motion maximum root frame displacement",maxFrameMove,maxFrameContext)
check(scene:PreviewAction("Kick") and not scene:PreviewAction("DiveLeft"),"Prévia deve bloquear sobreposição")
for _=1,400 do services.RunService.PreSimulation:Fire(1/60) end
check(not scene.actors.action,"Prévia não retornou à espera")

local assets=Instance.new("Folder");assets.Name="CL27Assets";assets.Parent=services.ReplicatedStorage
services.ReplicatedStorage.ChildAdded:Fire(assets)
local template=Instance.new("Model");template.Name="AcademySoccerBall";template:SetAttribute("SourceAssetId",17275757538)
local imported=Instance.new("Part");imported.Name="ImportedBall";imported.Size=Vector3.new(2,2,2);imported.Parent=template
local originalFrame=imported.CFrame
template.Parent=assets;assets.ChildAdded:Fire(template)
check(scene.imported and fallback.Parent==nil and scene.ball.Parent==scene.model,"Asset tardio não substituiu só a bola da arena")
check(imported.Parent==template and imported.CFrame==originalFrame and imported.Size.X==2,"Template compartilhado foi alterado")
check(originalBall.Parent==lobby,"Upgrade destruiu a bola do lobby")
scene:ApplySettings({quality="Baixa"})
check(scene.model:FindFirstChild("CobradorR15")~=nil,"Qualidade removeu personagens")
local callbacks=table.clone(scene.connections)
table.insert(callbacks,scene.actors.connection)
local previousTracks=table.clone(services.loadedTracks or {})
scene:Destroy();scene:Destroy()
check(#parent:GetChildren()==0,"Arena permaneceu no Workspace após destruir")
for _,connection in ipairs(callbacks) do check(not connection.Connected,"Conexão de asset/animação vazou") end
for _,track in ipairs(previousTracks) do check(track.Destroyed and not track.IsPlaying,"Track persistiu após saída") end
assets.ChildAdded:Fire(template)
check(#parent:GetChildren()==0,"Asset tardio recriou cena encerrada")
-- Real Scene, single camera owner, neutral daylight and settings restoration.
local owner=Scene.new({quality="Alta"})
owner:Show("Penalty",Data.clubs[1],Data.clubs[2],1,1)
advance(.01)
check(owner.penalty and not owner.menuAvatar and owner.atmosphere.Parent==nil,"Arena acumulou lobby/névoa")
check(services.Lighting.ClockTime==13.5 and not owner.bloom.Enabled,"Iluminação diurna incorreta")
services.RunService.RenderStepped:Fire(1/60)
local frameBefore=workspace.CurrentCamera.CFrame.Position
services.RunService.RenderStepped:Fire(1/30)
check((workspace.CurrentCamera.CFrame.Position-frameBefore).Magnitude==0,"Prévia recebeu movimento de câmera do lobby")
local oldPreview=owner.penalty.model
owner:Show("Tunnel",Data.clubs[1],Data.clubs[2],1,1)
advance(.4)
check(oldPreview.Parent==nil and owner.penalty==nil and owner.tunnel,"Troca de ambiente não descartou arena")
check(services.Lighting.ClockTime~=13.5,"Iluminação da arena vazou para túnel")
owner:Destroy();assets:Destroy();lobby:Destroy();parent:Destroy()
-- Reentry reuses one template; no further account query for either role.
local oldQueries=queryCount
local reentry=Preview.new(workspace,{quality="Baixa"});advance(.01)
check(reentry.model:GetAttribute("AvatarStatus")=="Ready" and queryCount==oldQueries,"Reentrada duplicou chamada de aparência")
local left,right=reentry.actors.rigs[1].model,reentry.actors.rigs[2].model
left:FindFirstChildOfClass("Shirt").ShirtTemplate="independent-change"
check(right:FindFirstChildOfClass("Shirt").ShirtTemplate=="account-shirt","Instâncias compartilham roupa mutável")
check(#reentry.actors.rigs[1].tracks==1 and #reentry.actors.rigs[2].tracks==1,"Animator não carregou idle próprio")
check(reentry:PreviewAction("DiveLeft"),"Mergulho esquerdo indisponível")
for _=1,40 do services.RunService.PreSimulation:Fire(1/60) end
for _=1,300 do services.RunService.PreSimulation:Fire(1/60) end
for _,action in ipairs(Motion.SaveOrder) do
	check(reentry:PreviewAction(action),"Coordenador não aceita "..action)
	check(not reentry:PreviewAction("Kick"),"Ações defensivas se sobrepõem")
	for _=1,math.ceil(Motion.duration(action)/.65*60)+2 do services.RunService.PreSimulation:Fire(1/60) end
	check(reentry.actors.action==nil,"Defesa não recuperou a espera: "..action)
end
check(not reentry:PreviewAction("InvalidAction"),"Comando desconhecido aceito")
check(reentry:PreviewAction("HighSave"),"Alta não reentra após recuperar")
for _=1,40 do services.RunService.PreSimulation:Fire(1/60) end
local animationConnection=reentry.actors.connection
reentry:Destroy();services.RunService.PreSimulation:Fire(1/60)
check(not animationConnection.Connected,"Saída no meio do mergulho vazou loop")
-- API outage leaves the approved environment/ball visible and offers a retry.
services.Players.LocalPlayer.UserId=2001;services.avatarQueryFailure=true
local failed=Preview.new(workspace,{quality="Baixa"});advance(1)
check(failed.model:GetAttribute("AvatarStatus")=="Error" and #failed.actors.rigs==0,"Falha não foi exposta sem dummy")
check(failed.ball.Parent==failed.model and failed.architecture.Parent==failed.model,"Falha do avatar interrompeu cenário")
services.avatarQueryFailure=false;failed:RetryAvatars();advance(.01)
check(failed.model:GetAttribute("AvatarStatus")=="Ready","Retry não recuperou avatar")
failed:Destroy()
-- Inaccessible cosmetic/animation assets never replace the identity or stop motion.
services.Players.LocalPlayer.UserId=2002
services.preloadAvatars=function(_,callback) callback("hair",Enum.AssetFetchStatus.Failure) end
services.trackFailure=true
local partial=Preview.new(workspace,{quality="Baixa"});advance(.01)
check(partial.model:GetAttribute("AvatarStatus")=="Ready" and partial.model:GetAttribute("AvatarMessage")~="","Cosmético indisponível não foi informado")
check(partial.actors.rigs[1].model:FindFirstChild("AccountHair")~=nil,"Cosmético foi removido silenciosamente")
check(partial.actors.rigs[1].model:GetAttribute("IdleTrackUnavailable"),"Falha de track não foi detectada")
local before=partial.actors.rigs[1].joints.Waist.Transform
services.RunService.PreSimulation:Fire(.1)
check(partial.actors.rigs[1].joints.Waist.Transform~=before,"Sem track, animação de futebol parou")
partial:Destroy();services.trackFailure=false;services.preloadAvatars=nil
-- Cancellation while a yielding API runs: late results must never recreate actors.
services.Players.LocalPlayer.UserId=2003;services.avatarQueryDelay=20
local late=Preview.new(workspace,{quality="Baixa"});advance(15.1)
check(late.model:GetAttribute("AvatarStatus")=="Slow","API lenta não informou estado")
late:Destroy();advance(5.1)
check(late.model.Parent==nil and #late.model:GetChildren()==0,"Resultado tardio ressuscitou arena")
services.avatarQueryDelay=nil
-- Different body proportions and new AnimationConstraint joints, no resizing by runtime.
for _,proportions in ipairs({{.75,1.15},{1.4,.9}}) do
	local model=FixtureRig.create({number=7},{id="stress",name="stress"},1)
	local yScale,xScale=proportions[1],proportions[2]
	local function scaled(cf)
		local p=cf.Position
		return CFrame.new(p.X*xScale,p.Y*yScale,p.Z*yScale)*cf.Rotation
	end
	for _,node in ipairs(model:GetDescendants()) do
		if node:IsA("BasePart") then node.Size=Vector3.new(node.Size.X*xScale,node.Size.Y*yScale,node.Size.Z*yScale);node.CFrame=scaled(node.CFrame)
		elseif node:IsA("Motor6D") then node.C0=scaled(node.C0);node.C1=scaled(node.C1) end
	end
	for _,node in ipairs(model:GetDescendants()) do
		if node:IsA("Motor6D") then
			local joint=Instance.new("AnimationConstraint");joint.Name=node.Name
			joint.Part0,joint.Part1,joint.C0,joint.C1=node.Part0,node.Part1,node.C0,node.C1
			joint.Parent=node.Parent;node:Destroy()
		end
	end
	local actor=AvatarRig.new(model,"striker",Layout.Striker,Layout.Ball)
	local originalSize=actor.feet.Left.part.Size
	local stressActions={"Kick"};for _,action in ipairs(Motion.SaveOrder) do table.insert(stressActions,action) end
	for _,action in ipairs(stressActions) do
	for sample=0,math.floor(Motion.duration(action)*30) do
		local t=sample/30
		local state=Motion.sample(if action=="Kick" then "striker" else "keeper",t,action,t,actor.scale,actor.width,actor.distance)
		actor:Apply(state,false)
		for _,side in ipairs({"Left","Right"}) do
			local foot=actor.feet[side].part
			check(AvatarRig.bottom(actor.frames[foot],foot.Size)>=.025,"Pé de avatar proporcional atravessou piso")
		end
		for _,joint in pairs(actor.joints) do check(joint.Transform.Position.Magnitude<.012,"Proporções esticaram articulação") end
		for part,frame in pairs(actor.frames) do if part~=actor.root then check(AvatarRig.bottom(frame,part.Size)>=.025,"Corpo proporcional atravessou gramado: "..t.." "..part.Name) end end
	end
	end
	check(actor.feet.Left.part.Size==originalSize,"Animação redimensionou o avatar")
	actor:Destroy()
end
print(string.format("PASS Penalty: %d assertions; numeric/matrix/API doubles only, no Roblox visual or performance certification.",assertions))
