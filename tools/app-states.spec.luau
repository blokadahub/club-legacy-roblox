-- Phase/state tests only. The clock/tweens are doubles; no frames are rendered.
local App = require(moduleNodes["src/client/App.luau"])
local Data = require(moduleNodes["src/shared/Data.luau"])
local UI = require(moduleNodes["src/client/UI.luau"])
local Scope = require(moduleNodes["src/client/Scope.luau"])
local assertions = 0
local function check(condition, message) assert(condition, message); assertions += 1 end
local function key(code) services.UserInputService.InputBegan:Fire({KeyCode = code}, false) end
local handle = App.start()
local gui = playerGui.CL27
local canvas = gui.Canvas
local transitionGui = playerGui:FindFirstChild("CL27_TransitionHUD")
local wipe = transitionGui and transitionGui:FindFirstChild("Transicao")
check(transitionGui ~= nil and wipe ~= nil and not wipe.Visible,
	"Transição independente não foi criada antes do menu")
check(wipe.Size.X.Scale == 1 and wipe.Size.Y.Scale == 1
	and wipe.Size.X.Offset == 0 and wipe.Size.Y.Offset == 0
	and wipe.Position.X.Scale == 0 and wipe.Position.Y.Scale == 0,
	"Transição precisa cobrir TODO o viewport, sem Canvas 16:9 ou retângulo interno")
check(transitionGui.IgnoreGuiInset and transitionGui.DisplayOrder > 85,
	"Carregamento precisa sobrepor os dois menus sem margens")
check(wipe.BackgroundTransparency >= 0.50 and wipe.BackgroundTransparency <= 0.70 and wipe.Active,
	"Fundo do loading deve permanecer visivel e bloquear cliques")
local emblem = wipe:FindFirstChild("IndicadorCL")
check(emblem ~= nil and emblem.Size.X.Offset == 32 and emblem.Size.Y.Offset == 32
	and emblem.AnchorPoint.X == 0.5 and emblem.AnchorPoint.Y == 1
	and emblem.Position.X.Scale == 0.5 and emblem.Position.Y.Scale == 1,
	"CL deve ficar centralizado no rodape e medir 32 px")
local mark = emblem:FindFirstChild("MarcaCLNeon")
check(mark ~= nil and mark:FindFirstChild("TracoCL_01") ~= nil,
	"Logo CL proprio nao foi construido a partir da referencia")
for i = 1, 5 do
	local line = mark:FindFirstChild(string.format("TracoCL_%02d", i))
	check(line ~= nil and line:FindFirstChild("AuraDifusa") ~= nil
		and line:FindFirstChild("HaloNeon") ~= nil
		and line:FindFirstChild("NucleoCL") ~= nil,
		"CL deve ter cinco bordas vetoriais e tres camadas de luz")
	check(line:FindFirstChild("NucleoCL").Size.Y.Offset == 3.1,
		"Traco CL deve ser um pouco grosso, mas sem blocos pesados")
end
local clSweep = mark:FindFirstChild("VarreduraOuterGlowCL")
local clPiece = clSweep and clSweep:FindFirstChild("SweepCL_01_01")
check(clSweep and clPiece and clPiece:IsA("CanvasGroup")
	and clPiece:FindFirstChild("HaloExternoSuave")
	and clPiece:FindFirstChild("GlowMedio")
	and clPiece:FindFirstChild("LinhaBranca"),
	"CL deve ter varredura branca em faixas, com halo difuso e linha definida")
check(clPiece:FindFirstChild("LinhaBranca").Size.Y.Offset == 2.25
	and clPiece:FindFirstChild("GlowMedio").Size.Y.Offset == 8.4
	and clPiece:FindFirstChild("HaloExternoSuave").Size.Y.Offset == 16,
	"Outer Glow deve ter nucleo um pouco mais espesso e halos difusos graduados")
local coreTint=clPiece:FindFirstChild("LinhaBranca").BackgroundColor3
local middleTint=clPiece:FindFirstChild("GlowMedio").BackgroundColor3
local outerTint=clPiece:FindFirstChild("HaloExternoSuave").BackgroundColor3
check(coreTint.G > coreTint.R and coreTint.G > coreTint.B
	and middleTint.G > middleTint.R and outerTint.G > outerTint.R,
	"Reflexo deve ter tonalidade branca-esverdeada, glow menta e halo verde claro")
check(clPiece:FindFirstChild("HaloExternoSuave"):FindFirstChildOfClass("UIGradient") ~= nil,
	"Halo precisa suavizar as bordas, não exibir retângulos opacos")
check(mark:FindFirstChild("CobraLuz_1") == nil,
	"Antiga animacao cobra deve ser completamente substituida")
check(emblem:FindFirstChild("OrbitaExterna") == nil
	and emblem:FindFirstChild("OrbitaInterna") == nil,
	"Efeitos orbitais antigos nao pertencem a esta referencia")
check(transitionGui:FindFirstChild("MarcaCentral",true)==nil
	and transitionGui:FindFirstChild("FaixaDeLuz_1",true)==nil,
	"O velho wipe cinematografico nao pode permanecer no carregamento")
-- O menu inicial deve existir em seu PRÓPRIO ScreenGui, antes de
-- qualquer montagem de cenário; não pode depender de telas legadas.
local homeHud = playerGui:FindFirstChild("CL27_HomeHUD")
check(homeHud ~= nil and homeHud.Enabled and homeHud.DisplayOrder > gui.DisplayOrder,
	"HUD independente não está à frente do cenário/menu principal")
