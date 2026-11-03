--!nonstrict
local Lighting = game:GetService("Lighting")
local Geometry = require(script.Parent.TunnelGeometry)
local TunnelLighting = {}
TunnelLighting.__index = TunnelLighting
local activeOwner = nil
local properties = {
	Ambient=Color3.fromRGB(8,11,20), OutdoorAmbient=Color3.fromRGB(3,5,10),
	Brightness=0.45, ClockTime=0, ExposureCompensation=-0.32, GlobalShadows=true,
	EnvironmentDiffuseScale=0.18, EnvironmentSpecularScale=0.3, ShadowSoftness=0.35,
	FogColor=Color3.fromRGB(27,65,68), FogStart=74, FogEnd=168,
}

function TunnelLighting.attach(part, spec, quality)
	if not spec then return end
	local light = Instance.new(spec.kind)
	light.Name = "TunnelSource"
	light.Color = Color3.fromRGB(table.unpack(spec.color))
	light.Brightness, light.Range = spec.brightness, spec.range
	light.Shadows = quality == "High" and spec.kind == "SurfaceLight"
	if spec.kind == "SurfaceLight" then
		light.Face, light.Angle = Enum.NormalId[spec.face], spec.angle
	end
	light.Parent = part
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
		bloom.Name, bloom.Intensity, bloom.Size, bloom.Threshold = "TunnelBloom",0.12,20,1.15
		local grade = Instance.new("ColorCorrectionEffect")
		grade.Name, grade.Contrast, grade.Saturation = "TunnelGrade",0.12,-0.08
		grade.TintColor = Color3.fromRGB(229,244,246)
		-- Bounded distance fog is deliberate. A global Atmosphere scatters across the
		-- near walls and ignores FogStart/FogEnd; this short enclosed scene uses fog.
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
		if item:IsA("Light") then
			item.Enabled = self.enabled
			item.Shadows = profile.shadows and item:IsA("SurfaceLight")
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
