-- Test double for screen construction/callbacks in the Luau CLI.
-- It does not emulate Roblox rendering, layout, fonts or ViewportFrame behavior.
local Harness = {}
local function dimension(scale, offset) return { Scale = scale, Offset = offset } end
local UDim = { new = dimension }
local UDim2 = {
	new = function(xs, xo, ys, yo) return { X = dimension(xs, xo), Y = dimension(ys, yo) } end,
	fromOffset = function(x, y) return { X = dimension(0, x), Y = dimension(0, y) } end,
	fromScale = function(x, y) return { X = dimension(x, 0), Y = dimension(y, 0) } end,
}
local Vector2 = { new = function(x, y) return { X = x, Y = y } end }
local Vector3 = { new = function(x, y, z) return { X = x, Y = y, Z = z } end }
local colorMeta = {}
colorMeta.__eq = function(a, b) return a.R == b.R and a.G == b.G and a.B == b.B end
local Color3 = {}
function Color3.new(r, g, b) return setmetatable({ R = r, G = g, B = b }, colorMeta) end
function Color3.fromRGB(r, g, b) return Color3.new(r / 255, g / 255, b / 255) end
local function enumCategory(name)
	return setmetatable({}, { __index = function(_, key) return name .. "." .. key end })
end
local Enum = setmetatable({}, { __index = function(_, category) return enumCategory(category) end })
local function sequence(...) return { ... } end
Harness.globals = {
	UDim = UDim, UDim2 = UDim2, Vector2 = Vector2, Vector3 = Vector3,
	Color3 = Color3, Enum = Enum,
	ColorSequence = { new = sequence }, NumberSequence = { new = sequence },
	ColorSequenceKeypoint = { new = sequence }, NumberSequenceKeypoint = { new = sequence },
}
local function signal()
	local object = { listeners = {} }
	function object:Connect(callback)
		table.insert(self.listeners, callback)
		return { Disconnect = function() end }
	end
	function object:Fire(...)
		for _, callback in ipairs(self.listeners) do callback(...) end
	end
	return object
end

