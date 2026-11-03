--!nonstrict
-- Lifecycle doubles only: no renderer, Roblox security or performance simulation.
local function signal()
	local handlers = {}
	local s = {}
	function s:Connect(callback)
		local c = {Connected=true, callback=callback}
		function c:Disconnect() self.Connected=false end
		table.insert(handlers,c)
		return c
	end
	function s:Fire(...)
		for _, c in ipairs(table.clone(handlers)) do if c.Connected then c.callback(...) end end
	end
	function s:Count()
		local n=0
		for _, c in ipairs(handlers) do if c.Connected then n+=1 end end
		return n
	end
	return s
end
local CFrame = {}
local cfMeta = {}
function CFrame.new(...)
	local v = {...}
	return setmetatable({v={v[1] or 0,v[2] or 0,v[3] or 0,v[4] or 1,v[5] or 0,v[6] or 0,
		v[7] or 0,v[8] or 1,v[9] or 0,v[10] or 0,v[11] or 0,v[12] or 1}},cfMeta)
end
cfMeta.__mul = function(a,b)
	local x,y,out = a.v,b.v,{}
	for i=0,2 do
		out[i+1]=x[i+1]
		for k=0,2 do out[i+1]+=x[4+i*3+k]*y[k+1] end
		for j=0,2 do
			out[4+i*3+j]=0
			for k=0,2 do out[4+i*3+j]+=x[4+i*3+k]*y[4+k*3+j] end
		end
	end
	return CFrame.new(table.unpack(out))
end
local Vector3 = {new=function(x,y,z) return {X=x,Y=y,Z=z} end}
local Color3 = {fromRGB=function(r,g,b) return {R=r/255,G=g/255,B=b/255} end}
local Enum = {}
for kind, values in pairs({Material={"Metal","Concrete","Neon"},NormalId={"Bottom","Back"},
	SurfaceType={"Smooth"},CameraType={"Scriptable","Custom"},FieldOfViewMode={"Vertical"}}) do
	Enum[kind]={}
	for _, value in ipairs(values) do Enum[kind][value]=kind.."."..value end
end
local methods, meta = {}, {}
meta.__index = function(self,key)
	if methods[key] then return methods[key] end
	if key=="Destroying" then return self.events.Destroying end
	if self.props[key] ~= nil then return self.props[key] end
	for _, child in ipairs(self.children) do if child.Name==key then return child end end
end
meta.__newindex = function(self,key,value)
	if key=="Parent" then
		local previous=self.props.Parent
		if previous then table.remove(previous.children,assert(table.find(previous.children,self))) end
		if value then table.insert(value.children,self) end
	end
	self.props[key]=value
end
local Instance = {}
function Instance.new(className)
	return setmetatable({props={ClassName=className,Name=className},children={},attributes={},events={Destroying=signal()}},meta)
end
function methods:GetChildren() return table.clone(self.children) end
function methods:GetDescendants()
	local out={}
	for _, child in ipairs(self.children) do
		table.insert(out,child)
		for _, nested in ipairs(child:GetDescendants()) do table.insert(out,nested) end
	end
	return out
end
function methods:IsA(name)
	return name==self.ClassName or name=="BasePart" and (self.ClassName=="Part" or self.ClassName=="WedgePart")
		or name=="Light" and (self.ClassName=="PointLight" or self.ClassName=="SurfaceLight")
		or name=="PostEffect" and (self.ClassName=="BloomEffect" or self.ClassName=="ColorCorrectionEffect")
end
function methods:FindFirstChild(name)
	for _, child in ipairs(self.children) do if child.Name==name then return child end end
end
function methods:GetAttribute(name) return self.attributes[name] end
function methods:SetAttribute(name,value)
	self.attributes[name]=value
	if self.events[name] then self.events[name]:Fire() end
end
function methods:GetAttributeChangedSignal(name)
	self.events[name]=self.events[name] or signal()
	return self.events[name]
