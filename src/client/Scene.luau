--!nocheck
-- The menus are filmed inside local Workspace architecture; no full-screen ViewportFrame.
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Rig = require(script.Parent.Rig)
local MenuAvatar = require(script.Parent.MenuAvatar)
local TunnelScene = require(script.Parent.Environments.TunnelScene)
local TunnelGeometry = require(script.Parent.Environments.TunnelGeometry)
local TunnelLighting = require(script.Parent.Environments.TunnelLighting)
local Scene = {}
Scene.__index = Scene

local C = {
	graphite = Color3.fromRGB(29, 36, 39),
	concrete = Color3.fromRGB(119, 124, 119),
	pale = Color3.fromRGB(220, 230, 216),
	cyan = Color3.fromRGB(58, 244, 213),
	green = Color3.fromRGB(17, 129, 106),
	blue = Color3.fromRGB(16, 39, 70),
	white = Color3.fromRGB(230, 247, 242),
}

local function block(parent, name, size, cf, color, material, transparency)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = name, size, cf
	p.Color = color or C.graphite
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.Anchored = true
	p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function cylinder(parent, name, radius, height, position, color, material)
	local p = block(parent, name, Vector3.new(height, radius * 2, radius * 2), CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2), color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function beam(parent, name, a, b, thickness, color, material)
	local mid = (a + b) / 2
	return block(parent, name, Vector3.new(thickness, thickness, (b - a).Magnitude), CFrame.lookAt(mid, b), color, material)
end

local function glow(parent, name, size, cf, color, brightness, range)
	local p = block(parent, name, size, cf, color, Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Color, light.Brightness, light.Range = color, brightness or 1.5, range or 12
	light:SetAttribute("CL27Range", range or 12)
	light.Shadows = false
	light.Parent = p
	return p
end

local function surface(host, colorA, colorB)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "PainelCinematografico"
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(1920, 760)
	gui.LightInfluence = 0
	gui.Brightness = 1.1
	gui.Parent = host
	local frame = Instance.new("Frame")
	frame.Size, frame.BackgroundColor3, frame.BorderSizePixel = UDim2.fromScale(1, 1), Color3.new(1, 1, 1), 0
	frame.ClipsDescendants = true
	frame.Parent = gui
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, colorA), ColorSequenceKeypoint.new(0.55, colorB), ColorSequenceKeypoint.new(1, C.green) })
	gradient.Rotation = 25
	gradient.Parent = frame
	for i = 1, 5 do
		local stripe = Instance.new("Frame")
		stripe.BorderSizePixel, stripe.BackgroundColor3 = 0, C.cyan
		stripe.BackgroundTransparency = i == 3 and 0.45 or 0.87
		stripe.Size = UDim2.fromScale(0.025 + i * 0.015, 2.2)
		stripe.Position = UDim2.fromScale(0.37 + i * 0.14, -0.5)
		stripe.Rotation = 49
		stripe.Parent = frame
	end
	return frame
end

local function screenText(parent, text, x, y, w, h, size, transparency)
	local label = Instance.new("TextLabel")
	label.Name = "TextoCenario"
	label.BackgroundTransparency = 1
	label.Position, label.Size = UDim2.fromScale(x, y), UDim2.fromScale(w, h)
	label.Text, label.TextColor3 = text, C.white
	label.Font, label.TextSize, label.TextTransparency = Enum.Font.GothamBold, size, transparency or 0
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function floor(parent, extent, light)
	local base = block(parent, "PisoPolido", Vector3.new(extent * 2, 0.3, extent * 2), CFrame.new(0, -0.2, -8), light and Color3.fromRGB(91, 95, 87) or Color3.fromRGB(19, 42, 43), Enum.Material.Marble)
	base.Reflectance = light and 0.08 or 0.12
	for x = -extent, extent, 5 do
		block(parent, "JuntaPiso", Vector3.new(0.025, 0.012, extent * 2), CFrame.new(x, -0.04, -8), Color3.fromRGB(35, 43, 40), Enum.Material.Metal)
	end
	for z = -extent, extent, 5 do
		block(parent, "JuntaPiso", Vector3.new(extent * 2, 0.012, 0.025), CFrame.new(0, -0.04, z - 8), Color3.fromRGB(35, 43, 40), Enum.Material.Metal)
	end
