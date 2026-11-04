--!strict
local SoundService=game:GetService("SoundService")
local ContentProvider=game:GetService("ContentProvider")
local Scope=require(script.Parent.Parent.Scope)
local Audio={}
Audio.IDS=table.freeze({98087823124682,101494550141867,135910449013772})
function Audio.new()
	local scope=Scope.new()
	local sounds={}
	local failed,played={},{}
	for i,id in ipairs(Audio.IDS) do
		local sound=Instance.new("Sound")
		sound.Name="CL27IntroEffect"..i
		sound.SoundId="rbxassetid://"..tostring(id)
		sound.Volume=.65
		sound.Looped=false
		sound.Parent=SoundService
		scope:Add(sound)
		sounds[i]=sound
		-- Concurrent bounded lifetime; an unavailable asset never holds the timeline.
		local worker=task.defer(function()
			local ok,err=pcall(function()
				ContentProvider:PreloadAsync({sound},function(_,status)
					if status~=Enum.AssetFetchStatus.Success then
						failed[i]=true
						warn("[CL27 Intro] Efeito "..i.." indisponível: "..tostring(status))
					end
				end)
			end)
			if not ok and scope.alive then
				failed[i]=true
				warn("[CL27 Intro] Pré-carregamento do efeito "..i..": "..tostring(err))
			end
		end)
		scope:Add(function() pcall(task.cancel,worker) end)
	end
	return {
		Play=function(_,index)
			if not scope.alive or played[index] then return end
			played[index]=true
			for _,sound in ipairs(sounds) do sound:Stop() end
			local sound=sounds[index]
			if failed[index] or not sound.IsLoaded then
				warn("[CL27 Intro] Efeito "..index.." não carregado no marco; abertura continua sem substituição.")
				return
			end
			sound:Play()
		end,
		Destroy=function() scope:Destroy() end,
	}
end
return Audio
