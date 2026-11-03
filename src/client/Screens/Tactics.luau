local UI = require(script.Parent.Parent.UI)
local Data = require(game:GetService("ReplicatedStorage").CL27.Data)
local Pitch = require(script.Parent.Pitch)

local WHITE = Color3.fromRGB(241, 248, 248)
local MUTED = Color3.fromRGB(149, 176, 187)
local ACCENT = Color3.fromRGB(67, 241, 202)
local PANEL = Color3.fromRGB(17, 34, 51)
local STYLES = { "Construção equilibrada", "Passe curto", "Progressão direta", "Amplitude ofensiva" }
local PRESSURE = { "Bloco baixo", "Bloco médio", "Pressão alta" }

return function(root, ctx)
	local state, scope = ctx.state, ctx.scope
	state.formation = math.clamp(state.formation or 1, 1, #Data.formations)
	state.tactics = state.tactics or { style = 1, pressure = 2, width = 60, depth = 55, withBall = true }
	local settings = state.tactics
	local formation = Data.formations[state.formation]
	UI.header(root, "GERENCIAMENTO DE EQUIPE", "PLANO DE JOGO", {
		{ label = "Elenco", callback = function() ctx.go("Squad") end },
		{ label = "Táticas", selected = true, callback = function() end },
		{ label = "Atribuições", callback = function() ctx.go("Assignments") end },
	})
	UI.text(root, "UMA IDENTIDADE. ONZE CONEXÕES.", 74, 138, 802, 33, 24, WHITE, Enum.Font.GothamBold)
	UI.text(root, "Organize a apresentação tática do seu clube.", 74, 181, 802, 25, 15, MUTED)
	UI.button(root, "COM A BOLA", 74, 225, 185, 40, function()
		settings.withBall = true
		ctx.rerender()
	end, scope, { selected = settings.withBall, quiet = true })
	UI.button(root, "SEM A BOLA", 268, 225, 185, 40, function()
		settings.withBall = false
		ctx.rerender()
	end, scope, { selected = not settings.withBall, quiet = true })
	local fx, fy, fw, fh = 74, 304, 827, 425
	Pitch.draw(root, fx, fy, fw, fh)
	for index = 1, math.min(11, #Data.players) do
		local p = Data.players[index]
		local position = formation.positions[index]
		local nx, ny = position.x or position[1], position.y or position[2]
		if not settings.withBall and index ~= 1 then ny = math.min(0.87, ny + 0.075) end
		-- Width and depth affect only this spatial presentation, without simulating play.
		if index ~= 1 then
			nx = 0.5 + (nx - 0.5) * (0.68 + settings.width / 155)
			ny = math.clamp(ny + (55 - settings.depth) / 500, 0.06, 0.92)
		end
		local x, y = Pitch.project(nx, ny, fw, fh)
		local card = UI.button(root, "", fx + x - 49, fy + y - 35, 98, 70, function()
			state.selectedPlayer = index
			ctx.go("Squad")
		end, scope, { quiet = true, transparency = 0.13 })
		card.BackgroundColor3 = PANEL
		card.BackgroundTransparency = 0.13
		UI.stroke(card, ACCENT, 0.72, 1)
		local number = UI.text(card, tostring(p.number), 30, 4, 42, 33, 24, ACCENT, Enum.Font.GothamBold)
		number.TextXAlignment = Enum.TextXAlignment.Center
		local name = UI.text(card, string.upper(p.shortName or p.name), 2, 39, 94, 19, 10, WHITE, Enum.Font.GothamBold)
		name.TextXAlignment = Enum.TextXAlignment.Center
		UI.text(card, p.position, 5, 5, 30, 16, 9, MUTED)
		UI.bar(card, p.fitness or 94, 8, 63, 82, 2, ACCENT)
	end
	UI.text(root, "SELECIONE UM ATLETA PARA CONSULTAR O PERFIL", 74, 773, 827, 24, 11, MUTED)
	local controls = UI.panel(root, 961, 138, 574, 676, PANEL, 0.1)
	UI.text(controls, "TÁTICA ATIVA", 28, 23, 370, 25, 12, ACCENT, Enum.Font.GothamBold)
	UI.text(controls, formation.name, 28, 58, 370, 53, 43, WHITE, Enum.Font.GothamBold)
	UI.text(controls, "FORMAÇÃO", 28, 134, 460, 20, 11, MUTED, Enum.Font.GothamBold)
	UI.button(controls, "‹", 27, 168, 48, 44, function()
		state.formation = (state.formation - 2) % #Data.formations + 1
		ctx.rerender()
	end, scope, { quiet = true })
	UI.text(controls, formation.name, 92, 174, 360, 30, 21, WHITE, Enum.Font.GothamBold)
	UI.button(controls, "›", 493, 168, 48, 44, function()
		state.formation = state.formation % #Data.formations + 1
		ctx.rerender()
	end, scope, { quiet = true })
	UI.line(controls, 27, 229, 541, 229, MUTED, 1).BackgroundTransparency = 0.8
	local function cycle(label, values, key, y)
		UI.text(controls, label, 28, y, 460, 20, 11, MUTED, Enum.Font.GothamBold)
		UI.button(controls, values[settings[key]] .. "  ›", 28, y + 29, 514, 42, function()
			settings[key] = settings[key] % #values + 1
			ctx.rerender()
		end, scope, { quiet = true })
	end
	cycle("CONSTRUÇÃO", STYLES, "style", 249)
	cycle("COMPORTAMENTO DEFENSIVO", PRESSURE, "pressure", 344)
	local function slider(label, key, y)
		UI.text(controls, label, 28, y, 365, 22, 11, MUTED, Enum.Font.GothamBold)
		UI.text(controls, tostring(settings[key]), 399, y - 3, 60, 28, 20, WHITE, Enum.Font.GothamBold)
		UI.bar(controls, settings[key], 28, y + 41, 390, 4, ACCENT)
		for i, delta in ipairs({ -5, 5 }) do
			UI.button(controls, if delta < 0 then "−" else "+", 439 + (i - 1) * 55, y + 15, 47, 43, function()
				settings[key] = math.clamp(settings[key] + delta, 10, 90)
				ctx.rerender()
			end, scope, { quiet = true })
		end
	end
	slider("AMPLITUDE", "width", 444)
	slider("ALTURA DO BLOCO", "depth", 530)
	UI.text(controls, "Ajustes de apresentação • salvos nesta sessão", 28, 632, 514, 22, 11, MUTED)
end
