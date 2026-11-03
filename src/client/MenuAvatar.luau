--!strict
-- Apenas a apresentação de HomeInterior/HomeTraining.
-- Usa a aparência REAL de Players.LocalPlayer, sem dummy/kit fictício.
-- Suporta tanto Motor6D quanto AnimationConstraint (Avatar Joint Upgrade).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MenuAvatar = {}
MenuAvatar.__index = MenuAvatar

local INTERVAL = 10
local TRANSITION = 0.85
local POSES = {
	-- Segura a bola de futebol à frente do tronco.
	hold = {
		Waist = CFrame.Angles(0, math.rad(-5), 0),
		Neck = CFrame.Angles(math.rad(-3), math.rad(5), 0),
		LeftShoulder = CFrame.Angles(math.rad(48), math.rad(-8), math.rad(-17)),
		RightShoulder = CFrame.Angles(math.rad(48), math.rad(9), math.rad(17)),
		LeftElbow = CFrame.Angles(math.rad(-62), 0, 0),
		RightElbow = CFrame.Angles(math.rad(-62), 0, 0),
	},
	-- Um pé sobre a bola; o outro sustenta o corpo.
	foot = {
		Waist = CFrame.Angles(math.rad(2), math.rad(5), math.rad(-2)),
		Neck = CFrame.Angles(math.rad(-3), math.rad(-5), 0),
		LeftShoulder = CFrame.Angles(math.rad(4), 0, math.rad(-8)),
		RightShoulder = CFrame.Angles(math.rad(-8), 0, math.rad(11)),
		LeftElbow = CFrame.Angles(math.rad(-14), 0, 0),
		RightElbow = CFrame.Angles(math.rad(-13), 0, 0),
		RightHip = CFrame.Angles(math.rad(-34), math.rad(-3), math.rad(-3)),
		RightKnee = CFrame.Angles(math.rad(46), 0, 0),
		RightAnkle = CFrame.Angles(math.rad(-13), 0, 0),
	},
}

local function cubic(value: number): number
	local t = math.clamp(value, 0, 1)
	return t * t * (3 - 2 * t)
end

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
		blend = 0,
		pose = 0,
		fromBlend = 0,
		changeElapsed = TRANSITION,
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
	end)
	return self
end

function MenuAvatar:_step(dt: number)
	if not self.alive or not self.model or not self.root or not self.ball then return end
	self.elapsed += dt
	local currentPose = math.floor(self.elapsed / INTERVAL) % 2
	if currentPose ~= self.pose then
		self.pose = currentPose
		self.fromBlend = self.blend
		self.changeElapsed = 0
	end
	local reduced = self.settings and self.settings.reducedMotion
	if reduced then
		self.blend = currentPose
	else
		self.changeElapsed = math.min(TRANSITION, self.changeElapsed + dt)
		self.blend = self.fromBlend + (currentPose - self.fromBlend) * cubic(self.changeElapsed / TRANSITION)
	end

	local breathing = if reduced then 0 else math.sin(self.elapsed * 1.35) * 0.018
	for name, joint in pairs(self.joints) do
		local hold = POSES.hold[name] or CFrame.identity
		local foot = POSES.foot[name] or CFrame.identity
		local pose = hold:Lerp(foot, self.blend)
		if name == "Waist" then
			pose *= CFrame.Angles(breathing, 0, 0)
		elseif name == "Neck" then
			pose *= CFrame.Angles(breathing * 0.4, 0, 0)
		end
		-- Transform funciona nos modelos clássicos e nos avatares com AJU.
		(joint :: any).Transform = pose
	end

	local hand = self.hand
	local holdPosition
	if hand then
		holdPosition = (hand.CFrame * CFrame.new(0, -0.12, -self.radius * 0.5)).Position
	else
		holdPosition = (self.root.CFrame * CFrame.new(0, 0.7, -0.95)).Position
	end
	local holdCFrame = CFrame.new(holdPosition)
	local footCFrame = CFrame.new(self.ballGround)
	self.ball:PivotTo(holdCFrame:Lerp(footCFrame, self.blend))
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
