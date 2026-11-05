-- Matrix-only API doubles for static pose/projection checks. Never a Roblox renderer.
local function dot(a,b) return a.X*b.X+a.Y*b.Y+a.Z*b.Z end
local function cross(a,b) return Vector3.new(a.Y*b.Z-a.Z*b.Y,a.Z*b.X-a.X*b.Z,a.X*b.Y-a.Y*b.X) end
local function frame(position,r)
	return typed("CFrame",{Position=position,r=r or {1,0,0,0,1,0,0,0,1}},cfMeta)
end
local function rotate(r,v)
	return Vector3.new(r[1]*v.X+r[2]*v.Y+r[3]*v.Z,r[4]*v.X+r[5]*v.Y+r[6]*v.Z,r[7]*v.X+r[8]*v.Y+r[9]*v.Z)
end
cfMeta.__mul=function(a,b)
	local r={}
	for i=0,2 do for j=1,3 do
		r[i*3+j]=a.r[i*3+1]*b.r[j]+a.r[i*3+2]*b.r[3+j]+a.r[i*3+3]*b.r[6+j]
	end end
	return frame(a.Position+rotate(a.r,b.Position),r)
end
cfMeta.__add=function(a,b) return frame(a.Position+b,a.r) end
local cfMethods={}
cfMeta.__index=function(self,key)
	if key=="LookVector" then return Vector3.new(-self.r[3],-self.r[6],-self.r[9]) end
	if key=="RightVector" then return Vector3.new(self.r[1],self.r[4],self.r[7]) end
	if key=="UpVector" then return Vector3.new(self.r[2],self.r[5],self.r[8]) end
	return cfMethods[key]
end
function cfMethods:Inverse()
	local m=self.r
	local r={m[1],m[4],m[7],m[2],m[5],m[8],m[3],m[6],m[9]}
	return frame(-rotate(r,self.Position),r)
