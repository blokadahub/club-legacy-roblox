--!strict
-- Apenas a apresentação de HomeInterior/HomeTraining.
-- Usa a aparência REAL de Players.LocalPlayer, sem dummy/kit fictício.
-- Suporta tanto Motor6D quanto AnimationConstraint (Avatar Joint Upgrade).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

-- Modelo visual escolhido: Academy soccer ball (Creator Store).
-- Pré-carregado e sanitizado pelo servidor em ReplicatedStorage.CL27Assets.
local ACADEMY_SOCCER_BALL_ID = 17275757538

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

-- Clona as peças do asset importado pelo servidor, preservando a geometria
-- e as texturas de todas as partes. Nunca executa scripts do modelo externo.
local function importedBall(template: Instance, parent: Instance, diameter: number, position: Vector3): Model?
	if not template:IsA("Model") or template:GetAttribute("SourceAssetId") ~= ACADEMY_SOCCER_BALL_ID then
		return nil
	end
	local ball = template:Clone()
	ball.Name = "CL27_AcademySoccerBall"
	local partCount = 0
	for _, part in ipairs(ball:GetDescendants()) do
		if part:IsA("LuaSourceContainer") then
			part:Destroy()
		elseif part:IsA("BasePart") then
			partCount += 1
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end
	if partCount == 0 then
		ball:Destroy()
		return nil
	end
	ball.Parent = parent
	local _, bounds = ball:GetBoundingBox()
	local longest = math.max(bounds.X, bounds.Y, bounds.Z)
	if longest <= 0.001 then
		ball:Destroy()
		return nil
	end
	-- Escala proporcional ao avatar. Nunca distorce a malha de cada MeshPart.
	ball:ScaleTo(diameter / longest)
	local centered, _ = ball:GetBoundingBox()
	ball.WorldPivot = CFrame.new(centered.Position)
	ball:PivotTo(CFrame.new(position))
	return ball
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
			-- O servidor carrega o asset uma vez; cada jogador o apresenta
			-- somente no seu próprio menu. A UI não espera o download do modelo.
			local assets = ReplicatedStorage:WaitForChild("CL27Assets", 12)
			if not assets or not self.alive then return end
			local function upgrade(template: Instance)
				if self.templateUpgraded or not self.alive or not self.parent.Parent then return end
				if template.Name ~= "AcademySoccerBall" then return end
				local ballModel = importedBall(template, self.parent, diameter, self.ballGround)
				if not ballModel then return end
				self.templateUpgraded = true
				if self.ballTemplateConnection then
					self.ballTemplateConnection:Disconnect()
					self.ballTemplateConnection = nil
				end
				local previous = self.ball
				self.ball = ballModel
				if previous then previous:Destroy() end
			end
			local existing = assets:FindFirstChild("AcademySoccerBall")
			if existing then upgrade(existing) end
			if not self.templateUpgraded and self.alive then
				self.ballTemplateConnection = assets.ChildAdded:Connect(upgrade)
				-- Confere novamente para não perder uma replicação entre
				-- a primeira consulta e a inscrição no evento ChildAdded.
				local arrived = assets:FindFirstChild("AcademySoccerBall")
				if arrived then upgrade(arrived) end
			end
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
	if self.ballTemplateConnection then self.ballTemplateConnection:Disconnect(); self.ballTemplateConnection = nil end
	if self.model then self.model:Destroy(); self.model = nil end
	if self.ball then self.ball:Destroy(); self.ball = nil end
	table.clear(self.joints)
end

return MenuAvatar
