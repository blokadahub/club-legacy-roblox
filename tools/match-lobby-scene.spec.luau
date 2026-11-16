-- Runs after penalty regressions, using the same matrix/virtual-clock doubles.
do
local Layout=require(moduleNodes["src/client/Environments/MatchLobbyLayout.luau"])
local Lobby=require(moduleNodes["src/client/Environments/MatchLobbyScene.luau"])
local Appearance=require(moduleNodes["src/client/AvatarAppearance.luau"])
local start=assertions
-- Correct absolute scale semantics for this fixture; production uses Model API.
local previousScale=methods.ScaleTo
function methods:GetScale() return self._props.ModelScale or 1 end
function methods:ScaleTo(value)
	local ratio=value/self:GetScale()
	previousScale(self,ratio);self._props.ModelScale=value
end
local oldIsA=methods.IsA
function methods:IsA(className)
	return oldIsA(self,className) or className=="LuaSourceContainer" and (self.ClassName=="Script" or self.ClassName=="LocalScript" or self.ClassName=="ModuleScript")
end
services.avatarQueryFailure=false;services.avatarQueryDelay=nil
local calls=0
function services.Players:GetHumanoidDescriptionFromUserIdAsync(id)
	calls+=1;check(id==self.LocalPlayer.UserId,"Lobby loaded another account")
	if services.lobbyAvatarFailure then error("Injected avatar failure") end
	if services.lobbyAvatarDelay then task.wait(services.lobbyAvatarDelay) end
	local d=Instance.new("HumanoidDescription");d.IdleAnimation=0
	return d
end
function services.Players:CreateHumanoidModelFromDescriptionAsync(_,rigType)
	check(rigType==Enum.HumanoidRigType.R15,"Not an official R15 request")
	local model=FixtureRig.create({number=1},{id="fixture",name="Fixture"},1)
	local script=Instance.new("LocalScript");script.Parent=model
	local shirt=Instance.new("Shirt");shirt.Parent=model
	local hair=Instance.new("Accessory");hair.Name="AccountHair";hair.Parent=model
	local handle=Instance.new("Part");handle.Name="Handle";handle.Size=Vector3.new(1,.4,1)
	handle.CFrame=model.Head.CFrame*CFrame.new(0,.65,0);handle.Parent=hair
	local weld=Instance.new("Weld");weld.Name="AccessoryWeld";weld.Part0=handle;weld.Part1=model.Head;weld.Parent=handle
	if services.lobbyLayered then local wrap=Instance.new("WrapLayer");wrap.Parent=handle end
	if services.lobbyConstraint then
		for _,joint in ipairs(model:GetDescendants()) do
			if joint:IsA("Motor6D") then
				local c=Instance.new("AnimationConstraint");c.Name=joint.Name;c.Parent=joint.Parent;joint:Destroy()
			end
		end
	end
	if services.lobbyBroken then model.LeftFoot:Destroy() end
	return model
