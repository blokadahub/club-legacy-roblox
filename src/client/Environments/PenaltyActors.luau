--!nonstrict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Appearance=require(script.Parent.Parent.AvatarAppearance)
local Rig=require(script.Parent.PenaltyRig)
local Motion=require(script.Parent.PenaltyMotion)
local Actors={}
Actors.__index=Actors
function Actors.new(parent,layout,settings)
	local self=setmetatable({parent=parent,layout=layout,settings=settings or {},alive=true,elapsed=0,rigs={}},Actors)
	self:Load()
	return self
end
function Actors:Status(status,message)
	if not self.alive then return end
	self.parent:SetAttribute("AvatarStatus",status)
	self.parent:SetAttribute("AvatarMessage",message or "")
end
function Actors:Load()
	if not self.alive or self.loading or #self.rigs>0 then return end
	self.loading=true
	self:Status("Loading","Carregando seu avatar Roblox…")
	local generation=(self.generation or 0)+1
	self.generation=generation
	self.timeout=task.delay(15,function()
		self.timeout=nil
		if self.alive and self.loading and self.generation==generation then
			self:Status("Slow","Seu avatar está demorando para carregar. Você pode voltar ao lobby.")
		end
	end)
	self.cancelLoad=Appearance.request(Players.LocalPlayer,function(template,err,warning)
		if not self.alive or self.generation~=generation then if template then template:Destroy() end;return end
		self.loading=false
		if self.timeout then pcall(task.cancel,self.timeout);self.timeout=nil end
		if not template then self:Status("Error",err);return end
		local models={template}
		local ok,problem=pcall(function()
			models[2]=template:Clone()
			for i,role in ipairs({"striker","keeper"}) do
				local model=models[i]
				model.Name=if i==1 then "CobradorR15" else "GoleiroR15"
				local position=if i==1 then self.layout.Striker else self.layout.Keeper
				local rig=Rig.new(model,role,position,self.layout.Ball)
				table.insert(self.rigs,rig)
				rig:Apply(Motion.sample(role,0,nil,0,rig.scale,rig.width,rig.distance),true)
			end
		end)
		if not ok then
			for _,rig in ipairs(self.rigs) do rig:Destroy() end
			for _,model in ipairs(models) do model:Destroy() end
			table.clear(self.rigs)
			Appearance.invalidate(Players.LocalPlayer.UserId)
			self:Status("Error","Não foi possível preparar seu avatar R15. Tente novamente.")
			warn("[CL27/PenaltyActors] "..tostring(problem));return
		end
		-- Both copies already posed before either enters Workspace: no visible T pose.
		for _,rig in ipairs(self.rigs) do rig.model.Parent=self.parent end
		for _,rig in ipairs(self.rigs) do rig:StartTracks() end
		self.connection=RunService.PreSimulation:Connect(function(dt) self:Step(dt) end)
		self:Status("Ready",warning)
	end)
end
function Actors:Step(dt)
	if not self.alive then return end
	self.elapsed+=math.clamp(dt,0,.1)
	if self.action then
		local activeRig=self.rigs[if self.action=="Kick" then 1 else 2]
		self.actionTime+=math.clamp(dt,0,.1)*math.clamp(activeRig.scale,.65,1.2)
		local duration=if self.action=="Kick" then Motion.KickDuration else Motion.DiveDuration
		if self.actionTime>=duration then self.action=nil;self.actionTime=0 end
	end
	for _,rig in ipairs(self.rigs) do
		local clock=if self.settings.reducedMotion and not self.action then 0 else self.elapsed
		rig:Apply(Motion.sample(rig.role,clock,self.action,self.actionTime or 0,rig.scale,rig.width,rig.distance),false)
	end
end
function Actors:Preview(action)
	if not self.alive or #self.rigs~=2 or self.action then return false end
	if action~="Kick" and action~="DiveLeft" and action~="DiveRight" then return false end
	self.action,self.actionTime=action,0
	return true
end
function Actors:ApplySettings(settings) self.settings=settings or self.settings end
function Actors:Destroy()
	if not self.alive then return end
	self.alive=false
	if self.connection then self.connection:Disconnect();self.connection=nil end
	if self.cancelLoad then self.cancelLoad();self.cancelLoad=nil end
	if self.timeout then pcall(task.cancel,self.timeout);self.timeout=nil end
	for _,rig in ipairs(self.rigs) do rig:Destroy() end
	table.clear(self.rigs)
end
return Actors
