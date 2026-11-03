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
	"Transição precisa sobrepor os dois menus e ignorar margens da tela")
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
	and homeRoot:FindFirstChild("NivelRealJogador").Text == "Nível —",
	"Nome/nível do Roblox não foram criados corretamente")
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
check(pulse ~= nil and pulse:IsA("CanvasGroup") and pulse.GroupTransparency == 1,
	"Pulso radial deve ser independente e começar transparente")
local yBefore = glow.Position.Y.Offset
clubOption.Activated:Fire()
check(pulse.GroupTransparency < 0.5,
	"Seleção deve produzir pulso discreto no halo radial")
check(handle.state.homeFocus == 4 and handle.state.screen == "HomeInterior",
	"Seleção lateral não pode navegar sem usar o botão principal")
local lessons = homeList:FindFirstChild("SubmenuAprenda")
check(lessons ~= nil and lessons.Visible
	and lessons:FindFirstChild("SubOpcao_4") ~= nil,
	"Aprenda a Jogar deve expandir quatro subopções")
check(clubOption.TextTransparency > 0 and glow.Position.Y.Offset == yBefore,
	"Troca de seleção deve iniciar sem deslocamento instantâneo")
advance(0.16)
check(clubOption.TextTransparency > 0 and clubOption.TextTransparency < 0.32
	and glow.Position.Y.Offset > yBefore and glow.Position.Y.Offset < 203,
	"Aos 160 ms, texto e halo radial devem estar em transição")
advance(0.36)
check(clubOption.TextTransparency == 0 and glow.Position.Y.Offset == 203
	and glow.GroupTransparency == 0.09 and pulse.GroupTransparency == 1,
	"Brilho radial não chegou suavemente à nova linha ou manteve o pulso")
check(homeList:FindFirstChild("Opcao_5").Position.Y.Offset > 400,
	"Upgrade deve terminar o deslocamento suave quando o submenu expande")
local core = glow:FindFirstChild("CamadaRadial_14")
local brightnessBefore = core.BackgroundTransparency
services.RunService.Heartbeat:Fire(0.05)
check(core.BackgroundTransparency ~= brightnessBefore,
	"Centro do halo deve respirar discretamente sem partículas")
kickOff.Activated:Fire()
advance(0.51)
check(handle.state.homeFocus == 3 and kickOff.TextTransparency == 0
	and glow.Position.Y.Offset == yBefore and not lessons.Visible,
	"Troca de Aprenda para Jogo Rápido não moveu o brilho ou recolheu submenu")
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
-- Testa a seleção interna sem fingir que os modos de jogo estão prontos.
clubOption.Activated:Fire()
advance(0.55)
lessons:FindFirstChild("SubOpcao_2").Activated:Fire()
check(handle.state.homeLesson == 2 and handle.state.screen == "HomeInterior",
	"Selecionar Rush deve alterar somente a apresentação, sem abrir rota")
advance(0.55)
check(showcase:FindFirstChild("TituloCentral").Text == "RUSH"
	and primary:FindFirstChild("TextoAcao").Text == "Conhecer Rush",
	"Submenu deve atualizar título e botão central com transição")
kickOff.Activated:Fire()
advance(0.55)
check(showcase:FindFirstChild("TituloCentral").Text == "JOGO RÁPIDO"
	and not lessons.Visible,
	"Trocar de seção precisa restaurar título e recolher submenu")
-- A trilha toca automaticamente SEM painel fixo ou lista intrusiva.
local overlay = gui:FindFirstChild("SoundtrackOverlay")
local sound = services.SoundService:FindFirstChild("CL27SoundtrackLocal")
check(overlay ~= nil and sound ~= nil and sound.IsPlaying, "Soundtrack must autoplay on entering CL 27")
local notification = overlay:FindFirstChild("NowPlayingNotification")
check(notification ~= nil and notification.Visible, "Notificação de música precisa abrir automaticamente")
check(notification:IsA("CanvasGroup"), "Notificação deve suportar transição de opacidade em grupo")
check(notification.Position.X.Scale == 1 and notification.Position.Y.Scale == 0,
	"Notificação deve ficar ancorada no canto superior direito")
