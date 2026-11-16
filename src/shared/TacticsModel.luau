--!nonstrict
-- Pure tactical rules. Normalized pitch coordinates: own goal y=1, attack y=0.
local C = require(script.Parent.TacticsCatalog)
export type Instruction = {playerId: number, roleId: string, behaviorId: string}
export type Configuration = {
	version: number, formationId: string, presetId: string,
	buildUp: string, pressure: string, mentality: string, width: number, line: number,
	positions: {[string]: Instruction},
}
local M = {}
function M.copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key,item in pairs(value) do result[key]=M.copy(item) end
	return result
end
function M.equal(a,b)
	if type(a)~=type(b) then return false end
	if type(a)~="table" then return a==b end
	for key,value in pairs(a) do if not M.equal(value,b[key]) then return false end end
	for key in pairs(b) do if a[key]==nil then return false end end
	return true
end
function M.option(key,id)
	for _,entry in ipairs(C.options[key] or {}) do if entry.id==id then return entry end end
	return nil
end
function M.player(roster,id)
	for _,p in ipairs(roster) do if p.id==id then return p end end
	return nil
end
function M.compatible(player,slot)
	return player and player.available~=false and table.find(slot.accepts,player.position)~=nil
end
function M.slot(config,id)
	local f=C.formations[config.formationId]
	if f then for _,s in ipairs(f.slots) do if s.id==id then return s end end end
	return nil
