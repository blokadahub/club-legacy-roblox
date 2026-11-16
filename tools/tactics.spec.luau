-- Uses the existing real-module harness. No Roblox rendering claims.
local M=require(moduleNodes["src/shared/TacticsModel.luau"])
local C=require(moduleNodes["src/shared/TacticsCatalog.luau"])
local Session=require(moduleNodes["src/shared/TacticsSession.luau"])
local Layout=require(moduleNodes["src/client/Screens/TacticsLayout.luau"])
local Pitch=require(moduleNodes["src/client/Screens/Pitch.luau"])
local before=assertions
local function expectInvalid(config,roster)
	local ok,err=M.validate(config,roster or Data.players)
	check(not ok and type(err)=="string","Invalid tactic accepted")
end
local function noCollision(points,formation)
	for i,a in ipairs(formation.slots) do
		local p=points[a.id]
		check(p.x>=Layout.cardWidth/2 and p.x<=Layout.width-Layout.cardWidth/2,"Card outside horizontal bounds")
		check(p.y>=Layout.cardHeight/2-4 and p.y+Layout.cardHeight/2<=520,"Card outside vertical bounds")
		for j=i+1,#formation.slots do
			local q=points[formation.slots[j].id]
			check(math.abs(p.x-q.x)>=Layout.cardWidth+1 or math.abs(p.y-q.y)>=Layout.cardHeight+1,
				"Overlapping tactical cards: "..formation.id.." / "..a.id.." / "..formation.slots[j].id)
		end
	end
end
local shapes={}
for _,id in ipairs(C.formationOrder) do
	local config=assert(M.create(Data.players,id))
	check(M.validate(config,Data.players),"Valid formation rejected: "..id)
	local ids={}
	for _,e in pairs(config.positions) do check(not ids[e.playerId],"Repeated starting player");ids[e.playerId]=true end
	local count=0;for _ in pairs(ids) do count+=1 end
	check(count==11,"Not eleven players")
	shapes[id]=config
	for _,width in ipairs({10,55,90}) do
		for _,line in ipairs({10,50,90}) do
			for _,preset in ipairs(C.presets) do
				M.applyPreset(config,preset.id);config.width=width;config.line=line
				local with=M.resolve(config,"with_ball");local without=M.resolve(config,"without_ball")
				local changed=0
				for key,p in pairs(with) do
					check(p.x>=0 and p.x<=1 and p.y>=0 and p.y<=1,"Anchor outside normalized pitch")
					check(p.slotId==key and p.playerId==config.positions[key].playerId,"Unstable slot/player identifier")
					if p.x~=without[key].x or p.y~=without[key].y then changed+=1 end
				end
				check(changed>=10,"Phases do not express different organization")
				local a=Layout.arrange(C.formations[id],with,Pitch.project)
				local b=Layout.arrange(C.formations[id],without,Pitch.project)
				noCollision(a,C.formations[id]);noCollision(b,C.formations[id])
				for _,t in ipairs({.25,.5,.75}) do
					local mixed={}
					for key,p in pairs(a) do mixed[key]={x=p.x+(b[key].x-p.x)*t,y=p.y+(b[key].y-p.y)*t} end
					noCollision(mixed,C.formations[id])
				end
				check(M.equal(M.indicators(config),M.indicators(M.copy(config))),"Nondeterministic indicators")
			end
		end
	end