check(overlay:FindFirstChild("SoundtrackControls") == nil
	and overlay:FindFirstChild("TracklistPanel") == nil,
	"Painel ou lista musical ainda está visível no layout")
check(notification:FindFirstChild("NomeFaixa") ~= nil and notification:FindFirstChild("ArtistaFaixa") ~= nil
	and notification:FindFirstChild("ProgressoNotificacao") ~= nil,
	"Novo design musical deve mostrar título, artista e progresso")
-- Os testes anteriores avançaram o relógio por 2,7 s; entrada inicial já finalizada.
check(notification.GroupTransparency == 0, "Notificação inicial deve permanecer legível")

local initialSound = sound.SoundId
check(initialSound == "rbxassetid://5409360995" or initialSound == "rbxassetid://5410086218"
	or initialSound == "rbxassetid://702367070", "Soundtrack played unknown audio ID")
sound.IsPlaying = false
sound.Ended:Fire()
advance(1.99)
check(not sound.IsPlaying, "Next song started before the exact 2-second gap")
advance(0.01)
check(sound.IsPlaying and notification.Visible, "Next song did not start after 2 seconds")
check(notification.GroupTransparency == 1, "Próxima música não reiniciou animação da notificação")
advance(0.44)
check(notification.GroupTransparency == 0, "Próxima notificação não apareceu suavemente")
advance(4.55)
check(notification.Visible and notification.GroupTransparency == 0,
	"Notificação encerrou antes dos cinco segundos completos")
advance(0.2)
check(notification.Visible and notification.GroupTransparency > 0 and notification.GroupTransparency < 1,
	"Notificação deve desaparecer com fade, sem corte seco")
advance(0.23)
check(not notification.Visible and notification.GroupTransparency == 1,
	"Notificação permaneceu visível após a saída animada")
check(gui:FindFirstChild("SoundtrackOverlay") == overlay and sound.Parent == services.SoundService,
	"Trilha sonora não deve se perder em navegação")

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
advance(0.51)
check(showcase:FindFirstChild("TituloCentral").Text == "UPGRADE"
	and showcase:FindFirstChild("PrevisoesUpgrade").Visible,
	"Upgrade precisa ter conteúdo próprio e três miniaturas")
primary.Activated:Fire()
check(handle.state.screen == "HomeInterior",
	"Upgrade ainda não é rota disponível; não deve abrir um sistema inventado")
kickOff.Activated:Fire()
advance(0.51)
check(showcase:FindFirstChild("TituloCentral").Text == "JOGO RÁPIDO",
	"Voltar de Upgrade precisa restaurar a apresentação de Jogo Rápido")


-- Ícones compactos em coluna e abertura da nova grade visual.
local settingsIcon = homeRoot:FindFirstChild("Configuracoes")
local accessIcon = homeRoot:FindFirstChild("Acessibilidade")
check(settingsIcon ~= nil and accessIcon ~= nil and settingsIcon.Text == "" and accessIcon.Text == "",
	"Configurações e Acessibilidade não podem usar emojis")
check(settingsIcon.Position.X.Scale == accessIcon.Position.X.Scale
	and accessIcon.Position.Y.Scale > settingsIcon.Position.Y.Scale + 0.07,
	"Ícones precisam ficar um acima do outro à esquerda")
check(settingsIcon:FindFirstChild("EscalaIcone").Scale < 1
	and accessIcon:FindFirstChild("EscalaIcone").Scale < 1,
	"Ícones superiores precisam ser visualmente menores")
accessIcon.Activated:Fire()
check(handle.state.screen == "HomeInterior" and wipe.Visible
	and wipe.GroupTransparency == 1,
	"Entrada deve começar transparente, sem flash de tela sólida")
