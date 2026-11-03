--!strict
-- Apenas a apresentação de HomeInterior/HomeTraining.
-- Usa a aparência REAL de Players.LocalPlayer, sem dummy/kit fictício.
-- Suporta tanto Motor6D quanto AnimationConstraint (Avatar Joint Upgrade).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MenuAvatar = {}
MenuAvatar.__index = MenuAvatar

-- Pose única: pé direito apoiado na bola, com respiração leve.
local FOOT_POSE = {
	Waist = CFrame.Angles(math.rad(2), math.rad(5), math.rad(-2)),
	Neck = CFrame.Angles(math.rad(-3), math.rad(-5), 0),
	LeftShoulder = CFrame.Angles(math.rad(4), 0, math.rad(-8)),
	RightShoulder = CFrame.Angles(math.rad(-8), 0, math.rad(11)),
	LeftElbow = CFrame.Angles(math.rad(-14), 0, 0),
	RightElbow = CFrame.Angles(math.rad(-13), 0, 0),
	RightHip = CFrame.Angles(math.rad(-34), math.rad(-3), math.rad(-3)),
	RightKnee = CFrame.Angles(math.rad(46), 0, 0),
	RightAnkle = CFrame.Angles(math.rad(-13), 0, 0),
}

-- Creator Store: Soccer Ball MeshPart (sem scripts).
-- A autorização de assets externos varia por experiência.
local SOCCER_BALL_ASSET = 447114367
local SOCCER_BALL_TEXTURE = 447114306

local function soccerBall(parent: Instance, diameter: number)
	local model = Instance.new("Model")
	model.Name = "CL27_BolaFutebol"
	local sphere = Instance.new("Part")
	sphere.Name = "BolaBranca"
	sphere.Shape = Enum.PartType.Ball
	sphere.Size = Vector3.new(diameter, diameter, diameter)
	sphere.Color = Color3.fromRGB(238, 243, 241)
	sphere.Material = Enum.Material.SmoothPlastic
	sphere.Anchored, sphere.CanCollide, sphere.CanTouch, sphere.CanQuery = true, false, false, false
	-- Superfície arredondada com textura de bola; os painéis 3D ficam como fallback
	-- visual caso a textura não seja exibida por permissão ou compatibilidade.
	local skin = Instance.new("SpecialMesh")
	skin.MeshType = Enum.MeshType.Sphere
	skin.TextureId = "rbxassetid://" .. tostring(SOCCER_BALL_TEXTURE)
	skin.Parent = sphere
	sphere.Parent = model
	model.PrimaryPart = sphere

	-- Painéis discretos de uma bola, sem dependência de assets privados.
	for i = 1, 11 do
		local phi = math.acos(1 - 2 * (i - 0.5) / 11)
		local theta = math.pi * (1 + math.sqrt(5)) * i
		local normal = Vector3.new(math.cos(theta) * math.sin(phi), math.cos(phi), math.sin(theta) * math.sin(phi))
		local patch = Instance.new("Part")
		patch.Name = "PainelEscuro"
		patch.Shape = Enum.PartType.Cylinder
		patch.Size = Vector3.new(0.016, diameter * 0.24, diameter * 0.24)
		patch.Material = Enum.Material.SmoothPlastic
		patch.Color = Color3.fromRGB(24, 36, 43)
		patch.Anchored, patch.CanCollide, patch.CanTouch, patch.CanQuery = true, false, false, false
		patch.CFrame = CFrame.lookAt(normal * (diameter * 0.497), Vector3.zero) * CFrame.Angles(0, math.pi / 2, 0)
		patch.Parent = model
	end
	model.Parent = parent
	return model
end

-- Tenta usar a MeshPart real do Creator Store. Se não houver autorização,
-- mantém a bola local já criada; nenhuma configuração de segurança é alterada.
local function creatorBall(diameter: number): Model?
	local assetService = game:GetService("AssetService")
	local loaded: Instance? = nil
	local success, result = pcall(function()
		return assetService:LoadAssetAsync(SOCCER_BALL_ASSET)
	end)
	if success and typeof(result) == "Instance" then
		loaded = result
	end
	local meshPart: MeshPart? = nil
	if loaded then
		local candidate = if loaded:IsA("MeshPart") then loaded else loaded:FindFirstChildWhichIsA("MeshPart", true)
		if candidate and candidate:IsA("MeshPart") then meshPart = candidate end
	end
	if not meshPart then
		if loaded then loaded:Destroy() end
		local meshSuccess, meshResult = pcall(function()
			return assetService:CreateMeshPartAsync(
				Content.fromUri("rbxassetid://" .. tostring(SOCCER_BALL_ASSET)),
				{RenderFidelity = Enum.RenderFidelity.Precise, CollisionFidelity = Enum.CollisionFidelity.Box}
			)
		end)
		if meshSuccess and typeof(meshResult) == "Instance" and meshResult:IsA("MeshPart") then
			meshPart = meshResult
		else
			return nil
		end
	end
	local ballModel = Instance.new("Model")
	ballModel.Name = "CL27_BolaFutebol_Mesh"
	meshPart.Parent = ballModel
	if loaded and loaded ~= meshPart then loaded:Destroy() end
	meshPart.Name = "BolaFutebol"
	meshPart.Size = Vector3.new(diameter, diameter, diameter)
	meshPart.Color = Color3.fromRGB(255, 255, 255)
	meshPart.Material = Enum.Material.SmoothPlastic
	meshPart.Anchored = true
	meshPart.CanCollide = false
	meshPart.CanQuery = false
	meshPart.CanTouch = false
	meshPart.TextureID = "rbxassetid://" .. tostring(SOCCER_BALL_TEXTURE)
	ballModel.PrimaryPart = meshPart
	return ballModel
