-- Utilitários editoriais das telas de gestão; todas as medidas usam o canvas 1600×900.
local UI = require(script.Parent.Parent.UI)
local M = {}
M.c = setmetatable({
	white = Color3.fromRGB(241, 248, 250),
	blue = Color3.fromRGB(72, 137, 238),
	ink = Color3.fromRGB(10, 27, 42),
	line = Color3.fromRGB(54, 80, 94), gold = Color3.fromRGB(229, 205, 139),
}, {__index = function(_, key)
	if key == "accent" then return UI.accent or Color3.fromRGB(70, 239, 201) end
	if key == "muted" then return UI.highContrast and Color3.fromRGB(211, 225, 231) or Color3.fromRGB(151, 176, 187) end
	if key == "panel" then return UI.highContrast and Color3.fromRGB(5, 15, 23) or Color3.fromRGB(20, 40, 56) end
	return nil
end})
function M.wrap(parent, text, x, y, width, height, size, color, font)
	local label = UI.text(parent, text, x, y, width, height, size, color, font)
	label.TextWrapped = true
	label.TextTruncate = Enum.TextTruncate.None
	label.TextYAlignment = Enum.TextYAlignment.Top
	return label
end
function M.title(parent, eyebrow, title, x, y, width)
	UI.text(parent, eyebrow, x, y, width, 24, 13, M.c.accent, Enum.Font.GothamBold)
	UI.text(parent, title, x, y + 30, width, 62, 42, M.c.white, Enum.Font.GothamBold)
end
function M.divider(parent, x, y, width)
	UI.line(parent, x, y, x + width, y, M.c.line, 1)
end
function M.money(value)
	return "R$ " .. string.gsub(string.format("%.1f", value), "[.]", ",") .. " mi"
end
function M.club(Data, index)
	return Data.clubs[index] or Data.clubs[1]
end
function M.player(Data, index)
	return Data.players[index] or Data.players[1]
end
function M.clubName(Data, value)
	if type(value) == "number" then
		return M.club(Data, value).name
	end
	return tostring(value or "Adversário a definir")
end
function M.fixture(Data, original, homeIndex)
	if not original then return nil end
	local fixture = table.clone(original)
	if type(fixture.opponent) == "number" then
		fixture.opponent = ((fixture.opponent + (homeIndex or 1) - 2) % #Data.clubs) + 1
	end
	if fixture.competition == Data.clubs[1].league then fixture.competition = M.club(Data, homeIndex).league end
	return fixture
end
function M.meta(parent, label, value, x, y, width)
	UI.text(parent, label, x, y, width, 22, 13, M.c.muted)
	UI.text(parent, tostring(value), x, y + 25, width, 34, 25, M.c.white, Enum.Font.GothamBold)
end
function M.tag(parent, text, x, y, width, selected)
	UI.frame(parent, x, y, width, 26, selected and M.c.accent or M.c.line, selected and 0.05 or 0.55)
	UI.text(parent, text, x + 9, y + 3, width - 18, 20, 11, selected and M.c.ink or M.c.white, Enum.Font.GothamBold)
end
function M.tabs(items, active, callback)
	local result = {}
	for index, label in ipairs(items) do
		table.insert(result, { label = label, selected = active == index, callback = function() callback(index) end })
	end
	return result
end
function M.attribute(parent, label, value, x, y, width, color)
	UI.text(parent, label, x, y, width - 55, 22, 14, M.c.muted)
	UI.text(parent, tostring(value), x + width - 46, y - 2, 46, 25, 20, M.c.white, Enum.Font.GothamBold)
	UI.bar(parent, value, x, y + 30, width, 4, color or M.c.accent)
end
return M
