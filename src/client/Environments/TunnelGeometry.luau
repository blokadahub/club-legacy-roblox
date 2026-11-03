--!strict
-- Pure numeric geometry: the same descriptors feed Roblox and the offline bake.
local Geometry = {}
Geometry.Width, Geometry.Height, Geometry.Length = 34, 20.5, 96
Geometry.CameraPosition = {0, 5.2, 8}
Geometry.CameraTarget = {-16, 10, -112}
Geometry.FieldOfView = 54
Geometry.Profiles = {
	Low = {detail = 1, lightStride = 4, bloom = false, shadows = false},
	Medium = {detail = 2, lightStride = 2, bloom = true, shadows = false},
	High = {detail = 3, lightStride = 1, bloom = true, shadows = true},
}
export type LightSpec = {kind: string, color: {number}, brightness: number, range: number, face: string?, angle: number?}
export type Descriptor = {
	name: string, className: string, size: {number}, frame: {number}, color: {number},
	material: string, reflectance: number, light: LightSpec?, shadow: boolean,
}

function Geometry.profile(quality: string)
	assert(Geometry.Profiles[quality], "Unknown tunnel quality: " .. quality)
	return Geometry.Profiles[quality]
end

-- Roblox CFrame row-major rotation, Rx * Ry * Rz, without engine dependencies.
function Geometry.frame(x: number, y: number, z: number, rx: number?, ry: number?, rz: number?): {number}
	local a, b, c = rx or 0, ry or 0, rz or 0
	local ca, sa, cb, sb, cc, sc = math.cos(a), math.sin(a), math.cos(b), math.sin(b), math.cos(c), math.sin(c)
	return {x,y,z, cb*cc,-cb*sc,sb, ca*sc+sa*sb*cc,ca*cc-sa*sb*sc,-sa*cb, sa*sc-ca*sb*cc,sa*cc+ca*sb*sc,ca*cb}
end

function Geometry.lookAt(a: {number}, b: {number}): {number}
	local zx, zy, zz = a[1]-b[1], a[2]-b[2], a[3]-b[3]
	local length = math.sqrt(zx*zx+zy*zy+zz*zz)
	assert(length > 0.001, "Degenerate beam/camera")
	zx, zy, zz = zx/length, zy/length, zz/length
	local rightLength = math.sqrt(zz*zz+zx*zx)
	assert(rightLength > 0.001, "Vertical lookAt requires another up vector")
	local xx, xz = zz/rightLength, -zx/rightLength
	return {a[1],a[2],a[3], xx,zy*xz,zx, 0,zz*xx-zx*xz,zy, xz,-zy*xx,zz}
end

