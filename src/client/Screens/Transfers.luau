local UI = require(script.Parent.Parent.UI)
local M = require(script.Parent.ManagementUI)
local Data = require(game:GetService("ReplicatedStorage"):WaitForChild("CL27"):WaitForChild("Data"))
local positions = {"Todos", "Ataque", "Meio-campo", "Defesa", "Goleiros", "Observados"}
local function group(position)
	if position == "GOL" then return 5 end
	if position == "ZAG" or position == "LD" or position == "LE" then return 4 end
	if position == "VOL" or position == "MC" or position == "MEI" or position == "MD" or position == "ME" then return 3 end
	return 2
end
local function valuation(player)
	return math.max(2.1, (player.overall - 55) * 2.3 + (player.potential - player.overall) * 0.9 - (player.age - 23) * 1.3)
end

return function(root, ctx)
	local state = ctx.state
	state.shortlist = state.shortlist or {}
	state.transferPosition = state.transferPosition or 1
	state.transferSelected = state.transferSelected or 12
	state.transferSort = state.transferSort or "Geral"
	UI.header(root, "Transferências", "REDE DE OBSERVAÇÃO")
	UI.text(root, "Encontre o próximo legado.", 65, 144, 1000, 58, 42, M.c.white, Enum.Font.GothamBold)
	UI.text(root, "Relatórios de observação  /  Janela de janeiro", 67, 208, 900, 30, 17, M.c.muted)
	local input = UI.new("TextBox", {
		Name = "BuscaDeAtleta", Position = UDim2.fromOffset(65, 265), Size = UDim2.fromOffset(600, 48),
		BackgroundColor3 = M.c.panel, BackgroundTransparency = 0.2, BorderSizePixel = 0,
		Text = state.transferQuery or "", PlaceholderText = "Buscar atleta por nome", TextColor3 = M.c.white,
		PlaceholderColor3 = M.c.muted, TextSize = 17, Font = Enum.Font.Gotham, ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, root)
	UI.new("UIPadding", {PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18)}, input)
	ctx.scope:Connect(input.FocusLost, function() state.transferQuery = input.Text; ctx.rerender() end)
	UI.button(root, "Ordem: " .. state.transferSort, 686, 265, 274, 48, function()
		state.transferSort = state.transferSort == "Geral" and "Potencial" or "Geral"; ctx.rerender()
	end, ctx.scope)
	for i, label in ipairs(positions) do
		UI.button(root, label, 65 + (i - 1) * 150, 337, 140, 41, function() state.transferPosition = i; ctx.rerender() end, ctx.scope, {selected = state.transferPosition == i, quiet = true})
	end
	UI.text(root, "ATLETA", 86, 405, 440, 23, 12, M.c.muted, Enum.Font.GothamBold)
	UI.text(root, "IDADE", 584, 405, 70, 23, 12, M.c.muted, Enum.Font.GothamBold)
	UI.text(root, "GER", 709, 405, 70, 23, 12, M.c.muted, Enum.Font.GothamBold)
	UI.text(root, "POT", 817, 405, 70, 23, 12, M.c.muted, Enum.Font.GothamBold)
	M.divider(root, 65, 442, 900)
	local visible = {}
	for index, player in ipairs(Data.players) do
		local query = string.lower(state.transferQuery or "")
		local matchesName = query == "" or string.find(string.lower(player.name), query, 1, true) ~= nil
		local matchesPosition = state.transferPosition == 1 or (state.transferPosition == 6 and state.shortlist[player.id]) or group(player.position) == state.transferPosition
		if matchesName and matchesPosition then table.insert(visible, {player = player, index = index}) end
	end
	table.sort(visible, function(a, b)
		local key = state.transferSort == "Geral" and "overall" or "potential"
		if a.player[key] == b.player[key] then return a.index < b.index end
		return a.player[key] > b.player[key]
	end)
	local scroll = UI.new("ScrollingFrame", {
		Name = "Relatorios", Position = UDim2.fromOffset(65, 454), Size = UDim2.fromOffset(905, 330),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = M.c.accent,
		CanvasSize = UDim2.fromOffset(0, #visible * 69), ScrollingDirection = Enum.ScrollingDirection.Y,
	}, root)
	for row, entry in ipairs(visible) do
		local player, index = entry.player, entry.index
		local item = UI.button(scroll, "", 0, (row - 1) * 69, 888, 63, function() state.transferSelected = index; ctx.rerender() end, ctx.scope, {selected = state.transferSelected == index})
		UI.text(item, player.position, 19, 19, 62, 25, 13, M.c.accent, Enum.Font.GothamBold)
		UI.text(item, player.name .. (state.shortlist[player.id] and "  ◇" or ""), 94, 17, 395, 30, 19, M.c.white, Enum.Font.GothamBold)
		UI.text(item, tostring(player.age), 520, 18, 65, 30, 18, M.c.muted)
		UI.text(item, tostring(player.overall), 644, 15, 65, 34, 24, M.c.white, Enum.Font.GothamBold)
		UI.text(item, tostring(player.potential), 752, 15, 65, 34, 24, M.c.accent, Enum.Font.GothamBold)
	end
	if #visible == 0 then UI.text(scroll, "Nenhum atleta encontrado com estes filtros.", 20, 35, 830, 50, 21, M.c.muted) end
	UI.keepScroll(scroll,state,"transferScrollY",ctx.scope)
	UI.text(root, #visible .. " relatórios disponíveis", 65, 800, 900, 25, 13, M.c.muted)
	local player = M.player(Data, state.transferSelected)
	local club = M.club(Data, (state.transferSelected % #Data.clubs) + 1)
	UI.panel(root, 1020, 147, 515, 657, M.c.panel, 0.15)
	UI.portrait(root, player, club, 1045, 168, 215, 224, ctx.scope)
	UI.text(root, tostring(player.overall), 1375, 184, 130, 92, 76, M.c.white, Enum.Font.GothamBold)
	UI.text(root, "GERAL", 1386, 277, 120, 26, 12, M.c.muted, Enum.Font.GothamBold)
	UI.text(root, player.name, 1055, 413, 450, 45, 31, M.c.white, Enum.Font.GothamBold)
	M.wrap(root, player.position .. "  •  " .. player.age .. " anos  •  " .. club.name, 1055, 467, 450, 44, 16, M.c.muted)
	M.divider(root, 1055, 529, 445)
	M.meta(root, "VALOR ESTIMADO", M.money(valuation(player)), 1055, 554, 245)
	M.meta(root, "POTENCIAL", player.potential, 1346, 554, 155)
	UI.text(root, "Relatório fictício  /  Observação completa", 1055, 644, 445, 26, 13, M.c.muted)
	local watched = state.shortlist[player.id]
	UI.button(root, watched and "Remover dos observados" or "Adicionar aos observados", 1055, 701, 445, 64, function()
		state.shortlist[player.id] = not state.shortlist[player.id]
		ctx.notify(state.shortlist[player.id] and "Atleta adicionado à lista de observação." or "Atleta removido da lista de observação.")
		ctx.rerender()
	end, ctx.scope, {primary = true})
end