end

local function trimRectangle(parent, width, depth, center, color, thickness)
	local t = thickness or 0.06
	for _, x in ipairs({ -width / 2, width / 2 }) do
		block(parent, "MolduraPiso", Vector3.new(t, 0.025, depth), CFrame.new(center + Vector3.new(x, 0, 0)), color, Enum.Material.Metal)
	end
	for _, z in ipairs({ -depth / 2, depth / 2 }) do
		block(parent, "MolduraPiso", Vector3.new(width, 0.025, t), CFrame.new(center + Vector3.new(0, 0, z)), color, Enum.Material.Metal)
	end
end

local function restoreCamera(snapshots, camera)
	local saved = camera and snapshots[camera]
	if not saved then return end
	snapshots[camera] = nil
	-- Another system may already have destroyed this camera. No retained camera
	-- references or signal connections are needed solely for this cleanup.
	pcall(function()
		camera.CameraType, camera.FieldOfView = saved.cameraType, saved.fov
		camera.CFrame, camera.Focus = saved.frame, saved.focus
	end)
end

function Scene.new(settings)
	local self = setmetatable({}, Scene)
	self.settings, self.actors, self.effects, self.lightTweens = settings or {}, {}, {}, {}
	self.settingsNeon = nil
	self.settingsRings = {}
	self.tunnel = nil
	self.folder = Instance.new("Folder")
	self.folder.Name = "CL27_CenarioLocal"
	self.folder.Parent = Workspace
	self.oldLighting = {}
	for _, key in ipairs({ "Ambient", "OutdoorAmbient", "Brightness", "ClockTime", "ExposureCompensation", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "GlobalShadows", "ShadowSoftness", "LightingStyle", "PrioritizeLightingQuality", "FogColor", "FogStart", "FogEnd" }) do
		self.oldLighting[key] = Lighting[key]
	end
	self.cameraSnapshots = setmetatable({}, { __mode = "k" })
	self.activeCamera = setmetatable({}, { __mode = "v" })
	local bloom = Instance.new("BloomEffect")
	bloom.Name, bloom.Intensity, bloom.Size, bloom.Threshold = "CL27_Bloom", 0.2, 28, 1.15
	bloom.Parent = Lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name, grade.Contrast, grade.Saturation = "CL27_Grade", 0.1, -0.06
	grade.Parent = Lighting
	local rays = Instance.new("SunRaysEffect")
	rays.Name, rays.Intensity, rays.Spread = "CL27_Raios", 0.025, 0.6
	rays.Parent = Lighting
	self.effects, self.grade, self.rays, self.bloom = { bloom, grade, rays }, grade, rays, bloom
	if not Lighting:FindFirstChildOfClass("Sky") then
		local sky = Instance.new("Sky")
		sky.Name = "CL27_CeuNativo"
		for _, face in ipairs({ "Bk", "Dn", "Ft", "Lf", "Rt", "Up" }) do
			sky["Skybox" .. face] = "rbxasset://textures/sky/sky512_" .. string.lower(face) .. ".tex"
		end
		sky.SunAngularSize, sky.MoonAngularSize, sky.StarCount = 11, 9, 1800
		sky.Parent = Lighting
		table.insert(self.effects, sky)
	end
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name, atmosphere.Density, atmosphere.Offset = "CL27_Profundidade", 0.15, 0.12
	atmosphere.Color, atmosphere.Decay, atmosphere.Haze = Color3.fromRGB(190, 216, 229), Color3.fromRGB(108, 130, 143), 0.6
	atmosphere.Parent = Lighting
	self.atmosphere = atmosphere
	table.insert(self.effects, atmosphere)
	self.elapsed = 0
	self.connection = RunService.RenderStepped:Connect(function(dt)
		self.elapsed += math.min(dt, 0.1)
		local camera = Workspace.CurrentCamera
		if not camera or not self.cameraPosition then return end
		local previous = self.activeCamera[1]
		if previous ~= camera then
			restoreCamera(self.cameraSnapshots, previous)
			self.activeCamera[1] = camera
		end
		if not self.cameraSnapshots[camera] then
			self.cameraSnapshots[camera] = {
				cameraType = camera.CameraType, fov = camera.FieldOfView,
				frame = camera.CFrame, focus = camera.Focus,
			}
		end
		camera.CameraType = Enum.CameraType.Scriptable
		-- Preserve the scene's framing inside the same fitted 16:9 canvas as the UI.
		-- A 4:3 viewport adds vertical space rather than cropping the side actors.
		local referenceFov = self.fov or 36
		local fittedHeight = self.canvasHeight or camera.ViewportSize.Y
		local viewportHeight = math.max(1, camera.ViewportSize.Y)
		camera.FieldOfView = math.clamp(math.deg(2 * math.atan(math.tan(math.rad(referenceFov / 2)) * viewportHeight / math.max(1, fittedHeight))), 1, 120)
		local strength = (self.mode == "Tunnel" or self.settings.reducedMotion) and 0 or 1
		local drift = Vector3.new(math.sin(self.elapsed * 0.16) * 0.065, math.sin(self.elapsed * 0.2) * 0.027, 0) * strength
		camera.CFrame = CFrame.lookAt(self.cameraPosition + drift, self.cameraTarget + drift * 0.3)
		camera.Focus = CFrame.new(self.cameraTarget)
		for _, actor in ipairs(self.actors) do Rig.animate(actor, self.elapsed, self.settings.reducedMotion) end
		-- Apenas na tela Configurações: círculos de luz integrados ao
		-- cenário preexistente. Não alteram o lobby de entrada.
		if self.settingsNeon and not self.settings.reducedMotion then
			for _, ring in ipairs(self.settingsRings) do
				ring.model:PivotTo(ring.center * CFrame.Angles(0, 0, self.elapsed * ring.speed))
				ring.light.Brightness = 0.38 + math.sin(self.elapsed * ring.frequency) * 0.12
			end
		end
	end)
	return self
