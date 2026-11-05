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
local parent=Instance.new("Folder");parent.Parent=workspace
local lobby=Instance.new("Folder");lobby.Parent=workspace
local originalBall=MenuAvatar.createFallbackBall(lobby,1)
local scene=Preview.new(parent,{quality="Alta"})
local fallback=scene.ball
check(fallback~=originalBall and originalBall.Parent==lobby,"Arena moveu a bola original do lobby")
check(near(fallback:GetPivot().Position.Y,Layout.BallDiameter/2),"Bola flutuando acima da marca")
for _,name in ipairs({"CobradorR15","GoleiroR15"}) do
	local actor=scene.model:FindFirstChild(name)
	check(actor and actor.Humanoid.RigType==Enum.HumanoidRigType.R15,"Personagem R15 ausente")
	for _,part in ipairs(actor:GetDescendants()) do
		if part:IsA("BasePart") then check(part.Anchored and not part.CanCollide,"Ator estático com física ativa") end
	end
	for _,side in ipairs({"LeftSola","RightSola"}) do
		local foot=actor:FindFirstChild(side)
		local bottom=math.huge
		for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
			bottom=math.min(bottom,foot.CFrame:PointToWorldSpace(Vector3.new(x*foot.Size.X/2,y*foot.Size.Y/2,z*foot.Size.Z/2)).Y)
		end end end
		check(bottom>=.034 and bottom<.10,"Pé flutuando ou atravessando gramado: "..name.." "..bottom)
	end
	check(actor.Head.Position.Y>4.7 and actor.Head.Position.Y<5.7,"Altura corporal incoerente")
	local look=actor.HumanoidRootPart.CFrame.LookVector
	check(name=="CobradorR15" and look.Z<-.8 or name=="GoleiroR15" and look.Z>.95,"Personagem orientado para lado errado")
	local ax,ay=project(actor.Head.Position)
	check(ax>.25 and ax<.56 and ay>.20 and ay<.60,"Personagem sai do enquadramento")
end
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
scene:Destroy();scene:Destroy()
check(#parent:GetChildren()==0,"Arena permaneceu no Workspace após destruir")
for _,connection in ipairs(callbacks) do check(not connection.Connected,"Conexão de asset vazou") end
assets.ChildAdded:Fire(template)
check(#parent:GetChildren()==0,"Asset tardio recriou cena encerrada")
-- Real Scene, single camera owner, neutral daylight and settings restoration.
local owner=Scene.new({quality="Alta"})
owner:Show("Penalty",Data.clubs[1],Data.clubs[2],1,1)
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
print(string.format("PASS Penalty: %d assertions; numeric/matrix/API doubles only, no Roblox visual or performance certification.",assertions))
