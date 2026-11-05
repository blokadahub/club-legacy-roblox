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