end

function Scene:_light(mode)
	for _, tween in ipairs(self.lightTweens) do tween:Cancel() end
	table.clear(self.lightTweens)
	Lighting.GlobalShadows, Lighting.ShadowSoftness = true, 0.35
	local interior = mode == "Interior"
	local tunnel = mode == "Tunnel"
	-- O controlador principal continua sendo o unico dono da Camera/Lighting.
	-- O tunel fornece apenas geometria e emissores locais.
	local environment = TunnelLighting.Environment
	Lighting.FogColor = if tunnel then environment.FogColor else self.oldLighting.FogColor
	Lighting.FogStart = if tunnel then environment.FogStart else self.oldLighting.FogStart
	Lighting.FogEnd = if tunnel then environment.FogEnd else self.oldLighting.FogEnd
	local target = {
		Ambient = if tunnel then environment.Ambient else (interior and Color3.fromRGB(36, 45, 46) or Color3.fromRGB(27, 59, 64)),
		OutdoorAmbient = if tunnel then environment.OutdoorAmbient else (interior and Color3.fromRGB(22, 29, 33) or Color3.fromRGB(35, 55, 60)),
		Brightness = if tunnel then environment.Brightness else (interior and 1.15 or 1.6),
		ClockTime = if tunnel then environment.ClockTime else (interior and 16.4 or 21),
		ExposureCompensation = if tunnel then environment.ExposureCompensation else (interior and -0.32 or -0.24),
		EnvironmentDiffuseScale = if tunnel then environment.EnvironmentDiffuseScale else (interior and 0.35 or 0.55),
		EnvironmentSpecularScale = if tunnel then environment.EnvironmentSpecularScale else (interior and 0.3 or 0.85),
	}
	-- The graphic wipe covers the geometry swap; lighting settles beneath it.
	local tween = TweenService:Create(Lighting, TweenInfo.new(self.settings.reducedMotion and 0 or 0.32, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), target)
	table.insert(self.lightTweens, tween)
	tween:Play()
	self.rays.Enabled = false
	self.atmosphere.Density = if tunnel then 0 else 0.035
	-- Presence of Atmosphere overrides classic distance fog even at zero density.
	self.atmosphere.Parent = if tunnel then nil else Lighting
	self.atmosphere.Haze = 0
	self.grade.TintColor = if tunnel then TunnelLighting.Post.TintColor else (interior and Color3.fromRGB(255, 248, 233) or Color3.fromRGB(221, 255, 247))
