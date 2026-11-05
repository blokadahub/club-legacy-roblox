--!nocheck
-- Original, asset-free R15 presentation rig. Front faces -Z, feet at Y=-2.81.
local TweenService = game:GetService("TweenService")
local Rig = {}
local rigs = setmetatable({}, { __mode = "k" })
-- Neither keys nor values in this registry retain a portrait/model after disposal.
local kitTweens = setmetatable({}, { __mode = "kv" })
local white = Color3.fromRGB(237, 245, 244)
local dark = Color3.fromRGB(13, 24, 31)

local function color(value, fallback)
	return typeof(value) == "Color3" and value or fallback
end

local function tint(object, property, target, duration)
	local previous = kitTweens[object]
	if previous then previous:Cancel(); kitTweens[object] = nil end
	if duration <= 0 or object[property] == target then object[property] = target; return end
	local tween = TweenService:Create(object, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { [property] = target })
	local targetRef = setmetatable({ object }, { __mode = "v" })
	-- The one-shot signal owns the active tween until completion/cancellation.
	-- It captures a weak target, never the model or a strong part reference.
	tween.Completed:Once(function()
		local current = targetRef[1]
		if current and kitTweens[current] == tween then kitTweens[current] = nil end
	end)
	kitTweens[object] = tween
	tween:Play()
end