advance(0.22)
check(handle.state.screen == "HomeInterior" and wipe.Visible
	and wipe.GroupTransparency > 0 and wipe.GroupTransparency < 1,
	"Durante a entrada, a cobertura deve avançar gradualmente")
advance(0.22)
check(handle.state.screen == "Settings" and not homeHud.Enabled
	and wipe.Visible and wipe.GroupTransparency == 0,
	"A página só pode trocar depois de a tela estar completamente coberta")
advance(0.06)
check(wipe.Visible and wipe.GroupTransparency == 0,
	"Manter a tela coberta durante a breve estabilização do cenário")
advance(0.30)
check(wipe.Visible and wipe.GroupTransparency > 0 and wipe.GroupTransparency < 1,
	"Durante a saída, a transição deve revelar suavemente o menu")
advance(0.28)
check(not wipe.Visible and wipe.GroupTransparency == 1 and not UI.inputLocked,
	"Transição fullscreen não terminou ou manteve os controles bloqueados")
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
advance(1.1)
check(handle.state.screen == "HomeInterior" and homeHud.Enabled
	and not settingsGui.Enabled and services.lastScene.settingsNeonVisible == false,
	"Voltar precisa restaurar lobby original sem neons de Settings")
settingsIcon.Activated:Fire()
check(wipe.Visible, "Engrenagem deve iniciar abertura de Configurações")
advance(1.1)
check(handle.state.screen == "Settings" and services.lastScene.settingsNeonVisible and settingsGui.Enabled,
	"Engrenagem não exibiu menu e neons")
check(settingsGrid:FindFirstChild("Cartao_6").BackgroundColor3.R > 0.95,
	"Seleção visual deve persistir ao reabrir Configurações")
settingsPage:FindFirstChild("FecharConfiguracoes").Activated:Fire()
advance(1.1)
check(handle.state.screen == "HomeInterior" and homeHud.Enabled and not settingsGui.Enabled,
	"Fechar Configurações não retornou ao lobby original")

-- Reproduzir a condição da captura: um erro no cenário no meio do wipe.
-- A interface continua visível e o jogador consegue voltar.
services.failNextSceneShow = true
settingsIcon.Activated:Fire()
advance(0.44)
check(handle.state.screen == "Settings" and settingsGui.Enabled
	and wipe.Visible and wipe.GroupTransparency == 0,
	"Um erro na cena não pode revelar o cenário antes de concluir a troca")
advance(0.64)
check(not wipe.Visible and not UI.inputLocked,
	"Um erro de render deixou a transição sobre o menu de configurações")
check(settingsGrid.Parent == settingsPage and settingsGrid:FindFirstChild("Cartao_2") ~= nil,
	"Um erro na cena removeu os cartões do HUD independente")
settingsPage:FindFirstChild("FecharConfiguracoes").Activated:Fire()
advance(1.1)
check(handle.state.screen == "HomeInterior" and not settingsGui.Enabled
	and homeHud.Enabled and not wipe.Visible and not UI.inputLocked,
	"Após o erro, voltar deve recuperar o lobby sem ficar travado")

check(handle.state.screen == "HomeInterior" and not wipe.Visible, "Initial state must be visible and idle")
primary.Activated:Fire()
check(handle.state.screen == "HomeInterior" and wipe.Visible and UI.inputLocked,
	"A ação principal Jogo Rápido deve abrir seleção de equipes via transição")
advance(0.22)
check(handle.state.screen == "HomeInterior" and wipe.GroupTransparency > 0 and wipe.GroupTransparency < 1, "Mid-entry must preserve source")
advance(0.22)
check(handle.state.screen == "Clubs" and UI.inputLocked and wipe.Visible
	and wipe.GroupTransparency == 0, "Swap must happen under opaque full-screen wipe")
