--!strict
-- Música ambiente CL 27. Reproduz sem banners, notificações ou HUD.
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
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
local LOAD_TIMEOUT = 18
local MUSIC_VOLUME = 0.4

function Soundtrack.start(screenGui: ScreenGui)
	local scope = Scope.new()
	local trackSound = UI.new("Sound", {
		Name = "CL27SoundtrackLocal",
		Looped = false, Volume = 0,
	}, SoundService)
	scope:Add(trackSound)

	local generation = 0
	local currentIndex = 0
	local waiting = false
	local failed: {[number]: boolean} = {}
	local function randomIndex(): number?
		local available = {}
		for index = 1, #Soundtrack.tracks do
			if not failed[index] then table.insert(available, index) end
		end
		if #available == 0 then return nil end
		return available[math.random(1, #available)]
	end

	local playTrack: (number) -> ()
	local function queueNext()
		if waiting or currentIndex == 0 then return end
		local nextTrack = randomIndex()
		if not nextTrack then return end
		generation += 1
		local token = generation
		waiting = true
		scope:Delay(GAP_SECONDS, function()
			if token ~= generation or not scope.alive then return end
			waiting = false
			playTrack(nextTrack)
		end)
	end

	playTrack = function(index: number)
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
		scope:Delay(LOAD_TIMEOUT, function()
			if token ~= generation or trackSound.IsLoaded or waiting then return end
			failed[index] = true
			trackSound:Stop()
			local replacement = randomIndex()
			if not replacement then return end
			generation += 1
			local nextToken = generation
			waiting = true
			scope:Delay(GAP_SECONDS, function()
				if nextToken ~= generation or not scope.alive then return end
				waiting = false
				playTrack(replacement)
			end)
		end)
	end

	scope:Connect(trackSound.Ended, queueNext)
	scope:Connect(RunService.Heartbeat, function()
		if waiting or not trackSound.IsLoaded or not trackSound.IsPlaying then return end
		local duration = trackSound.TimeLength
		if duration <= 0 then return end
		local remaining = duration - trackSound.TimePosition
		if remaining > 0 and remaining <= FADE_SECONDS then
			trackSound.Volume = MUSIC_VOLUME * math.clamp(remaining / FADE_SECONDS, 0, 1)
		end
	end)
	scope:Connect(screenGui.Destroying, function() scope:Destroy() end)
	local firstTrack = randomIndex()
	if firstTrack then playTrack(firstTrack) end
	return {destroy = function() scope:Destroy() end}
end

return Soundtrack
