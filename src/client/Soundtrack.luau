--!strict
-- CL 27 / Soundtrack: player local e independente das rotas.
-- Assets privados ou indisponíveis não podem ser liberados por código.
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local UI = require(script.Parent.UI)
local Scope = require(script.Parent.Scope)

local Soundtrack = {}
Soundtrack.tracks = table.freeze({
	table.freeze({artist = "Dion Timmer", title = "Shiawase", id = 5409360995}),
	table.freeze({artist = "Noisestorm", title = "Crab Rave", id = 5410086218}),
	table.freeze({artist = "CloudNone", title = "Faixa 03", id = 702367070}),
})
local GAP_SECONDS = 2
local FADE_SECONDS = 0.55
local NOTIFICATION_SECONDS = 5
local LOAD_TIMEOUT = 18

local function makeLabel(parent: Instance, text: string, x: number, y: number, w: number, h: number, size: number, color: Color3, z: number)
	return UI.new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h), Font = Enum.Font.GothamMedium,
		Text = text, TextColor3 = color, TextSize = size, TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = z,
	}, parent)
end

local function corner(parent: Instance, radius: number)
	return UI.new("UICorner", {CornerRadius = UDim.new(0, radius)}, parent)
end

local function button(parent: Instance, name: string, text: string, x: number, y: number, w: number, h: number, z: number, scope, callback: () -> ())
	local control = UI.new("TextButton", {
		Name = name, BackgroundColor3 = Color3.fromRGB(36, 67, 98),
		BackgroundTransparency = 0.57, BorderSizePixel = 0,
		Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
		Text = text, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(232, 242, 252),
		TextSize = 12, AutoButtonColor = true, Selectable = true, ZIndex = z,
	}, parent)
	corner(control, 5)
	scope:Connect(control.Activated, callback)
	return control
end

