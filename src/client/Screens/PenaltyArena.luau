--!nonstrict
local UI=require(script.Parent.Parent.UI)
local Theme=require(game:GetService("ReplicatedStorage").CL27.Theme)
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
	local controls=UI.new("Frame",{Name="PreviaAnimacoes",AnchorPoint=Vector2.new(.5,1),
		Position=UDim2.new(.5,0,1,-14),Size=UDim2.fromOffset(330,54),BackgroundTransparency=1},gui)
	for i,entry in ipairs({{"Ver chute","Kick"},{"Defesa ←","DiveLeft"},{"Defesa →","DiveRight"}}) do
		local button=UI.button(controls,entry[1],(i-1)*112,0,106,54,function()
			if preview then preview:PreviewAction(entry[2]) end
		end,ctx.scope,{quiet=true,textSize=13})
		button.Name=entry[2]
		button.BackgroundColor3=Color3.fromRGB(19,29,36);button.BackgroundTransparency=.15
	end
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
		status.Text=preview.model:GetAttribute("AvatarMessage") or ""
		retry.Visible=state=="Error"
		for _,button in ipairs(controls:GetChildren()) do
			button.Active=state=="Ready";button.Selectable=state=="Ready"
			button.TextTransparency=if state=="Ready" then 0 else .5
		end
	end
	if preview then
		ctx.scope:Connect(preview.model:GetAttributeChangedSignal("AvatarStatus"),refresh)
		ctx.scope:Connect(preview.model:GetAttributeChangedSignal("AvatarMessage"),refresh)
		refresh()
	end
end