end

local function jointsOf(model: Model): {[string]: Instance}
	local joints: {[string]: Instance} = {}
	for _, joint in ipairs(model:GetDescendants()) do
		if joint:IsA("AnimationConstraint") then
			joints[joint.Name] = joint
			joint.IsKinematic = true
		elseif joint:IsA("Motor6D") and joints[joint.Name] == nil then
			joints[joint.Name] = joint
		end
	end
	return joints
end

function MenuAvatar.mount(parent: Instance, groundPosition: Vector3, cameraPosition: Vector3, settings)
	local self = setmetatable({
		alive = true,
		parent = parent,
		player = Players.LocalPlayer,
		position = groundPosition,
		cameraPosition = cameraPosition,
		settings = settings,
		model = nil,
		ball = nil,
		joints = {},
		elapsed = 0,
		ballGround = nil,
		connection = nil,
	}, MenuAvatar)

	self.connection = RunService.PreSimulation:Connect(function(dt: number)
		self:_step(math.min(dt, 0.12))
	end)

	task.spawn(function()
		-- A criação precisa ser assíncrona para não bloquear a interface.
		local player = self.player
		if not player or player.UserId <= 0 then return end
		local success, result = pcall(function()
			local description = Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId)
			local model = Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
			description:Destroy()
			return model
		end)
		if not success then
			warn("[CL27/MenuAvatar] Avatar indisponível: " .. tostring(result))
			return
		end
		local model = result :: Model
		if not self.alive or not self.parent.Parent then
			model:Destroy()
			return
		end
		local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid then
			warn("[CL27/MenuAvatar] O avatar recebido não tem HumanoidRootPart/Humanoid.")
			model:Destroy()
			return
		end
		model.Name = "CL27_AvatarReal_" .. tostring(player.UserId)
		model.PrimaryPart = root
		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BaseScript") then
				descendant:Destroy()
			elseif descendant:IsA("BasePart") then
				descendant.CanCollide = false
				descendant.CanTouch = false
				descendant.CanQuery = false
				descendant.Anchored = descendant == root
				descendant.Massless = descendant ~= root
			end
		end
		humanoid.AutoRotate = false
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.EvaluateStateMachine = false
		model.Parent = self.parent

		-- Roblox avatares olham para seu -Z. A câmera real está no +Z.
		local origin = Vector3.new(groundPosition.X, 0, groundPosition.Z)
		local look = Vector3.new(cameraPosition.X, 0, cameraPosition.Z)
		model:PivotTo(CFrame.lookAt(origin, look))
		local leftFoot = model:FindFirstChild("LeftFoot") :: BasePart?
		local rightFoot = model:FindFirstChild("RightFoot") :: BasePart?
		if leftFoot and rightFoot then
			local bottom = math.min(leftFoot.Position.Y - leftFoot.Size.Y / 2, rightFoot.Position.Y - rightFoot.Size.Y / 2)
			model:PivotTo(model:GetPivot() + Vector3.new(0, groundPosition.Y - bottom + 0.06, 0))
		else
			local _, bounds = model:GetBoundingBox()
			model:PivotTo(model:GetPivot() + Vector3.new(0, groundPosition.Y + bounds.Y / 2, 0))
		end

		self.model = model
		self.root = root
		self.hand = model:FindFirstChild("RightHand") :: BasePart?
		self.foot = rightFoot
		self.joints = jointsOf(model)

		local diameter = math.clamp((rightFoot and rightFoot.Size.X or 0.65) * 1.45, 0.78, 1.08)
		self.radius = diameter / 2
		self.ball = soccerBall(self.parent, diameter)
		local forward = root.CFrame.LookVector
		local right = root.CFrame.RightVector
		self.ballGround = groundPosition + right * 0.62 + forward * 0.92 + Vector3.new(0, self.radius, 0)
		self:_step(0)
		task.spawn(function()
			local meshModel = creatorBall(diameter)
			if not meshModel then return end
			if not self.alive or not self.parent.Parent then
				meshModel:Destroy()
				return
			end
			meshModel.Parent = self.parent
			if self.ball then self.ball:Destroy() end
			self.ball = meshModel
			self.ball:PivotTo(CFrame.new(self.ballGround))
		end)
	end)
	return self
end

function MenuAvatar:_step(dt: number)
	if not self.alive or not self.model or not self.root or not self.ball then return end
	self.elapsed += dt
	local reduced = self.settings and self.settings.reducedMotion
	local breathing = if reduced then 0 else math.sin(self.elapsed * 1.35) * 0.018
	for name, joint in pairs(self.joints) do
		local pose = FOOT_POSE[name] or CFrame.identity
		if name == "Waist" then
			pose *= CFrame.Angles(breathing, 0, 0)
		elseif name == "Neck" then
			pose *= CFrame.Angles(breathing * 0.4, 0, 0)
		end
		(joint :: any).Transform = pose
	end
	-- A bola permanece sob o pé. Não há transição para a pose com as mãos.
	self.ball:PivotTo(CFrame.new(self.ballGround))
end

function MenuAvatar:SetSettings(settings)
	self.settings = settings
end

function MenuAvatar:Destroy()
	if not self.alive then return end
	self.alive = false
	if self.connection then self.connection:Disconnect(); self.connection = nil end
	if self.model then self.model:Destroy(); self.model = nil end
	if self.ball then self.ball:Destroy(); self.ball = nil end
	table.clear(self.joints)
end

return MenuAvatar
