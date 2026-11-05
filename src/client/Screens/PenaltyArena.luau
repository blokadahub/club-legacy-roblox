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
end