check(not homeHud.Enabled, "HUD inicial deve ocultar ao acessar outra seção")
check(services.GuiService.SelectedObject == nil, "Controller focus must wait until page input resumes")
advance(0.36)
check(wipe.GroupTransparency > 0 and wipe.GroupTransparency < 1 and UI.inputLocked, "Mid-exit must retain input lock")
advance(0.28)
check(not wipe.Visible and not UI.inputLocked, "Transition must finish visible and unlocked")
check(services.GuiService.SelectedObject ~= nil, "Controller focus must activate after transition")

-- An open central menu must isolate both global key listeners and old buttons.
local priorSelection = services.GuiService.SelectedObject
local clubBefore = handle.state.homeClub
key(Enum.KeyCode.M)
check(UI.inputLocked, "Central menu must lock underlying header tabs")
key(Enum.KeyCode.Right)
check(handle.state.homeClub == clubBefore, "Club keyboard input leaked beneath central menu")
local sourcePage = canvas.Clubs
for _, button in ipairs(sourcePage:GetDescendants()) do
	if button:IsA("GuiButton") and button.Text == "›" then button.Activated:Fire(); break end
end
check(handle.state.homeClub == clubBefore, "Underlying page button activated beneath central menu")
key(Enum.KeyCode.ButtonB)
check(handle.state.screen == "Clubs" and not UI.inputLocked, "Back must dismiss central menu before navigating")
check(services.GuiService.SelectedObject == priorSelection, "Closing central menu must restore controller selection")
key(Enum.KeyCode.DPadRight)
check(handle.state.homeClub == clubBefore, "Controller focus movement must not cycle clubs globally")
key(Enum.KeyCode.Right)
check(handle.state.homeClub ~= clubBefore, "Closing central menu must resume page input")

-- Latest queued route wins; no geometry swap is performed by a stale delay.
handle.go("Squad")
advance(0.2)
handle.go("Overview")
handle.go("Kits")
advance(0.24)
check(handle.state.screen == "Squad", "Current transition must finish its intended handoff")
advance(0.64)
check(handle.state.screen == "Squad" and UI.inputLocked and wipe.Visible,
	"Queued transition must begin only after first exit completes")
advance(0.44)
check(handle.state.screen == "Kits" and wipe.GroupTransparency == 0,
	"Latest queued route must replace earlier pending route under full coverage")
advance(0.64)
check(not wipe.Visible and not UI.inputLocked, "Queued navigation must release lock")
local kitBefore = handle.state.homeKit
key(Enum.KeyCode.DPadRight)
check(handle.state.homeKit == kitBefore, "Controller focus movement must not cycle kits globally")
key(Enum.KeyCode.Right)
check(handle.state.homeKit ~= kitBefore, "Keyboard arrows must continue cycling kits")
key(Enum.KeyCode.ButtonB)
advance(1.1)
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
advance(0.05)
check(handle.state.screen == "Squad" and UI.inputLocked, "Reduced motion still needs covered handoff")
advance(0.05)
check(handle.state.screen == "HomeTraining", "Reduced motion uses short entry phase")
advance(0.16)
check(not wipe.Visible and not UI.inputLocked, "Reduced motion must finish without lingering lock")

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
advance(0.28)
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
advance(0.54)
local mobileLessons = mobileList:FindFirstChild("SubmenuAprenda")
check(mobileLessons.Visible and mobileLessons.Size.X.Scale == 1
	and mobileList.CanvasPosition.Y > 0,
	"Submenu deve caber na largura do celular e posicionar a rolagem corretamente")
mobileLessons:FindFirstChild("SubOpcao_4").Activated:Fire()
check(mobile.state.homeLesson == 4,
	"Submenu móvel precisa aceitar toque no quarto item")
mobileList:FindFirstChild("Opcao_5").Activated:Fire()
advance(0.54)
check(mobile.state.homeFocus == 5 and mobileList.CanvasPosition.Y == 0,
	"Fechar submenu no celular deve restaurar posição inicial da rolagem")
mobile.destroy()
replacement.ViewportSize = Vector2.new(1600, 900)

print(string.format("PASS App phases: %d assertions; virtual-clock stubs only, no Roblox capture/easing certification.", assertions))
