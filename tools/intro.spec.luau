-- Real timeline, visuals, sound gate, App and Controller; deterministic time.
-- APIs are doubles. This cannot certify Roblox rendering or audio permissions.
local Timeline=require(moduleNodes["src/client/Intro/IntroTimeline.luau"])
local Visuals=require(moduleNodes["src/client/Intro/IntroVisuals.luau"])
local Controller=require(moduleNodes["src/client/Intro/IntroController.luau"])
local Audio=require(moduleNodes["src/client/Intro/IntroAudio.luau"])
local Soundtrack=require(moduleNodes["src/client/Soundtrack.luau"])
local App=require(moduleNodes["src/client/App.luau"])
local UI=require(moduleNodes["src/client/UI.luau"])
local count=0
local function check(value,message) assert(value,message);count+=1 end
local function near(a,b) return math.abs(a-b)<.0001 end
-- Regression: a normal late load must satisfy a pending cue, not discard it.
do
	services.unloadedSounds=true
	local audio=Audio.new()
	advance(0)
	local lateSound=services.SoundService:FindFirstChild("CL27IntroEffect1")
	local beforeLate=#audioLog
	audio:Play(1,now)
	check(#audioLog==beforeLate,"Unloaded effect played before readiness")
	advance(.2)
	lateSound.IsLoaded=true
	lateSound.Loaded:Fire()
	check(#audioLog==beforeLate+1 and audioLog[#audioLog].name=="CL27IntroEffect1",
		"Normal late load permanently lost its scheduled effect")
	audio:Destroy()
	services.unloadedSounds=false
end
-- Transient fetch failures retry once; duplicate completion notifications
-- cannot replay a cue, and the retry is not an unbounded background loop.
do
	services.unloadedSounds=true
	local attempts={}
	services.preloadIntro=function(items,callback)
		local sound=items[1]
		attempts[sound.Name]=(attempts[sound.Name] or 0)+1
		if attempts[sound.Name]==1 then callback(sound.SoundId,Enum.AssetFetchStatus.Failure)
		else
			sound.IsLoaded=true
			sound.Loaded:Fire()
			callback(sound.SoundId,Enum.AssetFetchStatus.Success)
		end
	end
	local audio=Audio.new()
	local plays=#audioLog
	audio:Play(1,now)
	advance(.36)
	check(#audioLog==plays+1,"Retry did not recover the pending sound")
	local recovered=services.SoundService:FindFirstChild("CL27IntroEffect1")
	recovered.Loaded:Fire();audio:Play(1,now);audio:Step(now)
	check(#audioLog==plays+1,"Loaded/preload/repeated request replayed sound")
	advance(7)
	for i=1,3 do check(attempts["CL27IntroEffect"..i]==2,"Preload retries unbounded") end
	audio:Destroy()
	services.preloadIntro=nil
	services.unloadedSounds=false
end
-- A stuck native preload yields. Both attempts time out/cancel without
-- stalling the client; later engine Loaded can still recover a live cue.
do
	services.unloadedSounds=true
	local workers={}
	services.preloadIntro=function()
		table.insert(workers,coroutine.running())
		coroutine.yield()
	end
	local audio=Audio.new()
	advance(7)
	check(#workers==6,"Stuck preloads did not remain bounded to two attempts per ID")
	for _,thread in ipairs(workers) do check(coroutine.status(thread)=="dead","Timed-out preload worker survived") end
	local plays=#audioLog
	audio:Play(1,now)
	advance(.1)
	local sound=services.SoundService:FindFirstChild("CL27IntroEffect1")
	sound.IsLoaded=true;sound.Loaded:Fire()
	check(#audioLog==plays+1,"Timeout permanently poisoned a later Loaded recovery")
	audio:Destroy()
	services.preloadIntro=nil
	services.unloadedSounds=false
end
-- New cues supersede older pending ones; expiry and destruction prevent
-- audio from leaking into the next phase or into the released playlist.
do
	services.unloadedSounds=true
	local audio=Audio.new()
	advance(0)
	local sound1=services.SoundService:FindFirstChild("CL27IntroEffect1")
	local sound2=services.SoundService:FindFirstChild("CL27IntroEffect2")
	local sound3=services.SoundService:FindFirstChild("CL27IntroEffect3")
	local plays=#audioLog
	audio:Play(1,now)
	audio:Play(2,now)
	sound1.IsLoaded=true;sound1.Loaded:Fire()
	check(#audioLog==plays,"Superseded effect played after newer cue")
	advance(.2)
	sound2.IsLoaded=true;sound2.Loaded:Fire()
	check(#audioLog==plays+1 and audioLog[#audioLog].name=="CL27IntroEffect2","Pending second effect lost")
	audio:Play(3,now)
	check(not sound2.IsPlaying,"Effects overlapped across cue handoff")
	advance(2.01)
	sound3.IsLoaded=true;sound3.Loaded:Fire();audio:Step(now)
	check(#audioLog==plays+1,"Expired sound started out of phase")
	audio:Play(1,now);audio:Play(3,now)
	check(#audioLog==plays+1,"Old or repeated request replayed after expiry")
	audio:Destroy()
	sound2.Loaded:Fire()
	check(#audioLog==plays+1,"Destroyed audio handled Loaded")
	services.unloadedSounds=false
end
-- Frame stalls must use the original cue timestamp, not a fresh grace
-- period based on whichever frame happened to deliver that event.
do
	local audio=Audio.new()
	local plays=#audioLog
	audio:Play(1,now-3)
	check(#audioLog==plays,"Stale frame delivered an out-of-phase cue")
	local scheduled=now+.5
	audio:Play(2,scheduled)
	audio:Step(now)
	check(#audioLog==plays,"Future cue started early")
	advance(.5);audio:Step(now)
	check(#audioLog==plays+1 and near(audioLog[#audioLog].time,scheduled),"Future cue not synchronized")
	audio:Destroy()
end
-- Polling also recovers readiness if Loaded/Preload completion was missed,
-- with useful tolerance near the end of the two-second grace window.
do
	services.unloadedSounds=true
	local audio=Audio.new()
	local plays=#audioLog
	audio:Play(1,now)
	advance(1.9)
	local sound=services.SoundService:FindFirstChild("CL27IntroEffect1")
	sound.IsLoaded=true
	audio:Step(now)
	check(#audioLog==plays+1,"Within-window readiness lost without a Loaded notification")
	audio:Step(now);sound.Loaded:Fire()
	check(#audioLog==plays+1,"Polling and Loaded duplicated a recovered cue")
	audio:Play(2,now)
	local pendingSound=services.SoundService:FindFirstChild("CL27IntroEffect2")
	audio:Destroy()
	pendingSound.IsLoaded=true;pendingSound.Loaded:Fire();advance(5)
	check(#audioLog==plays+1,"Cancelled pending cue or preload played after cleanup")
	services.unloadedSounds=false
end
-- Timing remains identical at 60, 30, 15 and 5 Hz; each event fires once.
for _,hz in ipairs({60,30,15,5}) do
	local received={}
	local timeline=Timeline.new(0,function(key,index,scheduledAt) table.insert(received,{key,index,scheduledAt}) end)
	for frame=0,math.ceil(17.8*hz) do timeline:Step(frame/hz,true) end
	check(#received==2 and received[1][2]==1 and received[2][2]==2,"Early sound order")
	check(near(received[1][3],6.3) and near(received[2][3],16.6),"Sound cue times drift with framerate")
	check(timeline:RequestStart(17.8),"START rejected")
	check(not timeline:RequestStart(17.81),"Duplicate START")
	timeline:Step(18.299,true)
	check(#received==3,"Third effect too early")
	timeline:Step(18.3,true)
	check(received[4][1]=="departure" and received[4][2]==3,"Third effect at 18.3")
	check(near(received[4][3],18.3),"Departure sound timestamp shifted")
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
do
	local emitted={}
	local timeline=Timeline.new(0,function(key,index,at) table.insert(emitted,{key,index,at}) end)
	timeline:Step(17.8,true)
	timeline:Step(18.1,false)
	local snapshot=timeline:Snapshot(18.1)
	check(snapshot.elapsed==18.1 and snapshot.welcomed and not snapshot.canStart,
		"Temporary readiness loss rewound the intro")
	check(not timeline:RequestStart(18.1),"START accepted a stale ready state")
	local visuals=Visuals.new(playerGui)
	visuals:Resize(Vector2.new(1600,900))
	visuals:Draw(snapshot,"RealName",false,nil)
	check(visuals.welcome.GroupTransparency==0 and not visuals.start.Active,
		"Readiness loss left a blank welcome or enabled START")
	visuals:Destroy()
	timeline:Step(18.2,true)
	check(timeline:RequestStart(18.2),"START did not recover after readiness returned")
	timeline:Step(24.2,true)
	check(#emitted==6 and near(emitted[4][3],18.7),"Readiness recovery duplicated/reordered events")
end
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
	check(not transition.Transicao.Visible,"Opening invoked the normal dark loading veil")
end
tick(2.2)
check(not transition.Transicao.Visible,"Opening used dark Cover")
check(transition:FindFirstChild("IndicadorCL",true)==nil
	and loader:FindFirstChild("IndicadorCL",true)~=nil,"Loader duplicated or not reparented")
local ambient=loader:FindFirstChild("CarregamentoContinuo")
check(ambient.BackgroundTransparency==1 and not ambient.Active,"Standalone loader darkened/intercepted the opening")
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
local readyCamera=workspace.CurrentCamera
workspace.CurrentCamera=nil
overlay:FindFirstChild("START",true).Activated:Fire()
workspace.CurrentCamera=readyCamera
tick(40)
check(overlay.Parent==playerGui and actualApp.state.menuInputLocked,"Welcome auto advanced or START accepted stale readiness")
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
local revealedNews=playerGui.CL27_HomeHUD:FindFirstChild("Opcao_1",true)
check(actualApp.state.homeFocus==1 and revealedNews.TextTransparency==0
	and playerGui.CL27_HomeHUD:FindFirstChild("Opcao_3",true).TextTransparency==.32,
	"Completed opening must reveal Notícias do CL as the only white selection")
check(services.GuiService.SelectedObject==revealedNews,"Opening did not hand gamepad focus to Notícias do CL")
local playsAfterReveal=#audioLog
revealedNews.SelectionGained:Fire()
check(#audioLog==playsAfterReveal,"Automatic focus after the opening played Cyber Click")
check(playerGui.CL27_HomeHUD:FindFirstChild("TituloCentral",true).Text=="NOTÍCIAS DO CL",
	"Opening revealed content from a different lobby selection")
check(#audioLog==logBefore+4 and audioLog[#audioLog].name=="CL27SoundtrackLocal","Music not released exactly once")
check(#scene.shows==1,"Lobby rebuilt during reveal")
check(transition:FindFirstChild("IndicadorCL",true)~=nil,"Loader not returned")
for i=1,3 do check(services.SoundService:FindFirstChild("CL27IntroEffect"..i)==nil,"Effect resource leaked") end
actualApp.go("Clubs");advance(2.5)
check(actualApp.state.screen=="Clubs" and not actualApp.state.menuInputLocked,"Navigation broken after opening")
actualApp.destroy()
intro:Destroy()

-- Production path with all three effects loading 200 ms after their cues.
-- Audio recovery must not extend the 23.8 s sequence or the 6 s exit.
do
	services.unloadedSounds=true
	services.preloadIntro=function() coroutine.yield() end
	local base=now
	local plays=#audioLog
	local delayedApp
	local delayedIntro=Controller.start(function(fx)
		delayedApp=App.start({deferIntro=true,transitionFx=fx})
		return delayedApp
	end)
	advance(0)
	local function sample(t)
		advance(base+t-now)
		services.RunService.Heartbeat:Fire(1/30)
		check(not delayedApp.transitionFx.layer.Visible,"Delayed audio introduced a normal loading veil")
	end
	local function loaded(index)
		local sound=services.SoundService:FindFirstChild("CL27IntroEffect"..index)
		sound.IsLoaded=true;sound.Loaded:Fire()
	end
	sample(6.3)
	check(#audioLog==plays,"First unloaded cue played before ready")
	sample(6.5);loaded(1)
	check(#audioLog==plays+1 and near(audioLog[#audioLog].time,base+6.5),"First late cue lost")
	sample(16.6)
	check(#audioLog==plays+1,"Second unloaded cue played before ready")
	sample(16.8);loaded(2)
	check(#audioLog==plays+2 and near(audioLog[#audioLog].time,base+16.8),"Second late cue lost")
	sample(17.8)
	playerGui.CL27_Intro:FindFirstChild("START",true).Activated:Fire()
	sample(18.3)
	check(#audioLog==plays+2,"Third unloaded cue played before ready")
	sample(18.5);loaded(3)
	check(#audioLog==plays+3 and near(audioLog[#audioLog].time,base+18.5),"Third late cue lost")
	sample(23.7)
	local music=services.SoundService:FindFirstChild("CL27SoundtrackLocal")
	music.IsLoaded=true;music.Loaded:Fire()
	check(#audioLog==plays+3 and music.Volume==0,"Loaded event unlocked music before reveal")
	sample(23.799)
	check(delayedApp.state.introLocked and #audioLog==plays+3,"Early completion after audio recovery")
	sample(23.8)
	check(playerGui:FindFirstChild("CL27_Intro")==nil and not delayedApp.state.introLocked,
		"Audio recovery extended cinematic duration")
	check(#audioLog==plays+4 and audioLog[#audioLog].name=="CL27SoundtrackLocal"
		and near(audioLog[#audioLog].time,base+23.8),"Music release timestamp changed")
	delayedApp:CompleteIntro()
	check(#audioLog==plays+4,"Repeated completion restarted music")
	delayedApp.destroy();delayedIntro:Destroy()
	services.preloadIntro=nil
	services.unloadedSounds=false
end

-- START ends the welcome phase, including its still-pending sound.
do
	services.unloadedSounds=true
	local base=now
	local plays=#audioLog
	local opening=Controller.start(function(fx)
		return App.start({deferIntro=true,transitionFx=fx})
	end)
	advance(0)
	advance(16.6);services.RunService.Heartbeat:Fire(1/30)
	advance(1.2);services.RunService.Heartbeat:Fire(1/30)
	playerGui.CL27_Intro:FindFirstChild("START",true).Activated:Fire()
	advance(.1)
	local welcomeSound=services.SoundService:FindFirstChild("CL27IntroEffect2")
	welcomeSound.IsLoaded=true;welcomeSound.Loaded:Fire()
	check(#audioLog==plays,"Late welcome sound started after START")
	advance(.4)
	local exitSound=services.SoundService:FindFirstChild("CL27IntroEffect3")
	exitSound.IsLoaded=true
	services.RunService.Heartbeat:Fire(1/30)
	check(#audioLog==plays+1 and audioLog[#audioLog].name=="CL27IntroEffect3"
		and near(audioLog[#audioLog].time,base+18.3),"Cancelling welcome disrupted departure sound")
	opening:Destroy()
	check(not services.SoundService:FindFirstChild("CL27SoundtrackLocal"),"Cancelled opening released music")
	services.unloadedSounds=false
end

-- Geometry bounds catch strokes clipped by the CanvasGroup even without rendering.
do
	local visuals=Visuals.new(playerGui)
	visuals:Resize(Vector2.new(1600,900))
	visuals:Draw({elapsed=6.2,ready=true,canStart=false},"RealName",false,nil)
	local circleCenter=visuals.logo.root.Position.X.Offset+visuals.logo.scale.Scale
		*(visuals.logo.disc.Position.X.Offset+105-400)
	check(near(circleCenter,800),"Solo CL Sports circle must return centered before title expansion")
	visuals:Draw({elapsed=6.6,ready=true,canStart=false},"RealName",false,nil)
	check(visuals.logo.disc.Position.X.Offset==0,"Expanded composition failed to align circle/title")
	local word=visuals.logo.word
	for _,stroke in ipairs(word:GetChildren()) do
		if stroke:IsA("Frame") then
			local angle=math.rad(stroke.Rotation)
			local halfX=(math.abs(math.cos(angle))*stroke.Size.X.Offset
				+math.abs(math.sin(angle))*stroke.Size.Y.Offset)/2
			local halfY=(math.abs(math.sin(angle))*stroke.Size.X.Offset
				+math.abs(math.cos(angle))*stroke.Size.Y.Offset)/2
			check(stroke.Position.X.Offset-halfX>=0 and stroke.Position.X.Offset+halfX<=word.Size.X.Offset
				and stroke.Position.Y.Offset-halfY>=0 and stroke.Position.Y.Offset+halfY<=word.Size.Y.Offset,
				"Wordmark stroke clipped by its own CanvasGroup")
		end
	end
	visuals:Draw({elapsed=22.25,ready=true,exit=4.45,canStart=false},"RealName",false,nil)
	check(near(visuals.shield.BackgroundTransparency*visuals.cut.BackgroundTransparency,.5),
		"Two black overlays darken the same final reveal")
	visuals:Destroy()
end

-- Frame sampling across all phases, mobile layouts and reduced motion.
for _,size in ipairs({Vector2.new(1536,863),Vector2.new(1920,1080),Vector2.new(854,393),Vector2.new(1024,768),Vector2.new(2560,1080),Vector2.new(393,854)}) do
	local visuals=Visuals.new(playerGui)
	visuals:Resize(size)
	local facets=visuals.gui:FindFirstChild("FacetasGeometricas",true)
	-- Background's cover scale is the first UIScale; inspect the button's
	-- own fitted canvas instead to verify its physical touch dimensions.
	local fitted=visuals.start.Parent.Parent:FindFirstChildOfClass("UIScale").Scale
	check(visuals.start.Size.Y.Offset*fitted>=48-.001
		and visuals.start.Size.X.Offset*fitted>=112-.001,"Mobile START touch area")
	local caption=visuals.start:FindFirstChild("TextoAcao",true)
	local disc=visuals.start:FindFirstChild("IconeControle",true)
	local sweep=visuals.start:FindFirstChild("OuterGlowSweepCapsula",true)
	local surface=visuals.start:FindFirstChild("SuperficieCapsula")
	check(disc and disc:FindFirstChild("TeclaX").Text=="X"
		and caption and caption.Text=="Start" and sweep,"START must use the lobby X capsule")
	check(caption.TextSize*fitted>=14-.001 and disc.Size.Y.Offset*fitted>=22-.001,
		"Mobile START caption/X became too small")
	check(visuals.start.BackgroundTransparency==1 and surface.Size.Y.Offset<=visuals.start.Size.Y.Offset
		and surface.Size.X.Offset<=visuals.start.Size.X.Offset,"Touch area must surround the independent visual surface")
	check(surface.Size.X.Offset/surface.Size.Y.Offset>=2.7
		and (fitted>=.65 or surface.Size.Y.Offset*fitted<=34),"Mobile touch minimum made START visibly thick again")
	local green=surface.BackgroundColor3
	check(near(green.R,92/255) and near(green.G,1) and near(green.B,51/255),"START must use exactly #5cff33")
	check(caption.Position.X.Offset>=disc.Position.X.Offset+disc.Size.X.Offset
		and caption.Size.X.Offset+surface.Size.X.Offset>0,
		"START caption overlaps its X disc or has no horizontal room")
	visuals:Draw({elapsed=17.8,ready=true,canStart=true},"RealName",false,nil)
	check(visuals.welcome.WelcomeTitulo.TextSize<=visuals.welcome.WelcomeTitulo.Size.Y.Offset
		and visuals.welcome.WelcomeSubtitulo.TextSize<=visuals.welcome.WelcomeSubtitulo.Size.Y.Offset,
		"Title text is taller than its native label and risks vertical clipping")
	check(visuals.logo.root.GroupTransparency==0 and near(visuals.logo.scale.Scale,.25)
		and visuals.logo.root.Position.Y.Offset==207,"Welcome must retain the small white brand above its title")
	if size.X==1536 then
		local canvas=visuals.welcome.Parent
		local function screenY(y) return canvas.Position.Y.Offset+(y-450)*fitted end
		local top=visuals.welcome.WelcomeTitulo
		local bottom=visuals.welcome.WelcomeSubtitulo
		-- Centers measured from the attached 1536x863 screenshot, independent
		-- of the native font's glyph metrics: brand 198, title 339/435, CTA 583.
		check(math.abs(screenY(visuals.logo.root.Position.Y.Offset)-198)<=3,"Brand position differs from reference")
		check(math.abs(screenY(visuals.welcome.Position.Y.Offset+top.Position.Y.Offset+top.Size.Y.Offset/2)-339)<=3
			and math.abs(screenY(visuals.welcome.Position.Y.Offset+bottom.Position.Y.Offset+bottom.Size.Y.Offset/2)-435)<=3,
			"Welcome title line centers differ from reference")
		check(math.abs(screenY(visuals.welcome.Position.Y.Offset+visuals.start.Position.Y.Offset)-583)<=3,"Start position differs from reference")
	end
	local lit=0
	local mask={}
	local minX,minY,maxX,maxY=math.huge,math.huge,-math.huge,-math.huge
	for i,sample in ipairs(sweep:GetChildren()) do
		local x,y=sample.Position.X.Offset*fitted,sample.Position.Y.Offset*fitted
		local w,h=surface.Size.X.Offset*fitted,surface.Size.Y.Offset*fitted
		check(x>=-1 and x<=w+1 and y>=-1 and y<=h+1,"START sweep left the outer capsule perimeter under UIScale")
		minX=math.min(minX,x);maxX=math.max(maxX,x);minY=math.min(minY,y);maxY=math.max(maxY,y)
		check(near(sample.LinhaBranca.Size.Y.Offset,2.25)
			and near(sample.GlowMedio.Size.Y.Offset,8.4)
			and near(sample.HaloExternoSuave.Size.Y.Offset,16),"Classic contour thickness must match the original canvas values")
		mask[i]=sample.GroupTransparency
		if sample.GroupTransparency<.98 then lit+=1 end
	end
	check(minX>=0 and minY>=0 and maxX<surface.Size.X.Offset*fitted and maxY<surface.Size.Y.Offset*fitted,
		"Classic sweep must follow the inset perimeter inside its green surface")
	check(#mask==78 and lit>=3 and lit<=28,"START glow must illuminate a short continuous portion of its border")
	visuals:Draw({elapsed=18.2,ready=true,canStart=true},"RealName",false,nil)
	local moved=false
	for i,sample in ipairs(sweep:GetChildren()) do
		if sample.GroupTransparency~=mask[i] then moved=true end
	end
	check(moved,"START contour glow did not move")
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
			check(facets.ImageTransparency==0 and facets.BackgroundTransparency==0,"Initial facets darkened or hidden")
			check(visuals.cut.BackgroundTransparency==(if t==1.93 then 0 else 1),"Accidental loading veil")
			check(visuals.logo.scale.Scale>0,"Invalid logo scale")
			if reduced then check(visuals.logo.disc.Rotation==0,"Reduced motion rotated logo") end
		end
		visuals:Draw({elapsed=18,ready=true,exit=3,canStart=false},"RealName",reduced,nil)
		local revealAlpha=visuals.shield.BackgroundTransparency*visuals.cut.BackgroundTransparency
		check(revealAlpha>0 and revealAlpha<1,"Missing gradual reveal")
		check(not sweep.Visible,"START sweep must stop on departure / reduced motion")
	end
	visuals:Destroy()
	check(sweep.Parent==nil,"START contour survived intro destruction")
end

-- Roblox top-bar insets must not shrink/shift the reference composition again.
do
	local originalInset=services.GuiService.GetGuiInset
	services.GuiService.GetGuiInset=function() return Vector2.new(0,58),Vector2.new() end
	local visuals=Visuals.new(playerGui)
	visuals:Resize(Vector2.new(854,393))
	visuals:Draw({elapsed=18,ready=true,canStart=true},"RealName",false,nil)
	local canvas=visuals.welcome.Parent
	local fitted=canvas:FindFirstChildOfClass("UIScale").Scale
	check(near(fitted,393/900) and near(canvas.Position.Y.Offset,393/2),"Top bar shrank or shifted the welcome canvas")
	local credit=visuals.welcome.WelcomeCredito
	check(credit.TextSize*fitted>=9 and credit.Position.Y.Offset>visuals.start.Position.Y.Offset+visuals.start.Size.Y.Offset/2,
		"Welcome footer became unreadable or collided with the touch target")
	visuals:Destroy()
	services.GuiService.GetGuiInset=originalInset
end

-- Regression for the actual mobile screenshot: failed lobby must not overlap the
-- cinematic brand or render an overflowing retry label.
local failureUI=Visuals.new(playerGui)
failureUI:Resize(Vector2.new(854,393))
failureUI:Draw({elapsed=5,ready=false,canStart=false,waiting=false},"RealName",false,
    "Não foi possível preparar o lobby. Tente novamente.")
check(failureUI.logo.root.GroupTransparency==1,"Failure screen left logo over error")
check(failureUI.start:FindFirstChild("TextoAcao",true).Text=="Tentar" and failureUI.start.Selectable,"Mobile failure button unreadable or disabled")
check(failureUI.message.GroupTransparency==0,"Failure message not visible during early intro")
failureUI:Draw({elapsed=5.1,ready=false,canStart=false,waiting=false},"RealName",false,nil)
check(failureUI.start:FindFirstChild("TextoAcao",true).Text=="Start","Retry state did not reset")
failureUI:Destroy()

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