end

function Scene:_actor(club, kit, position, yaw, pose, number)
	local actor = Rig.create({ name = "Atleta de apresentação", number = number or 7 }, club, kit)
	actor.Parent = self.folder
	actor:PivotTo(CFrame.new(position) * CFrame.Angles(0, math.rad(yaw), 0))
	Rig.pose(actor, pose or "Standing")
	table.insert(self.actors, actor)
	return actor
end

-- Avatar autêntico apenas nas duas telas iniciais; demais atletas continuam fictícios.
function Scene:_menuAvatar(position, cameraPosition)
	self.menuAvatar = MenuAvatar.mount(self.folder, position, cameraPosition, self.settings)
end

function Scene:_interior(club, kit)
	local p = self.folder
	floor(p, 36, true)
	trimRectangle(p, 22, 13, Vector3.new(3, -0.013, 1), Color3.fromRGB(22, 30, 28), 0.09)
	block(p, "ParedeFundo", Vector3.new(65, 13, 0.6), CFrame.new(0, 6, -7), C.graphite, Enum.Material.Concrete)
	block(p, "ParedeEsquerda", Vector3.new(0.7, 13, 35), CFrame.new(-17, 6, 0), Color3.fromRGB(74, 78, 72), Enum.Material.Concrete)
	block(p, "ParedeDireita", Vector3.new(0.7, 13, 35), CFrame.new(18, 6, 0), C.graphite, Enum.Material.Slate)
	block(p, "Teto", Vector3.new(48, 0.5, 32), CFrame.new(0, 11.1, -1), Color3.fromRGB(38, 43, 40), Enum.Material.Concrete)
	for z = -9, 12, 5 do
		block(p, "VigaTeto", Vector3.new(42, 0.5, 0.5), CFrame.new(0, 10.6, z), Color3.fromRGB(56, 61, 56), Enum.Material.Metal)
		glow(p, "LuzLinearTeto", Vector3.new(11, 0.06, 0.08), CFrame.new(4, 10.3, z), Color3.fromRGB(215, 230, 215), 0.45, 12)
	end
	for x = -15, 17, 4 do
		block(p, "AletaArquitetonica", Vector3.new(0.14, 10, 0.7), CFrame.new(x, 5, -6.35), Color3.fromRGB(58, 64, 59), Enum.Material.Metal)
	end
	for i = 1, 3 do
		local x = -12.8 + i * 1.5
		beam(p, "EstruturaDiagonal", Vector3.new(x - 3, 0, 1.8), Vector3.new(x + 1, 11, -0.7), 0.22, Color3.fromRGB(157, 168, 148), Enum.Material.Metal)
		beam(p, "LuzDiagonal", Vector3.new(x - 2.8, 0.2, 2), Vector3.new(x + 1.2, 10.8, -0.5), 0.035, C.white, Enum.Material.Neon)
	end
	for _, x in ipairs({ -8.4, 14.7 }) do
		glow(p, "LuzIndiretaVertical", Vector3.new(0.065, 9.6, 0.08), CFrame.new(x, 5.2, -5.9), Color3.fromRGB(196, 247, 217), 1.4, 14)
	end
	-- Parede livre: o telão e seus textos foram removidos do menu inicial.
	-- Inlaid pale strips catch the natural side light without fake UI shadows.
	for i = 0, 3 do
		block(p, "FaixaPisoIluminada", Vector3.new(3.8, 0.014, 10), CFrame.new(-9 + i * 5.7, -0.025, 4.7) * CFrame.Angles(0, -0.2, 0), Color3.fromRGB(160, 163, 139), Enum.Material.Marble)
	end
	local key = block(p, "JanelaLuz", Vector3.new(0.1, 7, 10), CFrame.new(-16.5, 6.2, 4), Color3.fromRGB(191, 212, 200), Enum.Material.Neon, 0.94)
	local keyLight = Instance.new("SurfaceLight")
	keyLight.Face, keyLight.Angle, keyLight.Range, keyLight.Brightness = Enum.NormalId.Right, 72, 18, 0.72
	keyLight.Color, keyLight.Shadows = Color3.fromRGB(220, 231, 218), true
	keyLight.Parent = key
	self:_menuAvatar(Vector3.new(5.3, 0, 0.1), Vector3.new(0, 3.9, 17))
	self.cameraPosition, self.cameraTarget, self.fov = Vector3.new(0, 3.9, 17), Vector3.new(0, 2.6, -1), 34
