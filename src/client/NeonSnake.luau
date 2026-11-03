--!strict
-- CL 27: tracos vetoriais e uma luz verde que percorre continuamente
-- a borda das letras CL e das capsulas verdes. Nenhum asset externo.
local NeonSnake = {}
local WHITE = Color3.fromRGB(237, 255, 240)
local GREEN = Color3.fromRGB(64, 255, 111)
local HALO = Color3.fromRGB(29, 230, 75)

local function node(className: string, parent: Instance, properties)
	local object = Instance.new(className)
	for k, v in pairs(properties) do (object :: any)[k] = v end
	object.Parent = parent
	return object
end

local function rounded(parent: Instance, name: string, width: number, height: number, color: Color3, transparency: number, z: number)
	local part = node("Frame", parent, {
		Name = name, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, height),
		BackgroundColor3 = color, BackgroundTransparency = transparency,
		BorderSizePixel = 0, ZIndex = z,
	})
	node("UICorner", part, {CornerRadius = UDim.new(1, 0)})
	return part
end

local function makeDot(parent: Instance, index: number)
	local group = node("Frame", parent, {
		Name = "CobraLuz_" .. tostring(index),
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(14, 14),
		ZIndex = 13,
	})
	local aura = rounded(group, "AuraVerde", 14, 14, HALO, 0.89, 13)
	local inner = rounded(group, "CorpoNeon", 7, 7, GREEN, 0.34, 14)
	local head = rounded(group, "NucleoBranco", 3, 3, WHITE, 0.06, 15)
	return {group=group, aura=aura, inner=inner, head=head}
end

-- Traçado intencionalmente inclinado, aproximando a silhueta da
-- referência CL 27: C aberto à direita, L com haste diagonal e base.
-- Coordenadas locais em uma tela de 32x32.
NeonSnake.CL_PATHS = {
	{Vector2.new(15, 5), Vector2.new(8, 5)},
	{Vector2.new(8, 5), Vector2.new(2.6, 23.4)},
	{Vector2.new(2.6, 23.4), Vector2.new(14, 23.4)},
	{Vector2.new(24, 5), Vector2.new(16.3, 23.4)},
	{Vector2.new(16.3, 23.4), Vector2.new(29, 23.4)},
}

local function pointOnLines(lines, fraction: number)
	local total = 0
	for _, line in ipairs(lines) do total += (line[2] - line[1]).Magnitude end
	local walk = (fraction % 1) * total
	for _, line in ipairs(lines) do
		local length = (line[2] - line[1]).Magnitude
		if walk <= length then return line[1]:Lerp(line[2], if length > 0 then walk / length else 0) end
		walk -= length
	end
	return lines[#lines][2]
end

function NeonSnake.newCL(parent: Instance)
	local mark = node("Frame", parent, {
		Name = "MarcaCLNeon", Size = UDim2.fromOffset(32, 32),
		BackgroundTransparency = 1, ZIndex = 7,
	})
	local segments = {}
	for i, line in ipairs(NeonSnake.CL_PATHS) do
		local dx = line[2] - line[1]
		local midpoint = (line[1] + line[2]) * 0.5
		local holder = node("Frame", mark, {
			Name = string.format("TracoCL_%02d", i),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(midpoint.X, midpoint.Y),
			Size = UDim2.fromOffset(dx.Magnitude, 12),
			Rotation = math.deg(math.atan2(dx.Y, dx.X)),
			BackgroundTransparency = 1, ZIndex = 7,
		})
		rounded(holder, "AuraDifusa", dx.Magnitude, 10, HALO, 0.92, 7)
		rounded(holder, "HaloNeon", dx.Magnitude, 5.5, GREEN, 0.66, 8)
		rounded(holder, "NucleoCL", dx.Magnitude, 2.8, WHITE, 0.25, 9)
		segments[i] = holder
	end
	local dots = {}
	for i = 1, 6 do dots[i] = makeDot(mark, i) end
	local self = {mark=mark, segments=segments, dots=dots}
	function self:Step(time: number)
		local progress = (time * 0.43) % 1
		for i, particle in ipairs(dots) do
			local trail = (i - 1) * 0.021
			local where = pointOnLines(NeonSnake.CL_PATHS, progress - trail)
			particle.group.Position = UDim2.fromOffset(where.X, where.Y)
			particle.aura.BackgroundTransparency = 0.83 + (i - 1) * 0.028
			particle.inner.BackgroundTransparency = 0.10 + (i - 1) * 0.13
			particle.head.BackgroundTransparency = math.min(1, 0.02 + (i - 1) * 0.19)
		end
	end
	function self:SetReducedMotion(reduced: boolean)
		for _, p in ipairs(dots) do p.group.Visible = not reduced end
	end
	function self:Destroy() mark:Destroy() end
	return self
end

-- Percurso contínuo no contorno de uma cápsula arredondada.
-- Arcos parametrizados evitam luz atravessando o centro do botão X.
local function capsulePoint(width: number, height: number, fraction: number): Vector2
	local margin = 3
	local left, right = margin, width - margin
	local top, bottom = margin, height - margin
	local radius = (bottom - top) / 2
	local cxL, cxR = left + radius, right - radius
	local straight = math.max(1, cxR - cxL)
	local arc = math.pi * radius
	local perimeter = straight * 2 + arc * 2
	local distance = (fraction % 1) * perimeter
	if distance < straight then return Vector2.new(cxL + distance, top) end
	distance -= straight
	if distance < arc then
		local angle = -math.pi / 2 + distance / radius
		return Vector2.new(cxR + math.cos(angle) * radius, height / 2 + math.sin(angle) * radius)
	end
	distance -= arc
	if distance < straight then return Vector2.new(cxR - distance, bottom) end
	distance -= straight
	local angle = math.pi / 2 + distance / radius
	return Vector2.new(cxL + math.cos(angle) * radius, height / 2 + math.sin(angle) * radius)
end

function NeonSnake.newCapsule(button: Instance)
	local guide = node("Frame", button, {
		Name = "CobraNeonCapsula", Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, ZIndex = 10,
		ClipsDescendants = false,
	})
	local dots = {}
	for i = 1, 6 do dots[i] = makeDot(guide, i) end
	local self = {guide=guide, dots=dots}
	function self:Step(time: number)
		local abs = (button :: any).AbsoluteSize
		local width = if typeof(abs) == "Vector2" and abs.X > 0 then abs.X else 230
		local height = if typeof(abs) == "Vector2" and abs.Y > 0 then abs.Y else 56
		for i, p in ipairs(dots) do
			local pos = capsulePoint(width, height, (time * 0.20) - (i - 1) * 0.014)
			p.group.Position = UDim2.fromOffset(pos.X, pos.Y)
			p.aura.BackgroundTransparency = 0.82 + (i - 1) * 0.03
			p.inner.BackgroundTransparency = math.min(1, 0.05 + (i - 1) * 0.15)
			p.head.BackgroundTransparency = math.min(1, 0.05 + (i - 1) * 0.19)
		end
	end
	function self:SetReducedMotion(reduced: boolean)
		for _, p in ipairs(dots) do p.group.Visible = not reduced end
	end
	function self:Destroy() guide:Destroy() end
	return self
end

return NeonSnake
