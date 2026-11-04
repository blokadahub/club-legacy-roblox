--!strict
local TweenService=game:GetService("TweenService")
local GuiService=game:GetService("GuiService")
local UI=require(script.Parent.Parent.UI)
local Background=require(script.Parent.IntroBackground)
local Visuals={}
local GREEN=Color3.fromRGB(35,255,80)
local WHITE=Color3.new(1,1,1)
local WORD_PADDING=16
local function group(parent,name,size)
	return UI.new("CanvasGroup",{Name=name,BackgroundTransparency=1,Size=size,GroupTransparency=0},parent)
end
local function text(parent,value,y,w,h,size,color)
	local label=UI.text(parent,value,0,y,w,h,size,color,Enum.Font.GothamBold)
	label.TextXAlignment=Enum.TextXAlignment.Center
	label.TextTruncate=Enum.TextTruncate.None
	return label
end
local function stroke(parent,coords,color,width)
	local line=UI.line(parent,coords[1],coords[2],coords[3],coords[4],color,width)
	line.Name="TracoMarcaCL"
	return line
end
local function monogram(parent,x,y,s,color)
	for _,line in ipairs({{64,10,22,10},{22,10,2,76},{2,76,45,76},{84,10,64,76},{64,76,105,76}}) do
		stroke(parent,{x+line[1]*s,y+line[2]*s,x+line[3]*s,y+line[4]*s},color,12*s)
	end
end
local function brand(parent)
	local root=group(parent,"MarcaCLSportsCL27",UDim2.fromOffset(800,210))
	root.AnchorPoint=Vector2.new(.5,.5)
	local rim=UI.frame(root,10,0,210,210,GREEN)
	rim.Name="ArcoTransformacao"
	rim.Visible=false
	UI.new("UICorner",{CornerRadius=UDim.new(1,0)},rim)
	local disc=UI.frame(root,0,0,210,210,WHITE)
	disc.Name="CLSports"
	UI.new("UICorner",{CornerRadius=UDim.new(1,0)},disc)
	monogram(disc,30,26,1.35,Color3.fromRGB(16,18,17))
	text(disc,"SPORTS",135,210,38,29,Color3.fromRGB(16,18,17))
	-- CanvasGroup clips its own texture. Padding preserves the complete
	-- rotated stroke thickness without moving the visible wordmark.
	local word=group(root,"CL27",UDim2.fromOffset(555+2*WORD_PADDING,180+2*WORD_PADDING))
	word.Position=UDim2.fromOffset(245-WORD_PADDING,15-WORD_PADDING)
	monogram(word,WORD_PADDING,5+WORD_PADDING,2.05,WHITE)
	for _,line in ipairs({{275,26,370,26},{370,26,355,81},{355,81,272,81},
		{272,81,254,152},{254,152,350,152},{401,26,513,26},{513,26,444,152}}) do
		stroke(word,{line[1]+WORD_PADDING,line[2]+WORD_PADDING,line[3]+WORD_PADDING,line[4]+WORD_PADDING},WHITE,24)
	end
	local scale=UI.new("UIScale",{Scale=1},root)
	local function color(tint)
		disc.BackgroundColor3=tint
		for _,object in ipairs(word:GetDescendants()) do
			if object:IsA("Frame") then object.BackgroundColor3=tint end
		end
	end
	return {root=root,scale=scale,disc=disc,rim=rim,word=word,color=color}
end
local function progress(t,a,b)
	return math.clamp((t-a)/(b-a),0,1)