local homeRoot = homeHud:FindFirstChild("HomeOverlay")
local homeList = homeRoot and homeRoot:FindFirstChild("MenuPrincipalFC")
check(homeList ~= nil and homeList:FindFirstChild("Opcao_1") ~= nil
	and homeList:FindFirstChild("Opcao_5") ~= nil,
	"Um ou mais botões principais não foram inseridos no PlayerGui")
check(homeList:FindFirstChild("Opcao_3").Text == "Jogo Rápido"
	and homeList:FindFirstChild("Opcao_3").TextTransparency == 0,
	"Jogo Rápido não está visivelmente selecionado na primeira entrada")
local expectedMenuNames = {"Notícias do CL", "Clubs", "Jogo Rápido", "Aprenda a Jogar", "Upgrade"}
for i, name in ipairs(expectedMenuNames) do
	check(homeList:FindFirstChild("Opcao_" .. i).Text == name,
		"Nomes precisam seguir a nova nomenclatura brasileira do lobby")
end
check(homeList:FindFirstChild("Opcao_3").TextSize == 27
	and homeList:FindFirstChild("Opcao_1").TextSize == 23,
	"Tipografia lateral deve ser menor, mas manter hierarquia de seleção")
local showcase = homeRoot:FindFirstChild("ConteudoCentral")
check(showcase ~= nil and showcase:IsA("CanvasGroup"),
	"Lobby não criou conteúdo central independente do cenário 3D")
check(showcase:FindFirstChild("TituloCentral").Text == "JOGO RÁPIDO",
	"Conteúdo central inicial não combina com foco no menu")
local primary = showcase:FindFirstChild("AcaoPrincipal")
check(primary ~= nil and primary:IsA("TextButton")
	and primary:FindFirstChildOfClass("UICorner") ~= nil
	and primary:FindFirstChild("IconeControle") ~= nil,
	"Ação central precisa ser uma cápsula verde com símbolo de controle")
check(showcase:FindFirstChild("Logotipos"):FindFirstChild("Simbolo_quick") ~= nil,
	"Símbolos devem ser próprios, geométricos e independentes da EA")
check(homeRoot:FindFirstChild("NomeRealJogador").Text == services.Players.LocalPlayer.Name
	and homeRoot:FindFirstChild("NivelRealJogador")==nil,
	"Nome deve continuar e texto Nível deve ser removido")
local brand = homeRoot:FindFirstChild("MarcaCL27")
check(brand and brand.Text == "CL 27"
	and brand.Position.X.Scale == 0.5 and brand.AnchorPoint.X == 0.5
	and brand.TextXAlignment == Enum.TextXAlignment.Center,
	"Texto CL 27 precisa estar precisamente centralizado na tela")
check(homeRoot:FindFirstChild("AjudaInferior")==nil,
	"Instrucoes A Selecionar B Voltar foram solicitadas para remocao")
local ctaSweep = primary:FindFirstChild("OuterGlowSweepCapsula")
local ctaPiece = ctaSweep and ctaSweep:FindFirstChild("SweepBorda_01")
check(ctaSweep and ctaPiece and ctaPiece:IsA("CanvasGroup")
	and ctaPiece:FindFirstChild("HaloExternoSuave")
	and ctaPiece:FindFirstChild("GlowMedio")
	and ctaPiece:FindFirstChild("LinhaBranca"),
	"Botao X deve manter Outer Glow Sweep branco-menta sem pontos em fila")
check(ctaPiece:FindFirstChild("LinhaBranca").Size.Y.Offset == 2.25
	and ctaPiece:FindFirstChild("GlowMedio").Size.Y.Offset == 8.4,
	"Capsula X e CL devem compartilhar a nova espessura de brilho")
check(primary:FindFirstChild("CobraNeonCapsula") == nil
	and primary:FindFirstChild("ReflexoAnimado") == nil,
	"Reflexo atravessando o botao e luz cobra devem permanecer removidos")
local sweepSamples = 0
for _, node in ipairs(ctaSweep:GetChildren()) do
	if node.Name:match("^SweepBorda_") then sweepSamples += 1 end
end
check(sweepSamples == 78, "Contorno deve ser amostrado para formar faixa continua, nao seis pontos")

-- Brilho localizado, não contorno completo piscando: apenas uma porção da
-- borda fica acesa a cada instante e o foco desloca-se continuamente.
services.RunService.Heartbeat:Fire(0.05)
local illuminated = 0
for _, sample in ipairs(ctaSweep:GetChildren()) do
	if sample.Name:match("^SweepBorda_") and sample.GroupTransparency < 0.98 then
		illuminated += 1
	end
end
check(illuminated >= 3 and illuminated <= 28,
	"Outer Glow Sweep deve iluminar uma faixa curta e deixar o resto da borda apagado")
local firstPillPiece = ctaSweep:FindFirstChild("SweepBorda_78")
local beforePillGlow = firstPillPiece.GroupTransparency
services.RunService.Heartbeat:Fire(0.10)
check(firstPillPiece.GroupTransparency ~= beforePillGlow,
	"Varredura deve deslocar luminosidade pela capsula sem flashes de borda inteira")
check(ctaPiece.Position.Y.Offset > 30 and ctaPiece.Position.X.Offset < 65,
	"Varredura da capsula precisa comecar junto a curva inferior esquerda")

local clubOption = homeList:FindFirstChild("Opcao_4")
local kickOff = homeList:FindFirstChild("Opcao_3")
local glow = homeList:FindFirstChild("BrilhoRadialSelecao")
check(glow ~= nil and glow:IsA("CanvasGroup"),
	"Não foi criada a camada radial única atrás do menu")
check(glow.Size.X.Offset <= 318 and glow.Size.Y.Offset == 92
	and glow.ZIndex < kickOff.ZIndex,
	"Brilho deve ficar atrás das letras e não ocupar um retângulo grande")