end
function methods:Destroy()
	if self.props.Destroyed then return end
	self.events.Destroying:Fire()
	for _, child in ipairs(self:GetChildren()) do child:Destroy() end
	self.Parent=nil
	self.props.Destroyed=true
end
local workspace = Instance.new("Workspace")
local services = {Workspace=workspace,Lighting=Instance.new("Lighting"),RunService={RenderStepped=signal()},Players={CharacterAutoLoads=true}}
local game = {GetService=function(_,name) return assert(services[name],name) end}
local warn = function(message) error(message) end
local folder=Instance.new("Folder")
local factories, nodes, cache = {}, {}, {}
local require
-- MODULES
require=function(node)
	assert(node and factories[node.Name],"Missing runtime module")
	if cache[node.Name]==nil then cache[node.Name]=factories[node.Name](node) end
	return cache[node.Name]
end
local assertions=0
local function check(value,message) assert(value,message); assertions+=1 end
local Scene=require(nodes.TunnelScene)
local Geometry=require(nodes.TunnelGeometry)
local Camera=require(nodes.TunnelCamera)
local lighting=services.Lighting
for _, key in ipairs({"Ambient","OutdoorAmbient","FogColor"}) do lighting[key]=Color3.fromRGB(100,110,120) end
for _, key in ipairs({"Brightness","ClockTime","ExposureCompensation","EnvironmentDiffuseScale","EnvironmentSpecularScale","ShadowSoftness"}) do lighting[key]=0.7 end
lighting.GlobalShadows=false
lighting.FogStart,lighting.FogEnd=300,2000
local saved=table.clone(lighting.props)
local oldEffects={}
for _, name in ipairs({"BloomEffect","Atmosphere","Sky"}) do
	local e=Instance.new(name); e.Enabled=false; e.Parent=lighting; table.insert(oldEffects,e)
end
local original=Instance.new("Camera")
original.CameraType,original.CFrame,original.FieldOfView=Enum.CameraType.Custom,CFrame.new(22,33,44),71
original.Parent=workspace
workspace.CurrentCamera=original
local originalFrame=original.CFrame
local baseline=#workspace:GetChildren()
local function count(root,className)
	local n=0
	for _, item in ipairs(root:GetDescendants()) do if item:IsA(className) then n+=1 end end
	return n
end
local function restored()
	for key,value in pairs(saved) do check(lighting[key]==value,"Lighting property not restored: "..key) end
	for _, e in ipairs(oldEffects) do check(e.Parent==lighting and e.Enabled==false,"Original effect changed") end
