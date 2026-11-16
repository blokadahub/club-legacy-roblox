--!nonstrict
-- One genuine R15 copy. Official appearance/cache stays in AvatarAppearance.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Appearance=require(script.Parent.Parent.AvatarAppearance)
local Scope=require(script.Parent.Parent.Scope)
local Layout=require(script.Parent.MatchLobbyLayout)
local Avatar={}
Avatar.__index=Avatar
local POSE={LeftShoulder=CFrame.Angles(0,0,math.rad(-7)),RightShoulder=CFrame.Angles(0,0,math.rad(7)),
	LeftElbow=CFrame.Angles(math.rad(-10),0,0),RightElbow=CFrame.Angles(math.rad(-10),0,0)}

-- An original plain training kit is possible on untextured classic R15 bodies.
-- Layered garments / textured body bundles retain their account appearance.
local function uniform(model,club)
	local names={"UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg"}
	for _,object in ipairs(model:GetDescendants()) do if object:IsA("WrapLayer") then return false end end
	for _,name in ipairs(names) do
		local part=model:FindFirstChild(name)
		if not part or (part:IsA("MeshPart") and part.TextureID~="") then return false end
	end
	for _,object in ipairs(model:GetChildren()) do
		if object:IsA("Shirt") or object:IsA("Pants") or object:IsA("ShirtGraphic") then object:Destroy() end
	end
	for _,name in ipairs(names) do
		local p=model:FindFirstChild(name)
		p.Color=if string.find(name,"Leg") or name=="LowerTorso" then Color3.fromRGB(30,34,37) else club.primary
	end
	local torso=model:FindFirstChild("UpperTorso")
	local gui=Instance.new("SurfaceGui")
	gui.Name="UniformeOriginalCL27";gui.Face=Enum.NormalId.Front
	gui.CanvasSize=Vector2.new(512,512);gui.LightInfluence=1;gui.AlwaysOnTop=false
	gui.Parent=torso
	local label=Instance.new("TextLabel")
	label.Size=UDim2.fromScale(.9,.22);label.Position=UDim2.fromScale(.05,.35)
	label.BackgroundTransparency=1;label.Text="CL 27";label.TextColor3=Color3.fromRGB(232,237,231)
	label.Font=Enum.Font.GothamBold;label.TextScaled=true;label.Parent=gui
	return true
end
function Avatar.new(parent,club,settings)
	local self=setmetatable({scope=Scope.new(),parent=parent,club=club,settings=settings or {},joints={},elapsed=0},Avatar)
	self.scope:Add(function()
		if self.cancel then self.cancel();self.cancel=nil end
		if self.step then self.step:Disconnect();self.step=nil end
		if self.model then self.model:Destroy();self.model=nil end
		table.clear(self.joints)
	end)
	self:Load()
	return self
end
function Avatar:_status(status,message)
	self.parent:SetAttribute("AvatarMessage",message or "")
	self.parent:SetAttribute("AvatarStatus",status)
end
function Avatar:_pose(dt)
	self.elapsed+=math.min(dt,.1)
	local breath=if self.settings.reducedMotion then 0 else math.sin(self.elapsed*1.3)*.008
	for name,joint in pairs(self.joints) do
		joint.Transform=if name=="Waist" then CFrame.Angles(breath,math.rad(-3),0)
			elseif name=="Neck" then CFrame.Angles(-breath*.5,math.rad(3),0)
			else POSE[name] or CFrame.identity
	end
end
function Avatar:ApplySettings(settings)
	self.settings=settings or self.settings
	if self.step then self.step:Disconnect();self.step=nil end
	if self.model then
		self:_pose(0)
		if not self.settings.reducedMotion then
			self.step=RunService.PreSimulation:Connect(function(dt) if self.scope.alive then self:_pose(dt) end end)
		end
	end
