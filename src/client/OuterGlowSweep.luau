--!strict
-- CL 27 | Animated Outer Glow Sweep
-- Reflexo branco quente concentrado que acompanha uma borda vetorial:
-- núcleo definido + halos em degradê + rastro contínuo e suave.
-- Não utiliza partículas, esferas em fila ou a animação "cobra".
-- GUI do Roblox não possui Gaussian Blur para interfaces; os halos
-- translúcidos com UIGradient aproximam o desfoque sem assets externos.

local OuterGlowSweep = {}

local MINT = Color3.fromRGB(108, 244, 143)
local GREEN = Color3.fromRGB(43, 223, 92)
local LIGHT = Color3.fromRGB(255, 255, 250)
local WARM = Color3.fromRGB(255, 250, 234)
local HAZE = Color3.fromRGB(245, 244, 226)

local function make(kind: string, parent: Instance, props)
	local object = Instance.new(kind)
	for key, value in pairs(props) do (object :: any)[key] = value end
	object.Parent = parent
	return object
end

local function round(parent: Instance, name: string, height: number, color: Color3, alpha: number, z: number)
	local frame = make("Frame", parent, {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = color,
		BackgroundTransparency = alpha,
		BorderSizePixel = 0,
		ZIndex = z,
	})
	make("UICorner", frame, {CornerRadius = UDim.new(1, 0)})
	return frame
end

local SOFT_EDGE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.18, 0.75),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(0.82, 0.75),
	NumberSequenceKeypoint.new(1, 1),
})

local function sweepPiece(parent: Instance, label: string, z: number)
	local group = make("CanvasGroup", parent, {
		Name = label, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(1, 18),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		ClipsDescendants = false,
		ZIndex = z,
	})
	-- As faixas seguem a tangente do contorno; não são luzes circulares.
	local halo = round(group, "HaloExternoSuave", 15, HAZE, 0.87, z)
	make("UIGradient", halo, {Rotation = 90, Transparency = SOFT_EDGE})
	local middle = round(group, "GlowMedio", 7.2, WARM, 0.70, z + 1)
	make("UIGradient", middle, {Rotation = 90, Transparency = SOFT_EDGE})
	round(group, "LinhaBranca", 1.65, LIGHT, 0.035, z + 2)
	return group
end

local function ease01(t: number): number
	local x = math.clamp(t, 0, 1)
	return x * x * (3 - 2 * x)
end

-- A faixa ativa é uma região contínua do perímetro, com ponta difusa
-- e cauda longa que perde intensidade progressivamente.
local function periodicStrength(head: number, position: number): number
	local behind = (head - position + 1) % 1
	if behind < 0.023 then
		return ease01(behind / 0.023)
	end
	if behind < 0.230 then
		return 1 - ease01((behind - 0.023) / 0.207)
	end
	return 0
end

-- A ponta da varredura em linhas abertas desaparece ANTES de reiniciar;
-- não há teleportes de luz entre C e L ou entre o fim e o início.
local function openStrength(head: number, position: number): number
	local behind = head - position
	if behind < -0.025 or behind > 0.25 then return 0 end
	local front = ease01((behind + 0.025) / 0.045)
	local tail = 1 - ease01((behind - 0.025) / 0.225)
	local entry = ease01(head / 0.12)
	local exit = ease01((1 - head) / 0.14)
	return front * tail * entry * exit
end

local CL_STROKES = {
	{Vector2.new(15, 5), Vector2.new(8, 5), "C"},
	{Vector2.new(8, 5), Vector2.new(2.6, 23.4), "C"},
	{Vector2.new(2.6, 23.4), Vector2.new(14, 23.4), "C"},
	{Vector2.new(24, 5), Vector2.new(16.3, 23.4), "L"},
	{Vector2.new(16.3, 23.4), Vector2.new(29, 23.4), "L"},
}

local function poseOnLine(a: Vector2, b: Vector2)
	local delta = b - a
	return (a + b) * 0.5, math.deg(math.atan2(delta.Y, delta.X)), delta.Magnitude
end