end

local function tree(parent, x, z, size)
	cylinder(parent, "Tronco", 0.16 * size, 3.1 * size, Vector3.new(x, 1.5 * size, z), Color3.fromRGB(69, 65, 47), Enum.Material.Wood)
	for i = 0, 2 do
		local crown = block(parent, "Copa", Vector3.new(2.5, 3, 2.5) * size, CFrame.new(x + (i - 1) * size * 0.65, 3.8 * size + (i % 2) * size * 0.7, z), Color3.fromRGB(44 + i * 5, 82 + i * 5, 47), Enum.Material.Grass)
		crown.Shape = Enum.PartType.Ball
	end
end

function Scene:_arena(homeClub, awayClub, homeKit, awayKit, withActors)
	local p = self.folder
	floor(p, 38, false)
	trimRectangle(p, 27, 13, Vector3.new(0, -0.008, -1), Color3.fromRGB(34, 128, 108), 0.055)
	block(p, "ArenaParede", Vector3.new(61, 16, 0.6), CFrame.new(0, 6.7, -8), Color3.fromRGB(7, 19, 26), Enum.Material.Metal)
	for i = -4, 4 do
		local x = i * 4.3
		local angle = i * -0.035
		local panel = block(p, "PainelArena", Vector3.new(4.35, 10.3, 0.2), CFrame.new(x, 5.1, -6.6 + math.abs(i) * 0.17) * CFrame.Angles(0, angle + math.pi, 0), C.green, Enum.Material.Neon)
		surface(panel, i < 0 and Color3.fromRGB(12, 32, 61) or Color3.fromRGB(10, 67, 65), i > 0 and Color3.fromRGB(8, 109, 92) or Color3.fromRGB(15, 85, 93))
	end
	for _, sign in ipairs({ -1, 1 }) do
		for i = 0, 2 do
			beam(p, "PilarDiagonalArena", Vector3.new(sign * (13 + i * 1.7), 0, -3), Vector3.new(sign * (17 + i * 1.7), 11, -4), 0.12, Color3.fromRGB(64, 102, 95), Enum.Material.Metal)
		end
		glow(p, "LuzLateralArena", Vector3.new(0.065, 9, 0.08), CFrame.new(sign * 12.4, 4.7, -4.8), C.cyan, 2, 22)
		glow(p, "LuzPisoArena", Vector3.new(14, 0.04, 0.05), CFrame.new(sign * 9, -0.015, -3.5), Color3.fromRGB(45, 185, 148), 1, 12)
	end
	for x = -10, 10, 5 do glow(p, "LuzTetoArena", Vector3.new(2.3, 0.05, 0.6), CFrame.new(x, 10, 0), Color3.fromRGB(216, 255, 244), 2, 18) end
	if withActors then
		self:_actor(homeClub, homeKit, Vector3.new(-6.1, 2.81, 0.6), 169, "Standing", 7)
		self:_actor(awayClub, awayKit, Vector3.new(6.1, 2.81, 0.6), 188, "Standing", 11)
	end
	self.cameraPosition, self.cameraTarget, self.fov = Vector3.new(0, 3.7, 17), Vector3.new(0, if withActors then 2.6 else 3.2, -1), if withActors then 34 else 36
