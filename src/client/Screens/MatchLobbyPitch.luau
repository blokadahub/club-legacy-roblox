--!nonstrict
-- Reuses the same projection/collision constraints as the confirmed editor.
local UI=require(script.Parent.Parent.UI)
local Controls=require(script.Parent.TacticsControls)
local Layout=require(script.Parent.TacticsLayout)
local Pitch=require(script.Parent.Pitch)
local Catalog=require(game:GetService("ReplicatedStorage").CL27.TacticsCatalog)
local Model=require(game:GetService("ReplicatedStorage").CL27.TacticsModel)
local V={}
local compactLabels={gk="G",lcb="ZE",rcb="ZD",cb="Z",lb="LE",rb="LD",dm="V",ldm="VE",rdm="VD",
	lcm="ME",rcm="MD",lw="PE",rw="PD",lm="ME",rm="MD",lam="ME",ram="MD",am="M",st="AT",lst="AE",rst="AD"}
function V.create(parent,scope,roster,onSelect)
	local C=Controls.colors
	local host=UI.frame(parent,0,0,Layout.width,Layout.height,C.ink,1)
	Pitch.draw(host,12,28,896,440,{stripeA=Color3.fromRGB(27,31,32),stripeB=Color3.fromRGB(23,27,28),line=Color3.fromRGB(83,96,93)})
	local cards={}
	for i=1,11 do
		local card={}
		card.button,card.edge=Controls.button(host,"Titular_"..i,function() if card.slotId then onSelect(card.slotId) end end,scope)
		card.button.Size=UDim2.fromOffset(Layout.cardWidth,Layout.cardHeight)
		card.button.AnchorPoint=Vector2.new(.5,.5);card.button.BackgroundTransparency=.12
		card.name=Controls.text(card.button,"",6,4,130,23,18,C.white,true)
		card.role=Controls.text(card.button,"",6,28,130,39,17,C.muted)
		card.position=Controls.text(card.button,"",6,68,130,21,18,C.green,true)
		for _,label in ipairs({card.name,card.role,card.position}) do label.TextXAlignment=Enum.TextXAlignment.Center end
		cards[i]=card
	end
	local view={host=host,cards=cards}
	function view:compact(enabled,physicalScale)
		for _,card in ipairs(cards) do
			card.name.Visible=not enabled;card.role.Visible=not enabled
			card.position.Position=UDim2.fromOffset(6,enabled and 0 or 68)
			card.position.Size=UDim2.fromOffset(130,enabled and Layout.cardHeight or 21)
			card.position.TextSize=if enabled then math.max(18,12/physicalScale) else 18
			card.position.Text=if enabled then compactLabels[card.slotId] else card.fullPosition
		end
	end
	function view:update(config,selected)
		local formation=Catalog.formations[config.formationId]
		local points=Layout.arrange(formation,Model.resolve(config,"with_ball"),Pitch.project)
		for i,slot in ipairs(formation.slots) do
			local card=cards[i];local entry=config.positions[slot.id]
			local player=Model.player(roster,entry.playerId)
			card.slotId=slot.id;card.button.Name="Titular_"..slot.id
			card.button:SetAttribute("SlotId",slot.id);card.button:SetAttribute("PlayerId",player.id)
			card.name.Text=player.shortName or player.name
			card.role.Text=Catalog.roles[entry.roleId].label
			card.position.Text=slot.label
			card.fullPosition=slot.label
			card.button.Position=UDim2.fromOffset(points[slot.id].x,points[slot.id].y)
			local focused=selected==slot.id
			card.button.BackgroundColor3=if focused then C.white else C.ink
			card.name.TextColor3=if focused then C.ink else C.white
			card.role.TextColor3=if focused then C.panel else C.muted
			card.position.TextColor3=if focused then Color3.fromRGB(39,102,62) else C.green
			card.edge.Color=if focused then C.green else C.border
		end
		for i,slot in ipairs(formation.slots) do
			local a=points[slot.id]
			for property,axis in pairs({NextSelectionLeft="l",NextSelectionRight="r",NextSelectionUp="u",NextSelectionDown="d"}) do
				local best,score=nil,math.huge
				for j,other in ipairs(formation.slots) do
					if i~=j then
						local b=points[other.id];local dx,dy=b.x-a.x,b.y-a.y
						local match=if axis=="l" then dx< -5 elseif axis=="r" then dx>5 elseif axis=="u" then dy< -5 else dy>5
						local distance=if axis=="l" or axis=="r" then math.abs(dx)+3*math.abs(dy) else math.abs(dy)+2*math.abs(dx)
						if match and distance<score then best=cards[j].button;score=distance end
					end
				end
				cards[i].button[property]=best
			end
		end
	end
	return view
end
return V
