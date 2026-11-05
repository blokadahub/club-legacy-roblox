--!nonstrict
local UI=require(script.Parent.Parent.UI)
local Theme=require(game:GetService("ReplicatedStorage").CL27.Theme)
local Motion=require(script.Parent.Parent.Environments.PenaltyMotion)
return function(root,ctx)
	-- ScreenGui is independent of the fitted canvas: 54 px targets stay usable on phones.
	local gui=UI.new("ScreenGui",{Name="CL27_PenaltyHUD",DisplayOrder=88,IgnoreGuiInset=false,
		ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},ctx.playerGui or root)
	ctx.scope:Add(gui)
	local back=UI.button(gui,"‹  LOBBY",16,14,148,54,function() ctx.go("HomeInterior",true) end,ctx.scope,{quiet=true,textSize=16})
	back.Name="VoltarDaArena"
	back.BackgroundColor3=Color3.fromRGB(19,29,36)
	back.BackgroundTransparency=0.12
	local label=UI.new("TextLabel",{Name="ArenaLabel",Text="ARENA DE TREINO  /  PÊNALTIS",
		Font=Enum.Font.GothamMedium,TextSize=12,TextColor3=Theme.white,
		TextXAlignment=Enum.TextXAlignment.Right,BackgroundTransparency=1,
		AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-18,0,24),Size=UDim2.new(0.48,0,0,30)},gui)
	label.TextWrapped=true

	local preview=ctx.scene.penalty
	-- One 48 px row at screen-right leaves the striker and ball unobstructed.
	local controls=UI.new("Frame",{Name="PreviaAnimacoes",AnchorPoint=Vector2.new(1,1),
		Position=UDim2.new(1,-12,1,-12),Size=UDim2.fromOffset(334,48),BackgroundTransparency=1},gui)
	local selected=1
	local function command(name,text,x,width,callback)
		local button=UI.button(controls,text,x,0,width,48,callback,ctx.scope,{quiet=true,textSize=12})
		button.Name=name;button.TextWrapped=true
		button.BackgroundColor3=Color3.fromRGB(19,29,36);button.BackgroundTransparency=.15
		return button
	end
	local kick=command("Kick","Ver chute",0,90,function() if preview then preview:PreviewAction("Kick") end end)
	local defense
	local function select(offset)
		selected=(selected-1+offset)%#Motion.SaveOrder+1
		defense.Text=selected.."/"..#Motion.SaveOrder.."  "..Motion.SaveLabels[Motion.SaveOrder[selected]]
		defense:SetAttribute("PreviewAction",Motion.SaveOrder[selected])
	end
	local previous=command("DefesaAnterior","‹",94,44,function() select(-1) end)
	defense=command("VerDefesa","",142,144,function()
		if preview then preview:PreviewAction(Motion.SaveOrder[selected]) end
	end)
	local nextButton=command("DefesaProxima","›",290,44,function() select(1) end)
	kick.NextSelectionRight=previous;previous.NextSelectionLeft=kick
	previous.NextSelectionRight=defense;defense.NextSelectionLeft=previous
	defense.NextSelectionRight=nextButton;nextButton.NextSelectionLeft=defense
	select(0)
	local viewportConnection
	local function resize()
		local camera=workspace.CurrentCamera
		if not camera then return end
		local width=math.clamp(camera.ViewportSize.X-24,296,334)
		local selectedWidth=if width<334 then 128 else 144
		local kickWidth=width-selectedWidth-100
		controls.Size=UDim2.fromOffset(width,48)
		kick.Size=UDim2.fromOffset(kickWidth,48);kick.Text=if width<334 then "Chute" else "Ver chute"
		previous.Position=UDim2.fromOffset(kickWidth+4,0)
		defense.Position=UDim2.fromOffset(kickWidth+52,0);defense.Size=UDim2.fromOffset(selectedWidth,48)
		nextButton.Position=UDim2.fromOffset(width-44,0)
	end
	local function watchCamera()
		if viewportConnection then viewportConnection:Disconnect() end
		local camera=workspace.CurrentCamera
		if camera then viewportConnection=ctx.scope:Connect(camera:GetPropertyChangedSignal("ViewportSize"),resize) end
		resize()
	end
	ctx.scope:Connect(workspace:GetPropertyChangedSignal("CurrentCamera"),watchCamera)
	watchCamera()
	local status=UI.new("TextLabel",{Name="EstadoAvatar",AnchorPoint=Vector2.new(.5,1),
		Position=UDim2.new(.5,0,1,-76),Size=UDim2.new(.9,0,0,40),BackgroundTransparency=1,
		Text="",TextColor3=Theme.white,Font=Enum.Font.GothamMedium,TextSize=14,TextWrapped=true},gui)
	local retry=UI.button(gui,"Recarregar avatar",0,0,180,48,function()
		if preview then preview:RetryAvatars() end
	end,ctx.scope,{quiet=true,textSize=14})
	retry.Name="RecarregarAvatar";retry.AnchorPoint=Vector2.new(.5,1)
	retry.Position=UDim2.new(.5,0,1,-124);retry.Visible=false
	local function refresh()
		if not preview then return end
		local state=preview.model:GetAttribute("AvatarStatus")
		local playing=preview.model:GetAttribute("PreviewAction")
		status.Text=preview.model:GetAttribute("AvatarMessage") or ""
		retry.Visible=state=="Error"
		for _,button in ipairs(controls:GetChildren()) do
			local available=state=="Ready" and (not playing or button==previous or button==nextButton)
			button.Active=available;button.Selectable=available
			button.TextTransparency=if available then 0 else .5
		end
	end
	if preview then
		ctx.scope:Connect(preview.model:GetAttributeChangedSignal("AvatarStatus"),refresh)
		ctx.scope:Connect(preview.model:GetAttributeChangedSignal("AvatarMessage"),refresh)
		ctx.scope:Connect(preview.model:GetAttributeChangedSignal("PreviewAction"),refresh)
		refresh()
	end
end