function Harness.build(screen, data, options)
	options = options or {}
	local ctx = { objects = {}, data = data, width = options.compact and 350 or 960, compact = options.compact == true, refreshes = 0, appliedSettings = 0, appliedIdentity = 0, messages = {} }
	local defaults = {
		selectedPlayerId = "p11", squadFilter = "Todos", formation = "4-3-3", mentality = "Equilibrada", training = {},
		lineup = { "p01", "p02", "p03", "p04", "p05", "p06", "p07", "p08", "p09", "p10", "p11" },
		calendarMonth = 7, selectedFixtureId = "f01", competition = "Liga Aurora", financeTab = "Visão geral",
		transferQuery = "", transferFilter = "Todos", selectedMarketId = "m01", shortlist = {}, offers = {},
		settings = { reducedMotion = false, quality = "Alta", textScale = 1, menuVolume = 0.3 },
		identity = { primary = Color3.fromRGB(185,242,78), secondary = Color3.fromRGB(19,30,35), crest = "Escudo", kit = "Faixa" },
	}
	ctx.state = options.state or {}
	for key, value in pairs(defaults) do
		if ctx.state[key] == nil then ctx.state[key] = value end
	end
	for key, value in pairs(defaults.settings) do
		if ctx.state.settings[key] == nil then ctx.state.settings[key] = value end
	end
	ctx.events = { navigation = {} }
	local function new(class, props, parent)
		local object = { ClassName = class, Children = {}, signals = {}, attributes = {}, AbsoluteSize = Vector2.new(ctx.width, 500) }
		for name, value in pairs(props or {}) do object[name] = value end
		object.Parent = parent
		function object:SetAttribute(name, value) self.attributes[name] = value end
		function object:GetAttribute(name) return self.attributes[name] end
		function object:GetPropertyChangedSignal(name)
			self.signals[name] = self.signals[name] or signal()
			return self.signals[name]
		end
		function object:IsA(kind) return kind == self.ClassName or kind == "GuiObject" end
		function object:Destroy() self.destroyed = true end
		function object:GetChildren() return self.Children end
		for _, name in ipairs({ "FocusLost", "Activated", "InputBegan", "InputEnded", "MouseEnter", "MouseLeave" }) do object[name] = signal() end
		if parent then table.insert(parent.Children, object) end
		table.insert(ctx.objects, object)
		return object
	end
	local ui = { new = new }
	ui.theme = {
		bg = Color3.fromRGB(8,14,18), panel = Color3.fromRGB(18,28,32), panelAlt = Color3.fromRGB(26,38,42),
		line = Color3.fromRGB(49,63,66), text = Color3.fromRGB(235,242,240), muted = Color3.fromRGB(147,168,169),
		accent = Color3.fromRGB(185,242,78), gold = Color3.fromRGB(246,197,89), danger = Color3.fromRGB(255,121,103),
	}
	function ui.label(parent, text, size, color, height)
		return new("TextLabel", { Text = tostring(text), TextSize = size or 15, TextColor3 = color, Size = UDim2.new(1,0,0,height or 28) }, parent)
	end
	function ui.panel(parent, height, color) return new("Frame", { Size = UDim2.new(1,0,0,height or 180), BackgroundColor3 = color }, parent) end
	function ui.row(parent, height) return ui.panel(parent, height or 44) end
	function ui.round(parent, radius) return new("UICorner", { CornerRadius = radius }, parent) end
	function ui.stroke(parent, color, transparency) return new("UIStroke", { Color = color, Transparency = transparency }, parent) end
	function ui.pad(parent, n) return new("UIPadding", { Padding = n }, parent) end
	function ui.stack(parent, gap, horizontal) return new("UIListLayout", { Gap = gap, Horizontal = horizontal }, parent) end
	function ui.button(parent, text, callback, opts)
		opts = opts or {}
		local object = new("TextButton", { Text = text, callback = callback, Size = type(opts.width) == "table" and opts.width or UDim2.new(opts.width and 0 or 1,opts.width or 0,0,opts.height or 44) }, parent)
		object.Activated:Connect(callback)
		return object
	end
	function ui.chip(parent, text, color) return ui.label(parent, text, 11, color, 26) end
	function ui.bar(parent, text, value, maximum, color)
		assert(type(value) == "number" and value == value, "bar must receive a finite number")
		local object = ui.row(parent, 48)
		object.Bar = { text = text, value = value, maximum = maximum, color = color }
		return object
	end
	function ui.section(parent, eyebrow, title, subtitle)
		local object = ui.row(parent, 114)
		ui.label(object, eyebrow)
		ui.label(object, title)
		if subtitle then ui.label(object, subtitle) end
		return object
	end
	function ui.metric(parent, label, value, detail)
		local object = ui.panel(parent, 104)
		ui.label(object, label)
		ui.label(object, value)
		if detail then ui.label(object, detail) end
		return object
	end
	function ui.grid(parent) return new("Frame", {}, parent) end
	function ui.playerCard(parent, player, callback, selected)
		local card = ui.button(parent, player.name, callback, { selected = selected })
		card.playerId = player.id
		return card
	end
	ctx.ui = ui
	ctx.parent = new("ScrollingFrame", {})
	ctx.scope = {
		connect = function(_, event, callback) return event:Connect(callback) end,
		add = function(_, callback) return callback end,
		tween = function(_, object, properties) for key, value in pairs(properties) do object[key] = value end end,
	}
	ctx.refresh = function() ctx.refreshes += 1 end
	ctx.applySettings = function() ctx.appliedSettings += 1 end
	ctx.applyIdentity = function() ctx.appliedIdentity += 1 end
	ctx.audioStatus = function() return "Som nativo disponível" end
	ctx.testAudio = function() ctx.audioTests = (ctx.audioTests or 0) + 1 end
	ctx.navigate = function(destination)
		ctx.destination, ctx.lastNavigation = destination, destination
		table.insert(ctx.events.navigation, destination)
	end
	ctx.toast = function(message) table.insert(ctx.messages, message) end
	ctx.avatar = function(parent, player) assert(player.id, "avatar needs a player"); return new("ViewportFrame", { PlayerId = player.id }, parent) end
	function ctx:find(text, class)
		for _, object in ipairs(self.objects) do
			if object.Text == text and (not class or object.ClassName == class) then return object end
		end
		error("UI object not found: " .. text)
	end
	function ctx:click(text) self:find(text, "TextButton").Activated:Fire() end
	function ctx:buttons()
		local buttons = {}
		for _, object in ipairs(self.objects) do
			if object.ClassName == "TextButton" then table.insert(buttons, object) end
		end
		return buttons
	end
	function ctx:player(id)
		for _, object in ipairs(self.objects) do
			if object.playerId == id then return object end
		end
		error("player card not found: " .. id)
	end
	function ctx:input(text, submit)
		for _, object in ipairs(self.objects) do
			if object.ClassName == "TextBox" then
				object.Text = text
				object:GetPropertyChangedSignal("Text"):Fire()
				object.FocusLost:Fire(submit == true)
				return
			end
		end
		error("screen has no text input")
	end
	screen(ctx)
	return ctx
end

return Harness
