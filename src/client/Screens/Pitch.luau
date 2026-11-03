-- Campo em projeção trapezoidal. As linhas e cartões compartilham a mesma projeção.
local UI = require(script.Parent.Parent.UI)

local Pitch = {}
local lineColor = Color3.fromRGB(116, 169, 174)

function Pitch.project(x, y, width, height)
	local inset = width * 0.13 * (1 - y)
	return inset + x * (width - inset * 2), y * height
end

function Pitch.draw(parent, x, y, width, height)
	local field = UI.frame(parent, x, y, width, height, Color3.fromRGB(14, 32, 49), 1)
	field.Name = "CampoEmPerspectiva"
	local slices = 48
	for i = 0, slices - 1 do
		local t = i / slices
		local inset = width * 0.13 * (1 - t)
		local color = if math.floor(t * 8) % 2 == 0 then Color3.fromRGB(21, 53, 66) else Color3.fromRGB(19, 46, 61)
		UI.frame(field, inset, t * height, width - inset * 2, height / slices + 1, color, 0.2)
	end
	local function point(px, py)
		return Pitch.project(px, py, width, height)
	end
	local function segment(ax, ay, bx, by, thickness)
		local x1, y1 = point(ax, ay)
		local x2, y2 = point(bx, by)
		local line = UI.line(field, x1, y1, x2, y2, lineColor, thickness or 1)
		line.BackgroundTransparency = 0.43
	end
	local function box(ax, ay, bx, by)
		segment(ax, ay, bx, ay)
		segment(ax, ay, ax, by)
		segment(bx, ay, bx, by)
		segment(ax, by, bx, by)
	end
	box(0, 0, 1, 1)
	segment(0, 0.5, 1, 0.5)
	box(0.23, 0, 0.77, 0.16)
	box(0.36, 0, 0.64, 0.065)
	box(0.23, 0.84, 0.77, 1)
	box(0.36, 0.935, 0.64, 1)
	for i = 0, 39 do
		local a, b = i / 40 * math.pi * 2, (i + 1) / 40 * math.pi * 2
		segment(0.5 + math.cos(a) * 0.14, 0.5 + math.sin(a) * 0.13, 0.5 + math.cos(b) * 0.14, 0.5 + math.sin(b) * 0.13)
	end
	return field
end

return Pitch
