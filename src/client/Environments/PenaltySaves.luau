--!nonstrict
-- Six authored defensive sequences. Shared interpolation, distinct body/foot paths.
-- +X is the keeper's right, which projects to screen-left from the penalty camera.
local Saves={}
Saves.Order={"LowLeft","LowRight","MidSave","HighSave","CentralSave","ShuffleSave"}
Saves.Labels={LowLeft="Rasteira ←",LowRight="Rasteira →",MidSave="Meia altura",HighSave="Defesa alta",CentralSave="Defesa central",ShuffleSave="Passo + mergulho"}
local ready={Waist={-10,0,0},Neck={5,0,0},LeftShoulder={15,0,-24},RightShoulder={15,0,24},
	LeftElbow={65,0,0},RightElbow={65,0,0},LeftWrist={0,0,-3},RightWrist={0,0,3},
	LeftHip={0,0,0},RightHip={0,0,0},LeftKnee={0,0,0},RightKnee={0,0,0},LeftAnkle={0,0,0},RightAnkle={0,0,0}}
local function key(t,root,roll,pose,ik,left,right)
	local full={}
	for name,value in pairs(ready) do full[name]=value end
	for name,value in pairs(pose or {}) do full[name]=value end
	return {t=t,root=root or {0,-.2,0},roll=roll or 0,pose=full,ik=ik==nil and 1 or ik,left=left or {0,0,0},right=right or {0,0,0}}
