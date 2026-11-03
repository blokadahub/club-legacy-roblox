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
print(string.format("PASS App phases: %d assertions; virtual-clock stubs only, no Roblox capture/easing certification.", assertions))
