--!strict
-- Iconografia monocromática para os oito cartões de personalização CL 27.
-- Cada desenho é construído com primitivas nativas (sem emojis/Unicode).
local Icons = {}

local function rectangle(parent: Instance, paint, name: string, x: number, y: number, w: number, h: number, color: Color3, rounded: number?, rotation: number?)
	local part = Instance.new("Frame")
	part.Name, part.BorderSizePixel = name, 0
	part.BackgroundColor3 = color
	part.Position = UDim2.fromOffset(x, y)
	part.Size = UDim2.fromOffset(w, h)
	part.Rotation = rotation or 0
	part.Parent = parent
	table.insert(paint, {part, "BackgroundColor3"})
	if rounded and rounded > 0 then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, rounded)
		corner.Parent = part
	end
	return part
end

local function outline(parent: Instance, paint, name: string, x: number, y: number, w: number, h: number, color: Color3, thickness: number, radius: number?)
	local part = Instance.new("Frame")
	part.Name, part.BorderSizePixel = name, 0
	part.BackgroundTransparency = 1
	part.Position, part.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(w, h)
	part.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 0)
	corner.Parent = part
	local border = Instance.new("UIStroke")
	border.Color = color
	border.Thickness = thickness
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Parent = part
	table.insert(paint, {border, "Color"})
	return part
end

local function stroke(parent: Instance, paint, name: string, x: number, y: number, w: number, thickness: number, angle: number, color: Color3)
	local part = rectangle(parent, paint, name, x - w / 2, y - thickness / 2, w, thickness, color, math.ceil(thickness / 2), angle)
	return part
end

local function circle(parent: Instance, paint, name: string, x: number, y: number, diameter: number, color: Color3)
	return rectangle(parent, paint, name, x, y, diameter, diameter, color, diameter / 2)
end

local function gear(parent: Instance, paint, x: number, y: number, radius: number, color: Color3)
	outline(parent, paint, "AnelMecanico", x, y, radius * 2, radius * 2, color, 5, radius)
	for k = 0, 7 do
		local a = math.pi * 2 * k / 8
		local cx = x + radius + math.cos(a) * (radius + 6)
		local cy = y + radius + math.sin(a) * (radius + 6)
		stroke(parent, paint, "Dente" .. tostring(k + 1), cx, cy, 11, 5.2, math.deg(a), color)
	end
	circle(parent, paint, "Pino", x + radius - 5, y + radius - 5, 10, color)
end

function Icons.create(parent: Instance, kind: string, color: Color3)
	local frame = Instance.new("Frame")
	frame.Name = "Icone_" .. kind
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromOffset(100, 100)
	frame.Parent = parent
	local parts = {}
	if kind == "settings" then
		gear(frame, parts, 29, 28, 21, color)
	elseif kind == "profile" then
		outline(frame, parts, "CarteiraIdentificacao", 18, 18, 68, 64, color, 4, 2)
		circle(frame, parts, "RetratoCabeca", 30, 29, 17, color)
		rectangle(frame, parts, "RetratoTronco", 25, 51, 28, 15, color, 7)
		for i = 0, 2 do
			rectangle(frame, parts, "LinhaDados" .. tostring(i), 59, 35 + 13 * i, if i == 1 then 19 else 23, 3, color, 1)
		end
	elseif kind == "online" then
		outline(frame, parts, "Globo", 26, 14, 57, 57, color, 4, 29)
		outline(frame, parts, "Longitude", 42, 14, 24, 57, color, 2, 12)
		stroke(frame, parts, "Equador", 55, 42, 53, 2.5, 0, color)
		stroke(frame, parts, "ParaleloSuperior", 55, 27, 40, 2.5, 0, color)
		stroke(frame, parts, "ParaleloInferior", 55, 58, 40, 2.5, 0, color)
		gear(frame, parts, 6, 61, 12, color)
	elseif kind == "playtime" then
		stroke(frame, parts, "Topo", 51, 17, 57, 6, 0, color)
		stroke(frame, parts, "Base", 51, 78, 57, 6, 0, color)
		stroke(frame, parts, "HasteEsquerdaAlta", 42, 36, 36, 5, 53, color)
		stroke(frame, parts, "HasteDireitaAlta", 60, 36, 36, 5, -53, color)
		stroke(frame, parts, "HasteEsquerdaBaixa", 42, 61, 36, 5, -53, color)
		stroke(frame, parts, "HasteDireitaBaixa", 60, 61, 36, 5, 53, color)
		rectangle(frame, parts, "Areia", 43, 66, 17, 6, color, 2)
	elseif kind == "edit" then
		outline(frame, parts, "CampoEdicao", 15, 25, 67, 48, color, 4, 2)
		stroke(frame, parts, "MeioCampo", 49, 49, 43, 3, 90, color)
		outline(frame, parts, "CirculoCentral", 39, 40, 18, 18, color, 2.5, 9)
		stroke(frame, parts, "Lapis", 72, 63, 49, 9, -44, color)
		stroke(frame, parts, "PontaLapis", 49, 85, 15, 6, -44, color)
	elseif kind == "sheets" then
		outline(frame, parts, "QuadroTatico", 14, 16, 75, 69, color, 4, 2)
		stroke(frame, parts, "Divisao", 52, 50, 68, 3, 90, color)
		outline(frame, parts, "Circulo", 39, 35, 25, 25, color, 2.4, 13)
		for i, point in ipairs({{29,30}, {71,30}, {32,68}, {70,68}, {53,49}}) do
			circle(frame, parts, "Atleta" .. tostring(i), point[1], point[2], 7, color)
		end
	elseif kind == "create" then
		circle(frame, parts, "CabecaJogador", 26, 19, 31, color)
		rectangle(frame, parts, "OmbrosJogador", 15, 58, 53, 26, color, 12)
		outline(frame, parts, "AroAdicao", 62, 58, 28, 28, color, 3.5, 14)
		rectangle(frame, parts, "MaisHorizontal", 68, 70, 17, 4, color, 2)
		rectangle(frame, parts, "MaisVertical", 75, 64, 4, 17, color, 2)
		-- Símbolo + desenhado por formas vetoriais, legível em ambas as cores.
	elseif kind == "music" then
		stroke(frame, parts, "HasteNotaEsquerda", 39, 48, 45, 6, 90, color)
		stroke(frame, parts, "HasteNotaDireita", 72, 43, 52, 6, 90, color)
		stroke(frame, parts, "BarraSuperior", 57, 20, 37, 7, -13, color)
		rectangle(frame, parts, "CabecaNotaEsquerda", 17, 67, 29, 17, color, 9, -16)
		rectangle(frame, parts, "CabecaNotaDireita", 50, 61, 29, 17, color, 9, -16)
	end
	return frame, parts
end

function Icons.tint(paint, color: Color3, scope, duration: number)
	for _, entry in ipairs(paint) do
		if scope and duration > 0 then
			scope:Tween(entry[1], {[entry[2]] = color}, duration)
		else
			(entry[1] :: any)[entry[2]] = color
		end
	end
end

return Icons
