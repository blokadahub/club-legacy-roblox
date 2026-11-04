--!strict
-- Música ambiente CL 27. Reproduz sem banners, notificações ou HUD.
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local UI = require(script.Parent.UI)
local Scope = require(script.Parent.Scope)

local Soundtrack = {}
Soundtrack.tracks = table.freeze({
	table.freeze({artist = "DESERT STAR", title = "Empty Sky", id = 5410084938}),
	table.freeze({artist = "Rome in Silver", title = "Beach Season Skin", id = 7028570258}),
	table.freeze({artist = "Pixel Terror & EMELINE", title = "Chroma", id = 5410084802}),
	table.freeze({artist = "Grant feat. Juneau", title = "Are We Still Young", id = 5410086445}),
	table.freeze({artist = "Protostar feat. Emma McGann", title = "Where I Belong", id = 7028527348}),
	table.freeze({artist = "Dion Timmer feat. Micah Martin", title = "Internet Boy", id = 5410084870}),
	table.freeze({artist = "DESERT STAR", title = "Carissa", id = 5410085602}),
	table.freeze({artist = "Dexter King feat. Aviella", title = "Get to Know You", id = 7024035759}),
	table.freeze({artist = "Conro", title = "All I Want", id = 7023680426}),
	table.freeze({artist = "WRLD feat. Savoi", title = "Hang Up", id = 5410084188}),
	table.freeze({artist = "APMOfficial", title = "One Way Street", id = 1836744721}),
	table.freeze({artist = "Dion Timmer", title = "Shiawase", id = 5409360995}),
})
local GAP_SECONDS = 2
local FADE_SECONDS = 0.55
local LOAD_TIMEOUT = 18
local MUSIC_VOLUME = 0.4

function Soundtrack.create(screenGui: ScreenGui)
	local scope = Scope.new()
	local released = false
	local trackSound = UI.new("Sound", {
		Name = "CL27SoundtrackLocal",
		Looped = false, Volume = 0,
	}, SoundService)
	scope:Add(trackSound)

	local generation = 0
	local currentIndex = 0
	local waiting = false
	local failed: {[number]: boolean} = {}
	local remaining: {number} = {}
	local function randomIndex(): number?
		-- Embaralha a lista inteira. Cada faixa toca uma vez por rodada.
		if #remaining == 0 then
			for index = 1, #Soundtrack.tracks do
				if not failed[index] then table.insert(remaining, index) end
			end
			for index = #remaining, 2, -1 do
				local random = math.random(1, index)
				remaining[index], remaining[random] = remaining[random], remaining[index]
			end
			-- Nao repete a ultima musica ao comecar outra rodada.
			if #remaining > 1 and currentIndex ~= 0 and remaining[#remaining] == currentIndex then
				remaining[#remaining], remaining[1] = remaining[1], remaining[#remaining]
			end
		end
		return table.remove(remaining)
	end

	local playTrack: (number) -> ()
	local function queueNext()
		if not released or waiting or currentIndex == 0 then return end
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
		if not scope.alive or not released then return end
		generation += 1
		local token = generation
		currentIndex = index
		waiting = false
		trackSound:Stop()
		trackSound.SoundId = "rbxassetid://" .. tostring(Soundtrack.tracks[index].id)
		trackSound.TimePosition = 0
		trackSound.Volume = 0
		trackSound:Play()
		if trackSound.IsLoaded then
			scope:Tween(trackSound, {Volume = MUSIC_VOLUME}, FADE_SECONDS)
		end
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
	scope:Connect(trackSound.Loaded, function()
		if released and currentIndex~=0 and not waiting then
			scope:Tween(trackSound, {Volume = MUSIC_VOLUME}, FADE_SECONDS)
		end
	end)
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
	return {
		release = function()
			if released or not scope.alive then return end
			released = true
			local firstTrack = randomIndex()
			if firstTrack then playTrack(firstTrack) end
		end,
		destroy = function() scope:Destroy() end,
	}
end

return Soundtrack
