-- Som curto distribuído com o cliente Roblox; nenhuma música ou mídia de terceiros.
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local Audio = { status = "Carregando som nativo" }
local group, click

function Audio.start(scope, settings)
	group = Instance.new("SoundGroup")
	group.Name = "CL27Menus"
	group.Volume = settings.menuVolume or 0.3
	group.Parent = SoundService
	click = Instance.new("Sound")
	click.Name = "SelecaoCL27"
	click.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	click.SoundGroup = group
	click.Volume = 0.5
	click.PlaybackSpeed = 1.25
	click.Parent = SoundService
	scope:add(function()
		click:Destroy()
		group:Destroy()
	end)
	task.spawn(function()
		local ok = pcall(function() ContentProvider:PreloadAsync({click}) end)
		if scope.alive then Audio.status = ok and click.IsLoaded and "Som nativo disponível" or "Som indisponível neste cliente" end
	end)
end

function Audio.apply(settings)
	if group then group.Volume = settings.menuVolume or 0.3 end
end

function Audio.play()
	if click and click.IsLoaded and group.Volume>0 then
		click.TimePosition = 0
		click:Play()
		return true
	end
	return false
end

return Audio