end
function cfMethods:ToObjectSpace(other) return self:Inverse()*other end
function cfMethods:PointToWorldSpace(v) return self.Position+rotate(self.r,v) end
function cfMethods:PointToObjectSpace(v) return rotate(self:Inverse().r,v-self.Position) end
CFrame.new=function(x,y,z,...)
	local rotation={...}
	return frame(if typeof(x)=="Vector3" then x else Vector3.new(x,y,z),if #rotation==9 then rotation else nil)
end
CFrame.Angles=function(x,y,z)
	local cx,sx,cy,sy,cz,sz=math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
	return frame(Vector3.zero,{1,0,0,0,cx,-sx,0,sx,cx})
		*frame(Vector3.zero,{cy,0,sy,0,1,0,-sy,0,cy})
		*frame(Vector3.zero,{cz,-sz,0,sz,cz,0,0,0,1})
end
CFrame.lookAt=function(position,target)
	local back=(position-target).Unit
	local right=cross(Vector3.new(0,1,0),back).Unit
	if right.Magnitude<0.5 then right=Vector3.new(1,0,0) end
	local up=cross(back,right)
	return frame(position,{right.X,up.X,back.X,right.Y,up.Y,back.Y,right.Z,up.Z,back.Z})
end
CFrame.identity=CFrame.new()
function methods:GetPivot() return self._props.Pivot or (self.PrimaryPart and self.PrimaryPart.CFrame) or self.WorldPivot or CFrame.identity end
function methods:PivotTo(value)
	local delta=value*self:GetPivot():Inverse()
	for _,part in ipairs(self:GetDescendants()) do if part:IsA("BasePart") then part.CFrame=delta*part.CFrame end end
	self._props.Pivot=value
end
function methods:GetBoundingBox()
	local low,high=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
	for _,part in ipairs(self:GetDescendants()) do
		if part:IsA("BasePart") then
			for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
				local v=part.CFrame:PointToWorldSpace(Vector3.new(x*part.Size.X/2,y*part.Size.Y/2,z*part.Size.Z/2))
				low=Vector3.new(math.min(low.X,v.X),math.min(low.Y,v.Y),math.min(low.Z,v.Z))
				high=Vector3.new(math.max(high.X,v.X),math.max(high.Y,v.Y),math.max(high.Z,v.Z))
			end end end
		end
	end
	return CFrame.new((low+high)/2),high-low
end
function methods:ScaleTo(scale)
	local pivot=self:GetPivot()
	for _,part in ipairs(self:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Size=part.Size*scale
			part.CFrame=pivot*CFrame.new(pivot:PointToObjectSpace(part.Position)*scale)
		end
	end
end
-- Additional official API doubles used by the real-avatar correction suite.
local vectorIndex=vectorMeta.__index
vectorMeta.__index=function(self,key)
	if key=="Dot" then return dot end
	if key=="Cross" then return cross end
	if key=="Lerp" then return function(a,b,t) return a+(b-a)*t end end
	return vectorIndex(self,key)
end
local frameIndex=cfMeta.__index
cfMeta.__index=function(self,key)
	if key=="Rotation" then return frame(Vector3.zero,self.r) end
	return frameIndex(self,key)
end
function cfMethods:VectorToWorldSpace(v) return rotate(self.r,v) end
function cfMethods:Lerp(other,t)
	-- Quaternion slerp: preserve orthonormal rotation during pose blending.
	local function quat(m)
		local trace=m[1]+m[5]+m[9]
		local x,y,z,w
		if trace>0 then local s=math.sqrt(trace+1)*2;w=.25*s;x=(m[8]-m[6])/s;y=(m[3]-m[7])/s;z=(m[4]-m[2])/s
		elseif m[1]>m[5] and m[1]>m[9] then local s=math.sqrt(1+m[1]-m[5]-m[9])*2;w=(m[8]-m[6])/s;x=.25*s;y=(m[2]+m[4])/s;z=(m[3]+m[7])/s
		elseif m[5]>m[9] then local s=math.sqrt(1+m[5]-m[1]-m[9])*2;w=(m[3]-m[7])/s;x=(m[2]+m[4])/s;y=.25*s;z=(m[6]+m[8])/s
		else local s=math.sqrt(1+m[9]-m[1]-m[5])*2;w=(m[4]-m[2])/s;x=(m[3]+m[7])/s;y=(m[6]+m[8])/s;z=.25*s end
		return {x,y,z,w}
	end
	local a,b=quat(self.r),quat(other.r)
	local cosine=0
	for i=1,4 do cosine+=a[i]*b[i] end
	if cosine<0 then for i=1,4 do b[i]=-b[i] end;cosine=-cosine end
	local wa,wb=1-t,t
	if cosine<.9995 then local angle=math.acos(math.clamp(cosine,-1,1));wa=math.sin((1-t)*angle)/math.sin(angle);wb=math.sin(t*angle)/math.sin(angle) end
	local q,n={},0
	for i=1,4 do q[i]=a[i]*wa+b[i]*wb;n+=q[i]*q[i] end
	for i=1,4 do q[i]/=math.sqrt(n) end
	local x,y,z,w=table.unpack(q)
	return frame(self.Position:Lerp(other.Position,t),{1-2*y*y-2*z*z,2*x*y-2*z*w,2*x*z+2*y*w,2*x*y+2*z*w,1-2*x*x-2*z*z,2*y*z-2*x*w,2*x*z-2*y*w,2*y*z+2*x*w,1-2*x*x-2*y*y})
end
CFrame.fromAxisAngle=function(axis,angle)
	local x,y,z=axis.X,axis.Y,axis.Z
	local c,s=math.cos(angle),math.sin(angle);local t=1-c
	return frame(Vector3.zero,{t*x*x+c,t*x*y-s*z,t*x*z+s*y,t*x*y+s*z,t*y*y+c,t*y*z-s*x,t*x*z-s*y,t*y*z+s*x,t*z*z+c})
end
local originalIsA=methods.IsA
function methods:IsA(className)
	return originalIsA(self,className) or className=="BaseScript" and (self.ClassName=="Script" or self.ClassName=="LocalScript")
end
function methods:Clone()
	local copies={}
	local function copy(node)
		local result=Instance.new(node.ClassName);copies[node]=result
		for _,child in ipairs(node:GetChildren()) do local c=copy(child);c.Parent=result end
		return result
	end
	local result=copy(self)
	for source,target in pairs(copies) do
		for key,value in pairs(source._props) do if key~="Parent" then target[key]=copies[value] or value end end
		target._attributes=table.clone(source._attributes)
	end
	return result
end
services.RunService.PreSimulation=signal()
task.defer=function(callback)
	local thread=coroutine.create(callback)
	local job=later(0,function() local ok,err=coroutine.resume(thread);if not ok then error(err) end end)
	job.thread=thread;return job
end
task.spawn=task.defer
task.wait=function(duration)
	local thread=coroutine.running()
	later(duration or .03,function() local ok,err=coroutine.resume(thread);if not ok then error(err) end end)
	return coroutine.yield()
end
services.ContentProvider={PreloadAsync=function(_,items,callback)
	if services.preloadAvatars then return services.preloadAvatars(items,callback) end
	callback("fixture",Enum.AssetFetchStatus.Success)
end}
function methods:LoadAnimation(animation)
	assert(self.ClassName=="Animator")
	if services.trackFailure then error("Injected animation asset denial") end
	local track=Instance.new("AnimationTrack");track.AnimationId=animation.AnimationId
	services.loadedTracks=services.loadedTracks or {};table.insert(services.loadedTracks,track)
	return track
end
local originalPlay,originalStop=methods.Play,methods.Stop
function methods:Play(...)
	if self.ClassName=="AnimationTrack" then self.IsPlaying=true else return originalPlay(self,...) end
end
function methods:Stop(...)
	if self.ClassName=="AnimationTrack" then self.IsPlaying=false else return originalStop(self,...) end
end

local originalSetAttribute=methods.SetAttribute
function methods:SetAttribute(key,value)
	originalSetAttribute(self,key,value)
	local event=self._events["Attribute_"..key]
	if event then event:Fire() end
end
