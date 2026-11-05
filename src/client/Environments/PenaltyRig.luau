--!nonstrict
-- Retarget procedural football poses to the API-created avatar; never resize body/cosmetics.
local Rig={}
Rig.__index=Rig
local function dot(a,b) return a:Dot(b) end
local function align(a,b)
	a,b=a.Unit,b.Unit
	local axis=a:Cross(b)
	local cosine=math.clamp(dot(a,b),-1,1)
	if axis.Magnitude<.00001 then
		return if cosine>0 then CFrame.identity else CFrame.Angles(math.pi,0,0)
	end
	return CFrame.fromAxisAngle(axis.Unit,math.acos(cosine))
end
local function bottom(frame,size)
	local y=math.huge
	for _,x in ipairs({-1,1}) do for _,v in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
		y=math.min(y,frame:PointToWorldSpace(Vector3.new(x*size.X/2,v*size.Y/2,z*size.Z/2)).Y)
	end end end
	return y
end
function Rig:FK(rootFrame,pose)
	local frames={[self.root]=rootFrame}
	for _,entry in ipairs(self.chain) do
		local joint=entry.joint
		frames[joint.Part1]=frames[joint.Part0]*joint.C0*(pose[entry.name] or CFrame.identity)*joint.C1:Inverse()
	end
	return frames
end
function Rig.new(model,role,position,target)
	local self=setmetatable({model=model,role=role,joints={},chain={},tracks={},animations={},alive=true},Rig)
	self.root=model:FindFirstChild("HumanoidRootPart")
	self.humanoid=model:FindFirstChildOfClass("Humanoid")
	assert(self.root and self.humanoid and self.humanoid.RigType==Enum.HumanoidRigType.R15,"Avatar incompatível com R15")
	model.PrimaryPart=self.root
	for _,node in ipairs(model:GetDescendants()) do
		if node:IsA("BaseScript") then node:Destroy()
		elseif node:IsA("BasePart") then
			node.Anchored=node==self.root
			node.CanCollide,node.CanTouch,node.CanQuery=false,false,false
			node.Massless=node~=self.root
		elseif node:IsA("AnimationConstraint") or node:IsA("Motor6D") then
			local name=if node.Part0==self.root then "Root" else node.Name
			if node:IsA("AnimationConstraint") then node.IsKinematic=true;self.joints[name]=node
			elseif not self.joints[name] then self.joints[name]=node end
		end
	end
	local resolved={[self.root]=true}
	for _=1,16 do
		for name,joint in pairs(self.joints) do
			if not resolved[joint.Part1] and resolved[joint.Part0] then
				table.insert(self.chain,{name=name,joint=joint});resolved[joint.Part1]=true
			end
		end
	end
	for _,side in ipairs({"Left","Right"}) do
		for _,suffix in ipairs({"Hip","Knee","Ankle"}) do assert(self.joints[side..suffix],"Articulação R15 ausente: "..side..suffix) end
		assert(model:FindFirstChild(side.."Foot"),"Pé R15 ausente")
	end
	self.humanoid.AutoRotate=false
	self.humanoid.EvaluateStateMachine=false
	self.humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
	self.animator=self.humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	self.animator.Parent=self.humanoid
	self.base=CFrame.lookAt(Vector3.new(position[1],0,position[3]),Vector3.new(target[1],0,target[3]))
	local rest=self:FK(CFrame.identity,{})
	self.rest=rest
	self.feet={}
	local floor=math.huge
	for _,side in ipairs({"Left","Right"}) do
		local foot=model:FindFirstChild(side.."Foot")
		floor=math.min(floor,bottom(rest[foot],foot.Size))
		self.feet[side]={part=foot,rotation=rest[foot].Rotation,z=rest[foot].Position.Z}
	end
	self.height=.035-floor
	self.width=math.max(.12,(math.abs(rest[self.feet.Left.part].Position.X)+math.abs(rest[self.feet.Right.part].Position.X))/2)
	local hip,knee,ankle=self.joints.LeftHip,self.joints.LeftKnee,self.joints.LeftAnkle
	self.leg=(knee.C0.Position-hip.C1.Position).Magnitude+(ankle.C0.Position-knee.C1.Position).Magnitude
	self.scale=self.leg/2.1
	self.distance=math.max(self.leg,(Vector3.new(target[1],0,target[3])-self.base.Position).Magnitude-.85*self.scale)
	model:SetAttribute("PresentationOnly",true)
	model:SetAttribute("FootballRole",role)
	return self
end
function Rig:FootTarget(side,target,angle)
	local foot=self.feet[side]
	local rotation=self.base.Rotation*foot.rotation*CFrame.Angles(math.rad(angle or 0),0,0)
	local center=Vector3.new(target.X,0,target.Z+foot.z)
	local world=self.base:PointToWorldSpace(center)
	local raised=-bottom(rotation,foot.part.Size)+.035+target.Y
	return CFrame.new(world.X,raised,world.Z)*rotation
