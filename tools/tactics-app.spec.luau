-- Real editor callbacks under App's safe-area scaling. Numerical UI evidence only.
do
local start=assertions
local T=require(moduleNodes["src/shared/TacticsModel.luau"])
local Catalog=require(moduleNodes["src/shared/TacticsCatalog.luau"])
local Controls=require(moduleNodes["src/client/Screens/TacticsControls.luau"])
local UI=require(moduleNodes["src/client/UI.luau"])
local handle=App.start()
handle.state.settings.reducedMotion=true
handle.go("Tactics")
advance(3.1)
local function page() return assert(playerGui.CL27.Canvas:FindFirstChild("Tactics")) end
local function node(name) return assert(page():FindFirstChild(name,true),name) end
local function press(name) node(name).Activated:Fire() end
local originalPage=page()
local originalCard=node("Posicao_gk")
local objectCount=#page():GetDescendants()
local oldInset=services.GuiService.GetGuiInset
local sizes={{1600,900},{1920,1080},{2560,1080},{1024,768},{854,393},{720,360},{640,360},{568,320}}
for _,insets in ipairs({{0,0,0,0},{20,24,12,8},{44,24,44,20}}) do
	services.GuiService.GetGuiInset=function() return Vector2.new(insets[1],insets[2]),Vector2.new(insets[3],insets[4]) end
	for _,size in ipairs(sizes) do
		workspace.CurrentCamera.ViewportSize=Vector2.new(table.unpack(size))
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Fire()
		local factor=playerGui.CL27.Canvas:FindFirstChildOfClass("UIScale")
		factor:GetPropertyChangedSignal("Scale"):Fire()
		local scale=factor.Scale
		local compact=scale<.65
		check(page()==originalPage and node("Posicao_gk")==originalCard,"Editor rebuilt during resize")
		for _,id in ipairs({"Predefinicao","AbaEquipe","AbaAtleta","FaseComBola","FaseSemBola","SalvarTatica","CancelarTatica","SelecionarFormacao","Diminuir_width"}) do
			local button=node(id)
			check(button.Size.X.Offset*scale>=44-.01 and button.Size.Y.Offset*scale>=44-.01,"Small editor target: "..id)
		end
		local left=node("ControlesColetivos")
		check(left.Size.Y.Offset>=node("SelecionarFormacao").Size.Y.Offset,"Compact editor cannot show one complete control")
		check(left.Position.Y.Offset+left.Size.Y.Offset<node("SalvarTatica").Position.Y.Offset,"Controls cover save")
		local preset=node("Predefinicao")
		check(preset.Position.Y.Offset+preset.Size.Y.Offset<node("AbaEquipe").Position.Y.Offset,"Preset covers tabs")
		for _,child in ipairs(preset:GetChildren()) do
			if child:IsA("TextLabel") and child.Visible~=false then
				check(child.Position.Y.Offset+child.Size.Y.Offset<=preset.Size.Y.Offset+.1,"Preset text escapes card")
			end
		end
		for _=1,#Catalog.formationOrder do
			press("AbaEquipe");press("SelecionarFormacao");press("SalvarTatica")
			for _,phase in ipairs({"FaseComBola","FaseSemBola"}) do
				press(phase)
				local field=node("CampoTaticoRolavel")
				local content=originalCard.Parent.Parent
				local zoom=content:FindFirstChildOfClass("UIScale").Scale
				check(field.CanvasSize.X.Offset==0 and field.CanvasSize.Y.Offset==0,"Formation requires panning")
				check(field.Position.X.Offset>=612 and field.Position.X.Offset+field.Size.X.Offset<=1544,"Field leaves right column")
				check(field.Position.Y.Offset+field.Size.Y.Offset<node("AnaliseTatica").Position.Y.Offset,"Field overlaps analysis")
				for _,slot in ipairs(Catalog.formations[handle.state.tacticalPlan.active.formationId].slots) do
					local card=node("Posicao_"..slot.id)
					local x=content.Position.X.Offset+(card.Position.X.Offset-card.Size.X.Offset/2)*zoom
					local y=content.Position.Y.Offset+(card.Position.Y.Offset-card.Size.Y.Offset/2)*zoom
					check(x>=-.01 and x+card.Size.X.Offset*zoom<=field.Size.X.Offset+.01,"Card cut horizontally: "..slot.id)
					check(y>=-.01 and y+card.Size.Y.Offset*zoom<=field.Size.Y.Offset+.01,"Card cut vertically: "..slot.id)
					check(card.Selectable==not compact and card.Active==not compact,"Tiny card remains interactive")
					check(card:FindFirstChild("NomeAtleta").Text==T.player(Data.players,card:GetAttribute("PlayerId")).shortName,"Card displays wrong athlete")
				end
			end
		end
		if compact then
			local target=node("AbrirAtletasCompacto")
			check(target.Visible and target.Active and target.Size.Y.Offset*scale>=44,"No usable compact picker")
			for i,slot in ipairs(Catalog.formations[handle.state.tacticalPlan.active.formationId].slots) do
				services.GuiService.SelectedObject=target
				press("AbrirAtletasCompacto")
				check(node("FichaTatica").Visible and not node("SalvarTatica").Active,"Modal leaks underlying inputs")
				check(node("EscolherAtleta_"..i).Size.Y.Offset*scale>=44,"Small roster row")
				local active=T.copy(handle.state.tacticalPlan.active)
				press("SelecionarFormacao");press("SalvarTatica")
				check(T.equal(active,handle.state.tacticalPlan.active),"Modal changed background draft")
				press("EscolherAtleta_"..i)
				check(not node("FichaTatica").Visible and node("Posicao_"..slot.id):GetAttribute("TacticalSelected"),"Picker failed to reach athlete "..slot.id)
				check(services.GuiService.SelectedObject==node("SelecionarFuncao"),"Picker did not focus individual controls")
			end
			services.GuiService.SelectedObject=node("AbrirAnalise")
			press("AbrirAnalise")
			local text=node("RelatorioTatico").Text
			local report=T.indicators(handle.state.tacticalPlan.active)
			for _,list in ipairs({report.advantages,report.risks}) do
				for _,item in ipairs(list) do check(string.find(text,item.text,1,true)~=nil,"Analysis omits model evidence") end
			end
			check(services.GuiService.SelectedObject==node("FecharFichaTatica"),"Analysis focuses hidden roster")
			press("FecharFichaTatica")
			check(services.GuiService.SelectedObject==node("AbrirAnalise"),"Closing analysis loses focus")
		else
			check(originalCard.Size.Y.Offset*scale*originalCard.Parent.Parent:FindFirstChildOfClass("UIScale").Scale>=44,"Desktop card below touch minimum")
		end
		check(#page():GetDescendants()==objectCount,"Interactions accumulate GUI instances")
	end
end
services.GuiService.GetGuiInset=oldInset
-- Numeric limits disable only the unavailable direction and keep exact meters.
press("AbaEquipe")
for _=1,20 do press("Estrategia_width") end
press("SalvarTatica")
check(handle.state.tacticalPlan.active.width==90 and not node("Estrategia_width").Active,"Upper limit is still actionable")
check(math.abs(node("Estrategia_width"):FindFirstChild("ValorTatico",true).Size.X.Scale-.9)<.0001,"Width meter ignores actual value")
for _=1,20 do press("Diminuir_width") end
press("SalvarTatica")
check(handle.state.tacticalPlan.active.width==10 and not node("Diminuir_width").Active,"Lower limit is still actionable")
press("AbrirAtletasCompacto")
check(node("FichaTatica").GroupTransparency==0,"Reduced motion still animates context")
press("FecharFichaTatica")
-- Resize while inputs are locked must still refit geometry.
local smallField=node("CampoTaticoRolavel").Size.Y.Offset
key(Enum.KeyCode.ButtonY)
local saved=T.copy(handle.state.tacticalPlan.active)
press("SelecionarFormacao");press("SalvarTatica")
check(T.equal(saved,handle.state.tacticalPlan.active),"Central no longer blocks editor")
workspace.CurrentCamera.ViewportSize=Vector2.new(1600,900)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Fire()
playerGui.CL27.Canvas:FindFirstChildOfClass("UIScale"):GetPropertyChangedSignal("Scale"):Fire()
check(node("CampoTaticoRolavel").Size.Y.Offset~=smallField and not node("AbrirAtletasCompacto").Visible,"Input lock prevents responsive resize")
key(Enum.KeyCode.ButtonY)
handle.go("MatchLobby");advance(.3)
handle.state.settings.reducedMotion=false
handle.go("Tactics");advance(.3)
workspace.CurrentCamera.ViewportSize=Vector2.new(1600,900)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Fire()
playerGui.CL27.Canvas:FindFirstChildOfClass("UIScale"):GetPropertyChangedSignal("Scale"):Fire()
local other=node("Posicao_lb")
other.MouseEnter:Fire();other.Activated:Fire();other.MouseLeave:Fire()
advance(.2)
check(other:FindFirstChild("ControlOutline").Thickness==2 and other:FindFirstChild("ControlOutline").Transparency==0,"Stale focus tween erased selection")
press("AbaEquipe");press("SelecionarFormacao")
local board=node("ConteudoCampoTatico")
check(board.GroupTransparency>0,"Formation has no finite visual handoff")
press("SelecionarFormacao");advance(.2)
check(board.GroupTransparency==0,"Interrupted formation feedback does not settle")
local analysisTarget=node("AbrirAnalise")
-- Open via the current full-size control callback to exercise finite entry.
analysisTarget.Activated:Fire()
local layer=node("FichaTatica")
check(layer.Visible and layer.GroupTransparency>0,"Context has no finite entry")
advance(.08)
check(layer.GroupTransparency>0 and layer.GroupTransparency<.22,"Context fade is not progressing")
press("FecharFichaTatica");advance(.3)
check(not layer.Visible and layer.GroupTransparency==0,"Closing context leaves a stale tween")
analysisTarget.Activated:Fire();advance(.2)
check(layer.GroupTransparency==0,"Context entry never settles")
handle.destroy();advance(.5)
check(layer.Destroyed,"Context outlives page scope")
for tween in pairs(activeTweens) do check(tween.target~=layer,"Disposed context retains tween") end
workspace.CurrentCamera.ViewportSize=Vector2.new(1600,900)
print(string.format("PASS Tactics App: %d assertions; full formation, 8 sizes × 3 insets, all formations/phases, modal isolation, roster access, finite FX, numeric limits. No rendered evidence.",assertions-start))
end