end
function Avatar:_mount(model)
	local root=model:FindFirstChild("HumanoidRootPart")
	local humanoid=model:FindFirstChildOfClass("Humanoid")
	assert(root and humanoid and humanoid.RigType==Enum.HumanoidRigType.R15,"Avatar R15 incompleto")
	model.Name="CL27_TecnicoR15";model.PrimaryPart=root
	for _,item in ipairs(model:GetDescendants()) do
		if item:IsA("LuaSourceContainer") then item:Destroy()
		elseif item:IsA("BasePart") then
			item.Anchored=item==root;item.CanCollide=false;item.CanTouch=false;item.CanQuery=false
			item.Massless=item~=root;item.CastShadow=true
		elseif item:IsA("AnimationConstraint") then
			item.IsKinematic=true;self.joints[item.Name]=item
		elseif item:IsA("Motor6D") and not self.joints[item.Name] then self.joints[item.Name]=item end
	end
	for _,accessory in ipairs(model:GetChildren()) do
		if accessory:IsA("Accessory") then
			local handle=accessory:FindFirstChild("Handle")
			local weld=handle and handle:FindFirstChild("AccessoryWeld")
			if not weld or not weld.Part1 then accessory:Destroy() end
		end
	end
	humanoid.AutoRotate=false;humanoid.EvaluateStateMachine=false
	humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
	local kit=uniform(model,self.club)
	self.parent:SetAttribute("AvatarOutfit",if kit then "Uniforme de treino CL-27" else "Aparência da sua conta")
	local _,bounds=model:GetBoundingBox()
	assert(bounds.Y>.1 and bounds.X>.1,"Dimensões do avatar inválidas")
	-- Uniform scale preserves proportions. Accessories are included in the frame.
	model:ScaleTo(model:GetScale()*math.min(Layout.Avatar.maxHeight/bounds.Y,Layout.Avatar.maxWidth/math.max(bounds.X,bounds.Z)))
	local position=Vector3.new(table.unpack(Layout.Avatar.position))
	local eye=Vector3.new(table.unpack(Layout.Camera.position))
	model:PivotTo(CFrame.lookAt(position,Vector3.new(eye.X,position.Y,eye.Z)))
	local left,right=model:FindFirstChild("LeftFoot"),model:FindFirstChild("RightFoot")
	assert(left and right,"Pés R15 ausentes")
	local bottom=math.min(left.Position.Y-left.Size.Y/2,right.Position.Y-right.Size.Y/2)
	model:PivotTo(model:GetPivot()+Vector3.new(0,position.Y-bottom,0))
	model.Parent=self.parent
	self.model=model
	self:ApplySettings(self.settings)
end
function Avatar:Load()
	if not self.scope.alive or self.loading then return end
	if self.model then return end
	if self.cancel then self.cancel();self.cancel=nil end
	if self.failedMount then
		Appearance.invalidate(Players.LocalPlayer.UserId);self.failedMount=false
	end
	self.requestId=(self.requestId or 0)+1
	local requestId=self.requestId
	self.loading=true;self:_status("loading","Carregando a aparência da sua conta…")
	local timeout=self.scope:Delay(12,function()
		if self.loading and self.requestId==requestId then
			if self.cancel then self.cancel();self.cancel=nil end
			self.loading=false
			self:_status("error","A aparência demorou para carregar. Tente novamente.")
		end
	end)
	self.cancel=Appearance.request(Players.LocalPlayer,function(model,err,warning)
		if not self.scope.alive then if model then model:Destroy() end;return end
		if timeout then pcall(task.cancel,timeout);self.scope.delays[timeout]=nil end
		self.loading=false
		if not model then self:_status("error",err);return end
		local ok,reason=pcall(function() self:_mount(model) end)
		if not ok then
			if self.step then self.step:Disconnect();self.step=nil end
			model:Destroy();self.model=nil;table.clear(self.joints)
			self.failedMount=true
			self:_status("error","Não foi possível apresentar seu avatar. Tente novamente.")
			warn("[CL27/MatchLobbyAvatar] "..tostring(reason));return
		end
		self.parent:SetAttribute("AvatarWarning",warning or "")
		self:_status("ready",warning or "Seu avatar • técnico do clube")
	end)
end
function Avatar:Destroy()
	if not self.scope.alive then return end
	self.scope:Destroy()
end
return Avatar
