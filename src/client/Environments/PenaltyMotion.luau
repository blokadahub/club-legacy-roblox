--!nonstrict
-- Authored football choreography, independent of ball/gameplay. Units scale to the rig.
-- Output foot targets are world-locked during stance; R15 retargeting is elsewhere.
local Saves=require(script.Parent.PenaltySaves)
local Motion={KickDuration=6.4,DiveDuration=4.15,SaveOrder=Saves.Order,SaveLabels=Saves.Labels}
function Motion.resolve(action) return if action=="DiveLeft" then "LowLeft" elseif action=="DiveRight" then "LowRight" else action end
function Motion.duration(action) action=Motion.resolve(action);return if action=="Kick" then Motion.KickDuration else Saves.duration(action) end
local function smooth(t) t=math.clamp(t,0,1);return t*t*(3-2*t) end
local function ramp(t,a,b) return smooth((t-a)/(b-a)) end
local function travel(t,a,b)
	local x=math.clamp(t-a,0,b-a)
	local duration=b-a;local accel=math.min(.12,duration/4)
	if x<accel then return x*x/(2*accel*(duration-accel)) end
	if x>duration-accel then return 1-(duration-x)^2/(2*accel*(duration-accel)) end
	return (x-accel/2)/(duration-accel)
end
local function v(x,y,z) return Vector3.new(x or 0,y or 0,z or 0) end
local function angles(x,y,z) return CFrame.Angles(math.rad(x or 0),math.rad(y or 0),math.rad(z or 0)) end
local function stepFoot(t,start,finish,a,b,lift)
	local u=math.clamp((t-a)/(b-a),0,1)
	return start:Lerp(finish,smooth(u))+v(0,math.sin(math.pi*u)*lift,0)
end
function Motion.sample(role,time,action,actionTime,scale,width,distance)
	local breath=math.sin(time*1.65)
	local weight=math.sin(time*0.73)
	local state={root=v(weight*0.035*scale,-(role=="keeper" and .20 or .07)*scale,0),roll=0,
		left=v(-width,0,0),right=v(width,0,0),footAngle=0,grounded=true,blend=0,
		pose={Waist=angles(role=="keeper" and -10 or -3,weight*1.5,breath*.4),Neck=angles(3,weight*-1.5,0),
			LeftShoulder=angles(role=="keeper" and 15-breath or -8-breath,0,-(role=="keeper" and 24 or 7)),
			RightShoulder=angles(role=="keeper" and 15+breath or -8+breath,0,role=="keeper" and 24 or 7),
			LeftElbow=angles(role=="keeper" and 65 or -12),RightElbow=angles(role=="keeper" and 65 or -12)}}
	if not action then return state end
	local idle=table.clone(state);idle.pose=table.clone(state.pose)
	local t=actionTime
	action=Motion.resolve(action)
	local p=state.pose
	if action=="Kick" and role=="striker" then
		local runStart,runEnd=.55,1.65
		local run=travel(t,runStart,runEnd)
		state.root=v(0,(-.07-.38*math.sin(math.pi*run)^2)*scale,0)
		-- Six alternating footfalls, held in world-space while the pelvis advances.
		local stepCount=math.max(6,2*math.ceil(distance/(3.3*scale)))
		local stride=distance/stepCount
		state.left=v(-width,0,0);state.right=v(width,0,0)
		for i=1,stepCount do
			local a=runStart+(i-1)*(runEnd-runStart)/stepCount
			local b=a+(runEnd-runStart)/stepCount
			local side=i%2==1 and "right" or "left"
			local origin=state[side]
			local target=v((side=="left" and -width or width)-width*i/stepCount,0,-stride*i-(i==stepCount and .25*scale or 0))
			state[side]=stepFoot(t,origin,target,a,b,.28*scale)
		end
		-- Plant left foot, backswing right, strike and follow through. Ball is untouched.
		local swing=ramp(t,1.70,1.92)
		local follow=ramp(t,1.92,2.22)
		local settle=ramp(t,2.22,2.90)
		do
			local runningFoot=state.right
			local foot=v(0,.18*scale,-distance+1.0*scale)
			foot=foot:Lerp(v(0,.22*scale,-distance-1.05*scale),swing)
			foot=foot:Lerp(v(0,.85*scale,-distance-1.50*scale),follow)
			state.right=runningFoot:Lerp(foot:Lerp(v(0,0,-distance),settle),ramp(t,runEnd-(runEnd-runStart)/stepCount,1.72))
		end
		state.footAngle=(-24*ramp(t,1.45,1.70)*(1-swing)+30*follow)*(1-settle)
		local runArms=ramp(t,.2,.50)*(1-ramp(t,1.60,1.82))
		local cadence=math.sin((t-runStart)*math.pi*stepCount/(runEnd-runStart))
		local armSwing=cadence*14*runArms
		local balance=swing*(1-settle)
		p.Waist=angles(-5-10*runArms-12*swing*(1-settle),-12*swing*(1-settle),-3*swing*(1-settle))
		p.Neck=angles(5,5*swing*(1-settle),0)
		p.LeftShoulder=angles(8+armSwing+10*balance,-3*balance,-6-28*balance)
		p.RightShoulder=angles(8-armSwing-8*balance,10*balance,6+12*balance)
		p.LeftElbow=angles(32+runArms*(53-6*cadence)+20*balance)
		p.RightElbow=angles(32+runArms*(53+6*cadence)+26*balance)
		p.LeftWrist=angles(-3,-2,-3-2*balance)
		p.RightWrist=angles(-3,2,3+2*balance)
		-- Walk backwards to the exact original marks, with planted alternating feet.
		if t>=3.2 then
			state.left=v(-2*width,0,-distance-.25*scale);state.right=v(0,0,-distance)
			local count=math.max(10,stepCount)
			for i=1,count do
				local a=3.2+(i-1)*3/count
				local side=i%2==1 and "left" or "right"
				local origin=state[side]
				local progress=math.min(1,math.ceil(i/2)/(count/2))
				state[side]=stepFoot(t,origin,v((side=="left" and -width or width)-width*(1-progress),0,-distance*(1-progress)),a,a+3/count*.9,.18*scale)
			end
		end

		local support=ramp(t,1.65,1.85)*(1-ramp(t,2.4,2.90))
		local center=((state.left+state.right)/2):Lerp(state.left,support*.60)
		state.root=v(center.X,state.root.Y,center.Z)
		state.blend=ramp(t,0,.25)*(1-ramp(t,6.15,6.4))
	elseif role=="keeper" and Saves.duration(action) then
		state=Saves.sample(action,t,scale,width)
		state.blend=ramp(t,0,.18)*(1-ramp(t,Saves.duration(action)-.20,Saves.duration(action)))
	end
	local blend=state.blend
	state.root=idle.root:Lerp(state.root,blend)
	state.left=idle.left:Lerp(state.left,blend)
	state.right=idle.right:Lerp(state.right,blend)
	state.roll*=blend;state.footAngle*=blend
	for name,cf in pairs(state.pose) do state.pose[name]=(idle.pose[name] or CFrame.identity):Lerp(cf,blend) end
	return state
end
return Motion
