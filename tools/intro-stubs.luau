-- Extra API surface for real opening modules, not a Roblox renderer.
local originalVectorIndex=vectorMeta.__index
vectorMeta.__index=function(self,key)
	if key=="Cross" then return function(a,b) return Vector3.new(a.Y*b.Z-a.Z*b.Y,a.Z*b.X-a.X*b.Z,a.X*b.Y-a.Y*b.X) end end
	if key=="Dot" then return function(a,b) return a.X*b.X+a.Y*b.Y+a.Z*b.Z end end
	return originalVectorIndex(self,key)
end
CFrame.fromMatrix=function(position,right,up,back)
	assert(math.abs(right:Dot(up))<.00001 and math.abs(right:Dot(back))<.00001)
	return CFrame.new(position)
end
function services.TweenService:GetValue(alpha)
	return 1-(1-alpha)^4
end
events.Loaded=true
local originalInstanceNew=Instance.new
Instance.new=function(className)
	local object=originalInstanceNew(className)
	if className=="Sound" then object.IsLoaded=not services.unloadedSounds end
	return object
end
local os={clock=function() return now end}
-- Real coroutines let PreloadAsync tests model a yielding/stuck fetch.
task.defer=function(callback)
	local thread=coroutine.create(callback)
	local job=later(0,function()
		local ok,err=coroutine.resume(thread)
		if not ok then error(err) end
	end)
	job.thread=thread
	return job
end
local originalCancel=task.cancel
task.cancel=function(job)
	originalCancel(job)
	if job.thread and coroutine.status(job.thread)=="suspended" then coroutine.close(job.thread) end
end
services.Players.LocalPlayer.Name="OpeningRealPlayer"
services.ReplicatedFirst={RemoveDefaultLoadingScreen=function() services.defaultLoadingRemoved=true end}
services.ContentProvider={
	PreloadAsync=function(_,items,callback)
		if services.preloadIntro then return services.preloadIntro(items,callback) end
		for _,object in ipairs(items) do
			callback(object.SoundId, if object.IsLoaded then Enum.AssetFetchStatus.Success else Enum.AssetFetchStatus.Failure)
		end
	end,
}
local audioLog={}
function methods:Play()
	assert(self.ClassName=="Sound")
	if string.find(self.Name,"CL27IntroEffect",1,true) then
		assert(self.IsLoaded,"Intro attempted playback before Loaded")
	end
	self.IsPlaying=true
	table.insert(audioLog,{name=self.Name,id=self.SoundId,time=now})
end
