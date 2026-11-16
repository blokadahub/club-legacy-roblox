-- Numeric color/layout and real callback regressions, not rendered screenshots.
do
local before=assertions
local UI=require(moduleNodes["src/client/UI.luau"])
local T=require(moduleNodes["src/shared/TacticsModel.luau"])
local function node(root,name) return assert(root:FindFirstChild(name,true),"Missing "..name) end
local function press(root,name) node(root,name).Activated:Fire() end
local function luminance(c)
	local function linear(v) return if v<=.04045 then v/12.92 else ((v+.055)/1.055)^2.4 end
	return .2126*linear(c.R)+.7152*linear(c.G)+.0722*linear(c.B)
end
local function contrast(a,b)
	local x,y=luminance(a),luminance(b)
	return (math.max(x,y)+.05)/(math.min(x,y)+.05)
end
local function assertReadable(card)
	local shade=card:FindFirstChild("CardShading")
	local colors={card.BackgroundColor3}
	if shade and shade.Enabled~=false then
		colors={}
		-- Harness sequences retain keypoints as an array.
		for _,key in ipairs(shade.Color.Keypoints or shade.Color) do
			local base=card.BackgroundColor3
			table.insert(colors,Color3.new(base.R*key.Value.R,base.G*key.Value.G,base.B*key.Value.B))
		end
	end
	for _,label in ipairs(card:GetChildren()) do
		if label:IsA("TextLabel") and label.Visible~=false then
			for _,color in ipairs(colors) do
				check(contrast(label.TextColor3,color)>=4.5,"Low authored text contrast: "..card.Name.." / "..label.Text)
			end
		end
	end
end
for _,route in ipairs({"MatchLobby","Tactics"}) do
	local root,ctx=mounted(route)
	local prefix=if route=="Tactics" then "Posicao_" else "Titular_"
	local keeper=node(root,prefix.."gk")
	local other=node(root,prefix.."lb")
	assertReadable(keeper);assertReadable(other)
	local outline=node(keeper,"ControlOutline")
	keeper.MouseEnter:Fire();keeper.MouseLeave:Fire()
	check(outline.Thickness==2 and outline.Transparency==0,"Hover erased tactical selection")
	-- A mouse leaving must not erase focus still held by the controller.
	other.SelectionGained:Fire();other.MouseEnter:Fire();other.MouseLeave:Fire()
	check(node(other,"ControlOutline").Thickness==2,"Mouse erased gamepad focus")
	other.SelectionLost:Fire()
	check(node(other,"ControlOutline").Thickness==1,"Focus outline stuck on unselected card")
	press(root,prefix.."lb")
	assertReadable(other);assertReadable(keeper)
	check(other:GetAttribute("TacticalSelected") and not keeper:GetAttribute("TacticalSelected"),"Selection was not transferred")
	if route=="MatchLobby" then
		press(root,"FecharFicha");press(root,"Reserva_1")
		local reserve=node(root,"Reserva_1")
		assertReadable(reserve)
		check(not other:GetAttribute("TacticalSelected"),"Bench selection also highlights a starter")
		local player=T.player(Data.players,reserve:GetAttribute("PlayerId"))
		local fill=node(reserve,"ValorCondicao")
		check(math.abs(fill.Size.X.Scale-player.fitness/100)<.0001,"Condition bar is decorative rather than roster data")
		press(root,"FecharFicha");press(root,"Titular_gk")
		check(not reserve:GetAttribute("TacticalSelected"),"Starter selection leaves reserve selected")
		press(root,"FecharFicha")
		check(node(root,"AbaLobby_1").BackgroundTransparency==1,"Navigation masks tunnel")
		for i=1,5 do check(node(node(root,"AbaLobby_"..i),"AbaAtiva").Visible==(i==1),"False active navigation tab") end
	else
		press(root,"FaseComBola")
		local phase=node(root,"FaseComBola")
		phase.MouseEnter:Fire();phase.MouseLeave:Fire()
		check(node(phase,"ControlOutline").Thickness==2,"Phase state lost after hover")
	end
	dispose(root,ctx)
end
local previous=UI.highContrast
UI.highContrast=true
local root,ctx=mounted("MatchLobby")
local unselected=node(root,"Titular_lb")
assertReadable(unselected)
local name=node(root,"CondicaoReserva")
check(luminance(name.TextColor3)>.8,"High contrast setting ignored by tactical controls")
dispose(root,ctx);UI.highContrast=previous
print(string.format("PASS Visual polish: %d assertions; authored contrast, persistent selection, mixed-input focus, bench data. No Roblox render.",assertions-before))
end
