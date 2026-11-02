-- Cada tela possui um escopo. Sair cancela tweens, eventos e tarefas de renderização.
local TweenService = game:GetService("TweenService")
local Scope = {}
Scope.__index = Scope

function Scope.new(settings)
	return setmetatable({ alive = true, cleanups = {}, tweens = {}, settings = settings }, Scope)
end

function Scope:add(cleanup)
	if self.alive then
		table.insert(self.cleanups, cleanup)
	else
		cleanup()
	end
	return cleanup
end

function Scope:connect(signal, callback)
	local connection = signal:Connect(function(...)
		if self.alive then callback(...) end
	end)
	self:add(function() connection:Disconnect() end)
	return connection
end

function Scope:tween(object, properties, duration)
	if not self.alive then return end
	if self.settings.reducedMotion then
		for key, value in pairs(properties) do object[key] = value end
		return
	end
	local tween = TweenService:Create(object, TweenInfo.new(duration or 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), properties)
	local connection
	connection = tween.Completed:Connect(function()
		self.tweens[tween] = nil
		connection:Disconnect()
	end)
	self.tweens[tween] = connection
	tween:Play()
	return tween
end

function Scope:destroy()
	if not self.alive then return end
	self.alive = false
	for tween, connection in pairs(self.tweens) do
		connection:Disconnect()
		tween:Cancel()
	end
	table.clear(self.tweens)
	for index = #self.cleanups, 1, -1 do
		self.cleanups[index]()
	end
	table.clear(self.cleanups)
end

return Scope
