--!nonstrict
-- Display-only collision constraints; never writes back to tactical anchors.
local L={width=920,height=510,cardWidth=142,cardHeight=92,gap=10}
L.compactLabels={gk="G",lcb="ZE",rcb="ZD",cb="Z",lb="LE",rb="LD",dm="V",ldm="VE",rdm="VD",
	lcm="ME",rcm="MD",lw="PE",rw="PD",lm="ME",rm="MD",lam="ME",ram="MD",am="M",st="AT",lst="AE",rst="AD"}
function L.arrange(formation,anchors,project)
	local rows={}
	for _,s in ipairs(formation.slots) do
		rows[s.row]=rows[s.row] or {}
		table.insert(rows[s.row],s)
	end
	local result={}
	local previousY=-math.huge
	for row=formation.rows,1,-1 do
		local slots=rows[row]
		table.sort(slots,function(a,b) return anchors[a.id].x<anchors[b.id].x end)
		local average=0
		for _,s in ipairs(slots) do average+=anchors[s.id].y end
		average/= #slots
		local _,desired=project(.5,average,L.width-24,L.height-70)
		local lower=math.max(L.cardHeight/2,previousY+L.cardHeight+L.gap)
		local upper=L.height-L.cardHeight/2-(row-1)*(L.cardHeight+L.gap)
		local y=math.clamp(desired+12,lower,math.max(lower,upper))
		-- Ordered rows remain separated even at extreme tactical settings.
		local lastX=-math.huge
		for i,s in ipairs(slots) do
			local x=project(anchors[s.id].x,average,L.width-24,L.height-70)+12
			local left=math.max(L.cardWidth/2+4,lastX+L.cardWidth+L.gap)
			local right=L.width-L.cardWidth/2-4-(#slots-i)*(L.cardWidth+L.gap)
			x=math.clamp(x,left,math.max(left,right))
			-- Keep individual advances visible within the safe row band.
			local individual=(anchors[s.id].y-average)*(L.height-70)
			local slack=math.max(0,math.min(4,(y-previousY-L.cardHeight)/2-1))
			result[s.id]={x=x,y=y+math.clamp(individual,-slack,slack),row=row}
			lastX=x
		end
		previousY=y
	end
	return result
end
return L
