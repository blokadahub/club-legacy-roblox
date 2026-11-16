--!nonstrict
-- Local visual primitives reuse UI construction and Scope lifecycle.
local UI=require(script.Parent.Parent.UI)
local Controls={}
Controls.colors={ink=Color3.fromRGB(10,13,14),panel=Color3.fromRGB(23,28,29),
	white=Color3.fromRGB(241,244,239),muted=Color3.fromRGB(174,184,180),
	green=Color3.fromRGB(155,225,110),border=Color3.fromRGB(64,76,68),warning=Color3.fromRGB(224,197,139)}
local C=Controls.colors
function Controls.text(parent,value,x,y,w,h,size,color,bold)
	local label=UI.text(parent,value,x,y,w,h,size,color or C.white,if bold then Enum.Font.GothamBold else Enum.Font.GothamMedium)
	label.TextTruncate=Enum.TextTruncate.None
	label.TextWrapped=true
	return label
end
function Controls.button(parent,name,callback,scope,primary)
	local b=UI.new("TextButton",{Name=name,Text="",BackgroundColor3=if primary then C.green else C.panel,
		BackgroundTransparency=0,BorderSizePixel=0,AutoButtonColor=false,Selectable=true,Active=true},parent)
	UI.new("UICorner",{CornerRadius=UDim.new(0,8)},b)
	local edge=UI.stroke(b,C.border,.25,1)
	local function focus(on) edge.Color=if on then C.green else C.border;edge.Thickness=if on then 2 else 1 end
	scope:Connect(b.MouseEnter,function() focus(true) end)
	scope:Connect(b.MouseLeave,function() focus(false) end)
	scope:Connect(b.SelectionGained,function() focus(true) end)
	scope:Connect(b.SelectionLost,function() focus(false) end)
	scope:Connect(b.Activated,callback)
	return b,edge
end
function Controls.row(parent,name,label,callback,scope)
	local b=Controls.button(parent,name,callback,scope)
	local caption=Controls.text(b,label,16,7,430,24,18,C.muted)
	local value=Controls.text(b,"",16,32,430,38,25,C.white,true)
	local arrow=Controls.text(b,"›",466,8,36,60,34,C.green,true)
	return {button=b,caption=caption,value=value,arrow=arrow}
end
function Controls.rowSize(row,y,height,scale)
	row.button.Position=UDim2.fromOffset(0,y)
	row.button.Size=UDim2.fromOffset(516,height-8)
	row.caption.Position=UDim2.fromOffset(16,5)
	row.caption.Size=UDim2.fromOffset(438,(height-8)*.4)
	row.caption.TextSize=math.max(17,11/scale)
	row.value.Position=UDim2.fromOffset(16,(height-8)*.4)
	row.value.Size=UDim2.fromOffset(438,(height-8)*.55)
	row.value.TextSize=math.max(24,12/scale)
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
