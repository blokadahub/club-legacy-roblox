--!strict
-- CL 27: carregamento CL com brilho branco suave varrendo as arestas das letras.
-- O cenário permanece visível e o símbolo continua fixo ao rodapé.
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local OuterGlowSweep = require(script.Parent.OuterGlowSweep)

local TransitionFX = {}
TransitionFX.MINIMUM_SECONDS = 2.5
TransitionFX.ENTER_SECONDS = 0.26
TransitionFX.EXIT_SECONDS = 0.26

local function make(className: string, parent: Instance, props)
	local object = Instance.new(className)
	for key, value in pairs(props) do (object :: any)[key] = value end
	object.Parent = parent
	return object
end

function TransitionFX.start(playerGui: Instance)
	local gui = make("ScreenGui", playerGui, {
		Name = "CL27_TransitionHUD", DisplayOrder = 150, IgnoreGuiInset = true,
		ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	local veil = make("CanvasGroup", gui, {
		Name = "Transicao", Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(5, 13, 15),
		BackgroundTransparency = 0.57, BorderSizePixel = 0,
		GroupTransparency = 1, ClipsDescendants = false,
		Visible = false, Active = true, ZIndex = 1,
	})
	local emblem = make("Frame", veil, {
		Name = "IndicadorCL",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -36),
		Size = UDim2.fromOffset(32, 32),
		BackgroundTransparency = 1, ZIndex = 7,
	})
	local letterFX = OuterGlowSweep.newCL(emblem)
	-- Indicador de espera continuo: separado do véu escuro e sem interceptar toque.
	-- O monograma é o MESMO da transição, nunca uma segunda cópia animada.
	local ambient = make("Frame", gui, {
		Name = "CarregamentoContinuo",
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Active = false, Visible = false, ZIndex = 2,
	})
	local persistent, persistentReduced = false, false
	local alive, active, reduced = true, false, false
	local elapsed, accumulator = 0, 0
	local tweens: {Tween} = {}
	local function cancel()
		for _, tween in ipairs(tweens) do tween:Cancel() end
		table.clear(tweens)
	end
	local function fade(transparency: number, duration: number)
		local tween = TweenService:Create(veil,
			TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{GroupTransparency = transparency})
		table.insert(tweens, tween)
		tween:Play()
	end
	local connection = RunService.Heartbeat:Connect(function(dt)
		if not alive or not active or reduced then return end
		accumulator += math.min(math.max(dt, 0), 0.1)
		if accumulator < (1 / 30) then return end
		elapsed += accumulator
		accumulator = 0
		letterFX:Step(elapsed)
	end)
	return {
		gui = gui, layer = veil, emblem = emblem,
		Cover = function(_, reducedMotion: boolean)
			if not alive then return 0 end
			cancel()
			ambient.Visible = false
			emblem.Parent = veil
			active = true
			reduced = reducedMotion == true
			elapsed, accumulator = 0, 0
			veil.Visible = true
			veil.GroupTransparency = 1
			letterFX:SetReducedMotion(reduced)
			if not reduced then letterFX:Step(0) end
			local duration = if reduced then 0.15 else TransitionFX.ENTER_SECONDS
			fade(0, duration)
			return duration
		end,
		Reveal = function(_, reducedMotion: boolean)
			if not alive then return 0 end
			cancel()
			local duration = if reducedMotion then 0.15 else TransitionFX.EXIT_SECONDS
			fade(1, duration)
			return duration
		end,
		Finish = function()
			if not alive then return end
			cancel()
			veil.GroupTransparency = 1
			veil.Visible = false
			if persistent then
				reduced = persistentReduced
				letterFX:SetReducedMotion(reduced)
				emblem.Parent = ambient
				ambient.Visible = true
				active = true
			else
				ambient.Visible = false
				active = false
			end
		end,
		SetPersistentLoading = function(_, enabled: boolean, reducedMotion: boolean)
			if not alive then return end
			persistent = enabled == true
			persistentReduced = reducedMotion == true
			-- A troca de rota ocorre sob o carregamento inicial. Só mostrar
			-- a marca isolada depois que a transição já tiver revelado a cena.
			if not veil.Visible then
				if persistent then
					reduced = persistentReduced
					letterFX:SetReducedMotion(reduced)
					emblem.Parent = ambient
					ambient.Visible = true
					active = true
				else
					ambient.Visible = false
					emblem.Parent = veil
					active = false
				end
			end
		end,
		Destroy = function()
			if not alive then return end
			alive = false
			active = false
			cancel()
			connection:Disconnect()
			letterFX:Destroy()
			gui:Destroy()
		end,
	}
end

return TransitionFX