end
function Rig:SolveLeg(side,frames,pose,target)
	local hip,knee,ankle=self.joints[side.."Hip"],self.joints[side.."Knee"],self.joints[side.."Ankle"]
	local hipFrame=frames[hip.Part0]*hip.C0
	local h=hipFrame.Position
	local a=(target*ankle.C1).Position
	local upperBone=knee.C0.Position-hip.C1.Position
	local lowerBone=ankle.C0.Position-knee.C1.Position
	local l1,l2=upperBone.Magnitude,lowerBone.Magnitude
	local delta=a-h
	local distance=math.clamp(delta.Magnitude,math.abs(l1-l2)+.001,l1+l2-.001)
	local direction=delta.Unit
	local front=self.base.LookVector
	local pole=(front-direction*dot(direction,front)).Unit
	local along=(l1*l1+distance*distance-l2*l2)/(2*distance)
	local bend=math.sqrt(math.max(0,l1*l1-along*along))
	local k=h+direction*along+pole*bend
	local upperRest=self.base.Rotation*self.rest[hip.Part1].Rotation
	local upperRotation=align(upperRest:VectorToWorldSpace(upperBone),k-h)*upperRest
	local upper=CFrame.new(h-upperRotation:VectorToWorldSpace(hip.C1.Position))*upperRotation
	local lowerRest=self.base.Rotation*self.rest[knee.Part1].Rotation
	local lowerRotation=align(lowerRest:VectorToWorldSpace(lowerBone),a-k)*lowerRest
	local lower=CFrame.new(k-lowerRotation:VectorToWorldSpace(knee.C1.Position))*lowerRotation
	pose[side.."Hip"]=hipFrame:ToObjectSpace(upper*hip.C1)
	pose[side.."Knee"]=(upper*knee.C0):ToObjectSpace(lower*knee.C1)
	pose[side.."Ankle"]=(lower*ankle.C0):ToObjectSpace(target*ankle.C1)
end
function Rig:Apply(state,initial)
	local pose=table.clone(state.pose)
	local rootFrame=self.base*CFrame.new(state.root.X,self.height+state.root.Y,state.root.Z)*CFrame.Angles(0,0,math.rad(state.roll))
	local frames=self:FK(rootFrame,pose)
	if state.grounded then
		local targets={Left=self:FootTarget("Left",state.left),Right=self:FootTarget("Right",state.right,state.footAngle)}
		-- Lower pelvis when required by stride/proportions, keeping support feet planted.
		local correction=0
		for _,side in ipairs({"Left","Right"}) do
			local hip,knee,ankle=self.joints[side.."Hip"],self.joints[side.."Knee"],self.joints[side.."Ankle"]
			local delta=(targets[side]*ankle.C1).Position-(frames[hip.Part0]*hip.C0).Position
			local reach=(knee.C0.Position-hip.C1.Position).Magnitude+(ankle.C0.Position-knee.C1.Position).Magnitude-.004
			local horizontal=delta.X*delta.X+delta.Z*delta.Z
			local vertical=math.sqrt(math.max(.01,reach*reach-horizontal))
			correction=math.min(correction,delta.Y+vertical)
		end
		rootFrame+=Vector3.new(0,correction,0)
		frames=self:FK(rootFrame,pose)
		for _,side in ipairs({"Left","Right"}) do self:SolveLeg(side,frames,pose,targets[side]) end
		frames=self:FK(rootFrame,pose)
	else
		-- Keep body above the plane during landing/get-up; ignore decorative accessories.
		local minimum=math.huge
		for part,frame in pairs(frames) do if part~=self.root then minimum=math.min(minimum,bottom(frame,part.Size)) end end
		if minimum<.035 then rootFrame+=Vector3.new(0,.035-minimum,0);frames=self:FK(rootFrame,pose) end
	end
	self.root.CFrame=rootFrame
	for name,joint in pairs(self.joints) do joint.Transform=pose[name] or CFrame.identity end
	self.frames=frames
	if initial then
		-- First pose is baked OFF Workspace; Animator/Transform updates follow thereafter.
		for part,frame in pairs(frames) do part.CFrame=frame end
		for _,node in ipairs(self.model:GetDescendants()) do
			if node:IsA("Weld") and node.Part0 and node.Part1 then node.Part1.CFrame=node.Part0.CFrame*node.C0*node.C1:Inverse() end
		end
	end
end
function Rig:StartTracks()
	-- Only the user's actual idle pack is eligible as a subtle baseline. Football
	-- limbs are authored procedurally; no unrelated catalog kick/dive IDs are guessed.
	local id=self.model:GetAttribute("AvatarIdleAnimation")
	if type(id)~="number" or id<=0 then return end
	task.spawn(function()
		if not self.alive then return end
		local animation=Instance.new("Animation")
		animation.AnimationId="rbxassetid://"..tostring(id)
		table.insert(self.animations,animation)
		local ok,track=pcall(function() return self.animator:LoadAnimation(animation) end)
		if not ok then if self.alive then self.model:SetAttribute("IdleTrackUnavailable",true) end;return end
		if not self.alive then track:Destroy();return end
		track.Priority=Enum.AnimationPriority.Idle
		track.Looped=true
		track:Play(.3,.15,1)
		table.insert(self.tracks,track)
	end)
end
function Rig:Destroy()
	if not self.alive then return end
	self.alive=false
	for _,track in ipairs(self.tracks) do track:Stop(0);track:Destroy() end
	for _,animation in ipairs(self.animations) do animation:Destroy() end
	table.clear(self.tracks);table.clear(self.animations)
	self.model:Destroy()
	table.clear(self.frames or {});table.clear(self.joints);table.clear(self.chain)
end
Rig.bottom=bottom
return Rig
