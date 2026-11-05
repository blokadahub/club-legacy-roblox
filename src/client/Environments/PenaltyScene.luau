--!nonstrict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Layout=require(script.Parent.PenaltyLayout)
local Actors=require(script.Parent.PenaltyActors)
local MenuAvatar=require(script.Parent.Parent.MenuAvatar)
local PenaltyScene={}
PenaltyScene.__index=PenaltyScene

function PenaltyScene.new(parent,settings)
	local self=setmetatable({connections={},alive=true},PenaltyScene)
	self.model=Instance.new("Model")
	self.model.Name="CL27_PenaltyPreview"
	self.model:SetAttribute("DevelopmentStage",1)
	local ok,err=pcall(function()
		self:Build(settings and settings.quality or "Alta")
		self:MountBall()
	end)
	if not ok then self:Destroy();error(err,2) end
	-- Architecture/ball are immediate; real avatars prepare asynchronously off-tree.
	self.model.Parent=parent
	self.actors=Actors.new(self.model,Layout,settings)
	return self
end

function PenaltyScene:Build(quality)
	local architecture=Instance.new("Model")
	architecture.Name="PitchAndStands"
	architecture.Parent=self.model
	local descriptors=Layout.build(quality)
	for _,data in ipairs(descriptors) do
		local part=Instance.new("Part")
		part.Name=data.name
		part.Size=Vector3.new(table.unpack(data.size))
		local position=Vector3.new(table.unpack(data.position))
		local frame=if data.target then CFrame.lookAt(position,Vector3.new(table.unpack(data.target))) else CFrame.new(position)*CFrame.Angles(table.unpack(data.rotation))
		if data.round then
			part.Shape=Enum.PartType.Cylinder
			part.Size=Vector3.new(data.size[3],data.size[1],data.size[2])
			frame=frame*CFrame.Angles(0,math.pi/2,0)
		elseif data.cylinder then part.Shape=Enum.PartType.Cylinder end
		part.CFrame=frame
		part.Color=Color3.fromRGB(table.unpack(data.color))
		part.Material=Enum.Material[data.material]
		part.Anchored=true
		part.CanCollide=data.collide
		part.CanTouch,part.CanQuery=false,data.collide
		part.CastShadow=data.name=="GoalPost_-1" or data.name=="GoalPost_1" or data.name=="GoalCrossbar"
		part.TopSurface,part.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
		part.Parent=architecture
	end
	local old=self.architecture
	self.architecture=architecture
	if old then old:Destroy() end
	self.quality=quality
	self.model:SetAttribute("ArchitectureParts",#descriptors)
end

function PenaltyScene:MountBall()
	local position=Vector3.new(table.unpack(Layout.Ball))
	self.ball=MenuAvatar.createFallbackBall(self.model,Layout.BallDiameter)
	self.ball:PivotTo(CFrame.new(position))
	self.ball:SetAttribute("PresentationOnly",true)
	local function watchAssets(assets)
		local function upgrade(template)
			if not self.alive or template.Name~="AcademySoccerBall" or self.imported then return end
			local ok,ball=pcall(MenuAvatar.cloneImportedBall,template,self.model,Layout.BallDiameter,position)
			if ok and ball then
				local old=self.ball
				self.ball=ball;self.imported=true
				ball:SetAttribute("PresentationOnly",true)
				old:Destroy()
			end
		end
		table.insert(self.connections,assets.ChildAdded:Connect(upgrade))
		local template=assets:FindFirstChild("AcademySoccerBall")
		if template then upgrade(template) end
	end
	table.insert(self.connections,ReplicatedStorage.ChildAdded:Connect(function(folder)
		if folder.Name=="CL27Assets" then watchAssets(folder) end
	end))
	local assets=ReplicatedStorage:FindFirstChild("CL27Assets")
	if assets then watchAssets(assets) end
end

function PenaltyScene:PreviewAction(action) return self.actors:Preview(action) end
function PenaltyScene:RetryAvatars() self.actors:Load() end

function PenaltyScene:ApplySettings(settings)
	if self.actors then self.actors:ApplySettings(settings) end
	local quality=settings.quality or "Alta"
	if self.alive and self.quality~=quality then self:Build(quality) end
end
function PenaltyScene:Destroy()
	if not self.alive then return end
	self.alive=false
	if self.actors then self.actors:Destroy();self.actors=nil end
	for _,connection in ipairs(self.connections) do connection:Disconnect() end
	table.clear(self.connections)
	self.model:Destroy()
end
return PenaltyScene