local halos = 0
for _, node in ipairs(homeList:GetChildren()) do
	if node.Name == "BrilhoRadialSelecao" then halos += 1 end
end
check(halos == 1, "Cada item não pode criar sua própria névoa redundante")
for _, node in ipairs(homeList:GetDescendants()) do
	if node:IsA("ImageLabel") then
		check(not string.find(tostring(node.Image), "smoke_main.dds", 1, true),
			"Textura de fumaça antiga ainda existe no lobby")
	end
end
for i = 1, 14 do
	local layer = glow:FindFirstChild(string.format("CamadaRadial_%02d", i))
	check(layer ~= nil and layer:IsA("Frame") and layer:FindFirstChildOfClass("UICorner") ~= nil,
		"Halo precisa de elipses concêntricas sem bordas retangulares")
	local gradient = layer:FindFirstChildOfClass("UIGradient")
	check(gradient ~= nil and gradient.Rotation == 90,
		"Camadas radiais devem dissolver verticalmente")
end
local pulse = glow:FindFirstChild("PulsoSelecao")
check(pulse ~= nil and pulse:IsA("CanvasGroup")
	and pulse.GroupTransparency == 1 and glow.GroupTransparency == 1,
	"Brilho verde deve ficar completamente invisivel antes do clique")
local yBefore = glow.Position.Y.Offset
clubOption.Activated:Fire()
check(glow.GroupTransparency == 0 and pulse.GroupTransparency < 0.5
	and not wipe.Visible and not UI.inputLocked and not handle.state.menuInputLocked,
	"Clicar na opcao branca deve causar impacto verde, sem loading artificial")
check(handle.state.homeFocus == 4 and handle.state.screen == "HomeInterior",
	"Opcao lateral deve mudar apenas a selecao sem abrir outra tela")
local lessons = homeList:FindFirstChild("SubmenuAprenda")
check(lessons and lessons.Visible and lessons:FindFirstChild("SubOpcao_4"),
	"Aprenda a Jogar deve expandir quatro subopcoes")
check(glow.Position.Y.Offset > yBefore,
	"Impacto verde deve aparecer atras da opcao que foi clicada")
advance(0.16)
check(clubOption.TextTransparency > 0 and clubOption.TextTransparency < 0.32
	and glow.GroupTransparency > 0 and glow.GroupTransparency < 1,
	"Glow forte deve diminuir rapidamente apos impacto")
advance(0.52)
check(clubOption.TextTransparency == 0 and glow.GroupTransparency == 1
	and pulse.GroupTransparency == 1 and not wipe.Visible and not UI.inputLocked,
	"Selecao branca deve permanecer SEM glow verde depois do impacto")
check(homeList:FindFirstChild("Opcao_5").Position.Y.Offset > 400,
	"Upgrade deve descer quando Aprenda a Jogar expande")
local core = glow:FindFirstChild("CamadaRadial_14")
local brightnessBefore = core.BackgroundTransparency
services.RunService.Heartbeat:Fire(0.05)
check(core.BackgroundTransparency ~= brightnessBefore,
	"Camadas podem animar em fundo, mas grupo oculto nao pode exibir luz")
kickOff.Activated:Fire()
check(glow.GroupTransparency == 0 and not wipe.Visible,
	"Novo clique deve reiniciar o impacto imediatamente, sem loading")
advance(0.69)
check(handle.state.homeFocus == 3 and kickOff.TextTransparency == 0
	and glow.GroupTransparency == 1 and not lessons.Visible,
	"Troca para Jogo Rapido precisa sumir com efeito verde logo apos clique")
local news = homeList:FindFirstChild("Opcao_1")
news.MouseEnter:Fire()
advance(0.32)
check(news.TextTransparency == 0 and kickOff.TextTransparency == 0.32
	and handle.state.homeFocus == 3,
	"Hover deve trocar o foco visual, nunca deixar dois botões brancos")
news.MouseLeave:Fire()
advance(0.32)
check(news.TextTransparency == 0.32 and kickOff.TextTransparency == 0,
	"MouseLeave deve restaurar somente a seleção persistente")
local manager = homeList:FindFirstChild("Opcao_2")
manager.InputBegan:Fire({UserInputType = Enum.UserInputType.Touch})
advance(0.32)
check(manager.TextTransparency == 0 and kickOff.TextTransparency == 0.32
	and handle.state.homeFocus == 3,
	"Toque deve transferir o foco visual sem duplicar o texto branco")
manager.InputEnded:Fire({UserInputType = Enum.UserInputType.Touch})
advance(0.32)
check(manager.TextTransparency == 0.32 and kickOff.TextTransparency == 0,
	"Soltar toque deve devolver foco branco somente ao botão selecionado")
-- Selecoes internas tambem devem ser imediatas; animacao breve de impacto.
clubOption.Activated:Fire()
advance(0.69)
lessons:FindFirstChild("SubOpcao_2").Activated:Fire()
check(not wipe.Visible and not UI.inputLocked,
	"Subopcao de Aprenda nao deve exibir carregamento")
check(handle.state.homeLesson == 2 and handle.state.screen == "HomeInterior",
	"Subopcao Rush deve atualizar foco sem inventar rota")
advance(0.55)
check(showcase:FindFirstChild("TituloCentral").Text == "RUSH"
	and primary:FindFirstChild("TextoAcao").Text == "Conhecer Rush",
	"Submenu deve atualizar CTA e titulo central")
kickOff.Activated:Fire()
advance(0.55)
check(showcase:FindFirstChild("TituloCentral").Text == "JOGO RÁPIDO"
	and not lessons.Visible and not wipe.Visible,
	"Troca de secao deve manter lobby livre do carregamento")
