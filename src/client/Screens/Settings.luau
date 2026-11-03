local UI = require(script.Parent.Parent.UI)
local M = require(script.Parent.ManagementUI)
local sections = {"Apresentação", "Acessibilidade", "Controles"}

return function(root, ctx)
	local state = ctx.state
	state.settings = state.settings or {reducedMotion = false, quality = "Alta", highContrast = false, showHints = true}
	state.settingsTab = state.settingsTab or 1
	local settings = state.settings
	UI.header(root, "Configurações", "PREFERÊNCIAS DE APRESENTAÇÃO")
	UI.text(root, "Ajuste a sua experiência.", 65, 144, 1200, 60, 42, M.c.white, Enum.Font.GothamBold)
	UI.text(root, "Preferências aplicadas nesta sessão", 67, 214, 1000, 29, 17, M.c.muted)
	for index, name in ipairs(sections) do
		UI.button(root, string.format("%02d", index) .. "   " .. name, 65, 314 + (index - 1) * 85, 348, 66, function() state.settingsTab = index; ctx.rerender() end, ctx.scope, {selected = state.settingsTab == index})
	end
	UI.line(root, 461, 313, 461, 802, M.c.line, 1)
	local function setting(label, value, description, y, callback)
		UI.text(root, label, 507, y, 670, 32, 24, M.c.white, Enum.Font.GothamBold)
		M.wrap(root, description, 507, y + 43, 690, 58, 17, M.c.muted)
		UI.button(root, value .. "  ›", 1249, y + 3, 285, 57, callback, ctx.scope, {selected = true})
		M.divider(root, 507, y + 130, 1027)
	end
	if state.settingsTab == 1 then
		UI.section(root, "CENÁRIO E RENDERIZAÇÃO", 507, 315, 1005)
		setting("Qualidade de apresentação", settings.quality or "Alta", "Ajusta efeitos, sombras e a densidade das redes de campo.", 376, function()
			settings.quality = settings.quality == "Alta" and "Média" or (settings.quality == "Média" and "Baixa" or "Alta"); ctx.rerender()
		end)
		setting("Ambiente preferido", state.homeEnvironment == "Training" and "Centro de treinamento" or "Sede do clube", "Escolhe a apresentação utilizada ao voltar ao menu principal.", 548, function()
			state.homeEnvironment = state.homeEnvironment == "Training" and "Interior" or "Training"
			ctx.rerender()
		end)
		UI.button(root, "Ver ambiente selecionado  →", 507, 734, 1027, 61, function()
			ctx.go(state.homeEnvironment == "Training" and "HomeTraining" or "HomeInterior")
		end, ctx.scope, {primary = true})
	elseif state.settingsTab == 2 then
		UI.section(root, "MOVIMENTO E LEITURA", 507, 315, 1005)
		setting("Reduzir movimento", settings.reducedMotion and "Ativado" or "Desativado", "Reduz deslocamentos de câmera e encurta transições da interface.", 376, function()
			settings.reducedMotion = not settings.reducedMotion; ctx.rerender()
		end)
		setting("Contraste reforçado", settings.highContrast and "Ativado" or "Desativado", "Reforça a leitura da interface sobre os ambientes tridimensionais.", 548, function()
			settings.highContrast = not settings.highContrast; ctx.rerender()
		end)
		UI.text(root, "Texto em português brasileiro  •  Seleção por toque, mouse e controle", 507, 751, 1000, 33, 16, M.c.accent, Enum.Font.GothamBold)
	else
		UI.section(root, "NAVEGAÇÃO DA CENTRAL", 507, 315, 1005)
		setting("Dicas de comandos", settings.showHints == false and "Ocultas" or "Visíveis", "Mostra as indicações de teclado e controle no rodapé da apresentação.", 376, function()
			settings.showHints = settings.showHints == false; ctx.rerender()
		end)
		local commands = {
			{"MOUSE / TOQUE", "Selecione elementos ou deslize as listas de atletas."},
			{"TECLADO", "M abre a central. B volta à tela anterior."},
			{"CONTROLE", "Direcional: navegar. A: selecionar. Y: central. B: voltar."},
		}
		for index, item in ipairs(commands) do
			local y = 554 + (index - 1) * 82
			UI.text(root, item[1], 507, y, 225, 29, 14, M.c.accent, Enum.Font.GothamBold)
			M.wrap(root, item[2], 765, y - 3, 766, 56, 18, M.c.white)
			M.divider(root, 507, y + 64, 1027)
		end
	end
end
