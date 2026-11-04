--!strict
local SoundService=game:GetService("SoundService")
local ContentProvider=game:GetService("ContentProvider")
local Scope=require(script.Parent.Parent.Scope)
local Audio={}
Audio.IDS=table.freeze({98087823124682,101494550141867,135910449013772})
Audio.MAX_LATE_SECONDS=2
local PRELOAD_TIMEOUT_SECONDS=3
local MAX_PRELOAD_ATTEMPTS=2
local RETRY_DELAY_SECONDS=.35

function Audio.new(clock)
	clock=clock or os.clock
	local scope=Scope.new()
	local sounds={}
	local requested={}
	local latest=0
	local pending=nil
	local function tryPlay(now)
		if not scope.alive or not pending or now+1e-6<pending.at then return end
		local cue=pending
		if now>cue.deadline then
			pending=nil
			warn("[CL27 Intro] Efeito "..cue.index.." excedeu a janela de áudio; sequência continua.")
			return
		end
		local sound=sounds[cue.index]
		if not sound.IsLoaded then return end
		-- Consume only when ready (or expired/superseded), never at request time.
		-- Loaded and PreloadAsync may both notify; neither can replay this cue.
		pending=nil
		sound.TimePosition=0
		local ok,err=pcall(function() sound:Play() end)
		if not ok then
			warn("[CL27 Intro] Reprodução do efeito "..cue.index..": "..tostring(err))
		elseif now-cue.at>.15 then
			warn(string.format("[CL27 Intro] Efeito %d iniciado com atraso de %.3f s.",cue.index,now-cue.at))
		end
	end

	local preload
	preload=function(index,attempt)
		if not scope.alive or sounds[index].IsLoaded then return end
		local sound=sounds[index]
		local finished=false
		local worker
		local function finish(reason)
			if finished then return end
			finished=true
			if not scope.alive then return end
			tryPlay(clock())
			if sound.IsLoaded then return end
			if attempt<MAX_PRELOAD_ATTEMPTS then
				scope:Delay(RETRY_DELAY_SECONDS,function() preload(index,attempt+1) end)
			else
				-- Failure is diagnostic, not a permanent IsLoaded=false latch.
				-- A subsequent Loaded event may still satisfy a live pending cue.
				warn("[CL27 Intro] Pré-carregamento do efeito "..index..": "..reason)
			end
		end
		worker=task.defer(function()
			if not scope.alive or sound.IsLoaded then finish("já carregado");return end
			local reason="asset ainda não carregado"
			local ok,err=pcall(function()
				ContentProvider:PreloadAsync({sound},function(_,status)
					if not scope.alive then return end
					if status~=Enum.AssetFetchStatus.Success then reason=tostring(status) end
					tryPlay(clock())
				end)
			end)
			finish(if ok then reason else tostring(err))
		end)
		scope:Add(function() pcall(task.cancel,worker) end)
		scope:Delay(PRELOAD_TIMEOUT_SECONDS,function()
			if finished then return end
			pcall(task.cancel,worker)
			finish("tempo limite de pré-carregamento")
		end)
	end

	for i,id in ipairs(Audio.IDS) do
		local sound=Instance.new("Sound")
		sound.Name="CL27IntroEffect"..i
		sound.SoundId="rbxassetid://"..tostring(id)
		sound.Volume=.65
		sound.Looped=false
		sound.Parent=SoundService
		scope:Add(sound)
		sounds[i]=sound
		scope:Connect(sound.Loaded,function() tryPlay(clock()) end)
		-- All three fetches start immediately, independently of their cue times.
		preload(i,1)
	end
	return {
		Play=function(_,index,scheduledAt)
			if not scope.alive or not sounds[index] or requested[index] or index<=latest then return end
			requested[index]=true
			latest=index
			-- No older pending sound may start after a newer cinematic cue.
			pending=nil
			for _,sound in ipairs(sounds) do sound:Stop() end
			local at=scheduledAt or clock()
			pending={index=index,at=at,deadline=at+Audio.MAX_LATE_SECONDS}
			tryPlay(clock())
		end,
		Step=function(_,now) tryPlay(now or clock()) end,
		CancelPending=function() pending=nil end,
		Destroy=function() pending=nil;scope:Destroy() end,
	}
end
return Audio
