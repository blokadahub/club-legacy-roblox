-- Atleta Roblox original montado localmente, sem HTTP, IDs de catálogo ou plugins.
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local KitDetails = require(script.Parent.Parent.Assets.KitDetails)
local Avatar = {}

local function part(model, name, size, cframe, color, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Shape = shape or Enum.PartType.Block
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local function makeRig(player, identity)
	local rig = Instance.new("Model")
	rig.Name = "AtletaCL27"
	local skin = player.skin
	local primary, secondary = identity.primary, identity.secondary
	part(rig,"Uniforme",Vector3.new(1.7,1.65,0.85),CFrame.new(0,2.9,0),primary)
	local trim = identity.kit == "Faixa" and Vector3.new(1.72,0.28,0.88) or Vector3.new(0.32,1.66,0.88)
	if identity.kit ~= "Liso" then
		part(rig,"Faixa",trim,CFrame.new(0,2.98,0),secondary)
		if identity.kit=="Listras" then
			for _, x in ipairs({-0.55,0.55}) do
				part(rig,"Listra",trim,CFrame.new(x,2.98,0),secondary)
			end
		end
	end
	KitDetails.crest(rig,identity,part)
	KitDetails.number(rig,player.number,CFrame.new(0.42,3.28,-0.46),secondary,0.30,part)
	KitDetails.number(rig,player.number,CFrame.new(0,2.94,0.46)*CFrame.Angles(0,math.pi,0),secondary,1.1,part)
	part(rig,"Calção",Vector3.new(1.52,0.52,0.8),CFrame.new(0,1.89,0),secondary)
	part(rig,"Pescoço",Vector3.new(0.48,0.28,0.48),CFrame.new(0,3.82,0),skin)
	local head = part(rig,"Cabeça",Vector3.new(1.08,1.13,1.02),CFrame.new(0,4.48,0),skin)
	local headMesh = Instance.new("SpecialMesh")
	headMesh.MeshType = Enum.MeshType.Head
	headMesh.Scale = Vector3.new(1.12,1.04,1.1)
	headMesh.Parent = head
	part(rig,"Cabelo",Vector3.new(1.12,0.37,1.02),CFrame.new(0,4.98,0.03),player.hair)
	for _, x in ipairs({-0.22,0.22}) do
		part(rig,"Olho",Vector3.new(0.085,0.10,0.035),CFrame.new(x,4.49,-0.54),Color3.fromRGB(20,23,24))
	end
	part(rig,"Sorriso",Vector3.new(0.24,0.035,0.035),CFrame.new(0,4.20,-0.55),Color3.fromRGB(82,49,40))
	for _, side in ipairs({-1,1}) do
		local shoulder = CFrame.new(side*1.09,3.06,0) * CFrame.Angles(0,0,side*math.rad(9))
		part(rig,"Manga",Vector3.new(0.54,0.75,0.72),shoulder,primary)
		part(rig,"Braço",Vector3.new(0.46,0.83,0.57),CFrame.new(side*1.24,2.40,-0.07)*CFrame.Angles(math.rad(-8),0,side*math.rad(10)),skin)
		part(rig,"Mão",Vector3.new(0.47,0.39,0.55),CFrame.new(side*1.32,1.87,-0.15),skin)
		part(rig,"Perna",Vector3.new(0.60,0.77,0.65),CFrame.new(side*0.43,1.25,0),skin)
		part(rig,"Meião",Vector3.new(0.61,0.69,0.66),CFrame.new(side*0.43,0.59,0),primary)
		part(rig,"Chuteira",Vector3.new(0.65,0.32,1),CFrame.new(side*0.43,0.12,-0.15),secondary)
	end
	rig.WorldPivot = CFrame.new(0,2.5,0)
	return rig
end

function Avatar.mount(parent, player, options, ctx)
	options = options or {}
	local ui, scope, settings = ctx.ui, ctx.scope, ctx.state.settings
	local viewport = ui.new("ViewportFrame", {
		Name = "Apresentacao3D",
		Size = UDim2.fromScale(1,1),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(174,191,195),
		LightColor = Color3.fromRGB(255,244,219),
		LightDirection = Vector3.new(-1,-0.5,-1),
		Active = options.interactive == true,
	}, parent)
	local world = ui.new("WorldModel", {Name="EstudioCL27"},viewport)
	local rig = makeRig(player,ctx.state.identity)
	rig.Parent = world
	local camera = ui.new("Camera", {FieldOfView=33},viewport)
	local full = options.fullBody ~= false
	camera.CFrame = CFrame.lookAt(full and Vector3.new(0,2.8,-10.4) or Vector3.new(0,3.9,-5.8), full and Vector3.new(0,2.65,0) or Vector3.new(0,3.7,0))
	viewport.CurrentCamera = camera
	local angle, elapsed, tickTime = -0.12,0,0
	local drag, lastX
	if options.interactive then
		scope:connect(viewport.InputBegan,function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				drag = input
				lastX = input.Position.X
			end
		end)
		scope:connect(UserInputService.InputChanged,function(input)
			if drag and (input == drag or input.UserInputType == Enum.UserInputType.MouseMovement) then
				angle += (input.Position.X-lastX)*0.012
				lastX = input.Position.X
			end
		end)
		scope:connect(UserInputService.InputEnded,function(input)
			if input == drag or input.UserInputType == Enum.UserInputType.MouseButton1 then drag = nil end
		end)
	end
	-- Apenas o(s) atleta(s) da tela ativa possuem conexão; qualidade econômica é estática.
	local base = CFrame.new(0,2.5,0)
	rig:PivotTo(base * CFrame.Angles(0,angle,0))
	if settings.quality ~= "Econômica" then
		scope:connect(RunService.RenderStepped,function(dt)
			elapsed += dt
			tickTime += dt
			if tickTime < (settings.quality == "Alta" and 1/60 or 1/30) then return end
			tickTime = 0
			local motion = not settings.reducedMotion
			local bob = motion and math.sin(elapsed*1.5)*0.018 or 0
			local turn = (motion and not drag) and math.sin(elapsed*0.35)*0.08 or 0
			rig:PivotTo(base * CFrame.new(0,bob,0) * CFrame.Angles(0,angle+turn,0))
		end)
	elseif options.interactive then
		scope:connect(UserInputService.InputChanged,function()
			if drag then rig:PivotTo(base*CFrame.Angles(0,angle,0)) end
		end)
	end
	return viewport
end

return Avatar
