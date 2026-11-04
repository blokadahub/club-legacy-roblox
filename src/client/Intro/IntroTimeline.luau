--!strict
-- Pure monotonic timeline: independent of rendering cadence and Roblox services.
local Timeline = {}
Timeline.__index = Timeline
Timeline.WELCOME = 16.6
Timeline.START_READY = 17.8
Timeline.EXIT_SECONDS = 6
Timeline.SOUNDS = table.freeze({6.3, 16.6, 0.5})

function Timeline.new(origin, emit)
	return setmetatable({origin=origin, emit=emit, elapsed=0, offset=0,
		ready=false, alive=true, fired={}, departure=nil, held=false}, Timeline)
end

function Timeline:_once(key, ...)
	if not self.alive or self.fired[key] then return end
	self.fired[key]=true
	self.emit(key, ...)
end

function Timeline:Step(now, ready)
	if not self.alive then return end
	self.ready=ready
	local elapsed=math.max(self.elapsed, now-self.origin-self.offset)
	if not self.departure then
		if elapsed>=Timeline.WELCOME and not ready then
			self.held=true
			elapsed=Timeline.WELCOME
		elseif self.held then
			self.offset=now-self.origin-Timeline.WELCOME
			elapsed=Timeline.WELCOME
			self.held=false
		end
	end
	self.elapsed=elapsed
	if elapsed>=6.3 then self:_once("sound", 1) end
	-- Distinct keys preserve at-most-once delivery across large time jumps.
	if elapsed>=Timeline.WELCOME and ready then self:_once("welcome", 2) end
	if self.departure then
		local exit=math.max(0, now-self.departure)
		if exit>=0.5-1e-6 then self:_once("departure", 3) end
		if exit>=2.9-1e-6 then self:_once("reveal") end
		if exit>=Timeline.EXIT_SECONDS-1e-6 then
			self:_once("complete")
			self.alive=false
		end
	end
end

function Timeline:RequestStart(now)
	if not self.alive or not self.ready or self.departure or self.elapsed<Timeline.START_READY then return false end
	self.departure=now
	self:_once("start")
	return true
end

function Timeline:Snapshot(now)
	return {elapsed=self.elapsed, ready=self.ready, waiting=self.held,
		canStart=self.alive and self.ready and not self.departure and self.elapsed>=Timeline.START_READY,
		exit=if self.departure then math.max(0,now-self.departure) else nil}
end

function Timeline:Destroy()
	self.alive=false
end
return Timeline
