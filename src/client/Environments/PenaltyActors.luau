--!nonstrict
local Rig = require(script.Parent.Parent.Rig)
local Actors = {}
local function make(parent,name,kit,position,target,pose)
	local club={id=name,name="CL 27",kits={kit}}
	local actor=Rig.create({name=name,number=name=="CobradorR15" and 27 or 1},club,1)
	actor.Name=name
	Rig.pose(actor,pose)
	-- Bake the Motor6D chain before publishing the static model. No frame delay,
	-- physics settling, T pose flash or animated feet below the turf in stage 1.
	local welds,motors={},{}
	for _,node in ipairs(actor:GetDescendants()) do
		if node:IsA("WeldConstraint") then
			table.insert(welds,{joint=node,offset=node.Part0.CFrame:ToObjectSpace(node.Part1.CFrame)})
		elseif node:IsA("Motor6D") then table.insert(motors,node) end
	end
	local resolved={[actor.PrimaryPart]=true}
	for _=1,16 do
		for _,joint in ipairs(motors) do
			if resolved[joint.Part0] then
				joint.Part1.CFrame=joint.Part0.CFrame*joint.C0*joint.C1:Inverse()
				resolved[joint.Part1]=true
			end
		end
	end
	for _,data in ipairs(welds) do data.joint.Part1.CFrame=data.joint.Part0.CFrame*data.offset end
	for _,node in ipairs(actor:GetDescendants()) do
		if node:IsA("BasePart") then node.Anchored=true;node.CastShadow=true end
	end
	actor:PivotTo(CFrame.lookAt(Vector3.new(position[1],0,position[3]),Vector3.new(target[1],0,target[3])))
	local bottom=math.huge
	for _,side in ipairs({"LeftFoot","RightFoot","LeftSola","RightSola"}) do
		local foot=actor:FindFirstChild(side)
		if foot then
			for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
				local corner=foot.CFrame:PointToWorldSpace(Vector3.new(x*foot.Size.X/2,y*foot.Size.Y/2,z*foot.Size.Z/2))
				bottom=math.min(bottom,corner.Y)
			end end end
		end
	end
	actor:PivotTo(actor:GetPivot()+Vector3.new(0,0.035-bottom,0))
	actor:SetAttribute("PresentationOnly",true)
	actor.Parent=parent
	return actor
end
function Actors.create(parent,layout)
	local dark=Color3.fromRGB(28,34,39)
	local striker=make(parent,"CobradorR15",{
		name="CL Academy",shirt=Color3.fromRGB(177,224,67),shorts=dark,socks=dark,accent=Color3.fromRGB(92,255,51),
	},layout.Striker,layout.Ball,"PenaltyStriker")
	local keeper=make(parent,"GoleiroR15",{
		name="CL Goalkeeper",shirt=Color3.fromRGB(225,57,113),shorts=Color3.fromRGB(201,40,91),
		socks=Color3.fromRGB(220,52,108),accent=Color3.fromRGB(248,208,220),
	},layout.Keeper,layout.Ball,"PenaltyKeeper")
	for _,side in ipairs({"LeftHand","RightHand"}) do
		local hand=keeper:FindFirstChild(side)
		hand.Color=Color3.fromRGB(232,240,230)
		hand.Size=hand.Size*1.12
	end
	return striker,keeper
end
return Actors
