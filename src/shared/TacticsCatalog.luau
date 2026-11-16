--!nonstrict
-- Stable domain identifiers. No Roblox services, colors, pixels or match results.
local C = {}
C.version = 1
C.formations = {}
local function slot(id, label, group, x, row, accepts)
	return {id=id, label=label, group=group, x=x, row=row, accepts=accepts}
end
local function formation(id, label, rows, slots)
	C.formations[id] = {id=id, label=label, rows=rows, slots=slots}
end
local function back(five)
	local slots = {
		slot("gk","GOL","keeper",.5,1,{"GOL"}),
		slot("lb","LE","fullback",.07,2,{"LE"}),
		slot("lcb","ZAG E","defender",if five then .29 else .36,2,{"ZAG"}),
		slot("rcb","ZAG D","defender",if five then .71 else .64,2,{"ZAG"}),
		slot("rb","LD","fullback",.93,2,{"LD"}),
	}
	if five then table.insert(slots,slot("cb","ZAG","defender",.5,2,{"ZAG"})) end
	return slots
end
local function extend(base, extra)
	for _, item in ipairs(extra) do table.insert(base,item) end
	return base
end
formation("4-3-3","4–3–3",4,extend(back(false),{
	slot("dm","VOL","holding",.5,3,{"VOL","MC"}),
	slot("lcm","MC E","midfielder",.23,3,{"MC","MEI","VOL"}),
	slot("rcm","MC D","midfielder",.77,3,{"MC","MEI","VOL"}),
	slot("lw","PE","winger",.12,4,{"PE","MEI"}),
	slot("st","ATA","forward",.5,4,{"ATA"}),
	slot("rw","PD","winger",.88,4,{"PD","MEI"}),
}))
formation("4-2-3-1","4–2–3–1",5,extend(back(false),{
	slot("ldm","VOL E","holding",.32,3,{"VOL","MC"}),
	slot("rdm","VOL D","holding",.68,3,{"VOL","MC"}),
	slot("lam","MEI E","winger",.16,4,{"PE","MEI"}),
	slot("am","MEI","creator",.5,4,{"MEI","MC"}),
	slot("ram","MEI D","winger",.84,4,{"PD","MEI"}),
	slot("st","ATA","forward",.5,5,{"ATA"}),
}))
formation("4-3-2-1","4–3–2–1",5,extend(back(false),{
	slot("dm","VOL","holding",.5,3,{"VOL","MC"}),
	slot("lcm","MC E","midfielder",.23,3,{"MC","VOL"}),
	slot("rcm","MC D","midfielder",.77,3,{"MC","VOL"}),
	slot("lam","MEI E","creator",.33,4,{"MEI","PE"}),
	slot("ram","MEI D","creator",.67,4,{"MEI","PD"}),
	slot("st","ATA","forward",.5,5,{"ATA"}),
}))
formation("5-4-1","5–4–1",4,extend(back(true),{
	slot("lm","ME E","winger",.08,3,{"PE","MEI"}),
	slot("lcm","MC E","midfielder",.36,3,{"MC","VOL","MEI"}),
	slot("rcm","MC D","midfielder",.64,3,{"MC","VOL","MEI"}),
	slot("rm","ME D","winger",.92,3,{"PD","MEI"}),
	slot("st","ATA","forward",.5,4,{"ATA"}),
}))
-- Keep the previously available shape, with an actual third center-back.
formation("3-5-2","3–5–2",4,{
	slot("gk","GOL","keeper",.5,1,{"GOL"}),
	slot("lcb","ZAG E","defender",.22,2,{"ZAG"}),
	slot("cb","ZAG","defender",.5,2,{"ZAG"}),
	slot("rcb","ZAG D","defender",.78,2,{"ZAG"}),
	slot("lb","ALA E","fullback",.05,3,{"LE"}),
	slot("lcm","MC E","midfielder",.28,3,{"MC","MEI"}),
	slot("dm","VOL","holding",.5,3,{"VOL","MC"}),
	slot("rcm","MC D","midfielder",.72,3,{"MC","MEI"}),
	slot("rb","ALA D","fullback",.95,3,{"LD"}),
	slot("lst","ATA E","forward",.34,4,{"ATA","PE"}),
	slot("rst","ATA D","forward",.66,4,{"ATA","PD"}),
})
C.formationOrder = {"4-3-3","4-2-3-1","4-3-2-1","5-4-1","3-5-2"}
C.legacyFormations = {"4-3-3","4-2-3-1","3-5-2"}
C.behaviors = {
	defend={id="defend",label="Defender",advance=-.025,pressure=-.1},
	balanced={id="balanced",label="Equilibrado",advance=0,pressure=0},
	attack={id="attack",label="Atacar",advance=.03,pressure=.1},
}
C.roles = {
	keeper={label="Goleiro",behaviors={"defend","balanced"},advance=0,spread=0,pressure=0},
	sweeper={label="Goleiro líbero",behaviors={"balanced"},advance=.025,spread=0,pressure=0},
	defender={label="Defensor",behaviors={"defend","balanced"},advance=0,spread=0,pressure=0},
	ball_defender={label="Construtor",behaviors={"defend","balanced"},advance=.018,spread=.02,pressure=0},
	fullback={label="Lateral",behaviors={"defend","balanced"},advance=.015,spread=.02,pressure=0},
	wingback={label="Lateral ofensivo",behaviors={"balanced","attack"},advance=.065,spread=.06,pressure=.1},
	holding={label="Volante",behaviors={"defend","balanced"},advance=-.025,spread=-.04,pressure=0},
	deep_playmaker={label="Organizador",behaviors={"defend","balanced"},advance=-.01,spread=-.02,pressure=0},
	box_to_box={label="Meia de área",behaviors={"balanced","attack"},advance=.025,spread=0,pressure=.1},
	playmaker={label="Armador",behaviors={"balanced","attack"},advance=.025,spread=-.06,pressure=0},
	winger={label="Ponta",behaviors={"balanced","attack"},advance=.035,spread=.08,pressure=.05},
	inside_forward={label="Ponta interior",behaviors={"balanced","attack"},advance=.045,spread=-.12,pressure=.05},
	striker={label="Atacante",behaviors={"balanced","attack"},advance=.035,spread=0,pressure=0},
	target={label="Pivô",behaviors={"balanced","attack"},advance=-.02,spread=0,pressure=-.05},
}
C.groupRoles = {
	keeper={"keeper","sweeper"},defender={"defender","ball_defender"},
	fullback={"fullback","wingback"},holding={"holding","deep_playmaker"},
	midfielder={"box_to_box","playmaker","holding"},creator={"playmaker","inside_forward"},
	winger={"winger","inside_forward"},forward={"striker","target"},
}
C.options = {
	buildUp={
		{id="balanced",label="Equilibrada",advance=0,tempo=.5,support=.5},
		{id="short",label="Passe curto",advance=-.018,tempo=.3,support=.85},
		{id="direct",label="Transição direta",advance=.025,tempo=.85,support=.3},
	},
	pressure={
		{id="low",label="Bloco baixo",advance=-.035,intensity=.25},
		{id="medium",label="Bloco médio",advance=0,intensity=.5},
		{id="high",label="Pressão alta",advance=.035,intensity=.85},
	},
	mentality={
		{id="cautious",label="Cautelosa",advance=-.02,risk=.25},
		{id="balanced",label="Equilibrada",advance=0,risk=.5},
		{id="attacking",label="Ofensiva",advance=.02,risk=.8},
	},
}
C.presets = {
	{id="balanced",label="Equilíbrio",shortDescription="Apoios e proteção entre setores.",description="Apoios próximos e proteção distribuída entre os setores.",buildUp="balanced",pressure="medium",mentality="balanced",width=55,line=50},
	{id="possession",label="Controle da bola",shortDescription="Passe curto e bloco adiantado.",description="Passe curto, apoios por dentro e bloco adiantado.",buildUp="short",pressure="medium",mentality="balanced",width=45,line=65},
	{id="counter",label="Transição rápida",shortDescription="Bloco baixo e passes profundos.",description="Recupere em bloco baixo e procure a profundidade.",buildUp="direct",pressure="low",mentality="cautious",width=65,line=30},
	{id="press",label="Pressão coordenada",shortDescription="Pressão alta; espaço nas costas.",description="Encurte o campo e pressione alto. Atenção ao espaço atrás.",buildUp="direct",pressure="high",mentality="attacking",width=60,line=80},
}
return C