end
local localOnly=Scene.new()
check(workspace.CurrentCamera==original,"Default scene claimed camera")
restored()
check(count(localOnly.model,"BasePart")==334,"Medium budget changed unexpectedly")
localOnly:Destroy(); localOnly:Destroy()
check(#workspace:GetChildren()==baseline,"Local scene leaked")
for iteration=1,3 do
	local scene=Scene.new({quality="Medium",takeOverLighting=true,camera=true})
	check(#lighting:GetChildren()==2,"Original atmosphere/sky must be parked")
	check(workspace.CurrentCamera==scene.camera.camera,"Camera was not installed")
	check(services.RunService.RenderStepped:Count()==0,"Static camera has a render loop")
	check(original.CFrame==originalFrame and original.FieldOfView==71,"Original camera mutated")
	local architecture=scene.architecture
	scene:ApplyQuality("Medium")
	check(scene.architecture==architecture,"Unchanged quality rebuilt architecture")
	check(not pcall(function() scene:ApplyQuality("Invalid") end),"Invalid quality accepted")
	check(scene.architecture==architecture,"Invalid quality damaged scene")
	scene:SetMotion(true,false)
	check(services.RunService.RenderStepped:Count()==1,"Animation connection missing")
	local fixed=scene.architecture:GetChildren()[1].CFrame
	for _=1,100 do services.RunService.RenderStepped:Fire(1/30) end
	check(scene.architecture:GetChildren()[1].CFrame==fixed,"Camera animated geometry")
	scene:SetMotion(true,true)
	check(services.RunService.RenderStepped:Count()==0,"Reduced motion retained loop")
	scene:SetEffectsEnabled(false)
	check(lighting.FogEnd==saved.FogEnd,"Fog toggle failed")
	for _, q in ipairs({"Low","High","Medium"}) do
		scene:ApplyQuality(q)
		check(count(scene.model,"BasePart")==#Geometry.build(q),"Quality accumulated geometry")
		for _, item in ipairs(scene.model:GetDescendants()) do
			if item:IsA("Light") then check(item.Enabled==false,"Quality re-enabled disabled lights") end
		end
	end
	scene:SetEffectsEnabled(true)
	check(lighting.FogStart==74,"Fog did not re-enable")
	scene:SetMotion(true,false)
	scene:Destroy(); scene:Destroy()
	check(workspace.CurrentCamera==original,"Original camera not restored")
	check(services.RunService.RenderStepped:Count()==0,"Destroy leaked animation callback")
	check(#workspace:GetChildren()==baseline,"Scene leaked instances")
	restored()
end
local moved=Scene.new({origin=CFrame.new(100,0,0),quality="Low"})
check(math.abs(moved.architecture:GetChildren()[1].CFrame.v[1]-100)<1e-8,"Origin not applied")
moved:Destroy()
local scene=Scene.new({camera=true,takeOverLighting=true})
local other=Instance.new("Camera"); other.Parent=workspace; workspace.CurrentCamera=other
scene:Destroy()
check(workspace.CurrentCamera==other,"Destroy overwrote another system's camera")
other:Destroy(); workspace.CurrentCamera=original
-- Constructor rollback after camera lease rejection must restore global Lighting.
local camera=Camera.new()
local before=#workspace:GetChildren()
check(not pcall(function() Scene.new({camera=true,takeOverLighting=true}) end),"Overlapping camera lease allowed")
check(#workspace:GetChildren()==before,"Failed constructor leaked its model")
restored()
camera:Destroy()
local owner=Scene.new({takeOverLighting=true})
check(not pcall(function() Scene.new({takeOverLighting=true}) end),"Overlapping Lighting lease allowed")
owner:Destroy(); restored()
-- Execute the real standalone bootstrap and attribute callbacks, then dispose it.
local preview=Instance.new("Model"); preview.Name="CinematicTunnelPreview"; preview.Parent=workspace
local bootstrap=nodes.Tunnel
factories.Tunnel(bootstrap)
check(preview.Destroyed==true,"Baked preview duplicated runtime geometry")
check(workspace:FindFirstChild("CinematicTunnel")~=nil,"Bootstrap did not initialize")
bootstrap:SetAttribute("Quality","Low")
check(count(workspace:FindFirstChild("CinematicTunnel"),"BasePart")==238,"Bootstrap quality attribute ignored")
bootstrap:SetAttribute("EffectsEnabled",false)
bootstrap:SetAttribute("ReducedMotion",false)
bootstrap:SetAttribute("Animate",true)
check(services.RunService.RenderStepped:Count()==1,"Bootstrap motion attributes ignored")
bootstrap:Destroy()
check(workspace:FindFirstChild("CinematicTunnel")==nil,"Bootstrap leaked scene")
for _, s in pairs(bootstrap.events) do check(s:Count()==0,"Bootstrap leaked attribute callback") end
check(services.RunService.RenderStepped:Count()==0,"Bootstrap leaked motion")
check(workspace.CurrentCamera==original,"Bootstrap failed to restore camera")
restored()
factories.NoCharacter(nodes.NoCharacter)
check(services.Players.CharacterAutoLoads==false,"Standalone character spawning not disabled")
print(string.format("PASS lifecycle: %d assertions; real modules, API doubles; no Roblox render/FPS certification",assertions))
