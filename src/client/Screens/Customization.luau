local UI = require(script.Parent.Parent.UI)
local M = require(script.Parent.ManagementUI)
local Rig = require(script.Parent.Parent.Rig)
local Data = require(game:GetService("ReplicatedStorage"):WaitForChild("CL27"):WaitForChild("Data"))
local accents = {
	{name = "Turquesa", color = Color3.fromRGB(70, 239, 201)},
	{name = "Esmeralda", color = Color3.fromRGB(54, 211, 143)},
	{name = "Azul", color = Color3.fromRGB(88, 165, 255)},
}
local function shirt(parent, kit, x, y)
	local shirtColor = kit.shirt or Color3.fromRGB(220, 235, 240)
	local accent = kit.accent or M.c.accent
	local left = UI.frame(parent, x + 3, y + 9, 35, 45, shirtColor)
	left.Rotation = 25
	local right = UI.frame(parent, x + 99, y + 9, 35, 45, shirtColor)
	right.Rotation = -25
	UI.frame(parent, x + 28, y + 2, 81, 110, shirtColor)
	UI.frame(parent, x + 61, y + 8, 6, 102, accent)
	UI.frame(parent, x + 51, y + 1, 35, 8, accent)
	UI.text(parent, "CL", x + 78, y + 23, 25, 20, 12, kit.shorts or M.c.ink, Enum.Font.GothamBold)
end

return function(root, ctx)
	local state = ctx.state
	state.homeKit = state.homeKit or 1
	state.accent = state.accent or "Turquesa"
	local club = M.club(Data, state.homeClub)
	state.homeKit = math.clamp(state.homeKit, 1, #club.kits)
	local accent = accents[1].color
	for _, item in ipairs(accents) do if item.name == state.accent then accent = item.color end end
	UI.header(root, "Personalização", "IDENTIDADE DO CLUBE")
	M.title(root, "CLUB LEGACY 27", "Sua identidade. Seu legado.", 65, 142, 1100)
	UI.text(root, "Apresentação visual e uniformes originais", 67, 245, 1000, 29, 17, M.c.muted)
	UI.section(root, "CORES DA INTERFACE", 65, 317, 735)
	for index, item in ipairs(accents) do
		local x = 65 + (index - 1) * 240
		UI.button(root, "", x, 363, 219, 70, function() state.accent = item.name; ctx.rerender() end, ctx.scope, {selected = state.accent == item.name})
		UI.frame(root, x + 19, 388, 19, 19, item.color)
		UI.text(root, item.name, x + 53, 381, 155, 32, 19, M.c.white, Enum.Font.GothamBold)
	end
	UI.section(root, "UNIFORME DE APRESENTAÇÃO", 65, 486, 765)
	local width = math.min(230, 735 / math.max(1, #club.kits))
	for index, kit in ipairs(club.kits) do
		local x = 65 + (index - 1) * (width + 18)
		local b = UI.button(root, "", x, 537, width, 203, function()
			if state.homeKit ~= index then state.homeReady = false; state.kitPresentation = false end
			state.homeKit = index
			ctx.rerender()
		end, ctx.scope, {selected = state.homeKit == index})
		shirt(b, kit, (width - 137) / 2, 22)
		UI.text(b, kit.name, 17, 160, width - 34, 29, 17, M.c.white, Enum.Font.GothamBold)
	end
	UI.button(root, "Abrir apresentação de uniformes  →", 65, 771, 735, 52, function() ctx.go("Kits") end, ctx.scope, {primary = true})
	UI.line(root, 845, 149, 845, 810, M.c.line, 1)
	UI.panel(root, 888, 149, 646, 674, M.c.panel, 0.35)
	UI.gradient(UI.frame(root, 888, 149, 646, 674, Color3.new(1, 1, 1), 0.83), {M.c.ink, accent}, 35)
	UI.text(root, "APRESENTAÇÃO DO CLUBE", 922, 183, 570, 26, 13, accent, Enum.Font.GothamBold)
	local viewport = UI.new("ViewportFrame", {
		Name = "UniformeDeApresentacao", Position = UDim2.fromOffset(910, 231), Size = UDim2.fromOffset(480, 475),
		BackgroundTransparency = 1, Ambient = Color3.fromRGB(171, 188, 205), LightColor = Color3.fromRGB(242, 255, 254),
		LightDirection = Vector3.new(-1, -0.4, -1),
	}, root)
	local world = UI.new("WorldModel", {Name = "Apresentacao"}, viewport)
	local model = Rig.create(M.player(Data, state.selectedPlayer or 1), club, state.homeKit)
	model.Parent = world
	model:PivotTo(CFrame.new())
	Rig.pose(model, "Presentation")
	local camera = UI.new("Camera", {CFrame = CFrame.lookAt(Vector3.new(0.3, 0.1, -10.8), Vector3.new(0, -0.1, 0)), FieldOfView = 36}, viewport)
	viewport.CurrentCamera = camera
	UI.badge(root, club, 1385, 263, 111)
	UI.text(root, club.name, 922, 725, 572, 43, 29, M.c.white, Enum.Font.GothamBold)
	UI.text(root, club.kits[state.homeKit].name .. "  /  Identidade original CL 27", 922, 779, 572, 27, 14, M.c.muted)
end
