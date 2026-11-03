--!strict
-- CL 27: nova tela de carregamento translucida e silenciosa.
-- O fundo permanece visivel sob uma pelicula discreta. Os quatro tracos
-- formam um monograma CL autoral de 32 px, sem assets de terceiros.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local TransitionFX = {}
TransitionFX.MINIMUM_SECONDS = 2.5
TransitionFX.ENTER_SECONDS = 0.26
TransitionFX.EXIT_SECONDS = 0.26

local function make(className: string, parent: Instance, properties)
	local node = Instance.new(className)
	for key, value in pairs(properties) do
		(node :: any)[key] = value
	end
	node.Parent = parent
	return node
end

local function stroke(parent: Instance, number: number, position: UDim2, width: number, rotation: number)
	-- Container rotacionado. Aureola externa + luz verde + nucleo claro.
	local group = make("CanvasGroup", parent, {
		Name = string.format("SegmentoCL_%02d", number),
		Position = position,
		Size = UDim2.fromOffset(width, 12),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = rotation,
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		ZIndex = 5,
	})
	make("Frame", group, {
		Name = "AuraDifusa",
		Position = UDim2.fromScale(0, 0.05),
		Size = UDim2.fromScale(1, 0.9),
		BackgroundColor3 = Color3.fromRGB(35, 207, 87),
		BackgroundTransparency = 0.86,
		BorderSizePixel = 0,
		ZIndex = 5,
	})
	make("Frame", group, {
		Name = "LuzVerde",
		Position = UDim2.new(0, 1, 0.5, -2.3),
		Size = UDim2.new(1, -2, 0, 4.6),
		BackgroundColor3 = Color3.fromRGB(69, 243, 127),
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		ZIndex = 6,
	})
	make("Frame", group, {
		Name = "NucleoClaro",
		Position = UDim2.new(0, 2, 0.5, -0.8),
		Size = UDim2.new(1, -4, 0, 1.6),
		BackgroundColor3 = Color3.fromRGB(196, 255, 213),
		BackgroundTransparency = 0.10,
		BorderSizePixel = 0,
		ZIndex = 7,
	})
	return group
end

function TransitionFX.start(playerGui: Instance)
	local gui = make("ScreenGui", playerGui, {
		Name = "CL27_TransitionHUD",
		DisplayOrder = 150,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Enabled = true,
	})
	local veil = make("CanvasGroup", gui, {
		Name = "Transicao",
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(5, 13, 15),
		BackgroundTransparency = 0.57,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		ClipsDescendants = false,
		Visible = false,
		Active = true,
		ZIndex = 1,
	})
	-- CL fixo em relacao a tela; nao e filho da Camera nem de um WorldGui.
	local emblem = make("Frame", veil, {
		Name = "IndicadorCL",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -36),
		Size = UDim2.fromOffset(32, 32),
		BackgroundTransparency = 1,
		ZIndex = 4,
	})
	local strokes = {
		stroke(emblem, 1, UDim2.fromOffset(10, 10), 18, -43),
		stroke(emblem, 2, UDim2.fromOffset(10, 22), 18, 43),
		stroke(emblem, 3, UDim2.fromOffset(22, 16), 23, -55),
		stroke(emblem, 4, UDim2.fromOffset(25, 27), 12, 0),
	}

	local alive = true
	local active = false
	local reduced = false
	local elapsed = 0
	local accumulator = 0
	local fades = {}
	local function stopFades()
		for _, tween in ipairs(fades) do tween:Cancel() end
		table.clear(fades)
	end
	local function fade(to: number, duration: number)
		local tween = TweenService:Create(veil, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			GroupTransparency = to,
		})
		table.insert(fades, tween)
		tween:Play()
	end
	-- Anima apenas as quatro opacidades (sem dezenas de tweens por ciclo).
	local connection = RunService.Heartbeat:Connect(function(dt)
		if not alive or not active or reduced then return end
		accumulator += math.min(math.max(dt, 0), 0.10)
		if accumulator < 1 / 30 then return end
		elapsed += accumulator
		accumulator = 0
		local cycle = (elapsed % 1.28) / 1.28
		local bloom = 0.85 + 0.15 * math.sin(elapsed * 4.8)
		for index, segment in ipairs(strokes) do
			-- Cada risco emerge em ordem; a marca completa brilha
			-- brevemente antes de se apagar para recomecar o desenho.
			local startAt = (index - 1) * 0.135
			local drawn = math.clamp((cycle - startAt) / 0.18, 0, 1)
			local fadeOut = 1 - math.clamp((cycle - 0.76) / 0.22, 0, 1)
			segment.GroupTransparency = 1 - drawn * fadeOut * bloom
		end
	end)

	return {
		gui = gui,
		layer = veil,
		emblem = emblem,
		Cover = function(_, reducedMotion: boolean)
			if not alive then return 0 end
			stopFades()
			active = true
			reduced = reducedMotion == true
			elapsed, accumulator = 0, 0
			veil.Visible = true
			veil.GroupTransparency = 1
			for _, segment in ipairs(strokes) do
				segment.GroupTransparency = if reduced then 0 else 1
			end
			local duration = if reduced then 0.15 else TransitionFX.ENTER_SECONDS
			fade(0, duration)
			return duration
		end,
		Reveal = function(_, reducedMotion: boolean)
			if not alive then return 0 end
			stopFades()
			local duration = if reducedMotion then 0.15 else TransitionFX.EXIT_SECONDS
			fade(1, duration)
			return duration
		end,
		Finish = function()
			if not alive then return end
			stopFades()
			active = false
			veil.GroupTransparency = 1
			veil.Visible = false
		end,
		Destroy = function()
			if not alive then return end
			alive = false
			active = false
			stopFades()
			connection:Disconnect()
			gui:Destroy()
		end,
	}
end

return TransitionFX