end
Appearance.invalidate(services.Players.LocalPlayer.UserId)
local originalCharacter=Instance.new("Model");originalCharacter.Name="UntouchedCharacter"
services.Players.LocalPlayer.Character=originalCharacter
local parent=Instance.new("Folder");parent.Parent=workspace
local baselineChildren=#workspace:GetChildren()
local lobby=Lobby.new(parent,Data.clubs[1],{quality="Alta"})
local Scope=require(moduleNodes["src/client/Scope.luau"])
local uiRoot=Instance.new("Frame");uiRoot.Parent=playerGui
local uiScope=Scope.new();uiScope.inputsPaused=true
require(moduleNodes["src/client/Screens/MatchLobby.luau"])(uiRoot,{scope=uiScope,state={homeClub=1,settings={}},scene={matchLobby=lobby},go=function() end,notify=function() end})
check(lobby.model:GetAttribute("AvatarStatus")=="loading" and not lobby.avatar.model,"Fake fallback used before account load")
advance(.02)
check(lobby.model:GetAttribute("AvatarStatus")=="ready","Avatar mount failed: "..tostring(lobby.model:GetAttribute("AvatarMessage")))
check(uiRoot:FindFirstChild("EstadoAvatar",true).Text=="Uniforme de treino CL-27","Input lock lost avatar completion status")
uiScope:Destroy();uiRoot:Destroy()
local model=lobby.avatar.model
check(model and model:FindFirstChildOfClass("Humanoid").RigType==Enum.HumanoidRigType.R15,"Missing R15")
check(model:FindFirstChild("AccountHair")~=nil,"Compatible accessory removed")
check(model:GetAttribute("AvatarUserId")==services.Players.LocalPlayer.UserId,"Lost real account metadata")
check(services.Players.LocalPlayer.Character==originalCharacter and #originalCharacter:GetChildren()==0,"Modified Player.Character")
check(model:FindFirstChild("UniformeOriginalCL27",true)~=nil,"Plain original kit not applied to compatible body")
check(model:FindFirstChildOfClass("LocalScript")==nil,"Avatar executes cloned script")
local root=model.HumanoidRootPart
for _,p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") then check(not p.CanCollide and not p.CanTouch and not p.CanQuery and p.Anchored==(p==root),"Unsafe presentation part") end
end
local bottom=math.min(model.LeftFoot.Position.Y-model.LeftFoot.Size.Y/2,model.RightFoot.Position.Y-model.RightFoot.Size.Y/2)
check(near(bottom,Layout.Avatar.position[2]),"Avatar floats or penetrates floor")
local camera=CFrame.lookAt(vec(Layout.Camera.position),vec(Layout.Camera.target))
local minX,maxX,minY,maxY=math.huge,-math.huge,math.huge,-math.huge
for _,part in ipairs(model:GetDescendants()) do
	if part:IsA("BasePart") then
		for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
			local p=camera:PointToObjectSpace(part.CFrame:PointToWorldSpace(Vector3.new(x*part.Size.X/2,y*part.Size.Y/2,z*part.Size.Z/2)))
			local h=2*-p.Z*math.tan(math.rad(Layout.Camera.fov/2))
			local u,v=.5+p.X/(h*16/9),.5-p.Y/h
			minX=math.min(minX,u);maxX=math.max(maxX,u);minY=math.min(minY,v);maxY=math.max(maxY,v)
		end end end
	end
end
check(minX>.77 and maxX<.98 and minY>.20 and maxY<.87,"Full avatar outside right presentation region")
print("Match lobby numeric avatar bounds",minX,maxX,minY,maxY)
check(#Layout.build()<70 and #lobby.lights==4,"Excessive geometry or lights")
local oldStep=lobby.avatar.step
services.RunService.PreSimulation:Fire(.1)
check(lobby.avatar.joints.Waist.Transform~=nil,"Subtle idle absent")
lobby:ApplySettings({quality="Baixa",reducedMotion=true})
check(not oldStep.Connected and not lobby.avatar.step,"Reduced motion keeps idle loop")
local lightCount=0;for _,l in ipairs(lobby.lights) do if l.Enabled then lightCount+=1 end end
check(lightCount==2,"Low quality light budget wrong")
lobby:ApplySettings({quality="Alta",reducedMotion=false})
local step=lobby.avatar.step;lobby:Destroy()
check(not step.Connected and model.Destroyed and lobby.model.Destroyed,"Exit leaks avatar/idle/scene")
for _=1,10 do
	local instance=Lobby.new(parent,Data.clubs[1],{reducedMotion=true})
	advance(.01);check(instance.model:GetAttribute("AvatarStatus")=="ready","Cached appearance lost")
	instance:Destroy()
end
check(calls==1 and #parent:GetChildren()==0,"Repeated navigation refetches appearance or leaves rigs")
Appearance.invalidate(services.Players.LocalPlayer.UserId)
services.lobbyLayered=true;services.lobbyConstraint=true
local layered=Lobby.new(parent,Data.clubs[1],{reducedMotion=true});advance(.02)
check(layered.model:GetAttribute("AvatarStatus")=="ready","AnimationConstraint rig rejected")
check(layered.avatar.model:FindFirstChildOfClass("Shirt")~=nil and layered.model:GetAttribute("AvatarOutfit")=="Aparência da sua conta","Layered outfit destroyed")
check(layered.avatar.joints.Waist.IsKinematic,"Avatar Joint Upgrade not kinematic")
layered:Destroy();services.lobbyLayered=false;services.lobbyConstraint=false
Appearance.invalidate(services.Players.LocalPlayer.UserId)
services.lobbyAvatarFailure=true
local failed=Lobby.new(parent,Data.clubs[1],{})
advance(.9)
check(failed.model:GetAttribute("AvatarStatus")=="error" and not failed.avatar.model,"Failed appearance creates substitute mannequin")
services.lobbyAvatarFailure=false;failed:RetryAvatar();advance(.02)
check(failed.model:GetAttribute("AvatarStatus")=="ready","Retry cannot recover appearance")
failed:Destroy()
Appearance.invalidate(services.Players.LocalPlayer.UserId)
services.lobbyAvatarDelay=.25
local late=Lobby.new(parent,Data.clubs[1],{})
advance(.01);late:Destroy();advance(.4)
check(#parent:GetChildren()==0 and not late.avatar,"Late callback resurrects disposed rig")
services.lobbyAvatarDelay=nil
Appearance.invalidate(services.Players.LocalPlayer.UserId)
services.lobbyBroken=true
local broken=Lobby.new(parent,Data.clubs[1],{});advance(.02)
check(broken.model:GetAttribute("AvatarStatus")=="error" and not broken.avatar.model,"Incomplete R15 not rejected safely")
services.lobbyBroken=false;broken:RetryAvatar();advance(.02)
check(broken.model:GetAttribute("AvatarStatus")=="ready","Fresh appearance not requested after invalid cached rig")
broken:Destroy()
Appearance.invalidate(services.Players.LocalPlayer.UserId)
services.lobbyAvatarDelay=13
local slow=Lobby.new(parent,Data.clubs[1],{});advance(12.1)
check(slow.model:GetAttribute("AvatarStatus")=="error" and not slow.avatar.model,"Slow appearance traps loading forever")
advance(1.1);slow:RetryAvatar();advance(.02)
check(slow.model:GetAttribute("AvatarStatus")=="ready","Timeout retry cannot recover cached arrival")
slow:Destroy();services.lobbyAvatarDelay=nil
check(#workspace:GetChildren()==baselineChildren,"Architecture leaked into Workspace")
-- Only Scene owns the camera/Lighting; switching back restores prior mode values.
local baselineLight=services.Lighting.Brightness
local scene=Scene.new({quality="Alta",reducedMotion=true})
scene:Show("Arena",Data.clubs[1],Data.clubs[2],1,1);advance(.4)
local arenaBrightness=services.Lighting.Brightness
scene:Show("MatchLobby",Data.clubs[1],Data.clubs[2],1,1);advance(.02)
local env=scene.matchLobby
check(env and scene.mode=="MatchLobby" and services.Lighting.Brightness==Layout.Environment.Brightness,"Scene did not apply lobby profile")
scene:Show("MatchLobby",Data.clubs[1],Data.clubs[2],1,1)
check(scene.matchLobby==env,"Same-mode selection rebuilt environment")
services.RunService.RenderStepped:Fire(.1)
local frame=workspace.CurrentCamera.CFrame
services.RunService.RenderStepped:Fire(.1)
check((frame.Position-workspace.CurrentCamera.CFrame.Position).Magnitude==0,"Lobby camera drifts")
local previousViewport=workspace.CurrentCamera.ViewportSize
for _,size in ipairs({{1600,900},{1920,1080},{2560,1080},{1024,768},{854,393},{720,360},{640,360},{568,320}}) do
	local width,height=table.unpack(size)
	workspace.CurrentCamera.ViewportSize=Vector2.new(width,height)
	local scale=math.min((width-80)/1600,(height-44)/900)
	scene.canvasHeight=900*scale
	scene.canvasCenter=Vector2.new(width/2+20,height/2+10)
	services.RunService.RenderStepped:Fire(.01)
	local actual=workspace.CurrentCamera
	local p=actual.CFrame:PointToObjectSpace(vec(Layout.Avatar.position))
	local h=2*-p.Z*math.tan(math.rad(actual.FieldOfView/2))
	local screen=Vector2.new(width/2+p.X*height/h,height/2-p.Y*height/h)
	local at=(screen-scene.canvasCenter)/scale+Vector2.new(800,450)
	check(at.X>1300 and at.X<1460 and at.Y>735 and at.Y<780,"Safe canvas camera/avatar misalignment")
end
workspace.CurrentCamera.ViewportSize=previousViewport
scene:Show("Arena",Data.clubs[1],Data.clubs[2],1,1);advance(.4)
check(env.model.Destroyed and scene.matchLobby==nil and services.Lighting.Brightness==arenaBrightness,"Leaving lobby fails cleanup/lighting restoration")
scene:Destroy()
check(services.Lighting.Brightness==baselineLight,"Destroy did not restore initial lighting")
parent:Destroy();originalCharacter:Destroy();services.Players.LocalPlayer.Character=nil
print(string.format("PASS Match lobby scene: %d assertions; R15 API fixtures, failures, cache, projection, lighting and disposal. Not Roblox rendering.",assertions-start))
end
