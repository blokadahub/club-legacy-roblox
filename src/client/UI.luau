--!strict
local Theme = require(game:GetService("ReplicatedStorage").CL27.Theme)
local Rig = require(script.Parent.Rig)
local UI = {}
UI.accent = Theme.accent
UI.actionGreen = Theme.actionGreen
UI.actionHover = Theme.actionHover
function UI.new(className, props, parent)
	local object = Instance.new(className)
	for key, value in pairs(props or {}) do object[key] = value end
	object.Parent = parent
	return object
end
function UI.frame(parent, x, y, w, h, color, transparency)
	return UI.new("Frame", {BorderSizePixel=0, BackgroundColor3=color or Theme.panel,
		BackgroundTransparency=transparency or 0, Position=UDim2.fromOffset(x,y), Size=UDim2.fromOffset(w,h)}, parent)
end
function UI.gradient(object, colors, rotation)
	local keys = {}
	for i, color in ipairs(colors) do table.insert(keys, ColorSequenceKeypoint.new((i-1)/math.max(1,#colors-1), color)) end
	return UI.new("UIGradient", {Color=ColorSequence.new(keys), Rotation=rotation or 0}, object)
end
function UI.stroke(object, color, transparency, thickness)
	return UI.new("UIStroke", {Color=color or UI.accent, Transparency=transparency or 0, Thickness=thickness or 1,
		ApplyStrokeMode=Enum.ApplyStrokeMode.Border}, object)
end
function UI.panel(parent,x,y,w,h,color,transparency)
	local panel = UI.frame(parent,x,y,w,h,color or Theme.panel,transparency or 0.14)
	-- UIGradient multiplies the parent color; white preserves the authored palette.
	panel.BackgroundColor3=Color3.new(1,1,1)
	UI.gradient(panel,{Color3.fromRGB(35,56,75),color or Theme.panel},90)
	return panel
end
function UI.text(parent, value,x,y,w,h,size,color,font)
	if UI.highContrast and color==Theme.muted then color=Color3.fromRGB(211,225,231) end
	return UI.new("TextLabel", {BackgroundTransparency=1, BorderSizePixel=0, Text=tostring(value),
		Position=UDim2.fromOffset(x,y), Size=UDim2.fromOffset(w,h), TextSize=size or 20,
		Font=font or Enum.Font.GothamMedium, TextColor3=color or Theme.white,
		TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Center,
		TextTruncate=Enum.TextTruncate.AtEnd, RichText=false}, parent)
end
function UI.line(parent,x1,y1,x2,y2,color,thickness)
	local delta = Vector2.new(x2-x1,y2-y1)
	local frame = UI.frame(parent,(x1+x2)/2,(y1+y2)/2,delta.Magnitude,thickness or 1,color or Theme.muted)
	frame.AnchorPoint=Vector2.new(0.5,0.5)
	frame.Rotation=math.deg(math.atan2(delta.Y,delta.X))
	return frame
end
function UI.button(parent,value,x,y,w,h,callback,scope,options)
	local opts = options or {}
	local background = if opts.primary then Theme.actionGreen else Theme.panelLight
	local transparency = opts.transparency or (if opts.quiet then 1 elseif opts.primary then 0 elseif opts.selected then 0.12 else 0.52)
	local button = UI.new("TextButton", {Name="Action_"..tostring(value), BorderSizePixel=0,
		BackgroundColor3=background, BackgroundTransparency=transparency, AutoButtonColor=false,
		Position=UDim2.fromOffset(x,y), Size=UDim2.fromOffset(w,h),
		Text=tostring(value), TextSize=opts.textSize or 18, Font=if opts.selected or opts.primary then Enum.Font.GothamBold else Enum.Font.GothamMedium,
		TextColor3=opts.textColor or (if opts.primary then Theme.background else (if opts.selected then UI.accent else Theme.white)),
		Selectable=true, TextTruncate=Enum.TextTruncate.AtEnd}, parent)
	if opts.selected then UI.frame(button,0,h-2,w,2,UI.accent) end
	local baseColor = button.TextColor3
	local function highlight(active)
		if not scope.alive then return end
		scope:Tween(button,{BackgroundTransparency=if active then (if opts.quiet then 0.85 else 0) else transparency,
			TextColor3=if active and not opts.primary then (opts.hoverTextColor or UI.accent) else baseColor},0.14)
	end
	scope:Connect(button.MouseEnter,function() highlight(true) end)
	scope:Connect(button.MouseLeave,function() highlight(false) end)
	scope:Connect(button.SelectionGained,function() highlight(true) end)
	scope:Connect(button.SelectionLost,function() highlight(false) end)
	scope:Connect(button.Activated,callback)
	return button
end
-- Shared lobby/intro capsule. The owner drives Step and destroys the sweep;
-- this component creates no connections, timers or independent frame loop.
function UI.capsule(parent,props,sizeProvider)
	local green=Theme.actionGreen
	local black=Color3.fromRGB(14,23,19)
	local button=UI.new("TextButton",{Text="",AutoButtonColor=false,Selectable=true,
		Active=true,BorderSizePixel=0,BackgroundColor3=green,BackgroundTransparency=1,
		ClipsDescendants=false,ZIndex=7},parent)
	for key,value in pairs(props or {}) do button[key]=value end
	-- The visual surface can be thinner than its transparent touch target.
	local surface=UI.new("Frame",{Name="SuperficieCapsula",BackgroundColor3=green,
		BorderSizePixel=0,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
		Size=UDim2.fromScale(1,1),ClipsDescendants=false,ZIndex=7},button)
	UI.new("UICorner",{CornerRadius=UDim.new(1,0)},surface)
	local border=UI.new("UIStroke",{Name="ReflexoBorda",Color=Color3.fromRGB(243,252,241),
		Thickness=1.1,Transparency=.82,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},surface)
	local disc=UI.new("Frame",{Name="IconeControle",Position=UDim2.new(0,7,.5,-17),
		Size=UDim2.fromOffset(34,34),BackgroundColor3=black,BorderSizePixel=0,ZIndex=9},surface)
	UI.new("UICorner",{CornerRadius=UDim.new(1,0)},disc)
	local key=UI.text(disc,"X",0,0,34,34,17,green,Enum.Font.GothamBold)
	key.Name="TeclaX"
	key.Size=UDim2.fromScale(1,1)
	key.TextXAlignment=Enum.TextXAlignment.Center
	key.ZIndex=10
	local label=UI.text(surface,"",47,0,0,0,17,black,Enum.Font.GothamBold)
	label.Name="TextoAcao"
	label.Size=UDim2.new(1,-52,1,0)
	label.TextXAlignment=Enum.TextXAlignment.Center
	label.TextTruncate=Enum.TextTruncate.None
	label.TextWrapped=true
	label.ZIndex=10
	local fx=require(script.Parent.OuterGlowSweep).newCapsule(surface,sizeProvider)
	return button,{surface=surface,border=border,disc=disc,key=key,label=label,fx=fx}
end
function UI.logo(parent,x,y,scale)
	local s=scale or 1
	UI.line(parent,x,y+9*s,x+17*s,y-6*s,UI.accent,4*s)
	UI.line(parent,x+3*s,y+22*s,x+30*s,y-5*s,UI.accent,4*s)
	local label=UI.text(parent,"CL 27",x+34*s,y-8*s,170*s,52*s,39*s,Theme.white,Enum.Font.GothamBlack)
	label.Rotation=-5
	return label
end
function UI.header(parent,title,section,tabs)
	UI.logo(parent,44,40,0.65)
	UI.line(parent,204,38,204,83,Theme.muted,1)
	UI.text(parent,title,226,35,420,28,if #title>26 then 22 else 24,Theme.white,Enum.Font.GothamBold)
	UI.text(parent,section or "CLUB LEGACY / TEMPORADA 2026–27",226,66,480,20,11,Theme.muted)
	for i,tab in ipairs(tabs or {}) do
		local x = 670+(i-1)*175
		-- Header tabs receive their already-connected action through a simple button.
		local b=UI.new("TextButton",{Text=tab.label,Font=if tab.selected then Enum.Font.GothamBold else Enum.Font.GothamMedium,
			TextSize=18,TextColor3=if tab.selected then UI.accent else Theme.muted,BackgroundTransparency=1,
			Position=UDim2.fromOffset(x,38),Size=UDim2.fromOffset(165,44),AutoButtonColor=false,Selectable=true},parent)
		if tab.selected then UI.frame(parent,x,88,155,2,UI.accent) end
		if tab.callback then b.Activated:Connect(function() if not UI.inputLocked then tab.callback() end end) end
	end
	UI.line(parent,44,105,1556,105,Color3.fromRGB(65,87,101),1).BackgroundTransparency=0.55
end
function UI.section(parent,value,x,y,w)
	UI.text(parent,string.upper(value),x,y,w or 400,28,15,Theme.muted,Enum.Font.GothamBold)
	UI.line(parent,x,y+35,x+(w or 400),y+35,Color3.fromRGB(72,96,111),1).BackgroundTransparency=0.5
end
function UI.stat(parent,label,value,x,y,w)
	UI.text(parent,label,x,y,w or 160,25,14,Theme.muted)
	UI.text(parent,value,x,y+28,w or 160,47,36,Theme.white,Enum.Font.GothamBold)
end
function UI.bar(parent,value,x,y,w,h,color)
	local track=UI.frame(parent,x,y,w,h or 4,Color3.fromRGB(63,79,93),0.35)
	UI.frame(track,0,0,w*math.clamp(value/100,0,1),h or 4,color or UI.accent)
	return track
end
-- Preserve the user's position while a screen rebuilds its selected/detail state.
-- Values use the fixed canvas units, so UIScale does not change the saved offset.
function UI.keepScroll(scroll,state,key,scope)
	local function clampY(value)
		return math.clamp(value or 0,0,math.max(0,scroll.CanvasSize.Y.Offset-scroll.Size.Y.Offset))
	end
	scroll.CanvasPosition=Vector2.new(0,clampY(state[key]))
	scope:Add(function()
		if scroll.Parent then state[key]=clampY(scroll.CanvasPosition.Y) end
	end)
end
function UI.badge(parent,club,x,y,size)
	local frame=UI.frame(parent,x,y,size,size,Color3.new(),1)
	local shield=UI.frame(frame,size*0.2,size*0.14,size*0.6,size*0.63,club.primary,0)
	UI.stroke(shield,club.secondary,0.1,math.max(1,size*0.012))
	local bottom=UI.frame(frame,size*0.287,size*0.56,size*0.426,size*0.426,club.primary)
	bottom.Rotation=45
	UI.stroke(bottom,club.secondary,0.1,math.max(1,size*0.012))
	UI.frame(frame,size*0.212,size*0.38,size*0.576,size*0.39,club.primary)
	UI.line(frame,size*0.3,size*0.25,size*0.7,size*0.25,club.secondary,math.max(1,size*0.02))
	local label=UI.text(frame,club.symbol or club.shortName,size*0.2,size*0.25,size*0.6,size*0.42,size*0.3,club.secondary,Enum.Font.GothamBlack)
	label.TextXAlignment=Enum.TextXAlignment.Center
	local small=UI.text(frame,"CL • "..tostring(club.founded or 1927),0,size*0.69,size,size*0.13,size*0.065,club.secondary,Enum.Font.GothamBold)
	small.TextXAlignment=Enum.TextXAlignment.Center
	return frame
end
function UI.portrait(parent,player,club,x,y,w,h,scope)
	local viewport=UI.new("ViewportFrame",{Name="Retrato_"..tostring(player.id),Size=UDim2.fromOffset(w,h),Position=UDim2.fromOffset(x,y),
		BackgroundTransparency=1,Ambient=Color3.fromRGB(185,200,217),LightColor=Color3.fromRGB(240,252,255),LightDirection=Vector3.new(-1,-0.5,-1)},parent)
	local world=UI.new("WorldModel",{},viewport)
	local model=Rig.create(player,club,1)
	model.Parent=world
	model:PivotTo(CFrame.new())
	Rig.pose(model,"Portrait")
	local camera=UI.new("Camera",{FieldOfView=29},viewport)
	local head=model:FindFirstChild("Head")
	local target=if head then head.Position-Vector3.new(0,0.3,0) else Vector3.new(0,4.6,0)
	camera.CFrame=CFrame.lookAt(target+Vector3.new(0,0,-4.4),target)
	viewport.CurrentCamera=camera
	if scope and not UI.reducedMotion then
		viewport.ImageTransparency=0.35
		scope:Tween(viewport,{ImageTransparency=0},0.22)
	end
	return viewport
end
return UI
