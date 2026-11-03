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
local wipe = canvas.Transicao
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
check(homeList:FindFirstChild("Opcao_3").Text == "Kick Off"
	and homeList:FindFirstChild("Opcao_3").TextTransparency == 0,
	"Kick Off não está visivelmente selecionado na primeira entrada")
check(homeRoot:FindFirstChild("NomeRealJogador").Text == services.Players.LocalPlayer.Name
	and homeRoot:FindFirstChild("NivelRealJogador").Text == "Nível —",
	"Nome/nível do Roblox não foram criados corretamente")
local clubOption = homeList:FindFirstChild("Opcao_4")
local kickOff = homeList:FindFirstChild("Opcao_3")
local clubMist = homeList:FindFirstChild("FumacaVerde_4")
check(clubMist ~= nil and clubMist:IsA("CanvasGroup"), "Névoa animável de Clubes não foi criada")
check(clubMist.GroupTransparency == 1, "Efeito de opção inativa deve iniciar invisível")
clubOption.Activated:Fire()
check(handle.state.homeFocus == 4 and handle.state.screen == "HomeInterior",
	"Seleção de Clubes abriu conteúdo inexistente")
check(clubOption.TextTransparency > 0,
	"Transição de destaque deve começar a partir do estado anterior, sem salto")
advance(0.16)
check(clubOption.TextTransparency > 0 and clubOption.TextTransparency < 0.32
	and clubMist.GroupTransparency > 0.18 and clubMist.GroupTransparency < 1,
	"Aos 160 ms, texto e fumaça devem estar no meio da transição")
advance(0.36)
check(clubOption.TextTransparency == 0 and clubMist.GroupTransparency == 0.18,
	"Opção selecionada não terminou o destaque suave")
local mistCloud = clubMist:FindFirstChild("Nuvem1")
check(mistCloud ~= nil, "Névoa selecionada não possui a primeira camada")
local cloudBefore = mistCloud.Position
services.RunService.Heartbeat:Fire(0.05)
check(mistCloud.Position ~= cloudBefore,
	"A névoa não recebeu movimento contínuo do loop leve")
kickOff.Activated:Fire()
advance(0.51)
check(handle.state.homeFocus == 3 and kickOff.TextTransparency == 0
	and clubMist.GroupTransparency == 1,
	"Transição de Clubes para Kick Off não dissipou a névoa anterior")
local news = homeList:FindFirstChild("Opcao_1")
news.MouseEnter:Fire()
advance(0.32)
check(news.TextTransparency == 0 and handle.state.homeFocus == 3,
	"Hover deve acender o texto sem alterar a seleção atual")
news.MouseLeave:Fire()
advance(0.32)
check(news.TextTransparency == 0.32,
	"MouseLeave deve escurecer suavemente a opção não selecionada")
local manager = homeList:FindFirstChild("Opcao_2")
manager.InputBegan:Fire({UserInputType = Enum.UserInputType.Touch})
advance(0.32)
check(manager.TextTransparency == 0 and handle.state.homeFocus == 3,
	"Toque deve revelar destaque transitório sem acionar navegação")
manager.InputEnded:Fire({UserInputType = Enum.UserInputType.Touch})
advance(0.32)
check(manager.TextTransparency == 0.32,
	"Soltar toque deve dissipar o destaque sem alteração de seleção")