-- Trilha continua ativa, mas NENHUMA notificação de música é criada.
local sound = services.SoundService:FindFirstChild("CL27SoundtrackLocal")
check(sound ~= nil and sound.IsPlaying, "Musica ambiente deve continuar tocando")
check(gui:FindFirstChild("SoundtrackOverlay")==nil
	and gui:FindFirstChild("NowPlayingNotification",true)==nil,
	"Remover totalmente banner e notificacao musical sem mutar a trilha")
local initialSound = sound.SoundId
check(initialSound == "rbxassetid://5409360995" or initialSound == "rbxassetid://5410086218"
	or initialSound == "rbxassetid://702367070", "Trilha tocou identificador nao esperado")
sound.IsPlaying = false
sound.Ended:Fire()
advance(1.99)
check(not sound.IsPlaying, "Proxima musica nao pode tocar antes do intervalo")
advance(0.01)
check(sound.IsPlaying and gui:FindFirstChild("NowPlayingNotification",true)==nil,
	"Musica deve trocar em 2 segundos SEM reaparecer notificacao")
-- O conteúdo central precisa continuar legível no Android em paisagem.
local uiCamera = workspace.CurrentCamera
uiCamera.ViewportSize = Vector2.new(854, 393)
uiCamera:GetPropertyChangedSignal("ViewportSize"):Fire()
check(primary.Size.Y.Offset == 44
	and showcase:FindFirstChild("TituloCentral").TextSize == 25
	and primary:FindFirstChildOfClass("UISizeConstraint") ~= nil,
	"A cápsula e a hierarquia central não se adaptaram à tela do celular")
uiCamera.ViewportSize = Vector2.new(1600, 900)
uiCamera:GetPropertyChangedSignal("ViewportSize"):Fire()
check(showcase:FindFirstChild("TituloCentral").TextSize == 36,
	"Rotação / aumento da tela deve restaurar tamanho desktop")

local upgradeOption = homeList:FindFirstChild("Opcao_5")
upgradeOption.Activated:Fire()
advance(0.55)
check(showcase:FindFirstChild("TituloCentral").Text == "UPGRADE"
	and showcase:FindFirstChild("PrevisoesUpgrade").Visible,
	"Upgrade precisa ter conteudo proprio e tres miniaturas")
primary.Activated:Fire()
check(handle.state.screen == "HomeInterior",
	"Upgrade ainda nao e rota disponivel; nao deve abrir um sistema inventado")
kickOff.Activated:Fire()
advance(0.55)
check(showcase:FindFirstChild("TituloCentral").Text == "JOGO RÁPIDO",
	"Voltar de Upgrade precisa restaurar a apresentação de Jogo Rápido")


-- Única engrenagem vetorial moderna, sem botão de acessibilidade no lobby.
local settingsIcon = homeRoot:FindFirstChild("Configuracoes")
check(settingsIcon and settingsIcon.Text == ""
	and settingsIcon:FindFirstChild("EngrenagemVetorial") ~= nil,
	"Trocar engrenagem por desenho vetorial moderno e sem emoji")
check(settingsIcon:FindFirstChild("Dente_12") ~= nil
	and settingsIcon:FindFirstChild("EngrenagemVetorial"):FindFirstChild("FuroCentral") ~= nil,
	"Ícone precisa ter aro de precisão e 12 dentes")
check(homeRoot:FindFirstChild("Acessibilidade") == nil,
	"Botao redundante de Acessibilidade deve desaparecer do lobby")
settingsIcon.Activated:Fire()
check(handle.state.screen == "HomeInterior" and wipe.Visible
	and wipe.GroupTransparency == 1 and UI.inputLocked,
	"Entrar em Configuracoes deve iniciar loading sem esconder o fundo abruptamente")
services.RunService.Heartbeat:Fire(0.09)
local beforeSweep = clPiece.GroupTransparency
services.RunService.Heartbeat:Fire(0.05)
check(clPiece.GroupTransparency ~= beforeSweep,
	"Foco branco precisa percorrer as arestas CL continuamente")
advance(0.18)
check(handle.state.screen == "HomeInterior" and wipe.Visible
	and wipe.GroupTransparency > 0 and wipe.GroupTransparency < 1,
	"Entrada do loading deve escurecer a tela gradualmente")
advance(1.87)
check(handle.state.screen == "Settings" and not homeHud.Enabled
	and wipe.Visible and wipe.GroupTransparency == 0,
	"Configuracoes devem carregar perto do final dos 2,5 segundos")
advance(0.18)
check(wipe.Visible and wipe.GroupTransparency == 0 and UI.inputLocked,
	"Controles ainda devem estar bloqueados antes de revelar Settings")
advance(0.10)
check(wipe.Visible and wipe.GroupTransparency > 0 and wipe.GroupTransparency < 1,
	"Loading deve revelar suavemente a tela de destino")
advance(0.18)
check(not wipe.Visible and wipe.GroupTransparency == 1 and not UI.inputLocked,
	"Loading deve liberar a interface somente apos os 2,5 segundos")
local settingsGui = playerGui:FindFirstChild("CL27_SettingsHUD")
check(settingsGui ~= nil and settingsGui.DisplayOrder > gui.DisplayOrder and settingsGui.Enabled,
	"Settings não está em um ScreenGui independente acima do wipe")
local settingsPage = settingsGui:FindFirstChild("SettingsCanvas"):FindFirstChild("Settings")
local settingsGrid = settingsPage:FindFirstChild("GradeConfiguracoes")
check(settingsGrid ~= nil and settingsGrid.Size.X.Offset == 1115
	and settingsGrid.Size.Y.Offset == 493,
	"Grade de configurações não apareceu na tela central")
