-- Apresentação de uniformes originais; não conduz a uma partida.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local UI = require(script.Parent.Parent.UI)
local Data = require(ReplicatedStorage.CL27.Data)

local WHITE = Color3.fromRGB(242, 250, 249)
local MUTED = Color3.fromRGB(155, 187, 189)
local TEAL = Color3.fromRGB(65, 243, 200)

local function label(parent, value, x, y, w, h, size, color, font)
	local object = UI.text(parent, value, x, y, w, h, size, color or WHITE, font)
	object.TextXAlignment = Enum.TextXAlignment.Center
	return object
end

local function part(parent, size, position, color, rotation)
	local object = Instance.new("Part")
	object.Size = size
	object.CFrame = CFrame.new(position) * (rotation or CFrame.identity)
	object.Anchored = true
	object.CanCollide = false
	object.CastShadow = false
	object.Material = Enum.Material.SmoothPlastic
	object.Color = color
	object.Parent = parent
	return object
end

local function kitPreview(parent, club, index, x, y, w, h, secondary)
	local kit = club.kits[index]
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "UniformeOriginal"
	viewport.Position = UDim2.fromOffset(x, y)
	viewport.Size = UDim2.fromOffset(w, h)
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(181, 200, 205)
	viewport.LightColor = Color3.fromRGB(255, 255, 243)
	viewport.LightDirection = Vector3.new(-1, -1, -3)
	viewport.ImageTransparency = if secondary then 0.55 else 0
	viewport.Parent = parent
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	local shirt = kit.shirt or club.primary
	local accent = kit.accent or club.secondary
	local shorts = kit.shorts or shirt
	part(world, Vector3.new(2.05, 2, 0.32), Vector3.new(0, 1.1, 0), shirt)
	part(world, Vector3.new(0.87, 0.95, 0.33), Vector3.new(-1.23, 1.58, 0), shirt, CFrame.Angles(0, 0, math.rad(-18)))
	part(world, Vector3.new(0.87, 0.95, 0.33), Vector3.new(1.23, 1.58, 0), shirt, CFrame.Angles(0, 0, math.rad(18)))
	part(world, Vector3.new(0.57, 0.16, 0.36), Vector3.new(0, 2.14, 0), accent)
	part(world, Vector3.new(0.14, 1.93, 0.035), Vector3.new(-0.73, 1.12, -0.18), accent)
	part(world, Vector3.new(0.09, 1.93, 0.035), Vector3.new(0.75, 1.12, -0.18), accent)
	part(world, Vector3.new(0.28, 0.38, 0.04), Vector3.new(-0.38, 1.58, -0.19), accent)
	part(world, Vector3.new(0.93, 0.85, 0.32), Vector3.new(-0.52, -0.39, 0), shorts)
	part(world, Vector3.new(0.93, 0.85, 0.32), Vector3.new(0.52, -0.39, 0), shorts)
	part(world, Vector3.new(0.7, 0.11, 0.35), Vector3.new(-0.52, -0.82, 0), accent)
	part(world, Vector3.new(0.7, 0.11, 0.35), Vector3.new(0.52, -0.82, 0), accent)
	local camera = Instance.new("Camera")
	camera.FieldOfView = 34
	camera.CFrame = CFrame.lookAt(Vector3.new(-0.4, 1.35, if secondary then -9.7 else -8.6), Vector3.new(0, 0.65, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	return viewport
end

return function(root, ctx)
	local state = ctx.state
	state.homeKit = state.homeKit or 1
	state.awayKit = state.awayKit or 2
	state.activeSide = state.activeSide or "home"
	local home = Data.clubs[state.homeClub]
	local away = Data.clubs[state.awayClub]
	state.homeKit = math.clamp(state.homeKit, 1, #home.kits)
	state.awayKit = math.clamp(state.awayKit, 1, #away.kits)
	UI.header(root, "Seleção de uniformes", "APRESENTAÇÃO")
	local left = label(root, "MANDANTE", -141, 409, 455, 48, 37, WHITE, Enum.Font.GothamBold)
	left.Rotation = -90
	local right = label(root, "VISITANTE", 1285, 409, 455, 48, 37, WHITE, Enum.Font.GothamBold)
	right.Rotation = 90

	local function update()
		ctx.scene:UpdateClubs(home, away, state.homeKit, state.awayKit)
	end
	local function cycle(side, direction)
		local club = if side == "home" then home else away
		state.activeSide = side
		state[side .. "Kit"] = (state[side .. "Kit"] - 1 + direction) % #club.kits + 1
		state[side .. "Ready"] = false
		state.kitPresentation = false
		update()
		ctx.rerender()
	end

	local function sidePanel(side, x, club)
		local kitIndex = state[side .. "Kit"]
		local kit = club.kits[kitIndex]
		local ready = state[side .. "Ready"]
		local selected = state.activeSide == side
		label(root, if ready then "✓  PRONTO" else "ESCOLHA O UNIFORME", x - 15, 212, 315, 33, 19, if ready then TEAL else WHITE, Enum.Font.GothamBold)
		label(root, string.upper(club.shortName), x - 15, 252, 315, 26, 14, MUTED)
		if selected then UI.line(root, x + 50, 293, x + 235, 293, TEAL, 2) end
		if #club.kits > 1 then
			local nextIndex = kitIndex % #club.kits + 1
			kitPreview(root, club, nextIndex, x + 163, 367, 112, 177, true)
		end
		kitPreview(root, club, kitIndex, x + 5, 321, 215, 304, false)
		UI.button(root, "‹", x - 10, 424, 35, 61, function() cycle(side, -1) end, ctx.scope, { quiet = true })
		UI.button(root, "›", x + 255, 424, 35, 61, function() cycle(side, 1) end, ctx.scope, { quiet = true })
		label(root, string.upper(kit.name), x - 15, 628, 315, 28, 16, WHITE, Enum.Font.GothamMedium)
		local dots = {}
		for index = 1, #club.kits do table.insert(dots, if index == kitIndex then "●" else "·") end
		label(root, table.concat(dots, "   "), x - 15, 665, 315, 24, 19, if selected then TEAL else MUTED)
		UI.button(root, if ready then "REVISAR ESCOLHA" else "CONFIRMAR", x + 17, 710, 251, 43, function()
			state.activeSide = side
			state[side .. "Ready"] = not ready
			state.kitPresentation = false
			ctx.rerender()
		end, ctx.scope, { selected = selected, primary = not ready })
	end

	sidePanel("home", 490, home)
	sidePanel("away", 850, away)
	UI.line(root, 800, 326, 800, 668, Color3.fromRGB(63, 112, 120), 1)
	label(root, home.name, 116, 766, 345, 31, 21, WHITE, Enum.Font.GothamBold)
	label(root, away.name, 1139, 766, 345, 31, 21, WHITE, Enum.Font.GothamBold)
	UI.button(root, "‹  ALTERAR CLUBES", 69, 790, 255, 40, function() ctx.go("Clubs") end, ctx.scope, { quiet = true })
	UI.button(root, if state.kitPresentation then "APRESENTAÇÃO CONCLUÍDA  ✓" else "APRESENTAR UNIFORMES", 590, 790, 420, 42, function()
		if not state.homeReady or not state.awayReady then
			ctx.notify("Confirme o uniforme de cada clube para apresentar.")
			return
		end
		state.kitPresentation = true
		update()
		ctx.notify("Identidades confirmadas. A apresentação visual está pronta.")
		ctx.rerender()
	end, ctx.scope, { primary = state.homeReady and state.awayReady })
	ctx.scope:Connect(UserInputService.InputBegan, function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.Left then cycle(state.activeSide, -1)
		elseif input.KeyCode == Enum.KeyCode.Right then cycle(state.activeSide, 1) end
	end)
end
