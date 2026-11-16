--!nonstrict
-- Match registration is separate from the club roster and from tactical rules.
-- No pixels, account IDs, network calls, persistence or simulated results.
local T=require(script.Parent.TacticsModel)
local Catalog=require(script.Parent.TacticsCatalog)
local TacticsSession=require(script.Parent.TacticsSession)
local M={version=1}
local Session={}
Session.__index=Session

function M.starters(tactic)
	local ids={}
	for _,entry in pairs(tactic.positions or {}) do ids[entry.playerId]=true end
	return ids
end
local function eligible(player)
	if not player or player.available==false then return false end
	for _,formation in pairs(Catalog.formations) do
		for _,slot in ipairs(formation.slots) do if T.compatible(player,slot) then return true end end
	end
	return false
end
function M.validate(tactic,benchIds,roster)
	local valid,err=T.validate(tactic,roster)
	if not valid then return false,err end
	if type(benchIds)~="table" then return false,"Inscreva cinco reservas." end
	local count=0
	for key in pairs(benchIds) do
		if type(key)~="number" or key%1~=0 or key<1 or key>5 then return false,"Lista de reservas inválida." end
		count+=1
	end
	if count~=5 then return false,"Inscreva exatamente cinco reservas." end
	local seen=M.starters(tactic)
	for i=1,5 do
		local id=benchIds[i]
		if seen[id] then return false,"Um atleta não pode ocupar duas vagas na partida." end
		if not eligible(T.player(roster,id)) then return false,"Reserva sem posição válida ou indisponível." end
		seen[id]=true
	end
	return true
end
-- Keep valid registrations after a tactical change. Fill vacant places in stable
-- roster-ID order, preferring one backup goalkeeper. Never changes the tactic.
function M.reconcile(tactic,previous,roster)
	local seen=M.starters(tactic)
	local bench={}
	local function add(id)
		if #bench<5 and not seen[id] and eligible(T.player(roster,id)) then
			seen[id]=true;table.insert(bench,id)
		end
	end
	for _,id in ipairs(previous or {}) do add(id) end
	local candidates=table.clone(roster)
	table.sort(candidates,function(a,b)
		if (a.position=="GOL")~=(b.position=="GOL") then return a.position=="GOL" end
		return a.id<b.id
	end)
	for _,player in ipairs(candidates) do add(player.id) end
	return bench
end
function M.ready(state,roster)
	local active=state.tacticalPlan and state.tacticalPlan.active
	local preparation=state.matchPreparation
	if not active or not preparation or not preparation.receipt then return false end
	return M.validate(active,preparation.benchIds,roster)
		and preparation.clubId==state.homeClub
		and T.equal(preparation.receipt.tactic,active)
		and T.equal(preparation.receipt.benchIds,preparation.benchIds)
end
-- Frozen-by-copy payload for Stage 03. Callers cannot mutate confirmed state.
function M.export(state,roster)
	if not M.ready(state,roster) then return nil,"Confirme a escalação atual antes de preparar a partida." end
	return {version=M.version,clubId=state.homeClub,tactic=T.copy(state.tacticalPlan.active),
		benchIds=T.copy(state.matchPreparation.benchIds)}
end
function M.new(state,roster)
	local tactics,err=TacticsSession.new(state,roster)
	if not tactics then return nil,err end
	local valid,reason=T.validate(state.tacticalPlan.active,roster)
	if not valid then return nil,reason end
	local previous=state.matchPreparation
	local bench=M.reconcile(state.tacticalPlan.active,previous and previous.benchIds,roster)
	-- Reconciliation is only a draft until explicit confirmation.
	return setmetatable({state=state,roster=roster,base=T.copy(state.tacticalPlan.active),
		clubId=state.homeClub,baseBench=T.copy(bench),tactic=T.copy(state.tacticalPlan.active),benchIds=bench},Session)
end
function Session:dirty()
	return not T.equal(self.tactic,self.base) or not T.equal(self.benchIds,self.baseBench)
end
function Session:cancel()
	self.tactic=T.copy(self.base);self.benchIds=T.copy(self.baseBench)
end
function Session:candidates()
	local used=M.starters(self.tactic)
	for _,id in ipairs(self.benchIds) do used[id]=true end
	local result={}
	for _,player in ipairs(self.roster) do
		if not used[player.id] and eligible(player) then table.insert(result,player) end
	end
	table.sort(result,function(a,b) return a.id<b.id end)
	return result
end
function Session:register(index,playerId)
	if type(index)~="number" or index%1~=0 or index<1 or index>5 then return false,"Vaga de reserva inválida." end
	local allowed=false
	for _,p in ipairs(self:candidates()) do if p.id==playerId then allowed=true end end
	if not allowed then return false,"Atleta indisponível ou já inscrito." end
	local bench=T.copy(self.benchIds);bench[index]=playerId
	-- Partial lists may be filled, but confirming still requires all five places.
	self.benchIds=bench
	return true
end
function Session:swap(slotId,benchIndex)
	local playerId=self.benchIds[benchIndex]
	local entry=self.tactic.positions[slotId]
	if not playerId or not entry then return false,"Selecione um titular e um reserva." end
	local oldId=entry.playerId
	local candidate=T.copy(self.tactic)
	local ok,err=T.replacePlayer(candidate,slotId,playerId,self.roster)
	if not ok then return false,err end
	local bench=T.copy(self.benchIds);bench[benchIndex]=oldId
	ok,err=M.validate(candidate,bench,self.roster)
	if not ok then return false,err end
	self.tactic,self.benchIds=candidate,bench
	return true
end
function Session:confirm()
	if self.clubId~=self.state.homeClub or not T.equal(self.base,self.state.tacticalPlan.active) then
		return false,"A tática ou o clube mudou. Reabra a preparação para atualizar a lista."
	end
	local ok,err=M.validate(self.tactic,self.benchIds,self.roster)
	if not ok then return false,err end
	self.state.tacticalPlan.active=T.copy(self.tactic)
	self.state.matchPreparation={version=M.version,clubId=self.clubId,benchIds=T.copy(self.benchIds),
		receipt={tactic=T.copy(self.tactic),benchIds=T.copy(self.benchIds)}}
	self.base=T.copy(self.tactic);self.baseBench=T.copy(self.benchIds)
	return true
end
return M