local settingsScene = services.lastScene
check(settingsScene.settingsNeonVisible == true, "A arena precisa exibir os neons somente em Settings")
for i = 1, 8 do
	local card = settingsGrid:FindFirstChild("Cartao_" .. tostring(i))
	check(card ~= nil and card:FindFirstChild("TituloCartao") ~= nil,
		"Falta cartão ou título na posição " .. tostring(i))
	check(card:FindFirstChild("Icone_" .. ({"settings","profile","online","playtime","edit","sheets","create","music"})[i]) ~= nil,
		"Falta ícone exclusivo no cartão " .. tostring(i))
	check(card.Position.X.Offset == ((i - 1) % 4) * 281
		and card.Position.Y.Offset == math.floor((i - 1) / 4) * 251
		and card.Size.X.Offset == 272 and card.Size.Y.Offset == 242,
		"Cartões ampliados devem manter grade 4 colunas por 2 linhas")
	check(card:FindFirstChild("TituloCartao").TextSize >= 24
		and card:FindFirstChild("Icone_" .. ({"settings","profile","online","playtime","edit","sheets","create","music"})[i]):FindFirstChildOfClass("UIScale").Scale > 1,
		"Títulos e ícones também precisam ser maiores, não apenas os cartões")
end
check(settingsGrid:FindFirstChild("Cartao_2").BackgroundColor3.R > 0.95,
	"Perfil deve começar com cartão branco")
check(settingsGrid:FindFirstChild("Cartao_1").BackgroundColor3.R < 0.1,
	"Os demais cartões devem permanecer escuros")
check(settingsPage:FindFirstChild("Action_≡  CENTRAL", true) == nil,
	"Menu de Configurações não deve conter rodapé antigo")
advance(0.36)
local beforeSettings = handle.state.settings.quality
settingsGrid:FindFirstChild("Cartao_6").Activated:Fire()
advance(0.22)
check(handle.state.settingsCard == 6 and handle.state.screen == "Settings"
	and handle.state.settings.quality == beforeSettings,
	"Cartões devem atualizar somente o foco visual, sem sistemas internos")
check(settingsGrid:FindFirstChild("Cartao_6").BackgroundColor3.R > 0.95
	and settingsGrid:FindFirstChild("Cartao_2").BackgroundColor3.R < 0.1,
	"Somente um cartão pode estar selecionado em branco")
settingsPage:FindFirstChild("FecharConfiguracoes").Activated:Fire()
check(wipe.Visible and UI.inputLocked and handle.state.screen=="Settings",
	"Fechar Configuracoes tambem deve carregar por 2,5 segundos")
advance(2.51)
check(handle.state.screen == "HomeInterior" and homeHud.Enabled
	and not settingsGui.Enabled and services.lastScene.settingsNeonVisible == false,
	"Voltar precisa restaurar lobby original sem neons de Settings")
settingsIcon.Activated:Fire()
check(wipe.Visible, "Engrenagem deve iniciar carregamento CL")
advance(2.51)
check(handle.state.screen == "Settings" and services.lastScene.settingsNeonVisible and settingsGui.Enabled,
	"Engrenagem não exibiu menu e neons")
check(settingsGrid:FindFirstChild("Cartao_6").BackgroundColor3.R > 0.95,
	"Seleção visual deve persistir ao reabrir Configurações")
settingsPage:FindFirstChild("FecharConfiguracoes").Activated:Fire()
advance(2.51)
check(handle.state.screen == "HomeInterior" and homeHud.Enabled and not settingsGui.Enabled,
	"Fechar Configurações não retornou ao lobby original")

-- Mesmo que a cena falhe na troca, os 2,5 segundos sao respeitados
-- e a interface permanece utilizavel depois da falha.
services.failNextSceneShow = true
settingsIcon.Activated:Fire()
advance(2.10)
check(handle.state.screen == "Settings" and settingsGui.Enabled
	and wipe.Visible and wipe.GroupTransparency == 0,
	"Erro no cenario nao pode remover o loading antes de concluir")
advance(0.41)
check(not wipe.Visible and not UI.inputLocked,
	"Um erro de render deixou a tela de carregamento permanente")
check(settingsGrid.Parent == settingsPage and settingsGrid:FindFirstChild("Cartao_2") ~= nil,
	"Erro na cena nao pode eliminar cartoes de Configuracoes")
settingsPage:FindFirstChild("FecharConfiguracoes").Activated:Fire()
advance(2.51)
check(handle.state.screen == "HomeInterior" and not settingsGui.Enabled
	and homeHud.Enabled and not wipe.Visible and not UI.inputLocked,
	"Depois do erro, voltar precisa restaurar o lobby sem travar")

check(handle.state.screen == "HomeInterior" and not wipe.Visible,
	"Lobby deve estar livre apos a ultima transicao")
primary.Activated:Fire()
check(handle.state.screen == "HomeInterior" and wipe.Visible and UI.inputLocked,
	"Acao principal Jogo Rapido precisa acionar carregamento CL")
advance(0.22)
check(handle.state.screen == "HomeInterior" and wipe.GroupTransparency > 0 and wipe.GroupTransparency < 1,
	"Background deve escurecer gradualmente, sem wipe solido")
advance(1.82)
check(handle.state.screen == "Clubs" and UI.inputLocked and wipe.Visible
	and wipe.GroupTransparency == 0, "Troca para modo de jogo deve ocorrer durante loading")
check(not homeHud.Enabled, "HUD inicial deve ocultar ao acessar outra secao")
check(services.GuiService.SelectedObject == nil, "Foco de controle deve aguardar desbloqueio")
advance(0.24)
check(wipe.GroupTransparency > 0 and wipe.GroupTransparency < 1 and UI.inputLocked,
	"Saida deve revelar o modo de jogo sem liberar input cedo")
