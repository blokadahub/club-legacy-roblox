--!strict
local actionGreen = Color3.fromRGB(92, 255, 51)
return table.freeze({
	background = Color3.fromRGB(6, 15, 27),
	panel = Color3.fromRGB(18, 35, 52),
	panelLight = Color3.fromRGB(31, 54, 71),
	white = Color3.fromRGB(241, 248, 249),
	muted = Color3.fromRGB(145, 169, 184),
	accent = Color3.fromRGB(54, 242, 201),
	actionGreen = actionGreen, -- #5cff33
	actionHover = Color3.fromRGB(127, 255, 92),
	blue = Color3.fromRGB(22, 53, 112),
	gold = Color3.fromRGB(233, 207, 136),
	durations = { micro = 0.14, panel = 0.26, transition = 0.48, camera = 0.8 },
	canvas = Vector2.new(1600, 900),
	-- Editorial surfaces shared by tactics, match lobby and management pages.
	-- Existing menu/intro tokens remain stable.
	sports = table.freeze({
		ink = Color3.fromRGB(10, 13, 14), panel = Color3.fromRGB(23, 28, 29),
		white = Color3.fromRGB(241, 244, 239), muted = Color3.fromRGB(184, 195, 196),
		green = actionGreen, border = Color3.fromRGB(64, 72, 73),
		warning = Color3.fromRGB(224, 197, 139),
	}),
})
