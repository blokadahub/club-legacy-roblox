--!strict
-- Transição cinematográfica do CL 27. Um ScreenGui próprio ocupa todo o
-- viewport, acima do HomeHUD e do SettingsHUD. Nunca depende do Canvas 16:9.
local TweenService = game:GetService("TweenService")

local TransitionFX = {}

local BASE = Color3.fromRGB(5, 13, 19)
local TEAL = Color3.fromRGB(13, 67, 65)
local GREEN = Color3.fromRGB(23, 126, 100)

local function make(className: string, parent: Instance, properties)
	local node = Instance.new(className)
	for key, value in pairs(properties) do
		(node :: any)[key] = value
	end
	node.Parent = parent
	return node
end

function TransitionFX.start(playerGui: Instance)
	local gui = make("ScreenGui", playerGui, {
		Name = "CL27_TransitionHUD",
		DisplayOrder = 150,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	local veil = make("CanvasGroup", gui, {
		Name = "Transicao",
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = BASE,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		ClipsDescendants = true,
		Visible = false,
		Active = true,
		ZIndex = 1,
	})
	make("UIGradient", veil, {
		Rotation = 17,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 13, 19)),
			ColorSequenceKeypoint.new(0.48, Color3.fromRGB(9, 32, 38)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 53, 51)),
		}),
	})

	-- A tela inteira fica coberta pelo fundo sólido. Os painéis em movimento
	-- são apenas textura cinematográfica, nunca retângulos que revelem a cena.
	local bands = {}
	for index = 1, 3 do
		local band = make("Frame", veil, {
			Name = "FaixaDeLuz_" .. tostring(index),
			Position = UDim2.fromScale(-0.52 - (index - 1) * 0.21, -0.4),
			Size = UDim2.fromScale(if index == 2 then 0.19 else 0.24, 1.8),
			Rotation = -21,
			BackgroundColor3 = if index == 2 then GREEN else TEAL,
			BackgroundTransparency = if index == 2 then 0.81 else 0.9,
			BorderSizePixel = 0,
			ZIndex = 2,
		})
		make("UIGradient", band, {
			Rotation = 0,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.26, 0.52),
				NumberSequenceKeypoint.new(0.5, 0.08),
				NumberSequenceKeypoint.new(0.74, 0.55),
				NumberSequenceKeypoint.new(1, 1),
			}),
		})
		bands[index] = band
	end

	local insignia = make("Frame", veil, {
		Name = "MarcaCentral",
		Size = UDim2.fromScale(0.30, 0.19),
		Position = UDim2.fromScale(0.35, 0.405),
		BackgroundTransparency = 1,
		ZIndex = 4,
	})
	make("TextLabel", insignia, {
		Name = "CL27",
		Text = "CL 27",
		TextColor3 = Color3.fromRGB(243, 252, 248),
		TextTransparency = 0.03,
		Font = Enum.Font.GothamBlack,
		TextSize = 43,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.68),
		ZIndex = 4,
	})
	make("TextLabel", insignia, {
		Name = "ClubLegacy",
		Text = "CLUB LEGACY",
		TextColor3 = Color3.fromRGB(144, 184, 175),
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, 0.62),
		Size = UDim2.fromScale(1, 0.22),
		ZIndex = 4,
	})
	local line = make("Frame", insignia, {
		Name = "LinhaEsmeralda",
		BackgroundColor3 = Color3.fromRGB(63, 203, 150),
		BackgroundTransparency = 0.17,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.36, 0.96),
		Size = UDim2.fromScale(0.28, 0.012),
		ZIndex = 4,
	})
	make("UICorner", line, {CornerRadius = UDim.new(1, 0)})

	local tweens: {Tween} = {}
	local alive = true
	local function cancel()
		for _, tween in ipairs(tweens) do tween:Cancel() end
		table.clear(tweens)
	end
	local function animate(object: Instance, goals, duration: number)
		local tween = TweenService:Create(
			object,
			TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			goals
		)
		table.insert(tweens, tween)
		tween:Play()
	end

	return {
		gui = gui,
		layer = veil,
		Cover = function(_, reducedMotion: boolean)
			if not alive then return 0 end
			cancel()
			veil.Visible = true
			veil.GroupTransparency = 1
			for index, band in ipairs(bands) do
				band.Position = UDim2.fromScale(-0.52 - (index - 1) * 0.21, -0.4)
			end
			local duration = if reducedMotion then 0.1 else 0.44
			animate(veil, {GroupTransparency = 0}, duration)
			if not reducedMotion then
				for index, band in ipairs(bands) do
					animate(band, {
						Position = UDim2.fromScale(0.20 + (index - 1) * 0.34, -0.4),
					}, duration * 1.9)
				end
			end
			return duration
		end,
		Reveal = function(_, reducedMotion: boolean)
			if not alive then return 0 end
			local duration = if reducedMotion then 0.14 else 0.56
			-- Não cancelar a animação das faixas: continuam se movendo por
			-- trás do desvanecimento e terminam com o wipe.
			animate(veil, {GroupTransparency = 1}, duration)
			return duration
		end,
		Finish = function()
			if not alive then return end
			cancel()
			veil.GroupTransparency = 1
			veil.Visible = false
		end,
		Destroy = function()
			if not alive then return end
			alive = false
			cancel()
			gui:Destroy()
		end,
	}
end

return TransitionFX