advance(0.24)
check(not wipe.Visible and not UI.inputLocked, "Loading de 2,5 segundos deve terminar")
check(services.GuiService.SelectedObject ~= nil, "Foco do controle deve voltar apos loading")

-- CLUBS é uma apresentação de túnel. Não renderizar a antiga seleção
-- de equipes, menus, overlays coloridos ou o rodapé inteiro.
local ambient = transitionGui:FindFirstChild("CarregamentoContinuo")
check(ambient ~= nil and ambient.Visible and not ambient.Active
	and ambient.BackgroundTransparency == 1 and emblem.Parent == ambient,
	"CL de carregamento deve permanecer no rodape sem escurecer o tunel")
check(wipe.Visible == false and not UI.inputLocked and not handle.state.menuInputLocked,
	"Carregamento infinito é apenas visual: nunca bloquear saída ou tela 3D")
local tunnelPage = canvas.Clubs
local backFromTunnel = tunnelPage:FindFirstChild("VoltarDoTunel")
check(backFromTunnel and backFromTunnel:IsA("TextButton"),
	"Clubs deve ter um retorno discreto para usuários Android")
check(tunnelPage:FindFirstChild("Action_≡  CENTRAL",true)==nil
	and tunnelPage:FindFirstChild("Action_‹  VOLTAR",true)==nil,
	"Clubs não deve mostrar rodapé ou seleção de equipes por cima do túnel")
local beforeClub = handle.state.homeClub
key(Enum.KeyCode.M)
check(handle.state.screen == "Clubs" and not UI.inputLocked,
	"Atalho de central não pode encobrir o túnel")
key(Enum.KeyCode.Right)
check(handle.state.homeClub == beforeClub,
	"Setas não devem alterar clubes enquanto o túnel é apresentado")
local oldHeading = tunnelPage:FindFirstChild("PAÍS    Todos   ›", true)
check(oldHeading == nil and #tunnelPage:GetChildren() == 1,
	"Clubs deve exibir somente o túnel e o pequeno botão de retorno")
advance(9)
check(ambient.Visible and not wipe.Visible and not UI.inputLocked,
	"Indicador CL deve continuar indefinidamente sem voltar a sobreposição escura")
-- O botão de retorno é necessário para celular: fecha o túnel e interrompe
-- a marca permanente; a transição de volta mantém os 2,5 segundos.
backFromTunnel.Activated:Fire()
check(wipe.Visible and UI.inputLocked and handle.state.screen == "Clubs",
	"Voltar do túnel deve iniciar transição normal, não travar na marca eterna")
advance(2.51)
check(handle.state.screen == "HomeInterior" and homeHud.Enabled
	and not ambient.Visible and not wipe.Visible and not UI.inputLocked,
	"Sair do túnel deve restaurar o lobby e remover o indicador persistente")
primary.Activated:Fire()
advance(2.51)
check(handle.state.screen == "Clubs" and ambient.Visible and not wipe.Visible,
	"Entrar novamente em Clubs deve montar de novo o túnel e o CL infinito")

-- Rotas programaticas em fila nao interrompem o loading ativo.
-- O ultimo destino continua vencendo apos o tempo de 2,5 segundos.
handle.go("Squad")
advance(0.2)
handle.go("Overview")
handle.go("Kits")
advance(2.29)
check(handle.state.screen == "Squad" and UI.inputLocked and wipe.Visible,
	"Destino pendente nao pode interromper o primeiro carregamento")
advance(2.05)
check(handle.state.screen == "Kits" and wipe.Visible and UI.inputLocked,
	"Ultima rota da fila deve vencer durante o carregamento seguinte")
advance(0.46)
check(not wipe.Visible and not UI.inputLocked,
	"Depois da fila o loading precisa liberar novamente os controles")
local kitBefore = handle.state.homeKit
key(Enum.KeyCode.DPadRight)
check(handle.state.homeKit == kitBefore, "Controller focus movement must not cycle kits globally")
key(Enum.KeyCode.Right)
check(handle.state.homeKit ~= kitBefore, "Keyboard arrows must continue cycling kits")
key(Enum.KeyCode.ButtonB)
advance(2.51)
check(handle.state.screen == "Squad", "History must preserve actual visited routes")
key(Enum.KeyCode.M)
for _, button in ipairs(canvas.Squad:GetDescendants()) do
	if button:IsA("GuiButton") and button.Text == "Táticas" then button.Activated:Fire(); break end
end
check(handle.state.screen == "Squad" and not wipe.Visible and UI.inputLocked, "Header tab must not navigate beneath central menu")
key(Enum.KeyCode.ButtonB)
check(not UI.inputLocked, "Closing central menu must release header lock")

handle.state.settings.reducedMotion = true
handle.go("HomeTraining")
advance(0.15)
check(handle.state.screen == "Squad" and UI.inputLocked and wipe.Visible,
	"Movimento reduzido mantem 2,5 s, apenas elimina a animacao segmentada")
check(not clSweep.Visible,
	"Movimento reduzido deve deixar CL estatico sem efeitos luminosos móveis")
advance(2.0)
check(handle.state.screen == "HomeTraining" and wipe.Visible and UI.inputLocked,
	"Movimento reduzido nao deve eliminar o tempo minimo de carregamento")
advance(0.36)
check(not wipe.Visible and not UI.inputLocked,
	"Movimento reduzido deve terminar em 2,5 s e liberar os controles")

