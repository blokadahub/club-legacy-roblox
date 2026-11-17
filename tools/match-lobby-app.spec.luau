do
local T=require(moduleNodes["src/shared/TacticsModel.luau"])
local R=require(moduleNodes["src/shared/MatchLobbyModel.luau"])
local start=assertions
local handle=App.start()
local function page() return assert(playerGui.CL27.Canvas:FindFirstChild("MatchLobby")) end
local function node(name) return assert(page():FindFirstChild(name,true),name) end
local function press(name) node(name).Activated:Fire() end
handle.go("MatchLobby")
check(handle.state.screen=="MatchLobby" and services.lastScene.mode=="MatchLobby","Route does not open prematch scene")
check(handle.state.menuInputLocked,"Entrance did not lock input")
press("ConfirmarEscalacao");check(not handle.state.matchPreparation,"Input leaked through entrance")
advance(.23)
check(not handle.state.menuInputLocked,"Short entrance failed to release controls")
check(playerGui.ScreenOrientation==Enum.ScreenOrientation.LandscapeSensor,"Lobby does not request landscape")
press("ConfirmarEscalacao");check(R.ready(handle.state,Data.players),"App cannot confirm sixteen")
local active=T.copy(handle.state.tacticalPlan.active)
press("CentralPrePartida")
press("Titular_gk");check(not node("FichaPrePartida").Visible,"Central did not lock underlying cards")
key(Enum.KeyCode.M)
press("Titular_gk");press("ProporAlteracao")
handle.go("Tactics")
check(T.equal(active,handle.state.tacticalPlan.active),"Leaving saved pending swap")
local tactics=playerGui.CL27.Canvas:FindFirstChild("Tactics")
tactics:FindFirstChild("SelecionarFormacao",true).Activated:Fire()
tactics:FindFirstChild("SalvarTatica",true).Activated:Fire()
check(not R.ready(handle.state,Data.players),"Saving new tactic leaves preparation ready")
handle.go("MatchLobby");advance(.23)
check(node("Titular_gk"):GetAttribute("PlayerId")==handle.state.tacticalPlan.active.positions.gk.playerId,"Lobby ignores editor's saved lineup")
press("ConfirmarEscalacao")
check(R.ready(handle.state,Data.players),"Reconfirmation failed")
local originalPage=page()
local originalCard=node("Titular_gk")
for _,size in ipairs({{1600,900},{1920,1080},{2560,1080},{1024,768},{854,393},{720,360},{640,360},{568,320}}) do
	workspace.CurrentCamera.ViewportSize=Vector2.new(table.unpack(size))
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Fire()
	local factor=playerGui.CL27.Canvas:FindFirstChildOfClass("UIScale")
	factor:GetPropertyChangedSignal("Scale"):Fire()
	local scale=factor.Scale
	check(page()==originalPage and node("Titular_gk")==originalCard,"Resize rebuilds lobby")
	for _,id in ipairs({"ConfirmarEscalacao","CancelarEscalacao","CentralPrePartida","SairPrePartida","AbaLobby_1","Reserva_1"}) do
		local b=node(id)
		check(b.Size.X.Offset*scale>=44-.01 and b.Size.Y.Offset*scale>=44-.01,"Small touch target: "..id)
		local text=if b.Text=="" then b:FindFirstChildOfClass("TextLabel") else b
		check(text.TextSize*scale>=11.9,"Small action text: "..id)
	end
	local field=node("CampoPrePartida")
	check(field.Position.X.Offset>=296 and field.Position.X.Offset+field.Size.X.Offset<=1220,"Field covers bench/avatar")
	check(field.Position.Y.Offset+field.Size.Y.Offset<=node("EstadoEscalacao").Position.Y.Offset,"Field overlaps footer")
	for i=1,5 do
		local card=node("Reserva_"..i)
		local name=card:FindFirstChild("NomeReserva")
		local condition=card:FindFirstChild("CondicaoReserva")
		local track=card:FindFirstChild("CondicaoFisica")
		check(name.Position.Y.Offset+name.Size.Y.Offset<=condition.Position.Y.Offset,"Reserve name overlaps condition")
		check(condition.Position.Y.Offset+condition.Size.Y.Offset<=track.Position.Y.Offset,"Condition text overlaps fitness bar")
		check(track.Position.Y.Offset+track.Size.Y.Offset<=card.Size.Y.Offset,"Fitness bar escapes reserve card")
	end
	local bench=node("ReservasInscritos")
	node("Reserva_5").SelectionGained:Fire()
	check(bench.CanvasPosition.Y>=0,"Invalid reserve scroll")
	local cardScale=originalCard.Parent:FindFirstChildOfClass("UIScale").Scale
	if scale<.65 then
		local target=node("AbrirTitularesCompacto")
		check(target.Visible and target.Selectable and target.Size.Y.Offset*scale>=44,"Compact board has no usable touch target")
		check(not originalCard.Selectable,"Compact overview exposes tiny gamepad targets")
		check(field.CanvasSize.X.Offset==0 and field.CanvasSize.Y.Offset==0,"Compact formation is cropped")
		press("AbrirTitularesCompacto")
		local first=node("AtletaSelecionado").Text
		for _=1,10 do
			press("ModoSubstituicao")
			check(node("AtletaSelecionado").Text~=first,"Compact starter picker repeats before eleven")
		end
		press("ModoSubstituicao")
		check(node("AtletaSelecionado").Text==first,"Compact picker cannot reach all eleven starters")
		press("FecharFicha")
	else check(originalCard.Size.Y.Offset*scale*cardScale>=44,"Pitch cards not usable on desktop") end
	press("Titular_gk")
	check(node("FichaPrePartida").Size.X.Offset+node("FichaPrePartida").Position.X.Offset<=1220,"Sheet obscures user avatar")
	check(node("ProporAlteracao").Size.Y.Offset*scale>=44-.01,"Small context action")
	node("EscolherCandidato").SelectionGained:Fire()
	press("FecharFicha")
end
handle.state.settings.reducedMotion=true
handle.go("Squad");handle.go("MatchLobby")
check(not handle.state.menuInputLocked and page().GroupTransparency==0,"Reduced motion waits for animation")
for _=1,12 do
	handle.go("Tactics");handle.go("MatchLobby")
	check(R.ready(handle.state,Data.players),"Confirmed session state lost navigating")
end
handle.go("HomeInterior")
check(handle.state.screen=="HomeInterior" and not handle.state.menuInputLocked,"Lobby return failed")
services.failNextSceneShow=true
handle.go("MatchLobby")
check(handle.state.screen=="HomeInterior" and not handle.state.menuInputLocked,"Scene failure did not recover")
handle.destroy()
workspace.CurrentCamera.ViewportSize=Vector2.new(1600,900)
print(string.format("PASS Match lobby App: %d assertions; route, locks, editor roundtrip, eight viewport sizes. API doubles only.",assertions-start))
end
