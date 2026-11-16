--!nonstrict
-- Active configuration belongs to App state; draft belongs to this editor visit.
local C=require(script.Parent.TacticsCatalog)
local M=require(script.Parent.TacticsModel)
local Session={}
Session.__index=Session
function Session.new(state,roster)
	state.tacticalPlan=state.tacticalPlan or {}
	local store=state.tacticalPlan
	if not store.active then
		local config,err=M.create(roster,C.legacyFormations[state.formation or 1])
		if not config then return nil,err end
		local old=state.tactics
		if old then
			config.buildUp=({"balanced","short","direct","balanced"})[old.style or 1] or "balanced"
			config.pressure=({"low","medium","high"})[old.pressure or 2] or "medium"
			config.width=math.clamp(math.round((old.width or 55)/5)*5,10,90)
			config.line=math.clamp(math.round((old.depth or 50)/5)*5,10,90)
			config.presetId=M.preset(config).id
		end
		local valid,reason=M.validate(config,roster)
		if not valid then return nil,reason end
		store.active=M.copy(config)
	end
	return setmetatable({store=store,roster=roster,draft=M.copy(store.active)},Session)
end
function Session:dirty() return not M.equal(self.draft,self.store.active) end
function Session:cancel() self.draft=M.copy(self.store.active) end
function Session:save()
	local valid,err=M.validate(self.draft,self.roster)
	if not valid then return false,err end
	self.store.active=M.copy(self.draft)
	return true
end
function Session:formation(id) return M.setFormation(self.draft,id,self.roster) end
function Session:preset(id) return M.applyPreset(self.draft,id) end
function Session:strategy(key,value)
	if key=="width" or key=="line" then
		if type(value)~="number" or value~=value or value%5~=0 or value<10 or value>90 then return false end
	elseif not M.option(key,value) then return false end
	self.draft[key]=value;self.draft.presetId=M.preset(self.draft).id
	return true
end
function Session:role(slotId,roleId)
	local s=M.slot(self.draft,slotId)
	if not s or not table.find(C.groupRoles[s.group],roleId) then return false end
	local e=self.draft.positions[slotId]
	e.roleId=roleId
	if not table.find(C.roles[roleId].behaviors,e.behaviorId) then e.behaviorId=C.roles[roleId].behaviors[1] end
	return true
end
function Session:behavior(slotId,behaviorId)
	local e=self.draft.positions[slotId]
	if not e or not table.find(C.roles[e.roleId].behaviors,behaviorId) then return false end
	e.behaviorId=behaviorId
	return true
end
return Session
