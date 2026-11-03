--!strict
-- CL 27 | Loading V2: monograma DL legivel, linhas finas e luz em camadas.
-- O desenho e 100% nativo em GUI: nenhum asset externo nem audio.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local TransitionFX = {}
TransitionFX.MINIMUM_SECONDS = 2.5
TransitionFX.ENTER_SECONDS = 0.26
TransitionFX.EXIT_SECONDS = 0.26

local function make(className: string, parent: Instance, props)
	local node = Instance.new(className)
	for key, value in pairs(props) do (node :: any)[key] = value end
	node.Parent = parent
	return node
end

local MINT = Color3.fromRGB(95, 250, 140)
local PALE = Color3.fromRGB(224, 255, 228)
local GLOW = Color3.fromRGB(31, 235, 96)

local function pill(parent: Instance, name: string, thickness: number, color: Color3, opacity: number, z: number)
	local frame = make("Frame", parent, {
		Name = name, BackgroundColor3 = color, BackgroundTransparency = opacity,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 0, 0, thickness),
		ZIndex = z,
	})
	make("UICorner", frame, { CornerRadius = UDim.new(1, 0) })
	-- Degradê leve evita um retangulo luminoso com as pontas cortadas.
	make("UIGradient", frame, {
		Rotation = 0,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.67),
			NumberSequenceKeypoint.new(0.15, 0.12),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(0.85, 0.12),
			NumberSequenceKeypoint.new(1, 0.67),
		}),
	})
	return frame
end

-- Pontos projetados para formar letras DL, não diagonais aleatórias:
-- D: haste vertical, parte superior, ombro, lado, ombro inferior e base.
-- L: haste vertical e base horizontal.
local GEOMETRY = {
	{4, 5, 4, 27},    -- D / haste
	{4, 5, 11, 5},   -- D / superior
	{11, 5, 17, 11}, -- D / ombro
	{17, 11, 17, 21},-- D / externo
	{17, 21, 11, 27},-- D / ombro inferior
	{11, 27, 4, 27}, -- D / base
	{22, 5, 22, 27}, -- L / haste
	{22, 27, 29, 27},-- L / base
}

local function thinSegment(parent: Instance, number: number, coords)
	local x1, y1, x2, y2 = coords[1], coords[2], coords[3], coords[4]
	local dx, dy = x2 - x1, y2 - y1
	local length = math.sqrt(dx * dx + dy * dy)
	local segment = make("CanvasGroup", parent, {
		Name = string.format("SegmentoDL_%02d", number),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(x1, y1),
		Size = UDim2.fromOffset(0.1, 10),
		Rotation = math.deg(math.atan2(dy, dx)),
		GroupTransparency = 1,
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		ZIndex = 7,
	})
	-- Glow simulado em três camadas macias. A linha visível tem 1,2 px.
	pill(segment, "AuraDifusa", 9, GLOW, 0.95, 7)
	pill(segment, "HaloNeon", 4.2, MINT, 0.78, 8)
	pill(segment, "NucleoClaro", 1.2, PALE, 0.025, 9)
	return {group=segment, x1=x1, y1=y1, dx=dx, dy=dy, length=length}
end

local function orbit(parent: Instance, name: string, diameter: number, thickness: number, transparency: number)
	local circle = make("Frame", parent, {
		Name = name, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(16, 16),
		Size = UDim2.fromOffset(diameter, diameter),
		BackgroundTransparency = 1, ZIndex = 3,
	})
	make("UICorner", circle, {CornerRadius = UDim.new(1, 0)})
	local outline = make("UIStroke", circle, {
		Name = "TracoCircular", Thickness = thickness,
		Color = MINT, Transparency = transparency,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
	local gradient = make("UIGradient", outline, {
		Name = "FendaLuminosa",
		Rotation = 0,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.28, 0.95),
			NumberSequenceKeypoint.new(0.56, 0.11),
			NumberSequenceKeypoint.new(0.79, 0.66),
			NumberSequenceKeypoint.new(1, 1),
		}),
	})
	return circle, outline, gradient
end

