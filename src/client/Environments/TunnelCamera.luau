--!nonstrict
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Geometry = require(script.Parent.TunnelGeometry)
local TunnelCamera = {}
TunnelCamera.__index = TunnelCamera
local activeOwner = nil

function TunnelCamera.new(options)
	options = options or {}
	assert(not activeOwner, "Another tunnel camera is active; destroy it first")
	local self = setmetatable({elapsed=0,origin=options.origin or CFrame.new(),previous=Workspace.CurrentCamera},TunnelCamera)
	local camera = Instance.new("Camera")
	camera.Name, camera.CameraType = "TunnelPresentationCamera", Enum.CameraType.Scriptable
	camera.FieldOfView, camera.FieldOfViewMode = Geometry.FieldOfView, Enum.FieldOfViewMode.Vertical
	camera.Parent = Workspace
	self.camera = camera
	activeOwner = self
	self:_step(0)
	Workspace.CurrentCamera = camera
	self:SetMotion(options.animate == true, options.reducedMotion ~= false)
	return self
end

function TunnelCamera:_step(dt)
	self.elapsed += math.clamp(dt,0,0.1)
	-- Bounded 0.18-stud dolly over a 100-second cycle. No geometry movement.
	local offset = if self.moving then math.sin(self.elapsed*math.pi/50)*0.18 else 0
	local a, b = Geometry.CameraPosition, Geometry.CameraTarget
	self.camera.CFrame = self.origin*CFrame.new(table.unpack(Geometry.lookAt({a[1],a[2],a[3]-offset},b)))
	self.camera.Focus = self.origin*CFrame.new(table.unpack(b))
end

function TunnelCamera:SetMotion(animate, reducedMotion)
	if self.destroyed then return end
	if self.connection then self.connection:Disconnect(); self.connection=nil end
	self.moving = animate == true and reducedMotion ~= true
	self.elapsed = 0
	self:_step(0)
	if self.moving then
		self.connection = RunService.RenderStepped:Connect(function(dt) self:_step(dt) end)
	end
end

function TunnelCamera:Destroy()
	if self.destroyed then return end
	self.destroyed = true
	if self.connection then self.connection:Disconnect(); self.connection=nil end
	-- If another feature has taken the camera meanwhile, leave its choice intact.
	if Workspace.CurrentCamera == self.camera then
		Workspace.CurrentCamera = if self.previous and self.previous.Parent then self.previous else nil
	end
	self.camera:Destroy()
	self.previous = nil
	activeOwner = nil
end

return TunnelCamera