function Soundtrack.start(screenGui: ScreenGui)
	local scope = Scope.new()
	local trackSound = UI.new("Sound", {
		Name = "CL27SoundtrackLocal", Looped = false, Volume = 0,
	}, SoundService)
	scope:Add(trackSound)

	-- UI independente do canvas 1600x900 e dos rerenders de navegação.
	local overlay = UI.new("Frame", {
		Name = "SoundtrackOverlay", BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1), ZIndex = 240,
	}, screenGui)
	scope:Add(overlay)

	local toast = UI.new("Frame", {
		Name = "NowPlayingNotification", AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -17, 0, 72), Size = UDim2.fromOffset(390, 83),
		BackgroundColor3 = Color3.fromRGB(8, 26, 50), BackgroundTransparency = 0.58,
		BorderSizePixel = 0, Visible = false, ZIndex = 300,
	}, overlay)
	corner(toast, 8)
	UI.new("UIStroke", {Color = Color3.fromRGB(89, 144, 190), Transparency = 0.73, Thickness = 1}, toast)
	UI.new("Frame", {Name = "AccentRule", BackgroundColor3 = Color3.fromRGB(115, 178, 219),
		BackgroundTransparency = 0.28, BorderSizePixel = 0, Position = UDim2.fromOffset(15, 16),
		Size = UDim2.fromOffset(3, 49), ZIndex = 301}, toast)
	makeLabel(toast, "CL 27   /   AGORA TOCANDO", 30, 12, 341, 19, 11, Color3.fromRGB(169, 200, 227), 301)
	local toastTrack = makeLabel(toast, "", 30, 34, 341, 33, 19, Color3.fromRGB(243, 248, 255), 301)
	toastTrack.Font = Enum.Font.GothamBold

	local dock = UI.new("Frame", {
		Name = "SoundtrackControls", AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -17, 1, -18), Size = UDim2.fromOffset(390, 105),
		BackgroundColor3 = Color3.fromRGB(10, 29, 51), BackgroundTransparency = 0.44,
		BorderSizePixel = 0, ZIndex = 250,
	}, overlay)
	corner(dock, 7)
	UI.new("UIStroke", {Color = Color3.fromRGB(100, 159, 205), Transparency = 0.78, Thickness = 1}, dock)
	makeLabel(dock, "CL 27   /   SOUNDTRACK", 13, 8, 362, 17, 10, Color3.fromRGB(168, 193, 213), 251)
	local nowPlaying = makeLabel(dock, "Iniciando trilha sonora…", 13, 28, 360, 26, 15, Color3.fromRGB(237, 245, 252), 251)
	nowPlaying.Font = Enum.Font.GothamBold

	local previousButton
	local pauseButton
	local nextButton
	local volumeLabel
	local currentIndex = 0
	local generation = 0
	local toastGeneration = 0
	local volume = 0.4
	local paused = false
	local waiting = false
	local pendingIndex: number? = nil
	local transitioning = false
	local failed: {[number]: boolean} = {}
	local history: {number} = {}

	local function nameFor(index: number): string
		local track = Soundtrack.tracks[index]
		return track.artist .. " — " .. track.title
	end

	local function updateControls()
		if not scope.alive then return end
		nowPlaying.Text = if currentIndex > 0 then nameFor(currentIndex) else "Aguardando faixa"
		pauseButton.Text = if paused then "TOCAR" else "PAUSAR"
		volumeLabel.Text = tostring(math.floor(volume * 100 + 0.5)) .. "%"
	end

	local function showNotification(index: number)
		toastGeneration += 1
		local token = toastGeneration
		toastTrack.Text = nameFor(index)
		toast.Visible = true
		scope:Delay(NOTIFICATION_SECONDS, function()
			if toastGeneration == token then toast.Visible = false end
		end)
	end

	local function randomIndex(): number?
		local available = {}
		for index = 1, #Soundtrack.tracks do
			if not failed[index] then table.insert(available, index) end
		end
		if #available == 0 then return nil end
		return available[math.random(1, #available)]
	end

	local startIndex: (number, boolean) -> ()
	local switchTo: (number, boolean) -> ()
	local function unavailable(index: number, token: number)
		if token ~= generation or paused or waiting or currentIndex ~= index or trackSound.IsLoaded then return end
		failed[index] = true
		local replacement = randomIndex()
		if not replacement then
			trackSound:Stop()
			transitioning = false
			nowPlaying.Text = "Áudios indisponíveis ou sem permissão"
			toast.Visible = false
			return
		end
		-- Falha de asset não trava a playlist; respeita o mesmo silêncio de 2 segundos.
		generation += 1
		local nextToken = generation
		waiting = true
		transitioning = false
		trackSound:Stop()
		scope:Delay(GAP_SECONDS, function()
			if generation == nextToken then
				waiting = false
				if paused then pendingIndex = replacement else startIndex(replacement, true) end
			end
		end)
	end

	startIndex = function(index: number, record: boolean)
		if not scope.alive then return end
		generation += 1
		local token = generation
		currentIndex = index
		pendingIndex = nil
		waiting = false
		transitioning = false
		paused = false
		if record then table.insert(history, index) end
		trackSound:Stop()
		trackSound.SoundId = "rbxassetid://" .. tostring(Soundtrack.tracks[index].id)
		trackSound.TimePosition = 0
		trackSound.Volume = 0
		trackSound:Play()
		scope:Tween(trackSound, {Volume = volume}, FADE_SECONDS)
		showNotification(index)
		updateControls()
		scope:Delay(LOAD_TIMEOUT, function() unavailable(index, token) end)
	end

	switchTo = function(index: number, record: boolean)
		generation += 1 -- invalida qualquer timer/fim anterior
		local token = generation
		waiting = false
		pendingIndex = nil
		if transitioning then
			trackSound:Stop()
			startIndex(index, record)
			return
		end
		transitioning = true
		if currentIndex == 0 or paused or not trackSound.IsPlaying then
			startIndex(index, record)
			return
		end
		scope:Tween(trackSound, {Volume = 0}, FADE_SECONDS)
		scope:Delay(FADE_SECONDS, function()
			if token ~= generation then return end
			startIndex(index, record)
		end)
	end

	previousButton = button(dock, "PreviousTrack", "ANT.", 13, 63, 60, 30, 251, scope, function()
		if #history > 1 then
			table.remove(history)
			switchTo(history[#history], false)
		elseif currentIndex > 0 then
			switchTo(currentIndex, false)
		end
	end)
	pauseButton = button(dock, "PauseOrResume", "PAUSAR", 79, 63, 84, 30, 251, scope, function()
		if paused then
			paused = false
			if pendingIndex then
				local nextTrack = pendingIndex
				pendingIndex = nil
				startIndex(nextTrack, true)
			elseif currentIndex > 0 then
				trackSound:Resume()
				scope:Tween(trackSound, {Volume = volume}, FADE_SECONDS)
			else
				local nextTrack = randomIndex()
				if nextTrack then startIndex(nextTrack, true) end
			end
		else
			paused = true
			-- Pause preserva a posição da faixa e desativa o timer de falha.
			generation += 1
			trackSound:Pause()
		end
		updateControls()
	end)
	nextButton = button(dock, "NextTrack", "PRÓX.", 169, 63, 61, 30, 251, scope, function()
		local nextTrack = randomIndex()
		if nextTrack then switchTo(nextTrack, true) end
	end)
	button(dock, "DecreaseVolume", "−", 240, 63, 29, 30, 251, scope, function()
		volume = math.max(0, math.round(volume * 10 - 1) / 10)
		if not paused and not waiting then scope:Tween(trackSound, {Volume = volume}, 0.16) end
		updateControls()
	end)
	volumeLabel = makeLabel(dock, "40%", 273, 64, 52, 29, 12, Color3.fromRGB(219, 230, 245), 251)
	volumeLabel.TextXAlignment = Enum.TextXAlignment.Center
	button(dock, "IncreaseVolume", "+", 335, 63, 40, 30, 251, scope, function()
		volume = math.min(1, math.round(volume * 10 + 1) / 10)
		if not paused and not waiting then scope:Tween(trackSound, {Volume = volume}, 0.16) end
		updateControls()
	end)

	scope:Connect(trackSound.Ended, function()
		if paused or waiting or transitioning or currentIndex == 0 then return end
		generation += 1
		local token = generation
		waiting = true
		local nextTrack = randomIndex()
		if not nextTrack then return end
		scope:Delay(GAP_SECONDS, function()
			if token ~= generation then return end
			waiting = false
			if paused then pendingIndex = nextTrack else startIndex(nextTrack, true) end
		end)
	end)

	-- Um aviso de carregamento tardio não é um erro definitivo; a checagem após 18s
	-- apenas evita que uma faixa bloqueada impeça a playlist inteira de avançar.
	local notificationScale = UI.new("UIScale", {Scale = 1}, toast)
	local playerScale = UI.new("UIScale", {Scale = 1}, dock)
	local function resize()
		local camera = Workspace.CurrentCamera
		if not camera then return end
		local size = camera.ViewportSize
		local factor = math.clamp(math.min(size.X / 690, size.Y / 480), 0.65, 1)
		notificationScale.Scale = factor
		playerScale.Scale = factor
	end
	local cameraConnection: RBXScriptConnection? = nil
	local function watchCamera()
		if cameraConnection then cameraConnection:Disconnect() end
		local camera = Workspace.CurrentCamera
		if camera then cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
		resize()
	end
	watchCamera()
	scope:Connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), watchCamera)
	scope:Add(function()
		if cameraConnection then cameraConnection:Disconnect() end
	end)

	scope:Connect(screenGui.Destroying, function() scope:Destroy() end)
	local firstTrack = randomIndex()
	if firstTrack then startIndex(firstTrack, true) end
	return {
		destroy = function() scope:Destroy() end,
	}
end

return Soundtrack
