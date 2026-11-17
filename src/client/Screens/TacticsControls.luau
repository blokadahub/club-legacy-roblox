--!nonstrict
-- Local visual primitives reuse UI construction and Scope lifecycle.
local UI=require(script.Parent.Parent.UI)
local Theme=require(game:GetService("ReplicatedStorage").CL27.Theme)
local Controls={}
Controls.colors=Theme.sports
local C=Controls.colors
local owners={}
-- Keep confirmed selection distinct from transient mouse/gamepad focus.
local function outline(button,scope)
	local edge=button:FindFirstChild("ControlOutline")
	if not edge then return end
	local owner=scope or owners[button]
	if owner and owner.tweens[edge] then owner.tweens[edge]:Cancel();owner.tweens[edge]=nil end
	local selected=button:GetAttribute("TacticalSelected")==true
	local focused=button:GetAttribute("TacticalFocused")==true
	edge.Thickness=if selected or focused then 2 else 1
	local goals={Color=if selected or focused then C.green else C.border,
		Transparency=if selected or focused then 0 else (button:GetAttribute("QuietOutline") and .85 or .25)}
	if scope and not UI.reducedMotion then scope:Tween(edge,goals,Theme.durations.micro)
	else
		if scope and scope.tweens[edge] then scope.tweens[edge]:Cancel();scope.tweens[edge]=nil end
		for key,value in pairs(goals) do edge[key]=value end
	end
end
function Controls.select(button,selected)
	button:SetAttribute("TacticalSelected",selected==true)
	outline(button)
end
function Controls.text(parent,value,x,y,w,h,size,color,bold)
	local ink=if UI.highContrast and color==C.muted then C.white else (color or C.white)
	local label=UI.text(parent,value,x,y,w,h,size,ink,if bold then Enum.Font.GothamBold else Enum.Font.GothamMedium)
	label.TextTruncate=Enum.TextTruncate.None
	label.TextWrapped=true
	return label
end
function Controls.button(parent,name,callback,scope,primary)
	local b=UI.new("TextButton",{Name=name,Text="",BackgroundColor3=if primary then C.green else C.panel,
		BackgroundTransparency=0,BorderSizePixel=0,AutoButtonColor=false,Selectable=true,Active=true},parent)
	UI.new("UICorner",{CornerRadius=UDim.new(0,8)},b)
	local edge=UI.stroke(b,C.border,.25,1);edge.Name="ControlOutline"
	owners[b]=scope;scope:Add(function() owners[b]=nil end)
	local hovered,gamepadFocus=false,false
	local function focus()
		b:SetAttribute("TacticalFocused",b.Active and (hovered or gamepadFocus));outline(b,scope)
	end
	scope:Connect(b.MouseEnter,function() hovered=true;focus() end)
	scope:Connect(b.MouseLeave,function() hovered=false;focus() end)
	scope:Connect(b.SelectionGained,function() gamepadFocus=true;focus() end)
	scope:Connect(b.SelectionLost,function() gamepadFocus=false;focus() end)
	scope:Connect(b.Activated,function() if b.Active then callback() end end)
	return b,edge
end
function Controls.row(parent,name,label,callback,scope)
	local b=Controls.button(parent,name,callback,scope)
	b.BackgroundTransparency=1;b:SetAttribute("QuietOutline",true);Controls.select(b,false)
	local rule=UI.frame(b,0,0,516,1,C.border,.45);rule.Name="SeparadorControle"
	local caption=Controls.text(b,label,16,7,430,24,18,C.muted)
	local value=Controls.text(b,"",16,32,430,38,25,C.white,true)
	local arrow=Controls.text(b,"›",466,8,36,60,34,C.green,true)
	return {button=b,caption=caption,value=value,arrow=arrow,rule=rule}
end
function Controls.rowSize(row,y,height,scale,width)
	width=width or 516
	local compact=scale<.65
	row.button.Position=UDim2.fromOffset(0,y)
	row.button.Size=UDim2.fromOffset(width,height-8)
	row.rule.Size=UDim2.fromOffset(width,1)
	row.caption.Position=UDim2.fromOffset(12,if compact then 3 else 0)
	row.caption.Size=UDim2.fromOffset(if compact then width-24 else width*.43,height*(if compact then .4 else .9))
	row.caption.TextSize=math.max(17,10/scale)
	row.value.Position=UDim2.fromOffset(if compact then 12 else width*.45,if compact then height*.4 else 0)
	row.value.Size=UDim2.fromOffset(if compact then width-24 else width*.55-42,height*(if compact then .5 else .9))
	row.value.TextSize=math.max(24,12/scale)
	row.value.TextXAlignment=if compact then Enum.TextXAlignment.Left else Enum.TextXAlignment.Right
	row.arrow.Position=UDim2.fromOffset(width-36,0);row.arrow.Size=UDim2.fromOffset(30,height-8)
	row.arrow.Visible=not compact
end
-- One short entry per opening. Reopening cancels any previous interpolation.
function Controls.present(group,scope,visible)
	if scope.tweens[group] then scope.tweens[group]:Cancel();scope.tweens[group]=nil end
	group.Visible=visible;group.GroupTransparency=0
	if visible and not UI.reducedMotion then
		group.GroupTransparency=.22
		scope:Tween(group,{GroupTransparency=0},.16)
	end
end
-- Keep the focused control inside a scroll window, also after gamepad navigation.
function Controls.reveal(scroll,button,zoom,scope)
	scope:Connect(button.SelectionGained,function()
		local factor=zoom and zoom() or 1
		local anchor=button.AnchorPoint or Vector2.new(0,0)
		local x=(button.Position.X.Offset-button.Size.X.Offset*anchor.X)*factor
		local y=(button.Position.Y.Offset-button.Size.Y.Offset*anchor.Y)*factor
		local w,h=button.Size.X.Offset*factor,button.Size.Y.Offset*factor
		local at=scroll.CanvasPosition
		local targetX=math.clamp(at.X,math.min(x,x+w-scroll.Size.X.Offset),x)
		local targetY=math.clamp(at.Y,math.min(y,y+h-scroll.Size.Y.Offset),y)
		scroll.CanvasPosition=Vector2.new(
			math.clamp(targetX,0,math.max(0,scroll.CanvasSize.X.Offset-scroll.Size.X.Offset)),
			math.clamp(targetY,0,math.max(0,scroll.CanvasSize.Y.Offset-scroll.Size.Y.Offset)))
	end)
end
return Controls