function OuterGlowSweep.newCL(parent: Instance)
	local mark = make("Frame", parent, {
		Name = "MarcaCLNeon", Size = UDim2.fromOffset(32, 32),
		BackgroundTransparency = 1, ZIndex = 7,
	})
	local overlay = make("Frame", mark, {
		Name = "VarreduraOuterGlowCL", Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, ClipsDescendants = false, ZIndex = 12,
	})

	local groups = {C = {}, L = {}}
	local sums = {C = 0, L = 0}
	for _, line in ipairs(CL_STROKES) do
		sums[line[3]] += (line[2] - line[1]).Magnitude
	end
	local accumulated = {C = 0, L = 0}
	for index, line in ipairs(CL_STROKES) do
		local center, angle, length = poseOnLine(line[1], line[2])
		local holder = make("Frame", mark, {
			Name = string.format("TracoCL_%02d", index),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(center.X, center.Y),
			Size = UDim2.fromOffset(length, 12),
			Rotation = angle, BackgroundTransparency = 1, ZIndex = 8,
		})
		local aura = round(holder, "AuraDifusa", 9, GREEN, 0.90, 8)
		make("UIGradient", aura, {Rotation = 90, Transparency = SOFT_EDGE})
		round(holder, "HaloNeon", 5.2, MINT, 0.60, 9)
		round(holder, "NucleoCL", 2.8, Color3.fromRGB(222, 255, 226), 0.16, 10)

		local count = math.max(2, math.ceil(length / 3.4))
		for j = 1, count do
			local t = (j - 0.5) / count
			local at = line[1] + (line[2] - line[1]) * t
			local part = sweepPiece(overlay, string.format("SweepCL_%02d_%02d", index, j), 12)
			part.Position = UDim2.fromOffset(at.X, at.Y)
			part.Size = UDim2.fromOffset(length / count + 1.4, 18)
			part.Rotation = angle
			table.insert(groups[line[3]], {
				node = part,
				fraction = (accumulated[line[3]] + length * t) / sums[line[3]],
			})
		end
		accumulated[line[3]] += length
	end

	local self = {mark = mark, overlay = overlay, samples = groups}
	function self:Step(time: number)
		local speed = time / 2.55
		for name, list in pairs(groups) do
			local offset = if name == "L" then 0.16 else 0
			local head = (speed + offset) % 1
			for _, sample in ipairs(list) do
				local power = openStrength(head, sample.fraction)
				sample.node.GroupTransparency = 1 - power
			end
		end
	end
	function self:SetReducedMotion(reduced: boolean)
		overlay.Visible = not reduced
	end
	function self:Destroy()
		mark:Destroy()
	end
	return self
end

-- Perímetro calculado pelo comprimento real de duas semicircunferências
-- e dois trechos retos. O ponto inicial é a região inferior esquerda.
local function pillGeometry(width: number, height: number)
	local margin = 1.3
	local radius = math.max(3, height * 0.5 - margin)
	local cxLeft, cxRight = height * 0.5, width - height * 0.5
	local straight = math.max(1, cxRight - cxLeft)
	local semicircle = math.pi * radius
	return radius, cxLeft, cxRight, straight, semicircle, semicircle * 2 + straight * 2
end

local function pillPose(width: number, height: number, fraction: number): (Vector2, number)
	local r, left, right, straight, arc, length = pillGeometry(width, height)
	local distance = (fraction % 1) * length
	local cy = height * 0.5
	if distance < arc then
		local angle = math.pi / 2 + distance / r
		local point = Vector2.new(left + math.cos(angle) * r, cy + math.sin(angle) * r)
		return point, math.deg(angle + math.pi / 2)
	end
	distance -= arc
	if distance < straight then
		return Vector2.new(left + distance, cy - r), 0
	end
	distance -= straight
	if distance < arc then
		local angle = -math.pi / 2 + distance / r
		return Vector2.new(right + math.cos(angle) * r, cy + math.sin(angle) * r),
			math.deg(angle + math.pi / 2)
	end
	distance -= arc
	return Vector2.new(right - distance, cy + r), 180
end

function OuterGlowSweep.newCapsule(button: Instance)
	local overlay = make("Frame", button, {
		Name = "OuterGlowSweepCapsula",
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = false, ZIndex = 12,
	})
	local samples = {}
	local count = 78
	for i = 1, count do
		local segment = sweepPiece(overlay, string.format("SweepBorda_%02d", i), 12)
		table.insert(samples, {node = segment, fraction = (i - 0.5) / count})
	end
	local previousWidth, previousHeight = -1, -1
	local function resize(width: number, height: number)
		local _, _, _, _, _, perimeter = pillGeometry(width, height)
		local pieceWidth = perimeter / count + 1.6
		for _, sample in ipairs(samples) do
			local position, tangent = pillPose(width, height, sample.fraction)
			sample.node.Position = UDim2.fromOffset(position.X, position.Y)
			sample.node.Size = UDim2.fromOffset(pieceWidth, 18)
			sample.node.Rotation = tangent
		end
		previousWidth, previousHeight = width, height
	end
	local self = {overlay = overlay, samples = samples}
	function self:Step(time: number)
		local size = (button :: any).AbsoluteSize
		local width = if typeof(size) == "Vector2" and size.X > 0 then size.X else 230
		local height = if typeof(size) == "Vector2" and size.Y > 0 then size.Y else 56
		if math.abs(width - previousWidth) > 0.25 or math.abs(height - previousHeight) > 0.25 then
			resize(width, height)
		end
		local head = (time / 4.8) % 1
		for _, sample in ipairs(samples) do
			local power = periodicStrength(head, sample.fraction)
			sample.node.GroupTransparency = 1 - power
		end
	end
	function self:SetReducedMotion(reduced: boolean)
		overlay.Visible = not reduced
	end
	function self:Destroy()
		overlay:Destroy()
	end
	return self
end

return OuterGlowSweep
