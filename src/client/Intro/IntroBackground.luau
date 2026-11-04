--!strict
-- Seven authored facets (14 wedges), no textures, lights, animation or main camera.
local Background = {}
local function point(x, y)
	return Vector3.new((x-960)/100, (540-y)/100, 0)
end
local function triangle(parent, a, b, c, shade)
	local ab, ac, bc=b-a,c-a,c-b
	if ab.Magnitude>ac.Magnitude and ab.Magnitude>bc.Magnitude then c,a=a,c
	elseif ac.Magnitude>bc.Magnitude then a,b=b,a end
	ab,ac,bc=b-a,c-a,c-b
	local right=ac:Cross(ab).Unit
	local up=bc:Cross(right).Unit
	local back=bc.Unit
	local height=math.abs(ab:Dot(up))
	for i, spec in ipairs({
		{(a+b)/2,right,back,math.abs(ab:Dot(back))},
		{(a+c)/2,-right,-back,math.abs(ac:Dot(back))},
	}) do
		local part=Instance.new("WedgePart")
		part.Name="FacetHalf"..i
		part.Anchored=true
		part.CanCollide=false
		part.CastShadow=false
		part.Material=Enum.Material.SmoothPlastic
		part.Color=Color3.fromRGB(shade,shade,shade)
		part.Size=Vector3.new(0.01,height,spec[4])
		part.CFrame=CFrame.fromMatrix(spec[1],spec[2],up,spec[3])
		part.Parent=parent
	end
end
function Background.new(parent)
	local view=Instance.new("ViewportFrame")
	view.Name="FacetasGeometricas"
	view.BackgroundColor3=Color3.fromRGB(24,24,24)
	view.BorderSizePixel=0
	view.Size=UDim2.fromOffset(1920,1080)
	view.AnchorPoint=Vector2.new(.5,.5)
	view.Position=UDim2.fromScale(.5,.5)
	view.Ambient=Color3.new(1,1,1)
	view.LightColor=Color3.new(0,0,0)
	view.Parent=parent
	local scale=Instance.new("UIScale")
	scale.Parent=view
	local camera=Instance.new("Camera")
	camera.Name="CameraFacetasIndependente"
	camera.CFrame=CFrame.new(0,0,50)
	camera.FieldOfView=math.deg(2*math.atan(5.4/50))
	camera.Parent=view
	view.CurrentCamera=camera
	local facets={
		{{0,0},{320,0},{0,610},23},
		{{320,0},{1400,0},{0,610},27},
		{{1400,0},{1830,1080},{0,610},30},
		{{1400,0},{1920,0},{1830,1080},12},
		{{1920,0},{1920,1080},{1830,1080},31},
		{{0,610},{1830,1080},{290,1080},25},
		{{0,610},{290,1080},{0,1080},34},
	}
	for _,f in ipairs(facets) do
		triangle(view,point(f[1][1],f[1][2]),point(f[2][1],f[2][2]),point(f[3][1],f[3][2]),f[4])
	end
	return {
		Resize=function(_,size) scale.Scale=math.max(size.X/1920,size.Y/1080) end,
		SetTransparency=function(_,alpha)
			view.ImageTransparency=alpha
			view.BackgroundTransparency=alpha
		end,
		Destroy=function() view:Destroy() end,
	}
end
return Background
