--!strict
local TweenService = game:GetService("TweenService")
local Scope = {}
Scope.__index = Scope
function Scope.new()
	return setmetatable({alive = true, cleanups = {}, tweens = {}, delays = {}}, Scope)
end
function Scope:Add(item)
	if not self.alive then
		if typeof(item) == "RBXScriptConnection" then item:Disconnect()
		elseif typeof(item) == "Instance" then item:Destroy()
		elseif type(item) == "function" then item() end
		return item
	end
	table.insert(self.cleanups, item)
	return item
end
function Scope:Connect(signal, fn)
	return self:Add(signal:Connect(function(...)
		if self.alive and not self.inputsPaused then fn(...) end
	end))
end
function Scope:Tween(object, goals, duration)
	if not self.alive or object.Parent == nil then return nil end
	local previous = self.tweens[object]
	if previous then previous:Cancel() end
	local tween = TweenService:Create(object, TweenInfo.new(duration or 0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), goals)
	self.tweens[object] = tween
	tween.Completed:Once(function()
		if self.tweens[object] == tween then self.tweens[object] = nil end
	end)
	tween:Play()
	return tween
end
function Scope:Delay(seconds, fn)
	if not self.alive then return nil end
	local thread
	thread = task.delay(seconds, function()
		self.delays[thread] = nil
		if self.alive then fn() end
	end)
	self.delays[thread] = true
	return thread
end
function Scope:Destroy()
	if not self.alive then return end
	self.alive = false
	for _, tween in pairs(self.tweens) do tween:Cancel() end
	table.clear(self.tweens)
	for thread in pairs(self.delays) do pcall(task.cancel, thread) end
	table.clear(self.delays)
	for i = #self.cleanups, 1, -1 do
		local item = self.cleanups[i]
		if typeof(item) == "RBXScriptConnection" then item:Disconnect()
		elseif typeof(item) == "Instance" then item:Destroy()
		elseif type(item) == "function" then pcall(item) end
	end
	table.clear(self.cleanups)
end
return Scope
