-- Testes do ciclo de vida; TweenService é um double, sem renderização.
return function(Scope, TweenService, signal)
	local checks = 0
	local function check(condition, message)
		checks += 1
		assert(condition, message)
	end
	local settings = { reducedMotion = false }
	local scope = Scope.new(settings)
	local event = signal()
	local called = 0
	scope:connect(event, function(value) called += value end)
	event:Fire(3)
	check(called == 3, "Evento ativo precisa executar")
	for _ = 1, 100 do
		local tween = scope:tween({}, {Transparency = 0}, .1)
		check(scope.tweens[tween] ~= nil, "Tween em execução precisa estar registrado")
		tween.Completed:Fire()
		check(scope.tweens[tween] == nil, "Tween concluído não pode ficar retido")
	end
	check(#scope.cleanups == 1, "Hover não pode acumular cleanups de tweens concluídos")
	local first = scope:tween({}, {X = 1})
	local second = scope:tween({}, {X = 2})
	local cleaned = 0
	scope:add(function() cleaned += 1 end)
	scope:destroy()
	check(not scope.alive and cleaned == 1, "Destruição deve executar cleanup")
	check(first.canceled and second.canceled, "Destruição deve cancelar tweens em execução")
	check(next(scope.tweens) == nil and #scope.cleanups == 0, "Escopo deve liberar registros")
	event:Fire(10)
	check(called == 3, "Eventos não podem executar após sair da tela")
	check(scope:tween({}, {X = 3}) == nil, "Escopo destruído não pode criar tween")
	scope:destroy()
	check(cleaned == 1, "Destruição deve ser idempotente")
	scope:add(function() cleaned += 1 end)
	check(cleaned == 2, "Cleanup adicionado após destruição precisa executar imediatamente")
	local reduced = Scope.new({reducedMotion=true})
	local object = {X = 0}
	local before = TweenService.created
	check(reduced:tween(object, {X=4}) == nil and object.X == 4, "Movimento reduzido deve aplicar estado final")
	check(TweenService.created == before, "Movimento reduzido não pode criar tween")
	reduced:destroy()
	print("Scope lifecycle checks passed: " .. checks .. " (mock TweenService; not Studio)")
end
