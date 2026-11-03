--!strict
-- CL 27: halo radial oval de seleção, desenhado com GUI nativa.
-- Evita texturas externas, nuvens, contornos e retângulos sólidos.
local RadialGlow = {}

local function create(className: string, parent: Instance, props)
	local node = Instance.new(className)
	for key, value in pairs(props) do
		(node :: any)[key] = value
	end
	node.Parent = parent
	return node
end

function RadialGlow.new(parent: Instance, y: number, width: number)
	local group = create("CanvasGroup", parent, {
		Name = "BrilhoRadialSelecao",
		BackgroundTransparency = 1,
		GroupTransparency = 0.09,
		Position = UDim2.fromOffset(-27, y - 21),
		Size = UDim2.fromOffset(width, 92),
		ClipsDescendants = false,
		Visible = true,
		ZIndex = 2,
	})
	local core = nil
	-- 14 ovais translúcidos produzem queda gradual de luz do centro até
	-- as extremidades. Gradiente vertical elimina cortes nas bordas.
	for index = 1, 14 do
		local depth = (index - 1) / 13
		local w = 1 - depth * 0.60
		local h = 1 - depth * 0.64
		local layer = create("Frame", group, {
			Name = string.format("CamadaRadial_%02d", index),
			Position = UDim2.fromScale((1-w)/2, (1-h)/2),
			Size = UDim2.fromScale(w, h),
			BackgroundColor3 = Color3.fromRGB(
				math.floor(29 + depth * 66),
				math.floor(163 + depth * 70),
				math.floor(73 + depth * 76)
			),
			BackgroundTransparency = 0.936 - depth * 0.014,
			BorderSizePixel = 0,
			ZIndex = 2,
		})
		create("UICorner", layer, { CornerRadius = UDim.new(1, 0) })
		create("UIGradient", layer, {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.17, 0.51),
				NumberSequenceKeypoint.new(0.37, 0.10),
				NumberSequenceKeypoint.new(0.50, 0),
				NumberSequenceKeypoint.new(0.63, 0.10),
				NumberSequenceKeypoint.new(0.83, 0.51),
				NumberSequenceKeypoint.new(1, 1),
			}),
		})
		if index == 14 then core = layer end
	end

	local pulse = create("CanvasGroup", group, {
		Name = "PulsoSelecao",
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Position = UDim2.fromScale(0.29, 0.30),
		Size = UDim2.fromScale(0.42, 0.40),
		ClipsDescendants = false,
		ZIndex = 3,
	})
	for index = 1, 4 do
		local inset = (index - 1) * 0.08
		local beam = create("Frame", pulse, {
			Name = "PulsoRadial_" .. tostring(index),
			Position = UDim2.fromScale(inset, inset),
			Size = UDim2.fromScale(1 - inset * 2, 1 - inset * 2),
			BackgroundColor3 = Color3.fromRGB(129, 223, 135),
			BackgroundTransparency = 0.84,
			BorderSizePixel = 0,
			ZIndex = 3,
		})
		create("UICorner", beam, { CornerRadius = UDim.new(1, 0) })
		create("UIGradient", beam, {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.50, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		})
	end
	return group, pulse, core
end

return RadialGlow