end
local state={formation=1}
local session=assert(Session.new(state,Data.players))
local original=M.copy(state.tacticalPlan.active)
check(session.draft~=state.tacticalPlan.active and session.draft.positions~=state.tacticalPlan.active.positions,"Draft aliases active state")
check(session:formation("5-4-1"),"5-4-1 unavailable with three center-backs")
check(session:role("lb","wingback") and session:behavior("lb","attack"),"Wingback instructions unavailable")
check(not session:role("gk","striker"),"Goalkeeper accepts striker role")
check(not session:behavior("gk","attack"),"Goalkeeper accepts attack instruction")
check(M.equal(state.tacticalPlan.active,original),"Editing mutated active configuration")
check(session:dirty(),"Dirty flag missing")
local hints=M.indicators(session.draft)
local overlap=false
for _,entry in ipairs(hints.risks) do if entry.id=="flank_cover" then overlap=true end end
check(overlap,"Role instructions missing from tactical indicators")
session:cancel();check(not session:dirty() and M.equal(session.draft,original),"Cancel failed")
session:formation("4-3-2-1");session:strategy("line",85)
check(session:save(),"Valid draft failed to save")
local committed=M.copy(state.tacticalPlan.active)
session:strategy("width",90)
check(M.equal(state.tacticalPlan.active,committed),"Saved config aliases draft")
local reopened=assert(Session.new(state,Data.players))
check(M.equal(reopened.draft,committed),"Session active state lost on reopening")
check(not reopened:strategy("width",0) and not reopened:strategy("width",11) and not reopened:strategy("width",0/0),"Invalid numeric instruction accepted")
check(not reopened:strategy("pressure","random"),"Invalid strategy accepted")
local broken=M.copy(committed);broken.positions.gk.playerId=broken.positions.rb.playerId;expectInvalid(broken)
broken=M.copy(committed);broken.positions.gk.roleId="striker";expectInvalid(broken)
broken=M.copy(committed);broken.positions.gk.behaviorId="attack";expectInvalid(broken)
broken=M.copy(committed);broken.positions.extra=M.copy(broken.positions.gk);expectInvalid(broken)
broken=M.copy(committed);broken.line=math.huge;expectInvalid(broken)
broken=M.copy(committed);broken.width=0/0;expectInvalid(broken)
broken=M.copy(committed);broken.formationId="9-9-9";expectInvalid(broken)
broken=M.copy(committed);broken.presetId="unknown";expectInvalid(broken)
broken=M.copy(committed);broken.positions.gk=nil;expectInvalid(broken)
local reduced=M.copy(Data.players)
for _,p in ipairs(reduced) do if p.id==13 then p.available=false end end
local reducedSession=assert(Session.new({},reduced))
local draftBefore=M.copy(reducedSession.draft)
check(not reducedSession:formation("5-4-1"),"Shape accepts an unavailable third center-back")
check(M.equal(reducedSession.draft,draftBefore),"Rejected shape partially mutated draft")
reducedSession.roster[1].available=false
check(not reducedSession:save(),"Save ignores a player becoming unavailable")
check(M.equal(reducedSession.store.active,draftBefore),"Failed save mutated active state")
local short={}
for i=1,10 do short[i]=Data.players[i] end
check(not M.create(short),"Ten-player roster accepted")
-- Exact compatible matching, including sparse non-array player IDs.
local sparse=M.copy(Data.players)
for _,p in ipairs(sparse) do p.id+=1000 end
for _,id in ipairs(C.formationOrder) do check(M.validate(assert(M.create(sparse,id)),sparse),"IDs interpreted as roster indices") end
-- Every allowed role has valid behaviors; changing role normalizes old instructions.
for _,id in ipairs(C.formationOrder) do
	local s=assert(Session.new({},Data.players));s:formation(id)
	for _,slot in ipairs(C.formations[id].slots) do
		for _,roleId in ipairs(C.groupRoles[slot.group]) do
			check(s:role(slot.id,roleId),"Supported role refused")
			for _,behaviorId in ipairs(C.roles[roleId].behaviors) do
				check(s:behavior(slot.id,behaviorId),"Supported behavior refused")
				check(M.validate(s.draft,Data.players),"Role creates invalid configuration")
				for _,phaseId in ipairs({"with_ball","without_ball"}) do
					noCollision(Layout.arrange(C.formations[id],M.resolve(s.draft,phaseId),Pitch.project),C.formations[id])
				end
			end
		end
	end