end
-- Deterministic bipartite matching, preserving previous compatible assignments.
-- A greedy first-fit would wrongly reject shapes when a versatile MC blocks a VOL.
function M.lineup(formationId,roster,previous)
	local f=C.formations[formationId]
	if not f then return nil,"Formação desconhecida." end
	local candidates,owners,assigned={},{},{}
	for i,s in ipairs(f.slots) do
		local list={}
		for _,p in ipairs(roster) do if M.compatible(p,s) then table.insert(list,p) end end
		table.sort(list,function(a,b)
			local old=previous and previous[s.id]
			local function rank(p)
				return if old and old.playerId==p.id then 0 else (table.find(s.accepts,p.position) or 99)
			end
			if rank(a)~=rank(b) then return rank(a)<rank(b) end
			return a.id<b.id
		end)
		candidates[i]=list
	end
	local function assign(i,seen)
		for _,p in ipairs(candidates[i]) do
			if not seen[p.id] then
				seen[p.id]=true
				if not owners[p.id] or assign(owners[p.id],seen) then
					owners[p.id]=i;assigned[i]=p.id;return true
				end
			end
		end
		return false
	end
	-- Most constrained slots first, stable tie break.
	local order={}
	for i in ipairs(f.slots) do table.insert(order,i) end
	table.sort(order,function(a,b) return if #candidates[a]==#candidates[b] then a<b else #candidates[a]<#candidates[b] end)
	for _,i in ipairs(order) do
		if not assign(i,{}) then return nil,"Elenco indisponível para "..f.label.." ("..f.slots[i].label..")." end
	end
	local result={}
	for i,s in ipairs(f.slots) do
		local old=previous and previous[s.id]
		local allowed=C.groupRoles[s.group]
		local role=if old and table.find(allowed,old.roleId) then old.roleId else allowed[1]
		local behaviors=C.roles[role].behaviors
		result[s.id]={playerId=assigned[i],roleId=role,behaviorId=if old and table.find(behaviors,old.behaviorId) then old.behaviorId else behaviors[1]}
	end
	return result
end
function M.create(roster,formationId)
	local lineup,err=M.lineup(formationId or "4-3-3",roster)
	if not lineup then return nil,err end
	return {version=C.version,formationId=formationId or "4-3-3",presetId="balanced",
		buildUp="balanced",pressure="medium",mentality="balanced",width=55,line=50,positions=lineup}
end
function M.validate(config,roster)
	if type(config)~="table" or config.version~=C.version then return false,"Versão tática inválida." end
	local f=C.formations[config.formationId]
	if not f or type(config.positions)~="table" then return false,"Formação inválida." end
	local rosterIds={}
	for _,p in ipairs(roster) do
		if type(p.id)~="number" or p.id%1~=0 or rosterIds[p.id] then return false,"IDs do elenco inválidos." end
		rosterIds[p.id]=true
	end
	for _,key in ipairs({"buildUp","pressure","mentality"}) do
		if not M.option(key,config[key]) then return false,"Estratégia inválida: "..key end
	end
	for _,key in ipairs({"width","line"}) do
		local v=config[key]
		if type(v)~="number" or v~=v or v<10 or v>90 or v%5~=0 then return false,"Ajuste fora do intervalo: "..key end
	end
	local knownPreset=config.presetId=="custom"
	for _,preset in ipairs(C.presets) do if preset.id==config.presetId then knownPreset=true end end
	if not knownPreset then return false,"Predefinição inválida." end
	local used,count={},0
	for _ in pairs(config.positions) do count+=1 end
	if count~=11 then return false,"A tática precisa ter onze posições." end
	for _,s in ipairs(f.slots) do
		local entry=config.positions[s.id]
		if type(entry)~="table" or used[entry.playerId] then return false,"Atleta ausente ou repetido." end
		if not M.compatible(M.player(roster,entry.playerId),s) then return false,"Atleta indisponível para "..s.label.."." end
		if not table.find(C.groupRoles[s.group],entry.roleId) then return false,"Função incompatível com "..s.label.."." end
		if not table.find(C.roles[entry.roleId].behaviors,entry.behaviorId) then return false,"Comportamento incompatível." end
		used[entry.playerId]=true
	end
	return true
end
function M.setFormation(config,id,roster)
	local lineup,err=M.lineup(id,roster,config.positions)
	if not lineup then return false,err end
	config.formationId=id;config.positions=lineup
	return true
end
-- Atomic pre-match replacement; instructions belong to the slot and are preserved.
function M.replacePlayer(config,slotId,playerId,roster)
	local valid,err=M.validate(config,roster)
	if not valid then return false,err end
	local slot=M.slot(config,slotId)
	if not slot or not M.compatible(M.player(roster,playerId),slot) then
		return false,"Atleta indisponível ou incompatível com a posição."
	end
	for _,entry in pairs(config.positions) do
		if entry.playerId==playerId then return false,"Este atleta já está entre os titulares." end
	end
	local candidate=M.copy(config)
	candidate.positions[slotId].playerId=playerId
	valid,err=M.validate(candidate,roster)
	if not valid then return false,err end
	config.positions=candidate.positions
	return true
end
function M.applyPreset(config,id)
	for _,p in ipairs(C.presets) do
		if p.id==id then
			for _,key in ipairs({"presetId","buildUp","pressure","mentality","width","line"}) do
				config[key]=if key=="presetId" then p.id else p[key]
			end
			return true
		end
	end
	return false
end
function M.preset(config)
	for _,p in ipairs(C.presets) do
		local same=true
		for _,key in ipairs({"buildUp","pressure","mentality","width","line"}) do if config[key]~=p[key] then same=false end end
		if same then return p end
	end
	return {id="custom",label="Personalizada",description="Uma identidade definida por você. Confira os apoios e os riscos abaixo."}
end
-- A future engine can consume these anchors and explicit numeric intentions.
-- They express shape, never ball simulation, scores or ratings of success.
function M.resolve(config,phase)
	assert(phase=="with_ball" or phase=="without_ball","Fase inválida")
	local f=C.formations[config.formationId]
	local inPossession=phase=="with_ball"
	local build=M.option("buildUp",config.buildUp)
	local press=M.option("pressure",config.pressure)
	local mental=M.option("mentality",config.mentality)
	local result={}
	for _,s in ipairs(f.slots) do
		local e=config.positions[s.id]
		local role,behavior=C.roles[e.roleId],C.behaviors[e.behaviorId]
		local y=.91-(s.row-1)*(.79/(f.rows-1))
		local spread=.78+config.width/250
		local advance=0
		if s.group=="keeper" then
			advance=if inPossession then role.advance else 0
		else
			advance=(config.line-50)/1000+mental.advance
			if inPossession then
				advance+=role.advance+behavior.advance+build.advance*(s.row-1)/(f.rows-1)
				spread+=role.spread
			else
				advance+=press.advance-.045
				spread*=.85
			end
		end
		result[s.id]={slotId=s.id,playerId=e.playerId,x=math.clamp(.5+(s.x-.5)*spread,.04,.96),
			y=math.clamp(y-advance,.055,.94),row=s.row,roleId=e.roleId,behaviorId=e.behaviorId,
			pressIntensity=math.clamp(press.intensity+role.pressure+behavior.pressure,0,1),
			tempo=build.tempo,support=build.support,risk=mental.risk}
	end
	return result
end
function M.indicators(config)
	local advantages,risks={},{}
	local function add(target,id,text) table.insert(target,{id=id,text=text}) end
	if config.buildUp=="short" then
		add(advantages,"short_support","Apoios para passes curtos")
		add(risks,"short_pressure","Saída exposta à pressão rival")
	elseif config.buildUp=="direct" then
		add(advantages,"fast_progress","Progressão rápida em profundidade")
		add(risks,"direct_loss","Mais risco de perder a posse")
	else add(advantages,"balanced_routes","Rotas curtas e longas de passe") end
	if config.pressure=="high" then
		add(advantages,"early_press","Pressão perto da saída rival")
		add(risks,"press_energy","Maior exigência física")
	elseif config.pressure=="low" then
		add(advantages,"deep_cover","Cobertura perto da própria área")
		add(risks,"deep_territory","Menos presença no campo rival")
	end
	if config.line>=70 then add(risks,"behind_line","Espaço nas costas da defesa")
	elseif config.line<=35 and config.pressure=="high" then add(risks,"split_block","Pressão alta distante da defesa") end
	if config.width>=65 then
		add(advantages,"wide_routes","Opções pelos corredores")
		add(risks,"wide_gaps","Distância maior entre apoios")
	elseif config.width<=40 then
		add(advantages,"central_support","Apoios próximos por dentro")
		add(risks,"narrow_routes","Poucas opções abertas")
	end
	if config.mentality=="attacking" then add(advantages,"forward_support","Mais presença ofensiva");add(risks,"counter_space","Menor proteção na transição")
	elseif config.mentality=="cautious" then add(advantages,"rest_defense","Mais proteção atrás da bola");add(risks,"isolated_attack","Menos apoio ao ataque") end
	local attackingBacks=0
	for id,entry in pairs(config.positions) do
		local s=M.slot(config,id)
		if s.group=="fullback" and entry.roleId=="wingback" and entry.behaviorId=="attack" then attackingBacks+=1 end
	end
	if attackingBacks>0 then add(advantages,"overlap","Laterais em ultrapassagem");add(risks,"flank_cover","Cobertura lateral exigida") end
	if #risks==0 then add(risks,"balanced_tradeoff","Estratégia sem especialização") end
	return {advantages=advantages,risks=risks}
end
return M
