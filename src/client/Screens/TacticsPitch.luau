--!nonstrict
local UI=require(script.Parent.Parent.UI)
local Pitch=require(script.Parent.Pitch)
local Layout=require(script.Parent.TacticsLayout)
local Controls=require(script.Parent.TacticsControls)
local Catalog=require(game:GetService("ReplicatedStorage").CL27.TacticsCatalog)
local Model=require(game:GetService("ReplicatedStorage").CL27.TacticsModel)
local C=Controls.colors
local View={}
function View.create(parent,scope,onSelect)
	local host=UI.frame(parent,0,0,Layout.width,510,C.ink,1)
	host.Name="PreviaTatica"
	Pitch.draw(host,12,28,Layout.width-24,Layout.height-70,{
		stripeA=Color3.fromRGB(30,35,35),stripeB=Color3.fromRGB(26,31,31),line=Color3.fromRGB(99,113,103)})
	local cards={}
	for i=1,11 do
		local card={}
		card.button,card.edge=Controls.button(host,"Posicao_"..i,function() if card.slotId then onSelect(card.slotId) end end,scope)
		card.button.AnchorPoint=Vector2.new(.5,.5)
		card.button.Size=UDim2.fromOffset(Layout.cardWidth,Layout.cardHeight)
		card.shade=UI.gradient(card.button,{Color3.fromRGB(37,47,44),Color3.fromRGB(14,20,20)},90)
		card.shade.Name="CardShading"
		card.label=Controls.text(card.button,"",8,3,126,21,18,C.green,true)
		card.role=Controls.text(card.button,"",6,24,130,42,18,C.white,true)
		card.behavior=Controls.text(card.button,"",6,68,130,21,17,C.muted)
		for _,label in ipairs({card.label,card.role,card.behavior}) do label.TextXAlignment=Enum.TextXAlignment.Center end
		cards[i]=card
	end
	local view={host=host,cards=cards}
	function view:update(config,phase,selected,animate)
		local formation=Catalog.formations[config.formationId]
		local anchors=Model.resolve(config,phase)
		local positions=Layout.arrange(formation,anchors,Pitch.project)
		for i,s in ipairs(formation.slots) do
			local card=cards[i]
			local entry=config.positions[s.id]
			card.slotId=s.id
			card.button.Name="Posicao_"..s.id
			card.button:SetAttribute("SlotId",s.id)
			card.button:SetAttribute("PlayerId",entry.playerId)
			card.label.Text=s.label
			card.role.Text=Catalog.roles[entry.roleId].label
			card.behavior.Text=Catalog.behaviors[entry.behaviorId].label
			local focused=s.id==selected
			card.button.BackgroundColor3=if focused then C.white else Color3.new(1,1,1)
			card.shade.Enabled=not focused
			card.label.TextColor3=if focused then Color3.fromRGB(39,102,62) else C.green
			card.role.TextColor3=if focused then C.ink else C.white
			card.behavior.TextColor3=if focused then C.panel elseif UI.highContrast then C.white else C.muted
			Controls.select(card.button,focused)
			local p=positions[s.id]
			local goal=UDim2.fromOffset(p.x,p.y)
			-- Shape switches are immediate: interpolating across slots could cross cards.
			-- Only same-shape phase changes tween between ordered, collision-free rows.
			if animate and not UI.reducedMotion then scope:Tween(card.button,{Position=goal},.18)
			else
				local tween=scope.tweens[card.button]
				if tween then tween:Cancel();scope.tweens[card.button]=nil end
				card.button.Position=goal
			end
		end
		-- Spatial gamepad graph; never recreate cards or steal selection on an edit.
		for i,s in ipairs(formation.slots) do
			local p=positions[s.id]
			for property,axis in pairs({NextSelectionLeft="left",NextSelectionRight="right",NextSelectionUp="up",NextSelectionDown="down"}) do
				local best,distance=nil,math.huge
				for j,t in ipairs(formation.slots) do
					if i~=j then
						local q=positions[t.id];local dx,dy=q.x-p.x,q.y-p.y
						local qualifies=if axis=="left" then dx< -5 elseif axis=="right" then dx>5 elseif axis=="up" then dy< -5 else dy>5
						local weight=if axis=="left" or axis=="right" then math.abs(dx)+math.abs(dy)*3 else math.abs(dy)+math.abs(dx)*2
						if qualifies and weight<distance then best=cards[j].button;distance=weight end
					end
				end
				cards[i].button[property]=best
			end
		end
	end
	return view
end
return View
