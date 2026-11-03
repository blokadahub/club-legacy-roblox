-- Seleção de clubes: dois eixos espelhados, centro livre e dados originais.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local UI = require(script.Parent.Parent.UI)
local Data = require(ReplicatedStorage.CL27.Data)

local WHITE = Color3.fromRGB(244, 249, 249)
local MUTED = Color3.fromRGB(157, 185, 190)
local TEAL = Color3.fromRGB(62, 241, 202)
local INK = Color3.fromRGB(12, 30, 45)

local function label(parent, value, x, y, w, h, size, color, font)
	local object = UI.text(parent, value, x, y, w, h, size, color or WHITE, font)
	object.TextXAlignment = Enum.TextXAlignment.Center
	return object
end

local function unique(field, country)
	local values = { "Todos" }
	for _, club in Data.clubs do
		if not country or country == "Todos" or club.country == country then
			local value = club[field]
			if value and not table.find(values, value) then table.insert(values, value) end
		end
	end
	return values
end

local function updateScene(ctx)
	ctx.scene:UpdateClubs(Data.clubs[ctx.state.homeClub], Data.clubs[ctx.state.awayClub], ctx.state.homeKit, ctx.state.awayKit)
end

local function ratingStars(parent, rating)
	for index = 1, 5 do
		local x = 128 + (index - 1) * 34
		label(parent, "☆", x, 287, 34, 31, 25, Color3.fromRGB(114, 141, 150))
		local fraction = math.clamp(rating - index + 1, 0, 1)
		if fraction > 0 then
			local clip = UI.frame(parent, x, 287, 34 * fraction, 31, WHITE, 1)
			clip.ClipsDescendants = true
			label(clip, "★", 0, 0, 34, 31, 25, Color3.fromRGB(216, 216, 171))
		end
	end
end