function Geometry.build(quality: string): {Descriptor}
	local profile = Geometry.profile(quality)
	local parts: {Descriptor} = {}
	local blue, red = {17,24,43}, {43,23,22}
	local steel, black = {31,35,42}, {9,12,17}
	local green, amber, cobalt = {73,240,87}, {255,133,30}, {32,62,255}
	local function add(name, size, cf, color, material, light, className, reflectance)
		local item: Descriptor = {name=string.format("%03d_%s", #parts+1, name), className=className or "Part",
			size=size, frame=cf, color=color, material=material or "Metal", light=light,
			reflectance=reflectance or 0, shadow=material ~= "Neon"}
		table.insert(parts, item)
		return item
	end
	local function beam(name, a, b, thickness, color)
		local dx, dy, dz = b[1]-a[1], b[2]-a[2], b[3]-a[3]
		local mid = {(a[1]+b[1])/2,(a[2]+b[2])/2,(a[3]+b[3])/2}
		return add(name,{thickness,thickness,math.sqrt(dx*dx+dy*dy+dz*dz)},Geometry.lookAt(mid,b),color)
	end
	local function source(kind, color, brightness, range, face)
		return {kind=kind,color=color,brightness=brightness,range=range,face=face,angle=105}
	end
	-- Separated slab joints, restrained rough metal highlights, no mirror planes.
	add("Foundation",{37,0.6,140},Geometry.frame(0,-0.43,-48),black,"Concrete")
	for row = 0, 13 do
		for column = -1, 1 do
			local tone = 18 + (row*7 + column*3)%5
			add("FloorSlab",{11.25,0.22,7.96},Geometry.frame(column*11.3,-0.11,4-row*8),
				{tone,tone+2,tone+5},"Metal",nil,nil,0.035)
		end
	end
	for _, side in ipairs({-1,1}) do
		local tint = if side == -1 then blue else red
		local tilt = side*math.rad(8)
		local function wallX(y) return side*(17-y*math.tan(math.rad(8))) end
		add("SlopedShell",{0.8,20.8,96},Geometry.frame(wallX(10.25),10.25,-40,0,0,tilt),tint)
		add("BasePlinth",{0.85,0.65,96},Geometry.frame(side*16.82,0.35,-40),steel)
		add("GreenRecess",{0.34,0.3,96},Geometry.frame(side*16.26,0.62,-40),black)
		-- Small sections remain visually continuous; only selected sections emit light.
		for bay = 0, 7 do
			local z = 2-bay*12
			local lit = bay%profile.lightStride == 0
			add("GreenBase",{0.1,0.11,11.98},Geometry.frame(side*16.03,0.68,z),green,"Neon",
				if lit then source("PointLight",green,0.32,7) else nil)
			local y = 9.15
			local x = wallX(y)-side*0.59
			-- Complementary wedges form real triangular plates, recessed behind ribs.
			add("TriangularPlateA",{0.17,14.3,11.12},Geometry.frame(x,y,z,0,0,tilt),tint,"Metal",nil,"WedgePart")
			-- Rz(tilt) * Rx(pi) has these signs for the complementary half.
			local reverse = Geometry.frame(x,y,z,0,0,tilt)
			for _, index in ipairs({5,6,8,9,11,12}) do reverse[index] = -reverse[index] end
			add("TriangularPlateB",{0.17,14.3,11.12},reverse,
				if side == -1 then {20,28,48} else {49,27,25},"Metal",nil,"WedgePart")
			beam("InclinedButtress",{wallX(1.2)-side*0.98,1.2,z+5.5},
				{wallX(17.9)-side*0.98,17.9,z-4.1},0.84,if side == -1 then {28,39,59} else {65,37,29})
			for _, seamY in ipairs({3.8,10.0,15.6}) do
				add("PanelHorizontalSeam",{0.1,0.07,10.8},Geometry.frame(wallX(seamY)-side*0.74,seamY,z,0,0,tilt),black)
			end
			if profile.detail >= 2 then
				beam("TriangleSeam",{wallX(2)-side*0.78,2,z-5.2},{wallX(16.1)-side*0.78,16.1,z+5.2},0.065,black)
				add("PanelSpine",{0.13,14.1,0.12},Geometry.frame(x-side*0.2,y,z+5.65,0,0,tilt),steel)
				for vent = 1, 3 do
					add("UpperVent",{0.1,0.075,2.6},Geometry.frame(wallX(17.3+vent*0.18)-side*0.55,17.3+vent*0.18,z+2,0,0,tilt),black)
				end
			end
			if profile.detail >= 3 then
				for _, seamZ in ipairs({-3.4,3.4}) do
					beam("FineDiagonal",{wallX(3)-side*0.82,3,z+seamZ},{wallX(14)-side*0.82,14,z+seamZ+1.5},0.045,steel)
				end
			end
		end
	end
	-- Three ceiling levels: black central service trench and sloped side coffers.
	add("CeilingShell",{35,0.65,100},Geometry.frame(0,20.8,-40),black)
	add("CentralServiceTrench",{6.1,0.48,98},Geometry.frame(0,20.18,-40),{5,7,11})
	for bay = 0, 7 do
		local z = 2-bay*12
		add("LeftCeilingCoffer",{11.3,0.42,11.85},Geometry.frame(-8.55,19.35,z,0,0,math.rad(-9)),{18,23,38})
		add("RightCeilingCoffer",{11.3,0.42,11.85},Geometry.frame(8.55,19.35,z,0,0,math.rad(9)),{47,24,20})
		add("CeilingCrossRib",{29,0.38,0.3},Geometry.frame(0,19.72,z-5.85),steel)
		add("BlueUpperRecess",{0.72,0.26,12},Geometry.frame(-13.5,18.3,z),black)
		add("BlueUpperNeon",{0.09,0.07,11.98},Geometry.frame(-13.31,18.17,z),cobalt,"Neon",
			if bay%profile.lightStride == 0 then source("PointLight",cobalt,0.75,13) else nil)
		add("OrangeFixtureHousing",{1.0,0.3,3.4},Geometry.frame(13.05,18.65,z,0,0,math.rad(9)),black)
		add("OrangeCeilingFixture",{0.52,0.08,2.9},Geometry.frame(13.05,18.46,z,0,0,math.rad(9)),amber,"Neon",
			if bay%profile.lightStride == 0 then source("SurfaceLight",amber,1.25,21,"Bottom") else nil)
		if profile.detail >= 2 then
			for _, x in ipairs({-2.7,2.7}) do
				add("CeilingConduit",{0.11,0.14,11.9},Geometry.frame(x,19.78,z),{26,28,32})
			end
		end
	end
	-- Far portal is OPEN; the dim chamber behind it makes a depth cue, not a neon wall.
	for _, side in ipairs({-1,1}) do
		add("ExitPier",{1.8,19.5,1.5},Geometry.frame(side*14.6,9.75,-88.5),{22,37,40},"Concrete")
		add("ExitChamberWall",{0.6,24,26},Geometry.frame(side*18,12,-102),{21,45,47},"Concrete")
		for i = 0, 4 do
			local z = -64-i*5
			add("FarAmberMarker",{0.13,0.16,0.65},Geometry.frame(side*15.9,0.92,z),amber,"Neon",
				if i == 2 then source("PointLight",amber,0.42,8) else nil)
		end
	end
	add("ExitLintel",{31,1.3,1.6},Geometry.frame(0,19.6,-88.5),{19,31,36})
	add("ExitCeiling",{37,0.5,26},Geometry.frame(0,24,-102),{13,30,33})
	add("DistantBackdrop",{37,24,0.6},Geometry.frame(0,12,-115),{21,48,49},"Concrete")
	add("DistantHorizon",{35,0.12,0.14},Geometry.frame(0,1,-113),{73,145,97},"Neon",
		source("SurfaceLight",{65,170,149},0.8,28,"Back"))
	add("HiddenTealWash",{18,0.1,3},Geometry.frame(0,22,-101),{26,47,48},"Metal",
		source("SurfaceLight",{44,148,164},1.6,29,"Bottom"))
	return parts
end

return Geometry