end
local function ease(t)
	return TweenService:GetValue(math.clamp(t,0,1),Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
end
Visuals.progress=progress
function Visuals.new(playerGui)
	-- Parent immediately: opaque shield exists before App or its dependencies run.
	local gui=UI.new("ScreenGui",{Name="CL27_Intro",DisplayOrder=250,IgnoreGuiInset=true,
		ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},playerGui)
	local shield=UI.new("Frame",{Name="BloqueioInicial",Size=UDim2.fromScale(1,1),
		BackgroundColor3=Color3.fromRGB(24,24,24),BorderSizePixel=0,Active=true},gui)
	local geometry=Background.new(shield)
	local background=group(shield,"Fundo",UDim2.fromScale(1,1))
	-- Background geometry remains below all graphics, without a loading veil.
	local canvas=UI.frame(background,0,0,1600,900,WHITE,1)
	canvas.AnchorPoint=Vector2.new(.5,.5)
	local scale=UI.new("UIScale",{},canvas)
	local logo=brand(canvas)
	local message=group(canvas,"EstadoPreparacao",UDim2.fromOffset(1080,180))
	message.Position=UDim2.fromOffset(260,342)
	message.GroupTransparency=1
	local messageText=text(message,"",0,1080,88,28,WHITE)
	messageText.TextWrapped=true
	local pill=text(message,"SESSÃO ROBLOX ATIVA",120,360,40,16,Color3.fromRGB(20,24,22))
	pill.Position=UDim2.fromOffset(360,120)
	pill.BackgroundColor3=WHITE
	pill.BackgroundTransparency=0
	UI.new("UICorner",{CornerRadius=UDim.new(1,0)},pill)
	local welcome=group(canvas,"BoasVindas",UDim2.fromOffset(1100,520))
	welcome.Position=UDim2.fromOffset(250,305)
	welcome.GroupTransparency=1
	local line1=text(welcome,"WELCOME",0,1100,105,88,GREEN)
	local line2=text(welcome,"TO THE CLUB",96,1100,105,88,GREEN)
	line1.Font=Enum.Font.GothamBlack
	line2.Font=Enum.Font.GothamBlack
	local start=UI.new("TextButton",{Name="START",Text="START",Font=Enum.Font.GothamBold,TextSize=23,
		TextColor3=Color3.fromRGB(9,21,12),BackgroundColor3=GREEN,BorderSizePixel=0,
		Size=UDim2.fromOffset(184,58),Position=UDim2.fromOffset(458,263),AutoButtonColor=false,
		Active=false,Selectable=false},welcome)
	start.AnchorPoint=Vector2.new(.5,.5)
	start.Position=UDim2.fromOffset(550,292)
	UI.new("UICorner",{CornerRadius=UDim.new(1,0)},start)
	UI.new("UIStroke",{Color=WHITE,Thickness=1,Transparency=.7,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},start)
	local supportA=text(welcome,"CL 27 — CLUB LEGACY 27",346,1100,30,15,Color3.fromRGB(181,184,182))
	local supportB=text(welcome,"Uma nova história começa no clube.",376,1100,30,14,Color3.fromRGB(145,149,146))
	local cut=UI.new("Frame",{Name="CorteCinematografico",BackgroundColor3=Color3.new(0,0,0),
		BorderSizePixel=0,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=20},shield)
	local passage=UI.new("Frame",{Name="PassagemArroxeada",BackgroundColor3=Color3.fromRGB(51,46,78),
		BorderSizePixel=0,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=21},shield)
	UI.new("UIGradient",{Color=ColorSequence.new(Color3.fromRGB(51,46,78),Color3.fromRGB(14,20,25)),Rotation=90},passage)
	local loader=UI.new("Frame",{Name="HostDoIndicadorUnico",BackgroundTransparency=1,
		Size=UDim2.fromScale(1,1),ZIndex=30},shield)
	local self={gui=gui,shield=shield,loader=loader,start=start,logo=logo,cut=cut,passage=passage,
		welcome=welcome,message=message}
	function self:Resize(size)
		geometry:Resize(size)
		local topLeft,bottomRight=GuiService:GetGuiInset()
		local available=size-topLeft-bottomRight-Vector2.new(32,32)
		scale.Scale=math.max(.05,math.min(available.X/1600,available.Y/900))
		-- Keep the actual interactive button at least 112 x 48 physical pixels,
		-- even when the surrounding 1600 x 900 composition is scaled down.
		start.Size=UDim2.fromOffset(math.max(184,112/scale.Scale),math.max(58,48/scale.Scale))
		start.TextSize=math.max(23,14/scale.Scale)
		local supportY=math.max(346,292+start.Size.Y.Offset/2+20)
		supportA.Position=UDim2.fromOffset(0,supportY)
		supportB.Position=UDim2.fromOffset(0,supportY+30)
		canvas.Position=UDim2.fromOffset(topLeft.X+16+available.X/2,topLeft.Y+16+available.Y/2)
		loader.Position=UDim2.fromOffset(0,-bottomRight.Y)
	end
	function self:Draw(snapshot,name,reduced,errorMessage)
		local t=snapshot.elapsed
		local exit=snapshot.exit
		local shrinking=ease(progress(t,7.05,7.4))
		local transformed=progress(t,6.3,6.6)
		local reveal=if exit then progress(exit,2.9,6) else 0
		background.GroupTransparency=0
		shield.BackgroundColor3=Color3.fromRGB(24,24,24)
		shield.BackgroundTransparency=0
		-- Viewport transparency follows reveal, no camera or lighting changes.
		geometry:SetTransparency(if exit then math.max(progress(exit,.5,.78),reveal) else 0)
		logo.root.Position=UDim2.fromOffset(800,450-240*shrinking)
		logo.scale.Scale=(1+0.28*ease(transformed))*(1-shrinking)+.25*shrinking
		if reduced then
			logo.scale.Scale=if t<7.4 then 1 else .25
			logo.root.Position=UDim2.fromOffset(800,if t<7.4 then 450 else 210)
		end
		logo.root.Rotation=0
		-- The reference reintroduces the circle alone at screen center;
		-- it moves left only as the title expands into the full composition.
		local circleSlide=if reduced or t<6.14 or t>=6.6 then 0 else 295*(1-ease(transformed))
		logo.disc.Position=UDim2.fromOffset(circleSlide,0)
		logo.disc.Rotation=if reduced or t<6.14 or t>6.6 then 0 else -24*(1-ease(progress(t,6.14,6.38)))
		logo.rim.Visible=t>=6.14 and t<6.6
		logo.rim.Position=UDim2.fromOffset(circleSlide+14*(1-ease(transformed)),0)
		logo.word.Position=UDim2.fromOffset(245-WORD_PADDING+(if reduced or t<6.14 then 0 else 340*(1-ease(transformed))),15-WORD_PADDING)
		logo.word.GroupTransparency=if t>=5.8 and t<6.3 then 1 else 0
		logo.root.GroupTransparency=if t<1.93 then 0 elseif t<2.15 then 1
			elseif t<5.8 then 0 elseif t<6.14 then 1
			elseif t<8.65 then 1-progress(t,6.14,6.3)
			elseif t<16.6 then progress(t,8.65,8.9) else 1
		if t>=6.3 and t<8.65 then logo.root.GroupTransparency=0 end
		logo.color(if t<2.15 then GREEN else WHITE)
		local msg=""
		local alpha=1
		pill.Visible=false
		if errorMessage then
			msg=errorMessage
			alpha=0
		elseif t>=8.9 and t<13.9 then
			msg=name.." está preparando sua experiência no Roblox..."
			pill.Visible=true
			alpha=1-progress(t,8.9,9.1)+progress(t,13.65,13.9)
		elseif t>=13.9 and t<15.25 then
			msg="Preparando os dados locais da experiência. Aguarde..."
			alpha=1-progress(t,13.9,14.05)+progress(t,15,15.25)
		elseif t>=15.25 and t<16.6 then
			msg=if snapshot.ready then "Conteúdo local carregado. Tudo pronto." else "Preparando o lobby..."
			alpha=1-progress(t,15.25,15.4)+progress(t,16.4,16.6)
		elseif snapshot.waiting then
			msg="Preparando o lobby..."
			alpha=0
		end
		message.Position=UDim2.fromOffset(260,if errorMessage then 315 else 342)
		messageText.Text=msg
		message.GroupTransparency=math.clamp(alpha,0,1)
		local welcomeIn=if t>=16.6 and (snapshot.ready or snapshot.welcomed) then ease(progress(t,16.6,17.15)) else 0
		welcome.GroupTransparency=1-welcomeIn
		welcome.Position=UDim2.fromOffset(250,305+(if reduced then 0 else 32*(1-welcomeIn)))
		line1.Position=UDim2.fromOffset(0,0)
		line2.Position=UDim2.fromOffset(0,96)
		start.Active=snapshot.canStart or errorMessage~=nil
		start.Selectable=start.Active
		if errorMessage then
			welcome.GroupTransparency=0
			line1.Visible=false;line2.Visible=false
			start.Text="TENTAR"
			logo.root.GroupTransparency=1
			supportA.Visible=false;supportB.Visible=false
		else
			line1.Visible=true;line2.Visible=true;start.Text="START"
			supportA.Visible=true;supportB.Visible=true
		end
		cut.BackgroundTransparency=if t>=1.93 and t<2.15 then 0 else 1
		passage.BackgroundTransparency=1
		if exit then
			local leave=progress(exit,0,.5)
			welcome.GroupTransparency=leave
			logo.root.GroupTransparency=leave
			if not reduced then
				line1.Position=UDim2.fromOffset(0,-90*ease(leave))
				line2.Position=UDim2.fromOffset(0,96-60*ease(leave))
			end
			background.GroupTransparency=math.max(leave,reveal)
			cut.BackgroundTransparency=1-math.min(progress(exit,.5,.78),1-progress(exit,2.9,6))
			if exit>=.5 and exit<1.5 then
				passage.BackgroundTransparency=1-math.min(progress(exit,.5,.72),1-progress(exit,1.05,1.5))
			end
			if exit>=1.5 then
				-- Only cut owns the black interval/reveal. Leaving the shield
				-- opaque too would multiply the fade and hide the lobby longer.
				shield.BackgroundTransparency=1
			end
		end
		return reveal, if exit then progress(exit,4.25,6) else 0
	end
	function self:Destroy() geometry:Destroy();gui:Destroy() end
	return self
end
return Visuals
