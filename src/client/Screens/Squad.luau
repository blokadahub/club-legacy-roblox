local UI = require(script.Parent.Parent.UI)
local Data = require(game:GetService("ReplicatedStorage").CL27.Data)
local Pitch = require(script.Parent.Pitch)

local WHITE = Color3.fromRGB(241, 248, 248)
local MUTED = Color3.fromRGB(149, 176, 187)
local ACCENT = Color3.fromRGB(67, 241, 202)
local PANEL = Color3.fromRGB(17, 34, 51)
local GOLD = Color3.fromRGB(221, 202, 133)
local ATTRIBUTES = {
	{ "pace", "Ritmo" }, { "shooting", "Finalização" }, { "passing", "Passe" },
	{ "dribbling", "Condução" }, { "defending", "Defesa" }, { "physical", "Físico" },
}

local function statusText(value, fallback)
	if type(value) == "string" then return value end
	if type(value) == "number" then return tostring(value) .. "%" end
	return fallback
end

return function(root, ctx)
	local state, scope = ctx.state, ctx.scope
	state.selectedPlayer = math.clamp(state.selectedPlayer or 1, 1, #Data.players)
	state.formation = math.clamp(state.formation or 1, 1, #Data.formations)
	local club = Data.clubs[state.homeClub or 1]
	local formation = Data.formations[state.formation]
	local rows = {}
	for _, position in ipairs(formation.positions) do
		local row = position.y or position[2]
		if not table.find(rows, row) then table.insert(rows, row) end
	end
	table.sort(rows)
	local smallestGap = 1
	for i = 2, #rows do smallestGap = math.min(smallestGap, rows[i] - rows[i - 1]) end
	local fieldCardHeight = math.min(88, math.floor(smallestGap * 366) - 2)
	UI.header(root, "GERENCIAMENTO DE EQUIPE", "CENTRAL DO CLUBE", {
		{ label = "Elenco", selected = true, callback = function() end },
		{ label = "Táticas", callback = function() ctx.go("Tactics") end },
		{ label = "Atribuições", callback = function() ctx.go("Assignments") end },
	})
	local fieldX, fieldY, fieldW, fieldH = 72, 145, 825, 366
	Pitch.draw(root, fieldX, fieldY, fieldW, fieldH)
	UI.text(root, "COM A BOLA", 82, 521, 150, 22, 13, WHITE, Enum.Font.GothamBold)
	UI.text(root, formation.name, 760, 520, 135, 24, 15, ACCENT, Enum.Font.GothamBold)
	local infoHost = UI.frame(root, 945, 137, 592, 677, PANEL, 0.12)
	infoHost.Name = "FichaDoJogador"
	local borders = {}
	local currentInfo
	local function drawInfo(index)
		if currentInfo then currentInfo:Destroy() end
		local p = Data.players[index]
		local body = UI.frame(infoHost, 0, 0, 592, 677, PANEL, 1)
		currentInfo = body
		UI.portrait(body, p, club, 28, 20, 122, 124, scope)
		UI.text(body, p.position .. "  /  " .. tostring(p.number), 167, 26, 265, 25, 14, MUTED)
		UI.text(body, string.upper(p.shortName or p.name), 167, 57, 320, 39, 27, WHITE, Enum.Font.GothamBold)
		UI.text(body, "Potencial " .. tostring(p.potential), 168, 107, 250, 24, 14, MUTED)
		local overall = UI.frame(body, 486, 34, 74, 74, Color3.fromRGB(29, 64, 74), 0.4)
		overall.Rotation = 45
		UI.stroke(overall, ACCENT, 0.7, 1)
		local number = UI.text(body, tostring(p.overall), 478, 46, 90, 54, 42, WHITE, Enum.Font.GothamBold)
		number.TextXAlignment = Enum.TextXAlignment.Center
		UI.line(body, 28, 158, 562, 158, MUTED, 1).BackgroundTransparency = 0.75
		local moods = {
			{ "FORMA", statusText(p.form, "Em alta"), WHITE },
			{ "MORAL", statusText(p.morale, "Confiante"), ACCENT },
			{ "CONDIÇÃO", tostring(p.fitness or 94) .. "%", GOLD },
		}
		for i, mood in ipairs(moods) do
			UI.text(body, mood[1], 29 + (i - 1) * 183, 178, 177, 20, 11, MUTED, Enum.Font.GothamBold)
			UI.text(body, mood[2], 29 + (i - 1) * 183, 205, 177, 25, 17, mood[3], Enum.Font.GothamMedium)
		end
		local ready = UI.text(body, "PRONTO PARA A PRÓXIMA ETAPA", 28, 251, 535, 28, 12, ACCENT, Enum.Font.GothamBold)
		ready.TextXAlignment = Enum.TextXAlignment.Center
		UI.frame(body, 28, 251, 535, 28, ACCENT, 0.95)
		UI.line(body, 304, 305, 304, 535, MUTED, 1).BackgroundTransparency = 0.78
		for i, attribute in ipairs(ATTRIBUTES) do
			local value = (p.attributes and p.attributes[attribute[1]]) or 70
			UI.text(body, attribute[2], 30, 301 + (i - 1) * 39, 185, 27, 16, MUTED)
			UI.text(body, tostring(value), 246, 300 + (i - 1) * 39, 45, 27, 19, WHITE, Enum.Font.GothamMedium)
		end
		local details = {
			{ "Idade", tostring(p.age) .. " anos" }, { "Altura", if type(p.height) == "number" then string.format("%.2f m", p.height / 100):gsub("%.", ",") else tostring(p.height) },
			{ "Posição", p.position }, { "Pé preferido", p.foot },
			{ "Função", if p.position == "GOL" then "Proteção" else "Apoio" }, { "Vínculo", "Até junho de 2029" },
		}
		for i, detail in ipairs(details) do
			UI.text(body, detail[1], 327, 301 + (i - 1) * 39, 115, 27, 13, MUTED)
			UI.text(body, detail[2], 442, 301 + (i - 1) * 39, 139, 27, 13, WHITE)
		end
		UI.line(body, 28, 551, 562, 551, MUTED, 1).BackgroundTransparency = 0.75
		UI.text(body, "TÉCNICA", 30, 567, 150, 22, 11, MUTED, Enum.Font.GothamBold)
		UI.text(body, "★ ★ ★ ★ ☆", 169, 564, 150, 28, 18, GOLD)
		UI.text(body, "ESTILOS DE JOGO", 30, 611, 180, 22, 11, MUTED, Enum.Font.GothamBold)
		for i, label in ipairs({ "P", "V", "C", "R", "+" }) do
			local symbol = UI.frame(body, 224 + (i - 1) * 58, 609, 27, 27, PANEL, 1)
			symbol.Rotation = 45
			UI.stroke(symbol, if i <= 3 then ACCENT else MUTED, 0.35, 1)
			local text = UI.text(body, label, 223 + (i - 1) * 58, 609, 29, 27, 12, if i <= 3 then WHITE else MUTED, Enum.Font.GothamBold)
			text.TextXAlignment = Enum.TextXAlignment.Center
		end
		for i = 1, 5 do
			local dot = UI.frame(body, 259 + (i - 1) * 17, 655, if i == 1 then 7 else 4, if i == 1 then 7 else 4, if i == 1 then WHITE else MUTED, 0.1)
			UI.new("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
		end
		-- Animate a small accent, preserving text readability throughout selection.
		local accent = UI.frame(body, 0, 0, 3, 677, ACCENT, 0.15)
		scope:Tween(accent, { BackgroundTransparency = 0.65 }, 0.28)
	end
	local function selectPlayer(index)
		state.selectedPlayer = index
		for id, border in pairs(borders) do
			border.Color = if id == index then ACCENT else MUTED
			border.Transparency = if id == index then 0.05 else 0.82
		end
		drawInfo(index)
	end
	local function card(parent, index, x, y, compact)
		local p = Data.players[index]
		local w = if compact then 112 else 101
		local h = if compact then 90 else fieldCardHeight
		local button = UI.button(parent, "", x, y, w, h, function() selectPlayer(index) end, scope, { quiet = true, transparency = 0.15 })
		button.Name = "Jogador_" .. tostring(p.id)
		button.BackgroundColor3 = PANEL
		button.BackgroundTransparency = 0.15
		button.BackgroundColor3 = Color3.new(1,1,1)
		UI.gradient(button, { Color3.fromRGB(48, 72, 87), PANEL }, 90)
		borders[index] = UI.stroke(button, if state.selectedPlayer == index then ACCENT else MUTED, if state.selectedPlayer == index then 0.05 else 0.82, 1)
		UI.portrait(button, p, club, 8, -3, w - 16, h - 21, scope)
		UI.text(button, tostring(p.overall), w - 33, 4, 31, 24, 17, WHITE, Enum.Font.GothamBold)
		UI.text(button, p.position, 5, 6, 39, 17, 9, MUTED, Enum.Font.GothamBold)
		UI.bar(button, p.fitness or 94, 9, h - 25, w - 18, 3, ACCENT)
		local name = UI.text(button, string.upper(p.shortName or p.name), 3, h - 21, w - 6, 19, 10, WHITE, Enum.Font.GothamBold)
		name.TextXAlignment = Enum.TextXAlignment.Center
		return button
	end
	for index = 1, math.min(11, #Data.players) do
		local pos = formation.positions[index]
		local px, py = Pitch.project(pos.x or pos[1], pos.y or pos[2], fieldW, fieldH)
		card(root, index, fieldX + px - 50.5, fieldY + py - fieldCardHeight / 2, false)
	end
	local bench = UI.panel(root, 72, 563, 825, 251, PANEL, 0.13)
	bench.Name = "BancoDeReservas"
	UI.text(bench, "RESERVAS", 22, 14, 240, 25, 15, WHITE, Enum.Font.GothamBold)
	UI.text(bench, tostring(#Data.players - 11) .. " ATLETAS DISPONÍVEIS", 535, 16, 267, 23, 11, MUTED)
	local scroll = UI.new("ScrollingFrame", {
		Name = "ListaDeReservas", Position = UDim2.fromOffset(20, 48), Size = UDim2.fromOffset(785, 191),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = MUTED,
		CanvasSize = UDim2.fromOffset(0, math.ceil(math.max(0, #Data.players - 11) / 6) * 98),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, bench)
	for index = 12, #Data.players do
		local slot = index - 12
		card(scroll, index, 6 + (slot % 6) * 127, math.floor(slot / 6) * 98, true)
	end
	drawInfo(state.selectedPlayer)
end