end

function Scene:Show(mode, homeClub, awayClub, homeKitIndex, awayKitIndex)
	-- Chamadas legadas de treino nao devem montar a cena removida.
	mode = if mode == "Training" then "Interior" else (mode or "Interior")
	if self.mode == mode then
		self:UpdateClubs(homeClub, awayClub, homeKitIndex, awayKitIndex)
		return
	end
	if self.menuAvatar then self.menuAvatar:Destroy(); self.menuAvatar = nil end
	if self.tunnel then self.tunnel:Destroy(); self.tunnel = nil end
	self.mode, self.clubText = mode, nil
	table.clear(self.actors)
	self.settingsNeon = nil
	table.clear(self.settingsRings)
	self.folder:ClearAllChildren()
	if mode == "Tunnel" then
		local quality = if self.settings.quality == "Baixa" then "Low" elseif self.settings.quality == "Alta" then "High" else "Medium"
		local success, result = pcall(function()
			return TunnelScene.new({
				parent = self.folder, origin = CFrame.new(), quality = quality,
				camera = false, takeOverLighting = false,
			})
		end)
		if success then
			self.tunnel = result
			local eye, target = TunnelGeometry.CameraPosition, TunnelGeometry.CameraTarget
			self.cameraPosition = Vector3.new(eye[1], eye[2], eye[3])
			self.cameraTarget = Vector3.new(target[1], target[2], target[3])
			self.fov = TunnelGeometry.FieldOfView
		else
			warn("[CL27] Túnel indisponível, apresentando cenário seguro: " .. tostring(result))
			self.mode = "Arena"
			self:_arena(homeClub, awayClub, homeKitIndex, awayKitIndex, false)
		end
	elseif mode == "Arena" or mode == "Kits" then self:_arena(homeClub, awayClub, homeKitIndex, awayKitIndex, mode == "Kits")
	else self:_interior(homeClub, homeKitIndex) end
	self:_light(self.mode)
	self:ApplySettings()
end

-- Camada decorativa exclusiva da tela Settings. Não muda a arena
-- anterior, não cria outra cena e destrói tudo quando a página fecha.
function Scene:SetSettingsAtmosphere(visible)
	if not visible then
		if self.settingsNeon then self.settingsNeon:Destroy(); self.settingsNeon = nil end
		table.clear(self.settingsRings)
		return
	end
	if self.settingsNeon then return end
	if self.mode ~= "Arena" then return end

	local folder = Instance.new("Folder")
	folder.Name = "CL27_SettingsNeon"
	folder.Parent = self.folder
	self.settingsNeon = folder
	local tones = {
		Color3.fromRGB(25, 203, 120),
		Color3.fromRGB(42, 239, 147),
		Color3.fromRGB(21, 168, 105),
	}
	for index, setting in ipairs({
		{center = Vector3.new(-11.3, 5.2, -5.5), radius = 2.4, speed = 0.24},
		{center = Vector3.new(11.3, 5.2, -5.5), radius = 2.65, speed = -0.2},
		{center = Vector3.new(0, 9.2, -6.1), radius = 2.45, speed = 0.16},
	}) do
		local ring = Instance.new("Model")
		ring.Name = "AnelNeon_" .. tostring(index)
		ring.Parent = folder
		local segments = 22
		for segment = 1, segments do
			local a = (segment - 1) / segments * math.pi * 2
			local b = segment / segments * math.pi * 2
			local center = setting.center
			local p1 = center + Vector3.new(math.cos(a) * setting.radius, math.sin(a) * setting.radius, 0)
			local p2 = center + Vector3.new(math.cos(b) * setting.radius, math.sin(b) * setting.radius, 0)
			local line = beam(ring, "Arco_" .. tostring(segment), p1, p2, 0.046, tones[index], Enum.Material.Neon)
			-- Arco luminoso com cauda em movimento: a rotação agora fica
			-- perceptível mesmo com o anel perfeitamente circular.
			line.Transparency = if segment <= 4 then 0.07 elseif segment <= 9 then 0.3 else 0.68
		end
		local heart = block(ring, "NucleoLuz", Vector3.new(0.05, 0.05, 0.05), CFrame.new(setting.center), tones[index], Enum.Material.Neon, 1)
		local lamp = Instance.new("PointLight")
		lamp.Name = "BrilhoVerde"
		lamp.Color = tones[index]
		lamp.Brightness = 0.38
		lamp.Range = 9
		lamp.Shadows = false
		lamp:SetAttribute("CL27Range", 9)
		lamp.Parent = heart
		ring:PivotTo(CFrame.new(setting.center))
		table.insert(self.settingsRings, {
			model = ring, center = CFrame.new(setting.center),
			speed = setting.speed, frequency = 0.7 + index * 0.21, light = lamp,
		})
	end
