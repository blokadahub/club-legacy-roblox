--!nonstrict
-- Pure layout in studs. R15 presentation height ~5.6; 3 studs = 1 metre.
-- Goal line z=0, field +Z. No shot, goalkeeper AI or physics in stage 1.
local Layout = {}
Layout.Scale = 3
Layout.Goal = {width=21.96, height=7.32, depth=5.4, post=0.36}
Layout.Pitch = {width=204, length=315, penalty=33, areaDepth=49.5, areaWidth=120.96, sixDepth=16.5, sixWidth=54.96}
Layout.BallDiameter = 0.78
Layout.Ball = {0, 0.39, 33}
Layout.Striker = {-5.3, 0, 42.5}
Layout.Keeper = {0, 0, 0.25}
Layout.Camera = {position={0,13.2,94}, target={0,2.1,17}, fov=16.6}
Layout.Environment = {
	Ambient={130,139,147}, OutdoorAmbient={151,159,166}, Brightness=2,
	ClockTime=13.5, ExposureCompensation=0.04,
	EnvironmentDiffuseScale=0.65, EnvironmentSpecularScale=0.16,
}
local palette = {
	grass={65,112,49}, stripe={69,119,52}, white={238,241,233},
	blue={49,83,131}, blueLight={58,94,146}, blueDark={39,67,108},
	concrete={126,132,136}, dark={27,34,41}, metal={174,183,190}, net={191,207,212},
}

