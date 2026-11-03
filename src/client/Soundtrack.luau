--!strict
-- Player musical em segundo plano. Nenhum dock ocupa o campo de visão.
-- Apenas a notificação animada de 5 segundos é exibida.
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
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
local MUSIC_VOLUME = 0.4

local function makeLabel(parent: Instance, name: string, text: string, x: number, y: number, w: number, h: number, size: number, color: Color3, font)
	return UI.new("TextLabel", {
		Name = name,
		Text = text,
		TextColor3 = color,
		Font = font or Enum.Font.GothamMedium,
		TextSize = size,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		ZIndex = 302,
	}, parent)
end

function Soundtrack.start(screenGui: ScreenGui)
	local scope = Scope.new()
	local trackSound = UI.new("Sound", {
		Name = "CL27SoundtrackLocal",
		Looped = false, Volume = 0,
	}, SoundService)
	scope:Add(trackSound)

	-- O overlay é transparente e não captura toques do menu.
	local overlay = UI.new("Frame", {
		Name = "SoundtrackOverlay", BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1), Active = false, ZIndex = 240,
	}, screenGui)
	scope:Add(overlay)

	local toast = UI.new("CanvasGroup", {
		Name = "NowPlayingNotification",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 12, 0, 72),
		Size = UDim2.fromOffset(345, 84),
		BackgroundColor3 = Color3.fromRGB(8, 27, 42),
		BackgroundTransparency = 0.32,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Visible = false,
		Active = false,
		ClipsDescendants = true,
		ZIndex = 300,
	}, overlay)
	UI.new("UICorner", {CornerRadius = UDim.new(0, 10)}, toast)
	UI.new("UIStroke", {
		Color = Color3.fromRGB(79, 145, 133),
		Transparency = 0.79, Thickness = 1,
	}, toast)
	local backdrop = UI.new("Frame", {
		Name = "FaixaCor", BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(22, 68, 68),
		Size = UDim2.fromScale(1, 1), ZIndex = 300,
	}, toast)
	UI.new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(13, 57, 61)),
			ColorSequenceKeypoint.new(0.64, Color3.fromRGB(9, 30, 47)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 18, 32)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.19),
			NumberSequenceKeypoint.new(1, 0.55),
		}),
	}, backdrop)
	UI.new("Frame", {
		Name = "AcentoVertical", BackgroundColor3 = Color3.fromRGB(64, 203, 151),
		BackgroundTransparency = 0.13, BorderSizePixel = 0,
		Position = UDim2.fromOffset(14, 18),
		Size = UDim2.fromOffset(3, 45), ZIndex = 301,
	}, toast)
	makeLabel(toast, "NotificacaoCabecalho", "CL 27   /   AGORA TOCANDO", 28, 10, 294, 22, 10, Color3.fromRGB(144, 203, 188), Enum.Font.GothamBold)
	local toastTitle = makeLabel(toast, "NomeFaixa", "", 28, 32, 295, 29, 19, Color3.fromRGB(249, 253, 253), Enum.Font.GothamBold)
	local toastArtist = makeLabel(toast, "ArtistaFaixa", "", 28, 59, 295, 17, 12, Color3.fromRGB(189, 215, 221), Enum.Font.GothamMedium)
	local progress = UI.new("Frame", {
		Name = "ProgressoNotificacao",
		Position = UDim2.new(0, 0, 1, -2),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = Color3.fromRGB(66, 215, 164),
		BackgroundTransparency = 0.19,
		BorderSizePixel = 0, ZIndex = 302,
	}, toast)

	local notificationScale = UI.new("UIScale", {Scale = 1}, toast)
	local toastGeneration = 0
	local generation = 0
	local currentIndex = 0
	local waiting = false
	local failed: {[number]: boolean} = {}

	local function showNotification(index: number)
		toastGeneration += 1
		local token = toastGeneration
		local track = Soundtrack.tracks[index]
		toastTitle.Text = track.title
		toastArtist.Text = track.artist
		toast.Visible = true
		toast.Position = UDim2.new(1, 12, 0, 72)
		toast.GroupTransparency = 1
		progress.Size = UDim2.new(1, 0, 0, 2)
		scope:Tween(toast, {
			Position = UDim2.new(1, -17, 0, 72),
			GroupTransparency = 0,
		}, 0.44)
		scope:Tween(progress, {Size = UDim2.new(0, 0, 0, 2)}, NOTIFICATION_SECONDS)
		scope:Delay(NOTIFICATION_SECONDS, function()
			if toastGeneration ~= token then return end
			scope:Tween(toast, {
				GroupTransparency = 1,
				Position = UDim2.new(1, -2, 0, 72),
			}, 0.39)
			scope:Delay(0.4, function()
				if toastGeneration == token then toast.Visible = false end
			end)
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

	local startIndex: (number) -> ()
	local function queueNext()
		if waiting or currentIndex == 0 then return end
		generation += 1
		local token = generation
		waiting = true
		local nextTrack = randomIndex()
		if not nextTrack then return end
		scope:Delay(GAP_SECONDS, function()
			if token ~= generation or not scope.alive then return end
			waiting = false
			startIndex(nextTrack)
		end)
	end

	startIndex = function(index: number)
		if not scope.alive then return end
		generation += 1
		local token = generation
		currentIndex = index
		waiting = false
		trackSound:Stop()
		trackSound.SoundId = "rbxassetid://" .. tostring(Soundtrack.tracks[index].id)
		trackSound.TimePosition = 0
		trackSound.Volume = 0
		trackSound:Play()
		scope:Tween(trackSound, {Volume = MUSIC_VOLUME}, FADE_SECONDS)
		showNotification(index)
		scope:Delay(LOAD_TIMEOUT, function()
			if token ~= generation or trackSound.IsLoaded or waiting then return end
			failed[index] = true
			trackSound:Stop()
			local replacement = randomIndex()
			if not replacement then
				toastGeneration += 1
				scope:Tween(toast, {GroupTransparency = 1}, 0.3)
				scope:Delay(0.32, function() toast.Visible = false end)
			else
				generation += 1
				local nextToken = generation
				waiting = true
				scope:Delay(GAP_SECONDS, function()
					if nextToken ~= generation or not scope.alive then return end
					waiting = false
					startIndex(replacement)
				end)
			end
		end)
	end

	scope:Connect(trackSound.Ended, queueNext)
	-- Atenuação só no final de cada faixa; sem loops de interface por frame.
	scope:Connect(RunService.Heartbeat, function()
		if waiting or not trackSound.IsLoaded or not trackSound.IsPlaying then return end
		local duration = trackSound.TimeLength
		if duration <= 0 then return end
		local remaining = duration - trackSound.TimePosition
		if remaining > 0 and remaining <= FADE_SECONDS then
			trackSound.Volume = MUSIC_VOLUME * math.clamp(remaining / FADE_SECONDS, 0, 1)
		end
	end)

	local cameraConnection: RBXScriptConnection? = nil
	local function resize()
		local camera = Workspace.CurrentCamera
		if not camera then return end
		local size = camera.ViewportSize
		notificationScale.Scale = math.clamp(math.min(size.X / 710, size.Y / 460), 0.72, 1)
	end
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
	if firstTrack then startIndex(firstTrack) end
	return {
		destroy = function() scope:Destroy() end,
	}
end

return Soundtrack