function TransitionFX.start(playerGui: Instance)
	local gui = make("ScreenGui", playerGui, {
		Name = "CL27_TransitionHUD", DisplayOrder = 150,
		IgnoreGuiInset = true, ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	local veil = make("CanvasGroup", gui, {
		Name = "Transicao",
		Position = UDim2.fromScale(0, 0), Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(5, 13, 15),
		BackgroundTransparency = 0.57, BorderSizePixel = 0,
		GroupTransparency = 1, ClipsDescendants = false,
		Visible = false, Active = true, ZIndex = 1,
	})
	-- 32px permanecem reservados para a marca, independente de camera e avatar.
	local emblem = make("Frame", veil, {
		Name = "IndicadorDL", AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -36),
		Size = UDim2.fromOffset(32, 32),
		BackgroundTransparency = 1, ZIndex = 5,
	})
	local halo = make("Frame", emblem, {
		Name = "BrilhoDeFundo", AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(38, 38),
		BackgroundTransparency = 0.966, BackgroundColor3 = GLOW,
		BorderSizePixel = 0, ZIndex = 2,
	})
	make("UICorner", halo, {CornerRadius = UDim.new(1, 0)})

	local outer, outerStroke, outerGradient = orbit(emblem, "OrbitaExterna", 69, 0.9, 0.62)
	local inner, innerStroke, innerGradient = orbit(emblem, "OrbitaInterna", 49, 0.75, 0.74)
	local traces = {}
	for index, coords in ipairs(GEOMETRY) do
		traces[index] = thinSegment(emblem, index, coords)
	end
	local sparks = {}
	for i = 1, 3 do
		local spark = make("Frame", emblem, {
			Name = "ParticulaLuminosa_" .. tostring(i),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(16, 16),
			Size = UDim2.fromOffset(if i == 1 then 3.3 else 2.4, if i == 1 then 3.3 else 2.4),
			BackgroundColor3 = PALE, BackgroundTransparency = 1,
			BorderSizePixel = 0, ZIndex = 10,
		})
		make("UICorner", spark, {CornerRadius = UDim.new(1, 0)})
		local sparkGlow = make("Frame", spark, {
			Name = "HaloParticula", AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(8, 8),
			BackgroundColor3 = MINT, BackgroundTransparency = 0.91,
			BorderSizePixel = 0, ZIndex = 9,
		})
		make("UICorner", sparkGlow, {CornerRadius = UDim.new(1, 0)})
		sparks[i] = spark
	end

	local alive, active, reduced = true, false, false
	local elapsed, accumulator = 0, 0
	local tweens = {}
	local function stopFades()
		for _, tween in ipairs(tweens) do tween:Cancel() end
		table.clear(tweens)
	end
	local function fade(goal: number, duration: number)
		local tween = TweenService:Create(veil,
			TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{GroupTransparency = goal})
		table.insert(tweens, tween)
		tween:Play()
	end
	local function drawSegment(segment, t: number, opacity: number)
		local drawn = math.clamp(t, 0, 1)
		segment.group.Size = UDim2.fromOffset(math.max(0.1, segment.length * drawn), 10)
		segment.group.Position = UDim2.fromOffset(
			segment.x1 + segment.dx * drawn * 0.5,
			segment.y1 + segment.dy * drawn * 0.5
		)
		segment.group.GroupTransparency = opacity
	end
	local function render(t: number)
		local cycle = (t % 1.52) / 1.52
		local luminosity = 0.94 + math.sin(t * 4.6) * 0.06
		local disappear = 1 - math.clamp((cycle - 0.82) / 0.16, 0, 1)
		for index, segment in ipairs(traces) do
			local startAt = (index - 1) * 0.070
			local drawn = math.clamp((cycle - startAt) / 0.19, 0, 1)
			local alpha = 1 - drawn * disappear * luminosity
			drawSegment(segment, drawn, alpha)
		end
		-- Movimento orbital lento dos reflexos circulares independentes do DL.
		outerGradient.Rotation = (t * 32) % 360
		innerGradient.Rotation = (360 - (t * 25) % 360) % 360
		outerStroke.Transparency = 0.70 + 0.12 * math.sin(t * 2.2)
		innerStroke.Transparency = 0.78 + 0.11 * math.sin(t * 1.75 + 1)
		halo.BackgroundTransparency = 0.959 + 0.020 * math.sin(t * 3.1)
		for i, spark in ipairs(sparks) do
			local angle = t * (if i == 1 then 1.1 else -0.8) + i * 2.09
			local radius = if i == 1 then 33 else 24
			spark.Position = UDim2.fromOffset(
				16 + math.cos(angle) * radius,
				16 + math.sin(angle) * radius
			)
			spark.BackgroundTransparency = 0.38 + 0.43 * (0.5 + 0.5 * math.sin(t * 4 + i))
		end
	end

	local heartbeat = RunService.Heartbeat:Connect(function(dt)
		if not alive or not active or reduced then return end
		accumulator += math.min(math.max(dt, 0), 0.10)
		if accumulator < 1 / 30 then return end
		elapsed += accumulator
		accumulator = 0
		render(elapsed)
	end)

	return {
		gui = gui, layer = veil, emblem = emblem,
		Cover = function(_, reducedMotion: boolean)
			if not alive then return 0 end
			stopFades()
			active = true
			reduced = reducedMotion == true
			elapsed, accumulator = 0, 0
			veil.Visible = true
			veil.GroupTransparency = 1
			if reduced then
				for _, segment in ipairs(traces) do drawSegment(segment, 1, 0) end
				for _, spark in ipairs(sparks) do spark.BackgroundTransparency = 1 end
			else
				render(0)
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
			heartbeat:Disconnect()
			gui:Destroy()
		end,
	}
end

return TransitionFX