return function(root, ctx)
	local state = ctx.state
	state.clubFilters = state.clubFilters or { home = {country = "Todos", league = "Todos"}, away = {country = "Todos", league = "Todos"} }
	state.activeSide = state.activeSide or "home"
	state.homeKit = state.homeKit or 1
	state.awayKit = state.awayKit or 2
	UI.header(root, "Seleção de clubes", "APRESENTAÇÃO")
	local heading = label(root, "MANDANTE", -155, 421, 520, 52, 39, WHITE, Enum.Font.GothamBold)
	heading.Rotation = -90
	local awayHeading = label(root, "VISITANTE", 1235, 421, 520, 52, 39, WHITE, Enum.Font.GothamBold)
	awayHeading.Rotation = 90

	local function candidates(side)
		local filters = state.clubFilters[side]
		local list = {}
		for index, club in Data.clubs do
			if (filters.country == "Todos" or filters.country == club.country)
				and (filters.league == "Todos" or filters.league == club.league) then table.insert(list, index) end
		end
		return list
	end

	local function setClub(side, index)
		state.activeSide = side
		state[side .. "Club"] = index
		state[side .. "Kit"] = if side == "home" then 1 else math.min(2, #Data.clubs[index].kits)
		state[side .. "Ready"] = false
		state.kitPresentation = false
		updateScene(ctx)
		ctx.rerender()
	end

	local function cycle(side, direction)
		local list = candidates(side)
		if #list == 0 then return end
		local index = table.find(list, state[side .. "Club"]) or 1
		setClub(side, list[(index - 1 + direction) % #list + 1])
	end

	local function cycleFilter(side, field)
		local filters = state.clubFilters[side]
		local values = unique(field, if field == "league" then filters.country else nil)
		local current = table.find(values, filters[field]) or 1
		filters[field] = values[current % #values + 1]
		if field == "country" then filters.league = "Todos" end
		local list = candidates(side)
		if #list > 0 then setClub(side, list[1]) else ctx.rerender() end
	end

	local function clubPanel(side, x)
		local club = Data.clubs[state[side .. "Club"]]
		local selected = state.activeSide == side
		local filters = state.clubFilters[side]
		UI.button(root, if selected then "●  SELECIONADO" else "○  SELECIONAR LADO", x, 139, 425, 36, function()
			state.activeSide = side
			ctx.rerender()
		end, ctx.scope, { quiet = true, selected = selected })
		UI.button(root, "PAÍS    " .. filters.country .. "   ›", x, 187, 425, 38, function() cycleFilter(side, "country") end, ctx.scope, { quiet = true })
		UI.button(root, "LIGA    " .. filters.league .. "   ›", x, 229, 425, 33, function() cycleFilter(side, "league") end, ctx.scope, { quiet = true })
		local panel = UI.panel(root, x, 275, 425, 415, INK, if selected then 0.19 else 0.42)
		UI.stroke(panel, if selected then TEAL else Color3.fromRGB(87, 124, 139), if selected then 0.06 else 0.7, if selected then 1.5 else 1)
		UI.line(panel, 1, 1, 424, 1, if selected then TEAL else MUTED, 1)
		label(panel, string.upper(club.name), 20, 14, 385, 49, 26, WHITE, Enum.Font.GothamBold)
		label(panel, club.country .. "  /  " .. club.shortName, 20, 61, 385, 24, 13, MUTED)
		UI.badge(panel, club, 126, 95, 174)
		UI.button(panel, "‹", 19, 164, 50, 61, function() cycle(side, -1) end, ctx.scope, { quiet = true })
		UI.button(panel, "›", 356, 164, 50, 61, function() cycle(side, 1) end, ctx.scope, { quiet = true })
		ratingStars(panel, math.clamp(club.stars or 4, 0, 5))
		UI.line(panel, 29, 330, 396, 330, Color3.fromRGB(89, 132, 146), 1)
		for index, entry in { {"ATA", club.attack}, {"MEI", club.midfield}, {"DEF", club.defense} } do
			local statX = 28 + (index - 1) * 123
			label(panel, entry[1], statX, 343, 123, 19, 12, MUTED)
			label(panel, tostring(entry[2]), statX, 363, 123, 42, 34, WHITE, Enum.Font.GothamMedium)
		end
		UI.panel(root, x, 705, 425, 75, INK, 0.5)
		label(root, string.upper(club.league), x + 20, 715, 385, 24, 17, WHITE, Enum.Font.GothamMedium)
		label(root, "TEMPORADA 2026 / 27", x + 20, 744, 385, 18, 12, MUTED)
	end

	clubPanel("home", 220)
	clubPanel("away", 955)
	label(root, "CL 27", 678, 284, 244, 49, 33, WHITE, Enum.Font.GothamBold)
	label(root, "ENCONTRO DE IDENTIDADES", 675, 344, 250, 46, 14, MUTED)
	UI.line(root, 736, 408, 864, 408, TEAL, 1)
	label(root, "VS", 700, 431, 200, 45, 23, WHITE, Enum.Font.GothamMedium)
	UI.button(root, if state.clubCompare then "OCULTAR COMPARAÇÃO" else "COMPARAR ATRIBUTOS", 671, 541, 258, 40, function()
		state.clubCompare = not state.clubCompare
		ctx.rerender()
	end, ctx.scope, { quiet = true })
	if state.clubCompare then
		local home = Data.clubs[state.homeClub]
		local away = Data.clubs[state.awayClub]
		for index, entry in { { "ATA", home.attack - away.attack }, { "MEI", home.midfield - away.midfield }, { "DEF", home.defense - away.defense } } do
			local difference = entry[2]
			label(root, entry[1] .. "   " .. (if difference > 0 then "+" else "") .. tostring(difference), 700, 592 + (index - 1) * 31, 200, 24, 15, if difference >= 0 then TEAL else MUTED)
		end
		label(root, "Diferença do mandante", 690, 694, 220, 23, 12, MUTED)
	else
		label(root, "Explore as identidades dos clubes", 675, 587, 250, 44, 12, MUTED)
	end
	UI.button(root, "SELECIONAR UNIFORMES  ›", 630, 796, 340, 43, function()
		updateScene(ctx)
		ctx.go("Kits")
	end, ctx.scope, { primary = true })
	ctx.scope:Connect(UserInputService.InputBegan, function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.Left then cycle(state.activeSide, -1)
		elseif input.KeyCode == Enum.KeyCode.Right then cycle(state.activeSide, 1) end
	end)
end