function Layout.build(quality)
	local parts = {}
	local function box(name,size,position,color,material,collide,rotation)
		local d={name=name,size=size,position=position,color=palette[color] or color,
			material=material or "SmoothPlastic",collide=collide==true,rotation=rotation or {0,0,0}}
		table.insert(parts,d)
		return d
	end
	local function rod(name,a,b,width,color)
		local dx,dy,dz=b[1]-a[1],b[2]-a[2],b[3]-a[3]
		local length=math.sqrt(dx*dx+dy*dy+dz*dz)
		local d=box(name,{width,width,length},{(a[1]+b[1])/2,(a[2]+b[2])/2,(a[3]+b[3])/2},color)
		d.target=b
		return d
	end
	local function line(name,x,z,w,l)
		return box(name,{w,0.025,l},{x,0.018,z},"white")
	end
	-- A single continuous collider; thin mowing colours and markings never collide.
	box("PitchGround",{222,0.7,333},{0,-0.35,157.5},"grass","Grass",true)
	for stripe=0,20 do
		box("MowingStripe_"..stripe,{204,0.015,15},{0,0.004,stripe*15+7.5},stripe%2==0 and "grass" or "stripe","Grass")
	end
	local p=Layout.Pitch
	line("GoalLine",0,0,p.width,0.30)
	line("FarGoalLine",0,p.length,p.width,0.30)
	line("TouchlineLeft",-102,p.length/2,0.30,p.length)
	line("TouchlineRight",102,p.length/2,0.30,p.length)
	line("HalfwayLine",0,p.length/2,p.width,0.30)
	local function area(prefix,width,depth,base,direction)
		line(prefix.."Front",0,base+depth*direction,width,0.30)
		for _,side in ipairs({-1,1}) do line(prefix.."Side_"..side,side*width/2,base+depth/2*direction,0.30,depth) end
	end
	area("PenaltyArea",p.areaWidth,p.areaDepth,0,1)
	area("GoalArea",p.sixWidth,p.sixDepth,0,1)
	area("FarPenaltyArea",p.areaWidth,p.areaDepth,p.length,-1)
	area("FarGoalArea",p.sixWidth,p.sixDepth,p.length,-1)
	local mark=box("PenaltyMark",{0.026,0.6,0.6},{0,0.027,p.penalty},"white")
	mark.cylinder=true;mark.rotation={0,0,math.pi/2}
	local function arc(name,cx,cz,r,a0,a1,segments)
		for i=1,segments do
			local a=a0+(a1-a0)*(i-1)/segments
			local b=a0+(a1-a0)*i/segments
			rod(name..i,{cx+math.cos(a)*r,0.03,cz+math.sin(a)*r},{cx+math.cos(b)*r,0.03,cz+math.sin(b)*r},0.25,"white")
		end
	end
	local r=27.45
	local start=math.asin((p.areaDepth-p.penalty)/r)
	arc("PenaltyArc_",0,p.penalty,r,start,math.pi-start,28)
	arc("CenterCircle_",0,p.length/2,r,0,math.pi*2,64)
	arc("FarPenaltyArc_",0,p.length-p.penalty,r,math.pi+start,math.pi*2-start,28)
	for _,x in ipairs({-102,102}) do
		arc("CornerNear_"..x.."_",x,0,3,x<0 and 0 or math.pi/2,x<0 and math.pi/2 or math.pi,8)
		arc("CornerFar_"..x.."_",x,p.length,3,x<0 and -math.pi/2 or math.pi,x<0 and 0 or math.pi*1.5,8)
	end
	local g=Layout.Goal
	-- Inner opening is 21.96 x 7.32; cylindrical posts sit outside that opening.
	for _,side in ipairs({-1,1}) do
		local x=side*(g.width+g.post)/2
		local post=rod("GoalPost_"..side,{x,0,0},{x,g.height+g.post/2,0},g.post,"white")
		post.round=true
		rod("RearUpright_"..side,{x,0,-g.depth},{x,g.height-0.6,-g.depth},0.13,"white")
		rod("RoofSupport_"..side,{x,g.height+g.post/2,0},{x,g.height-0.6,-g.depth},0.13,"white")
		rod("GroundSupport_"..side,{x,0.07,0},{x,0.07,-g.depth},0.13,"white")
	end
	local cross=rod("GoalCrossbar",{-(g.width+g.post)/2,g.height+g.post/2,0},{(g.width+g.post)/2,g.height+g.post/2,0},g.post,"white")
	cross.round=true
	rod("RearCrossbar",{-g.width/2,g.height-0.6,-g.depth},{g.width/2,g.height-0.6,-g.depth},0.12,"white")
	-- Open grid: strands only, no opaque sheet in front of the goalkeeper.
	local grid=quality=="Baixa" and 1.2 or 0.8
	for x=-g.width/2,g.width/2,grid do
		rod("NetBackVertical",{x,0,-g.depth},{x,g.height-0.6,-g.depth},0.026,"net")
		rod("NetRoof",{x,g.height-0.6,-g.depth},{x,g.height,0},0.026,"net")
	end
	for y=0,g.height-0.6,grid do
		rod("NetBackHorizontal",{-g.width/2,y,-g.depth},{g.width/2,y,-g.depth},0.026,"net")
		for _,side in ipairs({-1,1}) do
			rod("NetSideHorizontal",{side*g.width/2,y,0},{side*g.width/2,y,-g.depth},0.026,"net")
		end
	end
	for z=-g.depth,0,grid do
		local h=g.height+0.6*z/g.depth
		for _,side in ipairs({-1,1}) do rod("NetSideVertical",{side*g.width/2,0,z},{side*g.width/2,h,z},0.026,"net") end
	end
	-- Track, barrier, physical terraces, blue seats, aisles and rails behind the goal.
	box("RunoffTrack",{238,0.3,13},{0,-0.1,-12.5},{62,88,105},"Concrete")
	box("RearBarrier",{238,2.8,0.65},{0,1.4,-19.5},"dark","Concrete")
	for sector=-3,2 do
		local x=sector*36+18
		box("RearAdvertisingPanel",{32,2.25,0.12},{x,1.4,-19.08},sector%2==0 and {35,45,54} or {41,56,68})
	end
	for x=-117,117,6 do rod("FrontRailPost",{x,2.8,-19.3},{x,3.7,-19.3},0.075,"metal") end
	rod("FrontRailTop",{-119,3.7,-19.3},{119,3.7,-19.3},0.09,"metal")
	rod("FrontRailLower",{-119,3.1,-19.3},{119,3.1,-19.3},0.07,"metal")
	local rows=quality=="Baixa" and 16 or 20
	local clusters=quality=="Baixa" and 4 or 7
	for row=1,rows do
		local y,z=1.8+(row-1)*0.93,-22-(row-1)*2.5
		box("RearTerrace_"..row,{238,0.9,2.5},{0,y-0.45,z},"concrete","Concrete")
		for sector=-3,2 do
			local center=sector*38+19
			box("BlueSeatBase",{32,0.18,0.95},{center,y+0.45,z-0.35},"blueDark")
			for seat=1,clusters do
				local width=32/clusters
				local x=center-16+width*(seat-0.5)
				box("BlueSeatBack",{width-0.16,0.92,0.19},{x,y+1.05,z-0.85},(seat+row)%3==0 and "blueLight" or "blue",nil,false,{-0.11,0,0})
			end
		end
	end
	-- Stair wells break the seating into sectors. Thin rails follow the actual rake.
	for aisle=-3,3 do
		local x=aisle*38
		for row=1,rows do
			local y,z=1.8+(row-1)*0.93,-22-(row-1)*2.5
			box("AisleHalfStep",{4.5,0.46,1.25},{x,y+0.23,z+0.63},"concrete","Concrete")
		end
		for row=1,rows,5 do
			local y,z=1.8+(row-1)*0.93,-22-(row-1)*2.5
			rod("AisleRailPost",{x,y,z},{x,y+2.5,z},0.08,"metal")
		end
		rod("AisleHandrail",{x,4.3,-22},{x,4.3+(rows-1)*0.93,-22-(rows-1)*2.5},0.09,"metal")
	end
	local top=1.8+(rows-1)*0.93
	box("RearConcourse",{244,0.5,8},{0,top,-25-rows*2.5},"concrete","Concrete")
	box("RearFascia",{244,3.5,0.6},{0,top+1.75,-29-rows*2.5},"blueDark")
	-- Side stands continue the bowl; lower detail outside the principal camera.
	for _,side in ipairs({-1,1}) do
		box("SideBarrier",{0.6,2.8,324},{side*118,1.4,151},"dark","Concrete")
		for row=1,10 do
			local x=side*(122+row*2.6)
			box("SideTerrace",{2.6,0.85,324},{x,row*0.93,151},"concrete","Concrete")
			for section=0,7 do
				box("SideBlueSeats",{0.28,0.85,36},{x+side*0.6,row*0.93+0.65,section*40+10},row%2==0 and "blueLight" or "blue")
			end
		end
	end
	return parts
end
return Layout
