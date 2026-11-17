--!nonstrict
-- Presentation coordinates only. No tactical anchors or camera ownership here.
local L={
	Camera={position={0,4.3,22},target={0,4.3,0},fov=32},
	Avatar={position={8.4,.025,0},maxHeight=7.8,maxWidth=3.52},
	Environment={Ambient={48,50,56},OutdoorAmbient={18,22,29},Brightness=1.05,
		ClockTime=0,ExposureCompensation=-.12,EnvironmentDiffuseScale=.32,EnvironmentSpecularScale=.28},
}
function L.build()
	local parts={}
	local function part(name,size,position,color,material,shadow)
		table.insert(parts,{name=name,size=size,position=position,color=color,material=material or "SmoothPlastic",castShadow=shadow~=false})
	end
	part("PisoAcetinado",{32,.35,88},{0,-.175,-16},{27,28,30})
	part("ParedeEsquerda",{.45,13,88},{-16,6.5,-16},{23,28,33},"Concrete")
	part("ParedeDireita",{.45,13,88},{16,6.5,-16},{30,29,29},"Concrete")
	part("Teto",{32,.35,88},{0,13.1,-16},{16,19,23})
	part("Fundo",{32,13,.4},{0,6.5,-60},{9,12,16})
	-- Recessed doorway and metal jambs give a legible terminal plane. No emitter.
	part("PortaFundo",{7.2,9,.12},{0,4.5,-59.7},{15,19,21},"Metal",false)
	part("MarcoFundo_E",{.22,9.2,.36},{-3.72,4.6,-59.42},{48,51,53},"Metal")
	part("MarcoFundo_D",{.22,9.2,.36},{3.72,4.6,-59.42},{48,51,53},"Metal")
	part("MarcoFundo_T",{7.66,.22,.36},{0,9.31,-59.42},{48,51,53},"Metal")
	for i=0,7 do
		local z=21-i*10.5
		for _,side in ipairs({-1,1}) do
			part("Pilar_"..side.."_"..i,{.5,12.8,.42},{side*15.6,6.4,z},{46,49,52},"Metal")
			part("Painel_"..side.."_"..i,{.08,8.4,if i==7 then 4.2 else 8.8},{side*15.72,5.5,if i==7 then -57 else z-5},{30-i*2,33-i*2,36-i*2},"Metal")
		end
		part("Travessa_"..i,{31,.23,.35},{0,12.7,z},{45,47,50},"Metal")
		part("LuminariaQuente_"..i,{1.1,.12,5},{13,12.7,z-3},{230-i*14,177-i*10,108-i*7},"Neon")
	end
	for _,side in ipairs({-1,1}) do
		part("GuiaVerde_"..side,{.11,.04,82},{side*14.8,.025,-15},{60,126,87},"Neon")
		part("Rodape_"..side,{.4,.3,82},{side*15.6,.15,-15},{50,53,53},"Metal")
	end
	part("ContraluzAzul",{.08,.06,76},{-14.8,12.6,-14},{48,79,124},"Neon")
	-- Six shadowless floor joints establish distance below the tactical board.
	-- Their lower face touches the floor; no coplanar surfaces or extra lights.
	for i=1,6 do
		part("JuntaPiso_"..i,{28,.008,.045},{0,.004,4-i*10},{17,20,21},"SmoothPlastic",false)
	end
	-- A flush presentation inlay gives the feet contact without a floating podium.
	part("AreaDoTecnico",{5.3,.025,4.4},{8.4,.0125,0},{33,34,35})
	return parts
end
return L