end
local clips={
	-- Collapse save: low leading right hand, folded near leg, side-sit then knee-up.
	LowLeft={
		key(0), key(.22,{.10,-.50,-.03},-4,{Waist={-23,0,-5},LeftElbow={80},RightElbow={90}}),
		key(.45,{.55,-.65,-.05},-20,{RightShoulder={40,0,48},LeftShoulder={35,0,28},LeftHip={-20,0,-12},RightHip={-35},LeftKnee={40},RightKnee={70}},0),
		key(.95,{3.8,-1.80,-.18},-84,{Waist={-17,8,-9},RightShoulder={150,-10,5},LeftShoulder={135,25,65},RightElbow={15},LeftElbow={20},RightWrist={-15,0,4},LeftHip={-42,0,-14},RightHip={-12,0,-8},LeftKnee={90},RightKnee={25},LeftAnkle={-30}},0),
		key(1.28,{4.0,-2.15,-.20},-78,{Waist={-8,0,7},RightShoulder={130,-10,-10},LeftShoulder={125,15,25},RightElbow={35},LeftElbow={40},LeftHip={-55},RightHip={-20,0,-8},LeftKnee={108},RightKnee={50}},0),
		key(1.90,{3.7,-1.65,-.14},-32,{Waist={-36,0,2},LeftShoulder={42,0,-12},RightShoulder={30,0,22},LeftElbow={75},RightElbow={65},LeftHip={-62},RightHip={-22},LeftKnee={112},RightKnee={42}},0),
		key(2.48,{3.5,-.38,0},0,{Waist={-15},LeftHip={-16},RightHip={-16},LeftKnee={32},RightKnee={32},LeftAnkle={-16},RightAnkle={-16}},0,{3.5,0,0},{3.5,0,0}),
		key(2.78,{3.5,-.2,0},0,{},1,{3.5,0,0},{3.5,0,0}),key(4.15),
	},
	-- Scoop save: deeper two-hand pickup, right-knee tuck, front-supported recovery.
	LowRight={
		key(0),key(.18,{-.06,-.60,-.10},3,{Waist={-28},LeftShoulder={32,0,-18},RightShoulder={30,0,18},LeftElbow={98},RightElbow={92}}),
		key(.46,{-.65,-.70,-.20},25,{Waist={-30,-8,5},LeftShoulder={52,-15,-42},RightShoulder={60,-15,-25},LeftElbow={70},RightElbow={60},RightHip={-35,0,12},RightKnee={78},LeftHip={-15},LeftKnee={30}},0),
		key(.88,{-3.5,-1.95,-.50},82,{Waist={-31,-12,10},LeftShoulder={150,-10,-8},RightShoulder={140,-25,-65},LeftElbow={18},RightElbow={24},LeftWrist={-12,0,-12},RightWrist={-12,0,12},RightHip={-48,0,15},RightKnee={100},LeftHip={-20,0,16},LeftKnee={42}},0),
		key(1.20,{-3.7,-2.0,-.52},58,{Waist={-42,-8,6},LeftShoulder={35,0,-38},RightShoulder={40,0,-25},LeftElbow={86},RightElbow={95},LeftHip={-45},RightHip={-50},LeftKnee={75},RightKnee={105}},0),
		key(1.82,{-3.4,-1.4,-.36},12,{Waist={-45},LeftShoulder={48,0,-16},RightShoulder={48,0,16},LeftElbow={90},RightElbow={90},LeftHip={-35},RightHip={-55},LeftKnee={65},RightKnee={110}},0),
		key(2.35,{-3.2,-.30,0},0,{Waist={-12},LeftHip={-12},RightHip={-12},LeftKnee={24},RightKnee={24},LeftAnkle={-12},RightAnkle={-12}},0,{-3.2,0,0},{-3.2,0,0}),
		key(2.62,{-3.2,-.20,0},0,{},1,{-3.2,0,0},{-3.2,0,0}),key(4.05),
	},
	-- Mid-height: horizontal flight, two extended arms, scissor legs, side roll.
	MidSave={
		key(0),key(.25,{.12,-.48,0},-3,{Waist={-16},LeftElbow={85},RightElbow={85}}),
		key(.48,{.85,-.10,-.05},-22,{Waist={-12,8,-6},RightShoulder={62,-12,60},LeftShoulder={65,10,34},RightElbow={45},LeftElbow={60},LeftHip={-22},RightHip={-20},LeftKnee={44},RightKnee={40}},0),
		key(.92,{4.2,.38,-.22},-74,{Waist={-6,12,-8},RightShoulder={145,-10,-20},LeftShoulder={145,15,25},RightElbow={18},LeftElbow={20},RightHip={18,0,8},LeftHip={-36,0,-10},RightKnee={25},LeftKnee={75}},0),
		key(1.42,{4.7,-1.75,-.30},-84,{Waist={-12,18,-5},RightShoulder={55,0,94},LeftShoulder={62,0,45},RightElbow={40},LeftElbow={75},RightHip={-30},LeftHip={-52},RightKnee={62},LeftKnee={105}},0),
		key(2.14,{4.2,-1.1,-.15},-30,{Waist={-32,15,2},RightShoulder={48,0,20},LeftShoulder={48,0,-18},RightElbow={85},LeftElbow={80},RightHip={-45},LeftHip={-30},RightKnee={92},LeftKnee={58}},0),
		key(2.70,{3.9,-.25,0},0,{LeftHip={-10},RightHip={-10},LeftKnee={20},RightKnee={20},LeftAnkle={-10},RightAnkle={-10}},0,{3.9,0,0},{3.9,0,0}),
		key(3.00,{3.9,-.20,0},0,{},1,{3.9,0,0},{3.9,0,0}),key(4.55),
	},
	-- High save: vertical load then diagonal reach, one leading hand, soft upright landing.
	HighSave={
		key(0),key(.24,{-.08,-.55,0},4,{Waist={-18},LeftShoulder={12,0,-20},RightShoulder={12,0,20},LeftElbow={95},RightElbow={90}}),
		key(.46,{-.50,.25,-.02},14,{Waist={-5,-8,3},LeftShoulder={118,-10,-25},RightShoulder={70,0,12},LeftElbow={32},RightElbow={55},LeftHip={-18},RightHip={-28},LeftKnee={36},RightKnee={56}},0),
		key(.90,{-2.7,1.35,-.12},29,{Waist={5,-12,6},LeftShoulder={155,-12,-32},RightShoulder={120,8,5},LeftElbow={8},RightElbow={22},LeftWrist={-8},RightWrist={5},LeftHip={-20,0,-6},RightHip={20,0,8},LeftKnee={65},RightKnee={26}},0),
		key(1.38,{-3.4,.15,-.12},16,{Waist={-10,-8,2},LeftShoulder={105,0,-28},RightShoulder={70,0,18},LeftElbow={35},RightElbow={65},LeftHip={-20},RightHip={-12},LeftKnee={40},RightKnee={24},LeftAnkle={-20},RightAnkle={-12}},0),
		key(1.76,{-3.45,-.40,-.06},0,{Waist={-20},LeftShoulder={40,0,-26},RightShoulder={30,0,24},LeftHip={-18},RightHip={-18},LeftKnee={36},RightKnee={36},LeftAnkle={-18},RightAnkle={-18}},0,{-3.45,0,0},{-3.45,0,0}),
		key(2.12,{-3.3,-.20,0},0,{},1,{-3.3,0,0},{-3.3,0,0}),key(3.75),
	},
	-- Central block: no dive or airborne phase, hands form a frontal catching pocket.
	CentralSave={
		key(0),key(.16,{0,-.45,-.04},0,{Waist={-20},LeftShoulder={24,0,-12},RightShoulder={24,0,12},LeftElbow={90},RightElbow={90}}),
		key(.38,{.06,-.66,-.22},-2,{Waist={-26},Neck={12},LeftShoulder={35,-30,10},RightShoulder={35,30,-10},LeftElbow={82},RightElbow={82},LeftWrist={-10,10,0},RightWrist={-10,-10,0}}),
		key(.65,{.03,-.58,-.30},0,{Waist={-20},LeftShoulder={25,-32,12},RightShoulder={25,32,-12},LeftElbow={100},RightElbow={100},LeftWrist={-6,12,0},RightWrist={-6,-12,0}}),
		key(1.02,{0,-.35,-.15},0,{Waist={-14},LeftShoulder={22,-8,-16},RightShoulder={22,8,16},LeftElbow={90},RightElbow={90}}),key(1.65),
	},
	-- Set step, second push, diagonal one-arm dive; return has a deliberate set step.
	ShuffleSave={
		key(0),key(.28,{.65,-.28,0},-3,{Waist={-14,5,-2},RightElbow={80},LeftElbow={75}},1,{0,0,0},{1.3,.18,0}),
		key(.58,{1.35,-.24,0},0,{Waist={-12,8,0},RightShoulder={25,0,30},LeftShoulder={20,0,-24}},1,{1.4,.18,0},{1.3,0,0}),
		key(.86,{1.7,-.48,-.08},-10,{Waist={-22,12,-5},RightShoulder={38,0,46},LeftShoulder={22,0,-10},LeftHip={-24},RightHip={-18},LeftKnee={48},RightKnee={36}},0,{1.4,0,0},{1.3,0,0}),
		key(1.38,{5.4,-.25,-.65},-61,{Waist={-8,18,-6},RightShoulder={85,-15,118},LeftShoulder={50,12,35},RightElbow={12},LeftElbow={82},LeftHip={-42,0,-12},RightHip={18,0,12},LeftKnee={92},RightKnee={24}},0),
		key(1.85,{5.65,-1.85,-.72},-80,{Waist={-18,12,8},RightShoulder={50,0,70},LeftShoulder={45,0,5},RightElbow={55},LeftElbow={100},LeftHip={-52},RightHip={-24},LeftKnee={108},RightKnee={48}},0),
		key(2.58,{5.1,-.65,-.20},-12,{Waist={-28,5,0},RightShoulder={40,0,20},LeftShoulder={40,0,-20},LeftHip={-25},RightHip={-15},LeftKnee={50},RightKnee={30},LeftAnkle={-20},RightAnkle={-10}},0),
		key(2.95,{4.8,-.23,0},0,{},0,{4.8,0,0},{4.8,0,0}),key(3.22,{4.8,-.20,0},0,{},1,{4.8,0,0},{4.8,0,0}),key(5.10),
	},
}
local function smooth(t) t=math.clamp(t,0,1);return t*t*(3-2*t) end
local function lerp(a,b,t) return a+(b-a)*t end
local function vector(a,b,t,scale) return Vector3.new(lerp(a[1] or 0,b[1] or 0,t),lerp(a[2] or 0,b[2] or 0,t),lerp(a[3] or 0,b[3] or 0,t))*scale end
local function poseAt(p) return CFrame.Angles(math.rad(p[1] or 0),math.rad(p[2] or 0),math.rad(p[3] or 0)) end
function Saves.duration(action) local clip=clips[action];return clip and clip[#clip].t end
function Saves.sample(action,time,scale,width)
	local clip=clips[action];if not clip then return nil end
	local index=1
	while index<#clip-1 and time>clip[index+1].t do index+=1 end
	local a,b=clip[index],clip[index+1]
	local u=smooth((time-a.t)/(b.t-a.t))
	local state={root=vector(a.root,b.root,u,scale),roll=lerp(a.roll,b.roll,u),pose={},
		left=vector(a.left,b.left,u,scale)+Vector3.new(-width,0,0),right=vector(a.right,b.right,u,scale)+Vector3.new(width,0,0),
		footAngle=0,ikWeight=lerp(a.ik,b.ik,u)}
	state.grounded=state.ikWeight>=.99999
	for name,value in pairs(a.pose) do state.pose[name]=poseAt(value):Lerp(poseAt(b.pose[name]),u) end
	-- Lateral return is stepped, not a slide or teleport. Central block never travels.
	if action~="CentralSave" then
		local start=clip[#clip-1];local finish=clip[#clip].t
		if time>=start.t then
			local initial=start.root[1]*scale
			state.left=Vector3.new(-width+initial,0,0);state.right=Vector3.new(width+initial,0,0)
			local count=math.max(4,2*math.ceil(math.abs(initial)/(1.65*scale)))
			for i=1,count do
				local at=start.t+(i-1)*(finish-start.t)/count
				local side=i%2==1 and "left" or "right"
				local target=Vector3.new((side=="left" and -width or width)+initial*(1-math.ceil(i/2)/(count/2)),0,0)
				local phase=math.clamp((time-at)/((finish-start.t)/count*.95),0,1)
				state[side]=state[side]:Lerp(target,smooth(phase))+Vector3.new(0,math.sin(math.pi*phase)*.16*scale,0)
			end
			state.root=Vector3.new((state.left.X+state.right.X)/2,state.root.Y,state.root.Z)
		end
	end
	return state
end
return Saves