end

function Scene:ApplySettings(settings)
	if settings then self.settings = settings end
	if self.menuAvatar then self.menuAvatar:SetSettings(self.settings) end
	local quality = self.settings.quality or "Alta"
	local low, high = quality == "Baixa", quality == "Alta"
	Lighting.LightingStyle = low and Enum.LightingStyle.Soft or Enum.LightingStyle.Realistic
	Lighting.PrioritizeLightingQuality = high
	Lighting.GlobalShadows = not low
	self.bloom.Enabled = not low
	self.bloom.Intensity = if self.mode == "Tunnel" then TunnelLighting.Post.BloomIntensity else (self.mode == "Interior" and 0.06 or (high and 0.2 or 0.1))
	if self.tunnel then
		local tunnelQuality = if quality == "Baixa" then "Low" elseif quality == "Alta" then "High" else "Medium"
		self.tunnel:ApplyQuality(tunnelQuality)
		self.bloom.Size,self.bloom.Threshold = TunnelLighting.Post.BloomSize,TunnelLighting.Post.BloomThreshold
		self.grade.Contrast,self.grade.Saturation = TunnelLighting.Post.Contrast,TunnelLighting.Post.Saturation
	else
		self.bloom.Size, self.bloom.Threshold = 28, 1.15
		self.grade.Contrast, self.grade.Saturation = 0.1, -0.06
	end
	self.rays.Enabled = false
	for _, object in ipairs(self.folder:GetDescendants()) do
		if object:IsA("Light") and not object:GetAttribute("CL27TunnelLight") then
			object.Shadows = high and object:IsA("SurfaceLight")
			if object:IsA("PointLight") then
				object.Enabled = not low
				local originalRange = object:GetAttribute("CL27Range") or 12
				object.Range = high and originalRange or math.min(originalRange, 15)
			end
		elseif object:IsA("BasePart") and object.Name == "RedeGol" then
			object.Transparency = low and 1 or 0
		end
	end
end

function Scene:UpdateClubs(homeClub, awayClub, homeKitIndex, awayKitIndex)
	if self.actors[1] then Rig.applyKit(self.actors[1], homeClub, homeKitIndex, 0.24, self.settings.reducedMotion) end
	if self.actors[2] then Rig.applyKit(self.actors[2], awayClub, awayKitIndex, 0.24, self.settings.reducedMotion) end
	if self.clubText then self.clubText.Text = string.upper(homeClub and homeClub.name or "CLUB LEGACY") end
end

function Scene:Destroy()
	self:SetSettingsAtmosphere(false)
	if self.tunnel then self.tunnel:Destroy(); self.tunnel = nil end
	if self.menuAvatar then self.menuAvatar:Destroy(); self.menuAvatar = nil end
	if self.connection then self.connection:Disconnect() end
	for _, tween in ipairs(self.lightTweens) do tween:Cancel() end
	for _, effect in ipairs(self.effects) do effect:Destroy() end
	self.folder:Destroy()
	for key, value in pairs(self.oldLighting) do Lighting[key] = value end
	for camera in pairs(self.cameraSnapshots) do restoreCamera(self.cameraSnapshots, camera) end
	table.clear(self.activeCamera)
end

return Scene
