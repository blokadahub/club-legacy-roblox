-- Real timeline, visuals, sound gate, App and Controller; deterministic time.
-- APIs are doubles. This cannot certify Roblox rendering or audio permissions.
local Timeline=require(moduleNodes["src/client/Intro/IntroTimeline.luau"])
local Visuals=require(moduleNodes["src/client/Intro/IntroVisuals.luau"])
local Controller=require(moduleNodes["src/client/Intro/IntroController.luau"])
local Soundtrack=require(moduleNodes["src/client/Soundtrack.luau"])
local App=require(moduleNodes["src/client/App.luau"])
local UI=require(moduleNodes["src/client/UI.luau"])
local count=0
local function check(value,message) assert(value,message);count+=1 end
local function near(a,b) return math.abs(a-b)<.0001 end
-- Timing remains identical at 60, 30, 15 and 5 Hz; each event fires once.
for _,hz in ipairs({60,30,15,5}) do
	local received={}
	local timeline=Timeline.new(0,function(key,index) table.insert(received,{key,index}) end)
	for frame=0,math.ceil(17.8*hz) do timeline:Step(frame/hz,true) end
	check(#received==2 and received[1][2]==1 and received[2][2]==2,"Early sound order")
	check(timeline:RequestStart(17.8),"START rejected")
	check(not timeline:RequestStart(17.81),"Duplicate START")
	timeline:Step(18.299,true)
	check(#received==3,"Third effect too early")
	timeline:Step(18.3,true)
	check(received[4][1]=="departure" and received[4][2]==3,"Third effect at 18.3")
	timeline:Step(20.7,true)
	check(received[5][1]=="reveal","Reveal must start at 20.7")
	timeline:Step(23.799,true)
	check(timeline.alive,"Completed before 23.8")
	timeline:Step(23.8,true)
	timeline:Step(100,true)
	check(#received==6 and received[6][1]=="complete","Completion delivery")
end
local eventsLog={}
local delayed=Timeline.new(10,function(key) table.insert(eventsLog,key) end)
delayed:Step(100,false)
check(delayed.elapsed==16.6 and delayed.held and #eventsLog==1,"Loading must hold welcome")
check(not delayed:RequestStart(100),"Unavailable lobby accepted")
delayed:Step(101,true)
check(delayed.elapsed==16.6 and eventsLog[2]=="welcome","Resume from held time")
delayed:Step(102.21,true)
check(delayed:RequestStart(150),"Late START rejected")
delayed:Step(155.99,true)
check(delayed.alive,"Late START shortened departure")
delayed:Step(156,true)
check(not delayed.alive and eventsLog[#eventsLog]=="complete","Late START duration")
local cancelled=Timeline.new(0,function() error("Cancelled timeline dispatched") end)
cancelled:Destroy();cancelled:Step(100,true)
check(not cancelled:RequestStart(100),"Cancellation allowed START")

-- Silent creation; one release, including late-loaded music.
local musicGui=Instance.new("ScreenGui");musicGui.Parent=playerGui
local before=#audioLog
services.unloadedSounds=true
local music=Soundtrack.create(musicGui)
local musicSound=services.SoundService:FindFirstChild("CL27SoundtrackLocal")
check(#audioLog==before and not musicSound.IsPlaying,"Construction played music")
music.release();music.release()
check(#audioLog==before+1 and musicSound.Volume==0,"Release or pending fade duplicated")
musicSound.IsLoaded=true;musicSound.Loaded:Fire()
advance(.55)
check(near(musicSound.Volume,.4),"Late-loaded music lost volume fade")
music.destroy();musicGui:Destroy();services.unloadedSounds=false

-- Full production Controller drives existing App: no live HUD/input/music early.
local actualApp
local intro=Controller.start(function(fx)
	check(playerGui:FindFirstChild("CL27_Intro")~=nil,"App ran before shield mounted")
	actualApp=App.start({deferIntro=true,transitionFx=fx})
	return actualApp
end)
advance(0)
local overlay=playerGui.CL27_Intro
local loader=overlay:FindFirstChild("HostDoIndicadorUnico",true)
local transition=playerGui.CL27_TransitionHUD
check(services.defaultLoadingRemoved and overlay.DisplayOrder>transition.DisplayOrder,"Initial overlay ordering")
check(not playerGui.CL27.Enabled and not playerGui.CL27_HomeHUD.Enabled,"HUD leaked before reveal")
check(actualApp.state.menuInputLocked and UI.inputLocked,"Early inputs enabled")
local scene=services.lastScene
check(#scene.shows==1 and scene.shows[1]=="Interior","Lobby must prepare once")
actualApp.go("Clubs")
check(actualApp.state.screen=="HomeInterior","External navigation bypassed opening")
local origin=now
local logBefore=#audioLog
local function tick(t)
	advance(origin+t-now)
	services.RunService.Heartbeat:Fire(1/30)
end
tick(2.2)
check(not transition.Transicao.Visible,"Opening used dark Cover")
check(transition:FindFirstChild("IndicadorCL",true)==nil
	and loader:FindFirstChild("IndicadorCL",true)~=nil,"Loader duplicated or not reparented")
tick(6.3)
check(audioLog[#audioLog].name=="CL27IntroEffect1"
	and audioLog[#audioLog].id=="rbxassetid://98087823124682","First SFX")
tick(9.3)
local textFound=false
for _,object in ipairs(overlay:GetDescendants()) do
	if object:IsA("TextLabel") and string.find(object.Text,"OpeningRealPlayer",1,true) then textFound=true end
end
check(textFound,"Real player name not used")
tick(16.6)
check(audioLog[#audioLog].name=="CL27IntroEffect2"
	and audioLog[#audioLog].id=="rbxassetid://101494550141867","Welcome SFX")
tick(17.8)
check(overlay:FindFirstChild("START",true).Selectable,"START gamepad unavailable")
tick(40)
check(overlay.Parent==playerGui and actualApp.state.menuInputLocked,"Welcome auto advanced")
check(#audioLog==logBefore+2,"Music or extra SFX during wait")
overlay:FindFirstChild("START",true).Activated:Fire()
overlay:FindFirstChild("START",true).Activated:Fire()
tick(40.5)
check(audioLog[#audioLog].name=="CL27IntroEffect3"
	and audioLog[#audioLog].id=="rbxassetid://135910449013772","Departure SFX")
tick(42)
check(not playerGui.CL27_HomeHUD.Enabled,"HUD before black interval finished")
tick(44.7)
check(playerGui.CL27_HomeHUD.Enabled and actualApp.state.menuInputLocked,"Reveal HUD/lock")
check(#audioLog==logBefore+3,"Music before completed reveal")
tick(46)
check(playerGui:FindFirstChild("CL27_Intro")==nil,"Opening overlay leaked")
check(not actualApp.state.menuInputLocked and not UI.inputLocked,"Inputs not released")
check(#audioLog==logBefore+4 and audioLog[#audioLog].name=="CL27SoundtrackLocal","Music not released exactly once")
check(#scene.shows==1,"Lobby rebuilt during reveal")
check(transition:FindFirstChild("IndicadorCL",true)~=nil,"Loader not returned")
for i=1,3 do check(services.SoundService:FindFirstChild("CL27IntroEffect"..i)==nil,"Effect resource leaked") end
actualApp.go("Clubs");advance(2.5)
check(actualApp.state.screen=="Clubs" and not actualApp.state.menuInputLocked,"Navigation broken after opening")
actualApp.destroy()
intro:Destroy()

-- Frame sampling across all phases, mobile layouts and reduced motion.
for _,size in ipairs({Vector2.new(1920,1080),Vector2.new(854,393),Vector2.new(1024,768),Vector2.new(2560,1080),Vector2.new(393,854)}) do
	local visuals=Visuals.new(playerGui)
	visuals:Resize(size)
	local facets=visuals.gui:FindFirstChild("FacetasGeometricas",true)
	-- Background's cover scale is the first UIScale; inspect the button's
	-- own fitted canvas instead to verify its physical touch dimensions.
	local fitted=visuals.start.Parent.Parent:FindFirstChildOfClass("UIScale").Scale
	check(visuals.start.Size.Y.Offset*fitted>=48-.001
		and visuals.start.Size.X.Offset*fitted>=112-.001,"Mobile START touch area")
	local parts=0
	for _,part in ipairs(facets:GetChildren()) do
		if part.ClassName=="WedgePart" then
			parts+=1
			check(part.Size.Y>0 and part.Size.Z>0,"Degenerate facet")
		end
	end
	check(parts==14 and facets.CurrentCamera~=workspace.CurrentCamera,"Background cost/camera ownership")
	for _,reduced in ipairs({false,true}) do
		for _,t in ipairs({0,1.93,2.15,5.8,6.14,6.3,6.6,7.4,8.9,13.9,15.25,16.6,17.8}) do
			visuals:Draw({elapsed=t,ready=true,canStart=t>=17.8},"RealName",reduced,nil)
			check(visuals.shield.BackgroundTransparency==0,"Early background lost opacity")
			check(visuals.cut.BackgroundTransparency==(if t==1.93 then 0 else 1),"Accidental loading veil")
			check(visuals.logo.scale.Scale>0,"Invalid logo scale")
			if reduced then check(visuals.logo.disc.Rotation==0,"Reduced motion rotated logo") end
		end
		visuals:Draw({elapsed=18,ready=true,exit=3,canStart=false},"RealName",reduced,nil)
		check(visuals.shield.BackgroundTransparency>0 and visuals.shield.BackgroundTransparency<1,"Missing gradual reveal")
	end
	visuals:Destroy()
end

-- Cancellation disconnects Heartbeat and stops effects, with no music unlock.
local cancelledIntro=Controller.start(function(fx) return App.start({deferIntro=true,transitionFx=fx}) end)
advance(0)
local plays=#audioLog
cancelledIntro:Destroy()
advance(50);services.RunService.Heartbeat:Fire(50)
check(#audioLog==plays and playerGui:FindFirstChild("CL27_Intro")==nil,"Cancelled intro leaked")

-- Missing audio remains nonblocking.
services.unloadedSounds=true
local unavailable=Controller.start(function(fx) return App.start({deferIntro=true,transitionFx=fx}) end)
advance(0)
advance(18);services.RunService.Heartbeat:Fire(18)
check(playerGui.CL27_Intro:FindFirstChild("START",true).Selectable,"Audio failure blocked START")
unavailable:Destroy()
services.unloadedSounds=false
print(string.format("PASS Intro: %d assertions; complete timeline/integration with API doubles, no Roblox render/audio certification.",count))
