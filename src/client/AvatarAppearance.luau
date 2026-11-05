--!nonstrict
-- Official appearance pipeline shared with the lobby. Never edits Player.Character.
local Players=game:GetService("Players")
local ContentProvider=game:GetService("ContentProvider")
local Appearance={}
local cached=nil
local request=nil
local nextListener=0

function Appearance.create(userId)
	assert(type(userId)=="number" and userId>0,"Conta Roblox inválida")
	local description=Players:GetHumanoidDescriptionFromUserIdAsync(userId)
	local ok,result=pcall(function()
		return Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R15)
	end)
	local idle=description.IdleAnimation
	description:Destroy()
	if not ok then error(result,2) end
	local humanoid=result:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.RigType~=Enum.HumanoidRigType.R15 or not result:FindFirstChild("HumanoidRootPart") then
		result:Destroy();error("A API não devolveu um avatar R15 completo",2)
	end
	result:SetAttribute("AvatarUserId",userId)
	result:SetAttribute("AvatarIdleAnimation",idle or 0)
	return result
end

-- One immutable, off-Workspace template per local account, not one request per actor.
-- Callbacks receive clones; listeners can cancel without leaking a late API result.
function Appearance.invalidate(userId)
	if cached and cached.userId==userId then cached.model:Destroy();cached=nil end
end

function Appearance.request(player,callback)
	nextListener+=1
	local id=nextListener
	local cancelled=false
	local userId=player and player.UserId
	if cached and cached.userId==userId then
		task.defer(function() if not cancelled then callback(cached.model:Clone(),nil,cached.warning) end end)
	elseif not userId or userId<=0 then
		task.defer(function() if not cancelled then callback(nil,"Não foi possível identificar sua conta Roblox.") end end)
	else
		if cached then cached.model:Destroy();cached=nil end
		if not request then
			local job={userId=userId,listeners={}}
			request=job
			task.defer(function()
				local model,lastError
				for attempt=1,2 do
					local ok,result=pcall(Appearance.create,userId)
					if ok then model=result;break end
					lastError=tostring(result)
					if attempt==1 then task.wait(0.8) end
				end
				local warning=nil
				if model then
					local complete=true
					local ok=pcall(function()
						ContentProvider:PreloadAsync({model},function(_,status)
							if status~=Enum.AssetFetchStatus.Success then complete=false end
						end)
					end)
					if not ok or not complete then warning="Alguns itens do avatar não puderam carregar." end
					cached={userId=userId,model=model,warning=warning}
				end
				if request==job then request=nil end
				for _,listener in pairs(job.listeners) do
					local copy=model and model:Clone() or nil
					local ok,err=pcall(listener,copy,
						if model then nil else "Seu avatar não carregou. Tente novamente.",warning)
					if not ok then if copy then copy:Destroy() end;warn("[CL27/AvatarAppearance] "..tostring(err)) end
				end
				table.clear(job.listeners)
				if not model then warn("[CL27/AvatarAppearance] "..tostring(lastError)) end
			end)
		end
		local job=request
		if job.userId==userId then job.listeners[id]=callback end
		return function() cancelled=true;job.listeners[id]=nil end
	end
	return function() cancelled=true end
end
return Appearance
