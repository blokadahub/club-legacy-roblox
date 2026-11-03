--!nonstrict
local Lighting = game:GetService("Lighting")
local Geometry = require(script.Parent.TunnelGeometry)
local TunnelLighting = {}
TunnelLighting.__index = TunnelLighting
local activeOwner = nil
-- Shared by the integrated Scene and optional standalone takeover. No service
-- writes on require: the caller still owns the camera and global environment.
TunnelLighting.Environment = {
	Ambient=Color3.fromRGB(34,36,40), OutdoorAmbient=Color3.fromRGB(23,25,29),
	Brightness=1.0, ClockTime=0, ExposureCompensation=0.02, GlobalShadows=true,
	EnvironmentDiffuseScale=0.38, EnvironmentSpecularScale=0.48, ShadowSoftness=0.35,
	FogColor=Color3.fromRGB(52,54,57), FogStart=68, FogEnd=156,
}
TunnelLighting.Post = {
	BloomIntensity=0.09, BloomSize=18, BloomThreshold=1.2,
	Contrast=0.035, Saturation=-0.04, TintColor=Color3.fromRGB(245,247,250),
}
local properties = TunnelLighting.Environment
local profiles = {
	Low={fogRate=0.12, fogPeak=0.94, reflection=0.96},
	Medium={fogRate=0.24, fogPeak=0.92, reflection=0.94},
	High={fogRate=0.32, fogPeak=0.90, reflection=0.92},
}

local function lightOn(part, kind, color, brightness, range, face, shadow, offset)
	local light = Instance.new(kind)
	light.Name = "TunnelSource"
	light.Color, light.Brightness, light.Range = color,brightness,range
	light.Shadows = shadow == true
	light.Enabled = true
	light:SetAttribute("CL27TunnelLight",true)
	light:SetAttribute("CL27Range",range)
	light:SetAttribute("TunnelShadow",shadow == true)
	if kind == "SurfaceLight" then light.Face,light.Angle=Enum.NormalId[face],120 end
	if offset then
		local attachment = Instance.new("Attachment")
		attachment.Name, attachment.Position = "TunnelBounceOrigin",offset
		attachment.Parent = part
		light.Parent = attachment
	else light.Parent = part end
	return light
end

local function floorResponse(part, data, quality)
	part.Reflectance = 0.06
	local x,z = data.frame[1],data.frame[3]
	-- Only the 24 slabs directly below the existing green rails. One thin,
	-- light-influenced falloff per slab; no extra floor planes or mirror copy.
	if math.abs(x) < 1 or z < -84 then return end
	local gui = Instance.new("SurfaceGui")
	gui.Name,gui.Face = "TunnelFloorResponse",Enum.NormalId.Top
	gui.CanvasSize = Vector2.new(256,256)
	gui.AlwaysOnTop,gui.LightInfluence,gui.Brightness = false,1,1
	gui.MaxDistance = 110
	local band = Instance.new("Frame")
	band.Name,band.BorderSizePixel = "RailFalloff",0
	band.Size = UDim2.fromScale(3.2/data.size[1],1)
	band.Position = UDim2.fromScale(if x<0 then 0 else 1-3.2/data.size[1],0)
	band.BackgroundColor3 = Color3.fromRGB(73,240,87)
	local gradient = Instance.new("UIGradient")
	local peak = profiles[quality].reflection
	-- 0.895 studs from the outer slab edge aligns exactly with the rail at ±16.03.
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0,0.985), NumberSequenceKeypoint.new(0.895/3.2,peak),
		NumberSequenceKeypoint.new(0.6,1-(1-peak)*0.3), NumberSequenceKeypoint.new(1,1),
	})
	gradient.Rotation = if x<0 then 0 else 180
	gradient.Parent = band
	band.Parent = gui
	gui.Parent = part
end

local function distantFog(part, quality)
	local profile = profiles[quality]
	for layer,z in ipairs({-78,-92,-106}) do
		if quality ~= "Low" or layer ~= 2 then
			for _, x in ipairs({-5.5,5.5}) do
				local anchor = Instance.new("Attachment")
				anchor.Name = "TunnelFogOrigin"
				-- Backdrop is at (0,12,-115); its existing CFrame carries scene origin.
				anchor.Position = Vector3.new(x,-2,z+115)
				anchor:SetAttribute("TunnelDepth",-z)
				anchor.Parent = part
				local fog = Instance.new("ParticleEmitter")
				fog.Name = "TunnelDistantFog"
				fog.Texture = "rbxasset://textures/particles/smoke_main.dds"
				fog.Color = ColorSequence.new(Color3.fromRGB(124,126,129))
				fog.LightEmission,fog.LightInfluence = 0,1
				-- Opposing lateral currents expose texture movement within a few seconds.
				-- Shorter lives renew the silhouettes without raising the live-particle cap.
				fog.Lifetime,fog.Rate = NumberRange.new(14,18),profile.fogRate
				fog.Speed,fog.SpreadAngle = NumberRange.new(0.65,1.05),Vector2.new(18,10)
				fog.EmissionDirection = if x<0 then Enum.NormalId.Right else Enum.NormalId.Left
				fog.Drag,fog.Acceleration = 0.1,Vector3.new(0,0.035,0)
				fog.Rotation = NumberRange.new(0,360)
				fog.RotSpeed = if x<0 then NumberRange.new(2,4) else NumberRange.new(-4,-2)
				fog.TimeScale = 1
				fog.Orientation = Enum.ParticleOrientation.FacingCameraWorldUp
				fog.LockedToPart = true
				fog.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0,12,2),NumberSequenceKeypoint.new(0.5,16,3),
					NumberSequenceKeypoint.new(1,18,2),
				})
				local peak = profile.fogPeak-(layer-1)*0.015
				fog.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.05,peak),
					NumberSequenceKeypoint.new(0.55,peak),NumberSequenceKeypoint.new(1,1),
				})
				fog.Enabled = true
				fog.Parent = anchor
				fog:Emit(2) -- Natural fade-in under the existing loading transition.
			end
		end
	end