end
local function named(root,name) return assert(root:FindFirstChild(name,true),"Missing "..name) end
local function click(root,name) named(root,name).Activated:Fire() end
local root,ctx=mounted("Tactics")
local firstActive=M.copy(ctx.state.tacticalPlan.active)
local card=named(root,"Posicao_gk")
local objects=#root:GetDescendants()
local connections=#ctx.scope.cleanups
click(root,"SelecionarFormacao")
check(ctx.state.tacticalPlan.active.formationId==firstActive.formationId,"Selector saved without confirmation")
click(root,"SalvarTatica")
check(ctx.state.tacticalPlan.active.formationId=="4-2-3-1","Formation save not wired")
click(root,"SelecionarFormacao");click(root,"CancelarTatica");click(root,"SalvarTatica")
check(ctx.state.tacticalPlan.active.formationId=="4-2-3-1","Cancel lost confirmed formation")
click(root,"Posicao_lb");click(root,"SelecionarFuncao");click(root,"SelecionarComportamento");click(root,"SalvarTatica")
check(ctx.state.tacticalPlan.active.positions.lb.roleId=="wingback","Role editor not wired")
check(ctx.state.tacticalPlan.active.positions.lb.behaviorId=="attack","Behavior editor not wired")
click(root,"AbaEquipe")
for _,key in ipairs({"buildUp","pressure","mentality","width","line"}) do
	local old=ctx.state.tacticalPlan.active[key]
	click(root,"Estrategia_"..key);click(root,"SalvarTatica")
	check(ctx.state.tacticalPlan.active[key]~=old,"Strategy selector not wired: "..key)
end
for _,key in ipairs({"width","line"}) do
	local old=ctx.state.tacticalPlan.active[key]
	click(root,"Diminuir_"..key);click(root,"SalvarTatica")
	check(ctx.state.tacticalPlan.active[key]==old-5,"Numeric decrease not wired")
end
local activeBeforePhase=M.copy(ctx.state.tacticalPlan.active)
local beforePhase=named(root,"Posicao_st").Position
click(root,"FaseComBola")
local afterPhase=named(root,"Posicao_st").Position
check(beforePhase.Y.Offset~=afterPhase.Y.Offset or beforePhase.X.Offset~=afterPhase.X.Offset,"Phase button does not move the preview")
check(M.equal(activeBeforePhase,ctx.state.tacticalPlan.active),"Preview phase mutates active tactic")
for i=1,30 do
	click(root,"Predefinicao");click(root,"SelecionarFormacao");click(root,"FaseSemBola");click(root,"FaseComBola")
end
check(named(root,"Posicao_gk")==card,"Cards recreated on update")
check(#root:GetDescendants()==objects,"UI instances accumulated")
check(#ctx.scope.cleanups==connections,"Connections accumulated during updates")
check(ctx.rerenders==0,"Editor rebuilds App on interaction")
ctx.scope.inputsPaused=true
local paused=M.copy(ctx.state.tacticalPlan.active)
click(root,"SalvarTatica");check(M.equal(ctx.state.tacticalPlan.active,paused),"Save bypasses navigation lock")
ctx.scope.inputsPaused=false
click(root,"CancelarTatica")
local returnedState=ctx.state
local listeners=table.clone(ctx.scope.cleanups)
dispose(root,ctx)
for _,connection in ipairs(listeners) do if typeof(connection)=="RBXScriptConnection" then check(not connection.Connected,"Connection abandoned on destroy") end end
root,ctx=mounted("Tactics",returnedState)
click(root,"SalvarTatica");check(M.equal(ctx.state.tacticalPlan.active,paused),"Draft survived navigation without save")
-- Squad uses the confirmed lineup and keeps stable Data.players indexes for profiles.
ctx.state.tacticalPlan.active=assert(M.create(Data.players,"5-4-1"))
local squadRoot,squadCtx=mounted("Squad",ctx.state)
local backup=named(squadRoot,"Jogador_13")
check(backup.Parent==squadRoot,"Third center-back remains on bench after confirmed 5-4-1")
dispose(squadRoot,squadCtx);dispose(root,ctx)
print(string.format("PASS Tactics: %d assertions; domain, transactions, collision bounds, real UI callbacks and cleanup. API doubles only.",assertions-before))
