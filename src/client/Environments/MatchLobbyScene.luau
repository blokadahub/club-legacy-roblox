--!nonstrict
-- Builds only local architecture/emitters/actor. Scene owns Camera and Lighting.
local Scope=require(script.Parent.Parent.Scope)
local Layout=require(script.Parent.MatchLobbyLayout)
local Avatar=require(script.Parent.MatchLobbyAvatar)
local S={}
S.__index=S
function S.new(parent,club,settings)
	local self=setmetatable({scope=Scope.new(),lights={}},S)
	self.model=Instance.new("Model");self.model.Name="CL27_PrePartida"
	self.scope:Add(self.model)
	local ok,err=pcall(function()
		for _,data in ipairs(Layout.build()) do
			local p=Instance.new("Part");p.Name=data.name
			p.Size=Vector3.new(table.unpack(data.size));p.CFrame=CFrame.new(table.unpack(data.position))
			p.Color=Color3.fromRGB(table.unpack(data.color));p.Material=Enum.Material[data.material]
			p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
			p.CastShadow=data.castShadow~=false;p.Reflectance=0;p.Parent=self.model
		end
		local function light(name,position,color,brightness,range)
			local host=Instance.new("Part");host.Name=name;host.Size=Vector3.new(.1,.1,.1)
			host.CFrame=CFrame.new(table.unpack(position));host.Transparency=1
			host.Anchored=true;host.CanCollide=false;host.CanTouch=false;host.CanQuery=false
			host.Parent=self.model
			local emitter=Instance.new("PointLight");emitter.Color=Color3.fromRGB(table.unpack(color))
			emitter.Brightness=brightness;emitter.Range=range;emitter.Shadows=false
			emitter:SetAttribute("CL27MatchLight",true);emitter.Parent=host
			table.insert(self.lights,emitter)
		end
		light("LuzRosto",{6.4,8.8,7},{255,226,189},1.6,18)
		light("LuzRecorte",{12,8,-3},{249,187,120},1.1,15)
		light("LuzFria",{-10,8,5},{105,142,195},.55,23)
		light("ReflexoVerde",{13,.8,1},{91,150,111},.35,11)
		self.model.Parent=parent
		self.avatar=Avatar.new(self.model,club,settings)
		self:ApplySettings(settings or {})
	end)
	if not ok then self:Destroy();error(err,2) end
	return self
end
function S:ApplySettings(settings)
	if self.avatar then self.avatar:ApplySettings(settings) end
	for i,light in ipairs(self.lights) do
		light.Enabled=settings.quality~="Baixa" or i<=2
		light.Shadows=settings.quality=="Alta" and i==1
	end
end
function S:RetryAvatar() if self.avatar then self.avatar:Load() end end
function S:Destroy()
	if self.avatar then self.avatar:Destroy();self.avatar=nil end
	self.scope:Destroy();table.clear(self.lights)
end
return S