local function part(model, name, size, position, tint, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = CFrame.new(position)
	p.Color = tint
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	if shape then p.Shape = shape end
	p.Parent = model
	return p
end

local function detail(model, host, name, size, offset, tint, role, shape)
	local p = part(model, name, size, Vector3.zero, tint, shape)
	p.CFrame = host.CFrame * offset
	p:SetAttribute("KitRole", role)
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = host, p
	weld.Parent = p
	return p
end

local function motor(parent, name, p0, p1, c0, c1)
	for _, pair in ipairs({ { p0, c0 }, { p1, c1 } }) do
		local attachment = Instance.new("Attachment")
		attachment.Name = name .. "RigAttachment"
		attachment.CFrame = pair[2]
		attachment.Parent = pair[1]
	end
	local m = Instance.new("Motor6D")
	m.Name, m.Part0, m.Part1, m.C0, m.C1 = name, p0, p1, c0, c1
	m.Parent = parent
	return m
end

local function chest(host, number)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "IdentidadeOriginal"
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(512, 400)
	gui.LightInfluence = 0.65
	gui.Parent = host
	local brand = Instance.new("TextLabel")
	brand.Name = "Marca"
	brand.BackgroundTransparency = 1
	brand.Position, brand.Size = UDim2.fromScale(0.1, 0.13), UDim2.fromScale(0.8, 0.23)
	brand.Text, brand.Font, brand.TextScaled = "CL  /  27", Enum.Font.GothamBold, true
	brand.TextColor3 = white
	brand.Parent = gui
	local num = brand:Clone()
	num.Name, num.Text = "Numero", tostring(number or 7)
	num.Position, num.Size = UDim2.fromScale(0.3, 0.44), UDim2.fromScale(0.4, 0.4)
	num.Parent = gui
end

function Rig.create(playerData, club, kitIndex)
	playerData, club = playerData or {}, club or {}
	local skin = color(playerData.skin, Color3.fromRGB(167, 112, 81))
	local hair = color(playerData.hair, Color3.fromRGB(27, 22, 21))
	local model = Instance.new("Model")
	model.Name = playerData.name or "Atleta CL 27"
	local root = part(model, "HumanoidRootPart", Vector3.new(1.5, 1.6, 0.7), Vector3.zero, dark)
	root.Transparency, root.Anchored = 1, true
	model.PrimaryPart = root
	local lower = part(model, "LowerTorso", Vector3.new(1.35, 0.65, 0.7), Vector3.zero, white)
	local upper = part(model, "UpperTorso", Vector3.new(1.7, 1.2, 0.78), Vector3.new(0, 0.92, 0), white)
	local head = part(model, "Head", Vector3.new(0.94, 1.04, 0.9), Vector3.new(0, 2, 0), skin, Enum.PartType.Ball)
	lower:SetAttribute("KitRole", "shorts")
	upper:SetAttribute("KitRole", "shirt")
	local joints = {}
	joints.Root = motor(lower, "Root", root, lower, CFrame.identity, CFrame.identity)
	joints.Waist = motor(upper, "Waist", lower, upper, CFrame.new(0, 0.33, 0), CFrame.new(0, -0.59, 0))
	joints.Neck = motor(head, "Neck", upper, head, CFrame.new(0, 0.6, 0), CFrame.new(0, -0.48, 0))
	for _, side in ipairs({ "Left", "Right" }) do
		local sign = side == "Left" and -1 or 1
		local ua = part(model, side .. "UpperArm", Vector3.new(0.5, 0.94, 0.57), Vector3.new(sign * 1.15, 0.91, 0), white)
		local la = part(model, side .. "LowerArm", Vector3.new(0.43, 0.9, 0.53), Vector3.new(sign * 1.15, -0.02, 0), skin)
		local hand = part(model, side .. "Hand", Vector3.new(0.4, 0.36, 0.51), Vector3.new(sign * 1.15, -0.64, 0), skin)
		local ul = part(model, side .. "UpperLeg", Vector3.new(0.61, 1.08, 0.64), Vector3.new(sign * 0.39, -0.85, 0), white)
		local ll = part(model, side .. "LowerLeg", Vector3.new(0.52, 1.02, 0.55), Vector3.new(sign * 0.39, -1.9, 0), white)
		local foot = part(model, side .. "Foot", Vector3.new(0.6, 0.4, 0.98), Vector3.new(sign * 0.39, -2.61, -0.16), dark)
		ua:SetAttribute("KitRole", "shirt")
		ul:SetAttribute("KitRole", "shorts")
		ll:SetAttribute("KitRole", "socks")
		joints[side .. "Shoulder"] = motor(ua, side .. "Shoulder", upper, ua, CFrame.new(sign * 1.15, 0.44, 0), CFrame.new(0, 0.45, 0))
		joints[side .. "Elbow"] = motor(la, side .. "Elbow", ua, la, CFrame.new(0, -0.47, 0), CFrame.new(0, 0.46, 0))
		joints[side .. "Wrist"] = motor(hand, side .. "Wrist", la, hand, CFrame.new(0, -0.45, 0), CFrame.new(0, 0.17, 0))
		joints[side .. "Hip"] = motor(ul, side .. "Hip", lower, ul, CFrame.new(sign * 0.39, -0.3, 0), CFrame.new(0, 0.55, 0))
		joints[side .. "Knee"] = motor(ll, side .. "Knee", ul, ll, CFrame.new(0, -0.52, 0), CFrame.new(0, 0.53, 0))
		joints[side .. "Ankle"] = motor(foot, side .. "Ankle", ll, foot, CFrame.new(0, -0.51, 0), CFrame.new(0, 0.2, 0.16))
		detail(model, ua, side .. "PunhoCamisa", Vector3.new(0.515, 0.09, 0.585), CFrame.new(0, -0.38, 0), white, "accent")
		detail(model, ll, side .. "FaixaMeiao", Vector3.new(0.535, 0.1, 0.565), CFrame.new(0, 0.32, 0), white, "accent")
		detail(model, foot, side .. "Sola", Vector3.new(0.61, 0.055, 0.99), CFrame.new(0, -0.18, 0), dark, "boot")
		detail(model, foot, side .. "DetalheChuteira", Vector3.new(0.62, 0.07, 0.3), CFrame.new(0, 0.1, -0.14), white, "accent")
	end
	-- Collar, asymmetric stripe and a small original geometric crest.
	detail(model, upper, "Gola", Vector3.new(0.62, 0.095, 0.81), CFrame.new(0, 0.53, 0), dark, "accent")
	detail(model, upper, "FaixaLateral", Vector3.new(0.13, 1.1, 0.805), CFrame.new(0.64, 0, 0), dark, "accent")
	local crest = detail(model, upper, "EscudoOriginal", Vector3.new(0.2, 0.24, 0.025), CFrame.new(-0.43, 0.26, -0.405) * CFrame.Angles(0, 0, math.rad(45)), white, "accent")
	crest.Material = Enum.Material.Metal
	chest(upper, playerData.number)
	-- The eyes and hair are geometry, without photographs or catalog dependencies.
	detail(model, head, "Cabelo", Vector3.new(0.98, 0.56, 0.93), CFrame.new(0, 0.37, 0.04), hair, "hair", Enum.PartType.Ball)
	detail(model, head, "Franja", Vector3.new(0.81, 0.17, 0.25), CFrame.new(0, 0.27, -0.35) * CFrame.Angles(0, 0, -0.08), hair, "hair")
	for _, x in ipairs({ -0.18, 0.18 }) do
		detail(model, head, "Olho", Vector3.new(0.075, 0.07, 0.025), CFrame.new(x, 0.04, -0.437), dark, "face", Enum.PartType.Ball)
		detail(model, head, "Sobrancelha", Vector3.new(0.15, 0.03, 0.028), CFrame.new(x, 0.14, -0.428), hair, "hair")
	end
	detail(model, head, "Nariz", Vector3.new(0.1, 0.15, 0.09), CFrame.new(0, -0.04, -0.435), skin, "face", Enum.PartType.Ball)
	detail(model, head, "Boca", Vector3.new(0.19, 0.025, 0.02), CFrame.new(0, -0.22, -0.407), Color3.fromRGB(96, 55, 47), "face")
	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.BreakJointsOnDeath = false
	humanoid.AutoRotate = false
	-- Presentation is driven by Motor6D C0; no locomotion/state physics is needed.
	humanoid.EvaluateStateMachine = false
	humanoid.WalkSpeed = 0
	humanoid.Parent = model
	local bases = {}
	for name, joint in pairs(joints) do bases[name] = joint.C0 end
	local state = { joints = joints, rest = bases, pose = {}, phase = (playerData.number or 7) * 0.31 }
	rigs[model] = state
	local targets = setmetatable({}, { __mode = "v" })
	for i, object in ipairs(model:GetDescendants()) do targets[i] = object end
	model.Destroying:Once(function()
		for _, object in pairs(targets) do
			local tween = kitTweens[object]
			if tween then tween:Cancel(); kitTweens[object] = nil end
		end
		table.clear(state.joints)
		table.clear(state.rest)
		table.clear(state.pose)
	end)
	Rig.applyKit(model, club, kitIndex)
	Rig.pose(model, "Standing")
	return model
end

function Rig.applyKit(model, club, index, duration, reducedMotion)
	club = club or {}
	local kit = club.kits and club.kits[index or 1] or {}
	local palette = {
		shirt = color(kit.shirt, color(club.primary, white)),
		shorts = color(kit.shorts, color(club.primary, white)),
		socks = color(kit.socks, white),
		accent = color(kit.accent, color(club.secondary, Color3.fromRGB(28, 233, 181))),
	}
	local signature = table.concat({ tostring(club.id or ""), club.name or "", tostring(index or 1), kit.name or "", tostring(palette.shirt), tostring(palette.shorts), tostring(palette.socks), tostring(palette.accent) }, "|")
	local state = rigs[model]
	if state and state.kitSignature == signature and not reducedMotion then return end
	if state then state.kitSignature = signature end
	duration = reducedMotion and 0 or math.max(duration or 0, 0)
	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("BasePart") and palette[object:GetAttribute("KitRole")] then
			tint(object, "Color", palette[object:GetAttribute("KitRole")], duration)
		elseif object:IsA("TextLabel") then
			local luminance = palette.shirt.R * 0.21 + palette.shirt.G * 0.72 + palette.shirt.B * 0.07
			tint(object, "TextColor3", luminance > 0.58 and dark or white, duration)
		end
	end
	model:SetAttribute("Uniforme", kit.name or "Principal")
end

function Rig.pose(model, mode)
	local rig = rigs[model]
	if not rig then return end
	local p = {
		Waist = CFrame.Angles(0, math.rad(-6), math.rad(1)),
		Neck = CFrame.Angles(math.rad(-2), math.rad(8), 0),
		LeftShoulder = CFrame.Angles(math.rad(-5), 0, math.rad(-8)),
		RightShoulder = CFrame.Angles(math.rad(5), 0, math.rad(8)),
		LeftElbow = CFrame.Angles(math.rad(-9), 0, 0),
		RightElbow = CFrame.Angles(math.rad(-12), 0, 0),
		LeftHip = CFrame.Angles(0, math.rad(-4), math.rad(-3)),
		RightHip = CFrame.Angles(math.rad(-3), math.rad(5), math.rad(4)),
	}
	if mode == "PenaltyStriker" then
		p = {Waist=CFrame.Angles(0.04,0,0),Neck=CFrame.Angles(-0.04,0,0),
			LeftShoulder=CFrame.Angles(-0.03,0,-0.08),RightShoulder=CFrame.Angles(0.04,0,0.08),
			LeftElbow=CFrame.Angles(-0.12,0,0),RightElbow=CFrame.Angles(-0.10,0,0)}
	elseif mode == "PenaltyKeeper" then
		p = {Waist=CFrame.Angles(-0.12,0,0),Neck=CFrame.Angles(0.10,0,0),
			LeftShoulder=CFrame.Angles(-0.35,0,-0.48),RightShoulder=CFrame.Angles(-0.35,0,0.48),
			LeftElbow=CFrame.Angles(-0.38,0,0),RightElbow=CFrame.Angles(-0.38,0,0),
			LeftHip=CFrame.Angles(-0.20,0,-0.16),RightHip=CFrame.Angles(-0.20,0,0.16),
			LeftKnee=CFrame.Angles(0.35,0,0),RightKnee=CFrame.Angles(0.35,0,0),
			LeftAnkle=CFrame.Angles(-0.15,0,0),RightAnkle=CFrame.Angles(-0.15,0,0)}
	elseif mode == "Presentation" then
		p.Waist = CFrame.Angles(0.03, -0.15, -0.02)
		p.LeftShoulder = CFrame.Angles(-0.22, 0.08, -0.37)
		p.RightShoulder = CFrame.Angles(0.12, -0.08, 0.46)
		p.RightElbow = CFrame.Angles(-0.25, 0, 0)
		p.LeftKnee = CFrame.Angles(0.08, 0, 0)
	elseif mode == "Portrait" then
		p.Waist, p.Neck = CFrame.identity, CFrame.Angles(0, 0.04, 0)
	end
	rig.pose = p
	for name, joint in pairs(rig.joints) do joint.C0 = rig.rest[name] * (p[name] or CFrame.identity) end
end

function Rig.animate(model, elapsed, reducedMotion)
	local rig = rigs[model]
	if not rig then return end
	local breath = reducedMotion and 0 or math.sin(elapsed * 1.45 + rig.phase) * 0.007
	for _, name in ipairs({ "Waist", "Neck", "LeftShoulder", "RightShoulder" }) do
		local delta = name == "Waist" and CFrame.new(0, breath * 1.5, 0) * CFrame.Angles(breath, 0, 0)
			or CFrame.Angles(breath * 0.7, 0, breath * 0.2)
		rig.joints[name].C0 = rig.rest[name] * (rig.pose[name] or CFrame.identity) * delta
	end
end

return Rig