-- Soundtrack compartilha o ciclo de vida do App, não o das páginas.
local overlay = gui:FindFirstChild("SoundtrackOverlay")
local sound = services.SoundService:FindFirstChild("CL27SoundtrackLocal")
check(overlay ~= nil and sound ~= nil and sound.IsPlaying, "Soundtrack must autoplay on entering CL 27")
local notification = overlay:FindFirstChild("NowPlayingNotification")
local controls = overlay:FindFirstChild("SoundtrackControls")
check(notification ~= nil and notification.Visible and controls ~= nil, "Now-playing toast/transport must be visible")
check(notification.Position.X.Scale == 1 and notification.Position.Y.Scale == 0, "Notification must be top-right anchored")
local initialSound = sound.SoundId
check(initialSound == "rbxassetid://5409360995" or initialSound == "rbxassetid://5410086218" or initialSound == "rbxassetid://702367070", "Soundtrack played unknown audio ID")
sound.IsPlaying = false
sound.Ended:Fire()
advance(1.99)
check(not sound.IsPlaying, "Next song started before the exact 2-second gap")
advance(0.01)
check(sound.IsPlaying and notification.Visible, "Next song did not start after 2 seconds")
local pauseControl = controls:FindFirstChild("PauseOrResume")
pauseControl.Activated:Fire()
check(not sound.IsPlaying and pauseControl.Text == "TOCAR", "Pause did not preserve player controls")
advance(0.1)
pauseControl.Activated:Fire()
check(sound.IsPlaying and pauseControl.Text == "PAUSAR", "Resume did not restart the track")
local volumeUp = controls:FindFirstChild("IncreaseVolume")
volumeUp.Activated:Fire()
advance(0.2)
check(sound.Volume >= 0.49 and sound.Volume <= 0.51, "Volume did not increase from 40 to 50 percent")
controls:FindFirstChild("NextTrack").Activated:Fire()
advance(0.56)
check(sound.IsPlaying, "Next track action failed")
advance(5.1)
check(not notification.Visible, "Now-playing notification exceeded five seconds")
check(gui:FindFirstChild("SoundtrackOverlay") == overlay and sound.Parent == services.SoundService, "Music UI lost across state changes")
local tracklist = overlay:FindFirstChild("TracklistPanel")
check(tracklist ~= nil and not tracklist.Visible, "Tracklist should start collapsed")
controls:FindFirstChild("ToggleTracklist").Activated:Fire()
check(tracklist.Visible and tracklist:FindFirstChild("Track3") ~= nil, "Tracklist does not expose three songs")
tracklist:FindFirstChild("Track2").Activated:Fire()
advance(0.56)
check(sound.SoundId == "rbxassetid://5410086218" and sound.IsPlaying, "Manual track selection did not play Crab Rave")
sound.IsPlaying = false
sound.Ended:Fire()
advance(0.4)
pauseControl.Activated:Fire()
advance(2)
check(not sound.IsPlaying and pauseControl.Text == "TOCAR", "Pause during the song gap incorrectly started playback")
pauseControl.Activated:Fire()
check(sound.IsPlaying, "Resume during the song gap did not start the queued track")

check(handle.state.screen == "HomeInterior" and not wipe.Visible, "Initial state must be visible and idle")
handle.go("Clubs")
check(handle.state.screen == "HomeInterior" and wipe.Visible and UI.inputLocked, "Wipe must lock source before swapping")
advance(0.11)
check(handle.state.screen == "HomeInterior" and wipe.GroupTransparency > 0 and wipe.GroupTransparency < 1, "Mid-entry must preserve source")
advance(0.11)
check(handle.state.screen == "Clubs" and UI.inputLocked and wipe.Visible, "Swap must happen under opaque wipe")
check(not homeHud.Enabled, "HUD inicial deve ocultar ao acessar outra seção")
check(services.GuiService.SelectedObject == nil, "Controller focus must wait until page input resumes")
advance(0.18)
check(wipe.GroupTransparency > 0 and wipe.GroupTransparency < 1 and UI.inputLocked, "Mid-exit must retain input lock")
advance(0.18)
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
advance(0.1)
handle.go("Overview")
handle.go("Kits")
advance(0.12)
check(handle.state.screen == "Squad", "Current transition must finish its intended handoff")
advance(0.36)
check(handle.state.screen == "Squad" and UI.inputLocked, "Queued transition must begin after first completes")
advance(0.22)
check(handle.state.screen == "Kits", "Latest queued route must replace earlier pending route")
advance(0.36)
check(not wipe.Visible and not UI.inputLocked, "Queued navigation must release lock")
local kitBefore = handle.state.homeKit
key(Enum.KeyCode.DPadRight)
check(handle.state.homeKit == kitBefore, "Controller focus movement must not cycle kits globally")
key(Enum.KeyCode.Right)
check(handle.state.homeKit ~= kitBefore, "Keyboard arrows must continue cycling kits")
key(Enum.KeyCode.ButtonB)
advance(0.58)
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
advance(0.03)
check(handle.state.screen == "Squad" and UI.inputLocked, "Reduced motion still needs covered handoff")
advance(0.03)
check(handle.state.screen == "HomeTraining", "Reduced motion uses short entry phase")
advance(0.08)
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
advance(0.14)
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
check(scene.destroyed and gui.Destroyed, "Disposal must destroy scene and GUI")
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
presentation.cameraPosition = Vector3.new(0, 4, 17)
presentation.cameraTarget = Vector3.new(0, 2, -1)
services.RunService.RenderStepped:Fire(1 / 60)
check(originalCamera.CameraType == Enum.CameraType.Scriptable, "Scene did not take camera control")
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

print(string.format("PASS App phases: %d assertions; virtual-clock stubs only, no Roblox capture/easing certification.", assertions))
