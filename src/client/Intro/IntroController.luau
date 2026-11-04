--!strict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local GuiService=game:GetService("GuiService")
local UserInputService=game:GetService("UserInputService")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local Scope=require(script.Parent.Parent.Scope)
local TransitionFX=require(script.Parent.Parent.TransitionFX)
local Timeline=require(script.Parent.IntroTimeline)
local Visuals=require(script.Parent.IntroVisuals)
local Audio=require(script.Parent.IntroAudio)
local Controller={}
function Controller.start(prepare)
	local player=Players.LocalPlayer
	local playerGui=player:WaitForChild("PlayerGui")
	local old=playerGui:FindFirstChild("CL27_Intro")
	if old then old:Destroy() end
	local visuals=Visuals.new(playerGui)
	pcall(function() ReplicatedFirst:RemoveDefaultLoadingScreen() end)
	local scope=Scope.new()
	local effects=Audio.new()
	local fx=TransitionFX.start(playerGui)
	fx:SetIndicatorHost(visuals.loader)
	local app=nil
	local preparing=false
	local errorMessage=nil
	local ready=false
	local complete=false
	local loaderEnabled=false
	local focused=false
	local clock=os.clock
	local timeline
	local function destroy()
		if not scope.alive then return end
		if timeline then timeline:Destroy() end
		scope:Destroy()
		if GuiService.SelectedObject==visuals.start then GuiService.SelectedObject=nil end
		effects:Destroy()
		if not complete then
			if app then app.destroy() end
			fx:Destroy()
		end
		visuals:Destroy()
	end
	timeline=Timeline.new(clock(),function(event,index)
		if event=="sound" or event=="welcome" or event=="departure" then effects:Play(index) end
		if event=="complete" then
			-- Final order is deliberate: effects stop, HUD/inputs/music release once,
			-- the independent opening camera and overlay are then destroyed.
			complete=true
			effects:Destroy()
			fx:SetPersistentLoading(false,false)
			fx:SetIndicatorHost(nil)
			fx:SetIndicatorTime(nil)
			app:CompleteIntro()
			destroy()
		end
	end)
	local function prepareLobby()
		if preparing or ready or not scope.alive then return end
		preparing=true
		errorMessage=nil
		local worker=task.defer(function()
			local ok,result=pcall(prepare,fx)
			preparing=false
			if not scope.alive then
				if ok and result then result.destroy() end
				return
			end
			if ok and result then
				app=result
				ready=app:IsIntroReady()
				fx:SetPersistentLoading(loaderEnabled,app.state.settings.reducedMotion)
			else
				warn("[CL27 Intro] Falha ao preparar o lobby: "..tostring(result))
				errorMessage="Não foi possível preparar o lobby. Tente novamente."
			end
		end)
		scope:Add(function() pcall(task.cancel,worker) end)
	end
	scope:Connect(visuals.start.Activated,function()
		if errorMessage then prepareLobby();return end
		timeline:Step(clock(),ready)
		if timeline:RequestStart(clock()) then
			GuiService.SelectedObject=nil
			visuals.start.Active=false
			visuals.start.Selectable=false
		end
	end)
	local cameraConnection=nil
	local function resize()
		local camera=workspace.CurrentCamera
		if camera then visuals:Resize(camera.ViewportSize) end
	end
	local function watchCamera()
		if cameraConnection then cameraConnection:Disconnect() end
		if workspace.CurrentCamera then cameraConnection=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
		resize()
	end
	scope:Add(function() if cameraConnection then cameraConnection:Disconnect() end end)
	watchCamera()
	scope:Connect(workspace:GetPropertyChangedSignal("CurrentCamera"),watchCamera)
	local function step()
		local now=clock()
		if app then ready=app:IsIntroReady() end
		timeline:Step(now,ready)
		if not scope.alive then return end
		local snapshot=timeline:Snapshot(now)
		local reduced=app and app.state.settings.reducedMotion==true or false
		local _,hudAlpha=visuals:Draw(snapshot,player.Name,reduced,errorMessage)
		if app then app:RevealIntro(hudAlpha) end
		local showLoader=snapshot.elapsed>=2.15 and (not snapshot.exit or snapshot.exit<5.7)
		if showLoader~=loaderEnabled then
			loaderEnabled=showLoader
			fx:SetPersistentLoading(showLoader,reduced)
		end
		fx:SetIndicatorTime(snapshot.elapsed)
		if visuals.start.Selectable and UserInputService.GamepadEnabled then
			if not focused then GuiService.SelectedObject=visuals.start;focused=true end
		else focused=false end
	end
	scope:Connect(RunService.Heartbeat,step)
	scope:Connect(visuals.gui.Destroying,destroy)
	step()
	prepareLobby()
	return {Destroy=destroy}
end
return Controller
