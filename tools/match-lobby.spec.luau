-- Actual shared modules and UI callbacks, API doubles only.
do
local T=require(moduleNodes["src/shared/TacticsModel.luau"])
local R=require(moduleNodes["src/shared/MatchLobbyModel.luau"])
local C=require(moduleNodes["src/shared/TacticsCatalog.luau"])
local TS=require(moduleNodes["src/shared/TacticsSession.luau"])
local start=assertions
local function invalid(t,b,roster)
	local ok,err=R.validate(t,b,roster or Data.players)
	check(not ok and type(err)=="string","Invalid registration accepted")
end
for _,formationId in ipairs(C.formationOrder) do
	local state={homeClub=1,tacticalPlan={active=assert(T.create(Data.players,formationId))}}
	local active=T.copy(state.tacticalPlan.active)
	local session=assert(R.new(state,Data.players))
	check(R.validate(session.tactic,session.benchIds,Data.players),"Default sixteen invalid")
	check(#session.benchIds==5 and #Data.players==22,"Global roster trimmed")
	check(not R.ready(state,Data.players) and R.export(state,Data.players)==nil,"Unconfirmed lineup exported")
	local eligible={};for _,id in ipairs(session.benchIds) do eligible[id]=true end
	for id in pairs(R.starters(active)) do eligible[id]=true end
	local sixteen={};for _,p in ipairs(Data.players) do if eligible[p.id] then table.insert(sixteen,T.copy(p)) end end
	check(#sixteen==16,"Match registration count differs")
	local minimal=assert(R.new(state,sixteen))
	check(#minimal.benchIds==5 and #minimal:candidates()==0 and minimal:confirm(),"Exactly sixteen-player club rejected")
	for _,slot in ipairs(C.formations[formationId].slots) do
		for i,id in ipairs(session.benchIds) do
			local draft=T.copy(session.tactic);local bench=T.copy(session.benchIds)
			local expected=T.compatible(T.player(Data.players,id),slot)
			local ok=session:swap(slot.id,i)
			check(ok==expected,"Compatibility mismatch: "..formationId.." "..slot.id)
			if ok then
				check(session.tactic.positions[slot.id].playerId==id and session.benchIds[i]==draft.positions[slot.id].playerId,"Swap did not exchange IDs")
				check(session.tactic.positions[slot.id].roleId==draft.positions[slot.id].roleId,"Swap reset slot instructions")
				check(R.validate(session.tactic,session.benchIds,Data.players),"Swap corrupted registration")
			else check(T.equal(draft,session.tactic) and T.equal(bench,session.benchIds),"Rejected swap partially mutated draft") end
			check(T.equal(active,state.tacticalPlan.active),"Draft changed confirmed tactic")
			session:cancel();check(not session:dirty(),"Cancel failed")
		end
	end
	local extra=session:candidates()[1]
	check(extra and session:register(1,extra.id),"Eligible nonregistered player rejected")
	check(not session:register(2,extra.id) and not session:register(6,extra.id),"Invalid registration accepted")
	check(session:dirty() and session:confirm() and R.ready(state,Data.players),"Confirmation failed")
	local payload=assert(R.export(state,Data.players));payload.benchIds[1]=-1;payload.tactic.width=90
	check(R.ready(state,Data.players),"Export aliases active state")
	local reopened=assert(R.new(state,Data.players))
	check(T.equal(reopened.benchIds,state.matchPreparation.benchIds),"Registered bench lost after reopening")
	local prior=T.copy(state.matchPreparation)
	local tacticEditor=assert(TS.new(state,Data.players));tacticEditor:strategy("width",80);tacticEditor:save()
	check(not R.ready(state,Data.players),"Tactical change leaves stale ready receipt")
	check(not reopened:confirm(),"Stale draft overwrites editor")
	check(T.equal(state.matchPreparation,prior),"Failed confirmation modified registration")
	local refreshed=assert(R.new(state,Data.players));check(refreshed:confirm(),"Updated tactic cannot confirm")
	state.homeClub=2;check(not R.ready(state,Data.players) and not refreshed:confirm(),"Club change reuses confirmation")
	invalid(active,{1,2,3,4,5})
	invalid(active,{12,12,13,14,15})
	invalid(active,{12,13,14,15})
	invalid(active,{12,13,14,15,16,17})
	invalid(active,{[1]=12,[2]=13,[3]=14,[4]=15,[8]=16})
	invalid(active,{12,13,14,15,999})
	local unavailable=T.copy(Data.players)
	for _,p in ipairs(unavailable) do if p.id==session.benchIds[1] then p.available=false end end
	invalid(session.tactic,session.benchIds,unavailable)
end
local sparse=T.copy(Data.players)
for _,p in ipairs(sparse) do p.id=p.id*13 end
local sparseSession=assert(R.new({homeClub=1},sparse))
check(sparseSession:confirm(),"IDs treated as roster indices")
local state={homeClub=1};local session=assert(R.new(state,Data.players))
check(session:confirm(),"Initial confirmation failed")
local editor=assert(TS.new(state,Data.players));editor:formation("5-4-1");editor:save()
local reentered=assert(R.new(state,Data.players))
check(R.validate(reentered.tactic,reentered.benchIds,Data.players),"Bench reconciliation duplicates new third center-back")
check(not R.ready(state,Data.players),"Formation change does not invalidate preparation")
local shortRoster={};for i=1,15 do shortRoster[i]=Data.players[i] end
local short=assert(R.new({homeClub=1},shortRoster))
check(#short.benchIds==4 and not short:confirm(),"Missing reserve fabricated")
local noKeeper=T.copy(Data.players);noKeeper[1].available=false;noKeeper[12].available=false
check(R.new({},noKeeper)==nil,"Invalid lineup initialized")

local function get(root,name) return assert(root:FindFirstChild(name,true),"Missing "..name) end
local function activate(root,name) get(root,name).Activated:Fire() end
local root,ctx=mounted("MatchLobby")
local original=T.copy(ctx.state.tacticalPlan.active)
local starters,reserves=0,0
for _,object in ipairs(root:GetDescendants()) do
	if object.Name:match("^Titular_") then starters+=1 end
	if object.Name:match("^Reserva_%d$") then reserves+=1 end
end
check(starters==11 and reserves==5,"Lobby card counts wrong")
check(get(root,"IdentidadeReal").Text==services.Players.LocalPlayer.Name,"Account identity fabricated")
local objects,connections=#root:GetDescendants(),#ctx.scope.cleanups
local gk=get(root,"Titular_gk")
activate(root,"Titular_gk")
check(get(root,"FichaPrePartida").Visible and get(root,"AtletaSelecionado").Text==T.player(Data.players,original.positions.gk.playerId).name,"Starter detail mismatched")
activate(root,"ProporAlteracao")
check(T.equal(original,ctx.state.tacticalPlan.active) and gk:GetAttribute("PlayerId")~=original.positions.gk.playerId,"Proposed swap not isolated")
activate(root,"CancelarEscalacao")
check(gk:GetAttribute("PlayerId")==original.positions.gk.playerId,"UI cancel did not restore")
activate(root,"Titular_gk");activate(root,"ProporAlteracao");activate(root,"ConfirmarEscalacao")
check(R.ready(ctx.state,Data.players) and ctx.state.tacticalPlan.active.positions.gk.playerId==12,"UI did not confirm keeper swap")
local committed=T.copy(ctx.state.tacticalPlan.active)
activate(root,"Reserva_1");activate(root,"EscolherCandidato");activate(root,"ProporAlteracao")
check(R.ready(ctx.state,Data.players),"Draft bench invalidated confirmed payload")
activate(root,"CancelarEscalacao")
for i=1,25 do
	activate(root,"Titular_gk");activate(root,"FecharFicha");activate(root,"Reserva_2")
	activate(root,"ModoSubstituicao");activate(root,"FecharFicha")
	activate(root,"AbaLobby_4");activate(root,"FecharFicha")
end
check(objects==#root:GetDescendants() and connections==#ctx.scope.cleanups,"Selection accumulates instances/connections")
check(gk==get(root,"Titular_gk") and ctx.rerenders==0,"Lobby reconstructs UI on selection")
ctx.scope.inputsPaused=true;activate(root,"ConfirmarEscalacao")
check(T.equal(committed,ctx.state.tacticalPlan.active),"Confirmation bypasses navigation lock")
ctx.scope.inputsPaused=false
activate(root,"AbaLobby_3");check(ctx.lastRoute=="Tactics","Tactics tab not linked")
activate(root,"AbaLobby_2");check(ctx.lastRoute=="Squad","Squad tab not linked")
activate(root,"AbaLobby_5");check(ctx.lastRoute=="Settings","Settings tab not linked")
local saved=ctx.state;local listeners=table.clone(ctx.scope.cleanups)
dispose(root,ctx)
for _,connection in ipairs(listeners) do if typeof(connection)=="RBXScriptConnection" then check(not connection.Connected,"Lobby leaks connection") end end
root,ctx=mounted("Tactics",saved);activate(root,"SalvarTatica");dispose(root,ctx)
root,ctx=mounted("MatchLobby",saved)
check(get(root,"Titular_gk"):GetAttribute("PlayerId")==12 and R.ready(saved,Data.players),"Returning from editor loses confirmed lineup")
dispose(root,ctx)
print(string.format("PASS Match lobby rules/UI: %d assertions; registration, swaps, transactions, real callbacks, disposal. API doubles only.",assertions-start))
end
