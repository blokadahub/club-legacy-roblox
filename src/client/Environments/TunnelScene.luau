--!nonstrict
local Geometry = require(script.Parent.TunnelGeometry)
local Lighting = require(script.Parent.TunnelLighting)
local Camera = require(script.Parent.TunnelCamera)
local Scene = {}
Scene.__index = Scene

-- No camera/global Lighting changes unless explicitly requested by the caller.
function Scene.new(options)
	options = options or {}
	local quality = options.quality or "Medium"
	Geometry.profile(quality)
	local self = setmetatable({origin=options.origin or CFrame.new()},Scene)
	self.model = Instance.new("Model")
	self.model.Name = "CinematicTunnel"
	self.model.Parent = options.parent or workspace
	local ok, err = pcall(function()
		self:CreateArchitecture(quality)
		self.lighting = Lighting.new(self.model,{quality=quality,takeOverLighting=options.takeOverLighting == true})
		if options.camera then self:ConfigureCamera(options) end
	end)
	if not ok then self:Destroy(); error(err,2) end
	return self
end

function Scene:CreateArchitecture(quality)
	assert(not self.destroyed,"Tunnel has been destroyed")
	local descriptors = Geometry.build(quality)
	-- Construct off-tree so a build failure cannot leave a partial replacement.
	local architecture = Instance.new("Model")
	architecture.Name = "Architecture"
	local ok, err = pcall(function()
		for _, data in ipairs(descriptors) do
			local part = Instance.new(data.className)
			part.Name = data.name
			part.Size = Vector3.new(table.unpack(data.size))
			part.CFrame = self.origin*CFrame.new(table.unpack(data.frame))
			part.Color, part.Material = Color3.fromRGB(table.unpack(data.color)), Enum.Material[data.material]
			part.Reflectance, part.CastShadow = data.reflectance, data.shadow
			part.Anchored = true
			part.CanCollide, part.CanTouch, part.CanQuery = false,false,false
			part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
			part.Parent = architecture
			Lighting.attach(part,data.light,quality,data)
		end
	end)
	if not ok then architecture:Destroy(); error(err,2) end
	local old = self.architecture
	self.architecture = architecture
	architecture.Parent = self.model
	if old then old:Destroy() end
	self.quality = quality
	self.model:SetAttribute("Quality",quality)
	self.model:SetAttribute("PartCount",#descriptors)
	if self.lighting then self.lighting:ApplyQuality(quality) end
end

function Scene:ConfigureCamera(options)
	assert(not self.destroyed,"Tunnel has been destroyed")
	if self.camera then self.camera:Destroy(); self.camera=nil end
	options = options or {}
	self.camera = Camera.new({origin=self.origin,animate=options.animate,reducedMotion=options.reducedMotion})
	return self.camera
end

function Scene:ApplyQuality(quality)
	if self.destroyed then return end
	Geometry.profile(quality)
	if quality ~= self.quality then self:CreateArchitecture(quality) end
	self.lighting:ApplyQuality(quality)
end

function Scene:SetEffectsEnabled(enabled)
	if not self.destroyed then self.lighting:SetEffectsEnabled(enabled) end
end

function Scene:SetMotion(animate,reducedMotion)
	if not self.destroyed and self.camera then self.camera:SetMotion(animate,reducedMotion) end
end

function Scene:Destroy()
	if self.destroyed then return end
	self.destroyed = true
	if self.camera then self.camera:Destroy(); self.camera=nil end
	if self.lighting then self.lighting:Destroy(); self.lighting=nil end
	if self.model then self.model:Destroy() end
end

return Scene