end

function TunnelLighting.attach(part, spec, quality, data)
	local name = part.Name:match("^%d+_(.+)$") or part.Name
	if name == "FloorSlab" and data then floorResponse(part,data,quality)
	elseif part.Material == Enum.Material.Metal then part.Reflectance=math.max(part.Reflectance,0.025) end
	if name == "DistantBackdrop" then distantFog(part,quality) end
	if name == "GreenBase" then
		-- All rail segments cast local light even on Low; surface Neon stays intact.
		lightOn(part,"PointLight",Color3.fromRGB(73,240,87),0.95,10)
	elseif name == "CeilingCrossRib" and data then
		local bay = math.floor((-data.frame[3]-3.85)/12+0.5)
		if bay%2 == 0 then
			lightOn(part,"PointLight",Color3.fromRGB(186,194,202),1.3,28,nil,false,Vector3.new(0,-5.5,0))
		end
	elseif name == "ExitCeiling" then
		lightOn(part,"SurfaceLight",Color3.fromRGB(186,189,194),0.75,26,"Bottom")
	elseif spec and name ~= "DistantHorizon" then
		local color = Color3.fromRGB(table.unpack(spec.color))
		local brightness,range = spec.brightness,spec.range
		if name == "BlueUpperNeon" then brightness,range=1.65,17
		elseif name == "OrangeCeilingFixture" then brightness,range=2.1,26
		elseif name == "FarAmberMarker" then brightness,range=0.65,9
		elseif name == "HiddenTealWash" then brightness,range=0.35,26 end
		local shadow = quality == "High" and name == "OrangeCeilingFixture"
			and data and (math.abs(data.frame[3]-2)<0.1 or math.abs(data.frame[3]+46)<0.1)
		lightOn(part,spec.kind,color,brightness,range,spec.face,shadow)
	end
end

-- Local lights need no Lighting takeover. Global atmosphere is explicit and leased.
function TunnelLighting.new(root, options)
	options = options or {}
	local self = setmetatable({root=root, quality=options.quality or "Medium", enabled=true, effects={}, saved={}, parked={}},TunnelLighting)
	Geometry.profile(self.quality)
	if options.takeOverLighting then
		assert(not activeOwner, "Another tunnel already owns Lighting; destroy it first")
		activeOwner = self
		self.ownsLighting = true
		for key, value in pairs(properties) do self.saved[key]=Lighting[key]; Lighting[key]=value end
		-- Restore the original instances themselves, including their original Enabled values.
		for _, effect in ipairs(Lighting:GetChildren()) do
			if effect:IsA("PostEffect") or effect:IsA("Atmosphere") or effect:IsA("Sky") then
				table.insert(self.parked,effect)
				effect.Parent = nil
			end
		end
		local bloom = Instance.new("BloomEffect")
		bloom.Name,bloom.Intensity,bloom.Size,bloom.Threshold = "TunnelBloom",TunnelLighting.Post.BloomIntensity,TunnelLighting.Post.BloomSize,TunnelLighting.Post.BloomThreshold
		local grade = Instance.new("ColorCorrectionEffect")
		grade.Name,grade.Contrast,grade.Saturation = "TunnelGrade",TunnelLighting.Post.Contrast,TunnelLighting.Post.Saturation
		grade.TintColor = TunnelLighting.Post.TintColor
		self.effects = {bloom,grade}
		for _, effect in ipairs(self.effects) do effect.Parent=Lighting end
	end
	self:ApplyQuality(self.quality)
	return self
end

function TunnelLighting:ApplyQuality(quality)
	if self.destroyed then return end
	local profile = Geometry.profile(quality)
	self.quality = quality
	for _, item in ipairs(self.root:GetDescendants()) do
		if item:IsA("Light") and item:GetAttribute("CL27TunnelLight") then
			item.Enabled = self.enabled
			item.Shadows = profile.shadows and item:GetAttribute("TunnelShadow") == true
		elseif item:IsA("ParticleEmitter") and item.Name == "TunnelDistantFog" then
			local wasEnabled = item.Enabled
			item.Enabled = self.enabled
			if not self.enabled then item:Clear()
			elseif not wasEnabled then item:Emit(2) end
		elseif item:IsA("SurfaceGui") and item.Name == "TunnelFloorResponse" then
			item.Enabled = self.enabled
		end
	end
	for _, effect in ipairs(self.effects) do
		effect.Enabled = self.enabled and (not effect:IsA("BloomEffect") or profile.bloom)
	end
end

function TunnelLighting:SetEffectsEnabled(enabled)
	if self.destroyed then return end
	self.enabled = enabled == true
	self:ApplyQuality(self.quality)
	if self.ownsLighting then
		Lighting.FogStart = if self.enabled then properties.FogStart else self.saved.FogStart
		Lighting.FogEnd = if self.enabled then properties.FogEnd else self.saved.FogEnd
		Lighting.FogColor = if self.enabled then properties.FogColor else self.saved.FogColor
	end
end

function TunnelLighting:Destroy()
	if self.destroyed then return end
	self.destroyed = true
	for _, effect in ipairs(self.effects) do effect:Destroy() end
	if self.ownsLighting then
		for key, value in pairs(self.saved) do Lighting[key]=value end
		for _, effect in ipairs(self.parked) do effect.Parent=Lighting end
		activeOwner = nil
	end
	table.clear(self.effects)
	table.clear(self.parked)
	table.clear(self.saved)
end

return TunnelLighting