-- Completed jobs must not accumulate cleanup closures throughout a long session.
local scope, callbacks = Scope.new(), 0
for _ = 1, 100 do scope:Delay(0.01, function() callbacks += 1 end); advance(0.01) end
check(callbacks == 100, "Scheduled work failed to execute")
check(#scope.cleanups == 0, "Completed delays accumulate lifetime cleanup closures")
check(next(scope.delays) == nil, "Completed delays must leave no active jobs")
scope:Delay(1, function() callbacks += 1000 end)
scope:Destroy()
advance(1)
check(callbacks == 100 and not scope.alive, "Destroyed scope executed delayed work")

-- A same-page update keeps the selected controller row and its scroll position.
handle.go("Development")
advance(2.51)
local development = canvas.Development
local athleteList = development:FindFirstChild("AtletasEmDesenvolvimento", true)
local lastAthlete
for _, object in ipairs(athleteList:GetDescendants()) do if object:IsA("GuiButton") then lastAthlete = object end end
athleteList.CanvasPosition = Vector2.new(0, 500)
services.GuiService.SelectedObject = lastAthlete
lastAthlete.Activated:Fire()
local replacementList = canvas.Development:FindFirstChild("AtletasEmDesenvolvimento", true)
local replacementLast
for _, object in ipairs(replacementList:GetDescendants()) do if object:IsA("GuiButton") then replacementLast = object end end
check(handle.state.selectedPlayer == #Data.players, "Selecting the last athlete did not update the detail state")
check(replacementList.CanvasPosition.Y == 500, "Detail rerender reset the list scroll position")
check(services.GuiService.SelectedObject == replacementLast, "Detail rerender reset controller focus to the first button")

handle.go("Calendar")
advance(0.02)
local scene = services.lastScene
handle.destroy()
advance(2)
check(scene.destroyed and gui.Destroyed and settingsGui.Destroyed and transitionGui.Destroyed,
	"Disposal must destroy scene, principal UI, Settings HUD and transition overlay")
check(homeHud.Destroyed, "HUD independente não foi destruído com o App")
check(not UI.inputLocked, "Disposal must release shared input lock")
handle.go("Finance")
advance(1)
check(not UI.inputLocked, "Disposed App handle must ignore navigation")

-- Execute the actual Scene camera callback/lifecycle on narrow camera doubles.
-- No geometry is built and no viewport is rendered by this check.
local SceneReal = require(moduleNodes["src/client/Scene.luau"])
local originalCamera = workspace.CurrentCamera
originalCamera.CameraType = Enum.CameraType.Custom
originalCamera.FieldOfView = 55
local originalFrame = CFrame.new(1, 2, 3)
originalCamera.CFrame = originalFrame
services.Lighting.LightingStyle = Enum.LightingStyle.Soft
services.Lighting.PrioritizeLightingQuality = false
local presentation = SceneReal.new({reducedMotion = false})
presentation:ApplySettings({quality = "Alta"})
check(services.Lighting.LightingStyle == Enum.LightingStyle.Realistic and services.Lighting.PrioritizeLightingQuality,
	"High quality did not request native realistic lighting")
presentation:ApplySettings({quality = "Média"})
check(services.Lighting.LightingStyle == Enum.LightingStyle.Realistic and not services.Lighting.PrioritizeLightingQuality,
	"Medium quality did not preserve realistic lighting without priority")
presentation:ApplySettings({quality = "Baixa"})
check(services.Lighting.LightingStyle == Enum.LightingStyle.Soft and not services.Lighting.PrioritizeLightingQuality,
	"Low quality did not use native soft lighting")
-- A geometria antiga da arena não é substituída; os neons pertencem
-- exclusivamente à exibição de Configurações.
presentation.mode = "Arena"
presentation:SetSettingsAtmosphere(true)
local neon = presentation.folder:FindFirstChild("CL27_SettingsNeon")
check(neon ~= nil and #presentation.settingsRings == 3,
	"Os três anéis verdes de Configurações não foram criados")
for i = 1, 3 do
	local ring = neon:FindFirstChild("AnelNeon_" .. tostring(i))
	check(ring ~= nil and #ring:GetChildren() == 23,
		"Cada anel precisa ter 22 segmentos e 1 ponto de luz")
end
-- A Scene real utiliza os módulos copiados do PR #7 sem câmera própria:
-- o App é o único controlador da câmera e da iluminação.
presentation:ApplySettings({quality="Alta", reducedMotion=false})
presentation:Show("Tunnel", Data.clubs[1], Data.clubs[2], 1, 1)
check(presentation.tunnel ~= nil
	and presentation.folder:FindFirstChild("CinematicTunnel", true) ~= nil,
	"Scene deve montar a arquitetura real do túnel no Workspace")
check(presentation.tunnel.model:GetAttribute("PartCount") == 366,
	"Qualidade Alta deve usar geometria real com 366 peças")
check(presentation.fov == 54 and presentation.cameraPosition.Y == 5.2
	and presentation.tunnel.camera == nil,
	"Túnel deve reutilizar a câmera principal no FOV original de 54 graus")
check(presentation.atmosphere.Density == 0 and services.Lighting.FogStart == 74,
	"Atmosfera original não pode encobrir a névoa distante do túnel")
presentation:ApplySettings({quality="Baixa",reducedMotion=true})
check(presentation.tunnel.quality == "Low"
	and presentation.tunnel.model:GetAttribute("PartCount") == 238,
	"Modo Baixa deve reduzir o túnel para 238 partes")
presentation:ApplySettings({quality="Média",reducedMotion=true})
check(presentation.tunnel.quality == "Medium"
	and presentation.tunnel.model:GetAttribute("PartCount") == 334,
	"Modo Média deve usar 334 partes sem alterar o módulo original")
local formerTunnel = presentation.tunnel
presentation:Show("Arena", Data.clubs[1], Data.clubs[2], 1, 1)
check(presentation.tunnel == nil and formerTunnel.destroyed
	and services.Lighting.FogStart ~= 74,
	"Sair do túnel deve liberar a geometria e restaurar a névoa")
presentation.cameraPosition = Vector3.new(0, 4, 17)
presentation.cameraTarget = Vector3.new(0, 2, -1)
services.RunService.RenderStepped:Fire(1 / 60)
check(originalCamera.CameraType == Enum.CameraType.Scriptable, "Scene did not take camera control")
check(presentation.settingsRings[1].light.Brightness ~= 0.38,
	"Os neons devem pulsar enquanto o cenário está ativo")
presentation:SetSettingsAtmosphere(false)
check(presentation.settingsNeon == nil and #presentation.settingsRings == 0 and neon.Parent == nil,
	"Neons continuam na arena depois de sair de Configurações")
local replacement = Instance.new("Camera")
replacement.ViewportSize = Vector2.new(1600, 900)
replacement.CameraType = Enum.CameraType.Custom
replacement.FieldOfView = 65
local replacementFrame = CFrame.new(4, 5, 6)
replacement.CFrame = replacementFrame
workspace.CurrentCamera = replacement
services.RunService.RenderStepped:Fire(1 / 60)
check(replacement.CameraType == Enum.CameraType.Scriptable, "Scene did not follow replacement camera")
presentation:Destroy()
check(services.Lighting.LightingStyle == Enum.LightingStyle.Soft and not services.Lighting.PrioritizeLightingQuality,
	"Scene did not restore native lighting preferences during disposal")
check(replacement.CameraType == Enum.CameraType.Custom and replacement.FieldOfView == 65 and replacement.CFrame == replacementFrame,
	"Scene must restore a replacement camera during disposal")
check(originalCamera.CameraType == Enum.CameraType.Custom and originalCamera.FieldOfView == 55 and originalCamera.CFrame == originalFrame,
	"Scene must restore its original camera during disposal")
services.RunService.RenderStepped:Fire(1 / 60)
check(replacement.CameraType == Enum.CameraType.Custom, "Disposed Scene retained its render callback")
-- A única pose mantém a bola sob o pé e não alterna após 10/20 segundos.
do
	local MenuAvatar = require(moduleNodes["src/client/MenuAvatar.luau"])
	local presentation = Instance.new("Model")
	local root = Instance.new("Part")
	root.CFrame = CFrame.new(5, 3, 0)
	root.Parent = presentation
	local ball = Instance.new("Model")
	local motor = Instance.new("Motor6D")
	local constraint = Instance.new("AnimationConstraint")
	local ballLocation = Vector3.new(5.6, 0.5, 1)
	local fake = {
		alive = true, model = presentation, root = root, ball = ball,
		ballGround = ballLocation, radius = 0.5, hand = nil,
		elapsed = 0,
		joints = {RightShoulder = motor, RightHip = constraint},
		settings = {reducedMotion = false},
	}
	MenuAvatar._step(fake, 0.01)
	check(fake.elapsed == 0.01, "Idle character animation did not advance")
	check(motor.Transform ~= nil and constraint.Transform ~= nil, "Legacy and upgraded joints did not receive pose")
	check(ball:GetPivot().Position == ballLocation, "Ball must remain at the player's foot")
	MenuAvatar._step(fake, 10)
	MenuAvatar._step(fake, 10)
	check(fake.pose == nil and fake.blend == nil, "Character must never switch to the holding pose")
	check(ball:GetPivot().Position == ballLocation, "Ball moved away from foot after 20 seconds")
	fake.settings.reducedMotion = true
	MenuAvatar._step(fake, 0.1)
	check(motor.Transform ~= nil and constraint.Transform ~= nil, "Reduced-motion pose disappeared")
	ball:Destroy()
	presentation:Destroy()
end

-- Tela móvel horizontal: as cinco opções devem caber e o submenu deve
-- ficar acessível por rolagem sem reduzir o texto a tamanho ilegível.
replacement.ViewportSize = Vector2.new(854, 393)
local mobile = App.start()
local mobileHud = playerGui:FindFirstChild("CL27_HomeHUD")
local mobileList = mobileHud:FindFirstChild("HomeOverlay"):FindFirstChild("MenuPrincipalFC")
check(mobileList:FindFirstChild("Opcao_5").Position.Y.Offset <= 225,
	"No celular o último item fica escondido; diminuir distância entre linhas")
check(mobileList:FindFirstChild("Opcao_1").TextSize >= 22,
	"Correção de espaçamento não pode encolher a tipografia excessivamente")
mobileList:FindFirstChild("Opcao_4").Activated:Fire()
advance(0.55)
local mobileLessons = mobileList:FindFirstChild("SubmenuAprenda")
check(mobileLessons.Visible and mobileLessons.Size.X.Scale == 1
	and mobileList.CanvasPosition.Y > 0,
	"Submenu deve caber na largura do celular e posicionar a rolagem corretamente")
mobileLessons:FindFirstChild("SubOpcao_4").Activated:Fire()
check(mobile.state.homeLesson == 4 and not mobile.state.menuInputLocked,
	"Submenu movel nao deve bloquear cliques com loading artificial")
advance(0.55)
mobileList:FindFirstChild("Opcao_5").Activated:Fire()
advance(0.55)
check(mobile.state.homeFocus == 5 and mobileList.CanvasPosition.Y == 0,
	"Fechar submenu no celular deve restaurar posição inicial da rolagem")
mobile.destroy()
replacement.ViewportSize = Vector2.new(1600, 900)

print(string.format("PASS App phases: %d assertions; virtual-clock stubs only, no Roblox capture/easing certification.", assertions))
