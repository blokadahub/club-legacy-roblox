--[[
	CL - Club Legacy 0.1
	Caminho: src/client/Main.client.luau
	Tipo: LocalScript (StarterPlayerScripts)
	Interface 2D criada inteiramente por código. Apenas exibe dados e envia
	pedidos ao servidor; nenhuma regra de jogo é decidida aqui.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function loadConfig()
	local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 15)
	local module = sharedFolder and sharedFolder:FindFirstChild("Config")
	if not module then
		module = ReplicatedStorage:FindFirstChild("Config", true)
	end
	assert(module and module:IsA("ModuleScript"), "[CL] ModuleScript Config não encontrado")
	return require(module)
end

local Config = loadConfig()
local money = Config.formatMoney

local remoteFolder = ReplicatedStorage:WaitForChild(Config.REMOTE_FOLDER)
local requestFn = remoteFolder:WaitForChild(Config.REQUEST_FUNCTION)

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

---------------------------------------------------------------------
-- TEMA
---------------------------------------------------------------------
local C = {
	panel = Color3.fromRGB(19, 23, 36),
	panel2 = Color3.fromRGB(28, 34, 52),
	panel3 = Color3.fromRGB(40, 48, 72),
	accent = Color3.fromRGB(0, 214, 128),
	accentDark = Color3.fromRGB(0, 120, 75),
	blue = Color3.fromRGB(70, 150, 255),
	text = Color3.fromRGB(236, 239, 246),
	muted = Color3.fromRGB(140, 149, 172),
	danger = Color3.fromRGB(232, 72, 85),
	warn = Color3.fromRGB(255, 186, 60),
	disabled = Color3.fromRGB(45, 50, 64),
	gold = Color3.fromRGB(255, 205, 80),
	dark = Color3.fromRGB(9, 11, 19),
}
local POS_COLORS = { GOL = C.warn, ZAG = C.blue, LAT = C.blue, VOL = C.accent, MEI = C.accent, PON = C.danger, ATA = C.danger }
local FONT_M, FONT_B = Enum.Font.GothamMedium, Enum.Font.GothamBold
local DESIGN_W, DESIGN_H = 820, 410

---------------------------------------------------------------------
-- ESTADO LOCAL
---------------------------------------------------------------------
local state = nil
local currentScreen = "loading"
local pending = false
local scrollMemory = {}
local marketFilter = "Todos"
local newCareerChoice = 1
local customNameText = ""
local SCREENS = {}
local render, navigate, call, showReport

---------------------------------------------------------------------
-- HELPERS DE UI
---------------------------------------------------------------------
local orderCounter = 0
local function new(className, props, children)
	local inst = Instance.new(className)
	local parent = nil
	if inst:IsA("GuiObject") then
		inst.BorderSizePixel = 0
	end
	if props then
		for k, v in pairs(props) do
			if k == "Parent" then
				parent = v
			else
				inst[k] = v
			end
		end
	end
	if inst:IsA("GuiObject") and not (props and props.LayoutOrder) then
		orderCounter += 1
		inst.LayoutOrder = orderCounter
	end
	if children then
		for _, c in ipairs(children) do
			c.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function corner(r)
	return new("UICorner", { CornerRadius = UDim.new(0, r or 8) })
end

local function padding(px)
	return new("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
	})
end

local function label(parent, text, opts)
	opts = opts or {}
	return new("TextLabel", {
		Parent = parent,
		BackgroundTransparency = 1,
		Text = text,
		Font = opts.font or FONT_M,
		TextSize = opts.size or 15,
		TextColor3 = opts.color or C.text,
		TextXAlignment = opts.align or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = opts.wrap ~= false,
		TextTruncate = opts.truncate and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None,
		Size = opts.dim or UDim2.new(1, 0, 0, 0),
		AutomaticSize = opts.dim and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
		Position = opts.pos,
	})
end

local function button(parent, text, opts)
	opts = opts or {}
	local disabled = opts.disabled == true
	local b = new("TextButton", {
		Parent = parent,
		Text = text,
		Font = FONT_B,
		TextSize = opts.size or 15,
		TextColor3 = disabled and C.muted or (opts.textColor or C.text),
		BackgroundColor3 = disabled and C.disabled or (opts.color or C.panel3),
		AutoButtonColor = not disabled,
		Active = not disabled,
		Size = opts.dim or UDim2.new(1, 0, 0, 40),
		Position = opts.pos,
		TextWrapped = true,
	}, { corner(8) })
	if not disabled and opts.onClick then
		b.Activated:Connect(function()
			opts.onClick()
		end)
	end
	return b
end

local function card(parent, title, opts)
	opts = opts or {}
	local f = new("Frame", {
		Parent = parent,
		BackgroundColor3 = opts.color or C.panel,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, {
		corner(10),
		new("UIStroke", { Color = C.panel3, Thickness = 1, Transparency = 0.3 }),
		padding(10),
		new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	if title then
		label(f, title, { font = FONT_B, size = 17, color = opts.titleColor or C.accent })
	end
	return f
end

local function row(parent, height, bg)
	return new("Frame", {
		Parent = parent,
		Size = UDim2.new(1, 0, 0, height or 36),
		BackgroundColor3 = bg or C.panel2,
	}, {
		corner(6),
		new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 6) }),
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

local function hstack(parent, height)
	return new("Frame", {
		Parent = parent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height),
	}, {
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

local function cell(r, text, w, opts)
	opts = opts or {}
	return label(r, text, {
		dim = UDim2.new(w, 0, 1, 0),
		size = opts.size or 13,
		color = opts.color,
		font = opts.font,
		align = opts.align,
		wrap = false,
		truncate = true,
	})
end

local function twoLine(r, top, bottom, w, topColor)
	local box = new("Frame", { Parent = r, BackgroundTransparency = 1, Size = UDim2.new(w, 0, 1, 0) })
	label(box, top, { dim = UDim2.new(1, -4, 0, 20), pos = UDim2.new(0, 0, 0, 3), font = FONT_B, size = 13, color = topColor, wrap = false, truncate = true })
	label(box, bottom, { dim = UDim2.new(1, -4, 0, 16), pos = UDim2.new(0, 0, 0, 23), size = 11, color = C.muted, wrap = false, truncate = true })
	return box
end

local function posTag(parent, pos, w)
	local holder = new("Frame", { Parent = parent, BackgroundTransparency = 1, Size = UDim2.new(w, 0, 1, 0) })
	new("TextLabel", {
		Parent = holder,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 40, 0, 22),
		BackgroundColor3 = POS_COLORS[pos] or C.muted,
		Text = pos,
		Font = FONT_B,
		TextSize = 12,
		TextColor3 = C.dark,
	}, { corner(5) })
	return holder
end

local function kv(parent, k, v, color)
	local r = row(parent, 30, C.panel2)
	cell(r, k, 0.6, { size = 13, color = C.muted })
	cell(r, v, 0.4, { size = 14, font = FONT_B, color = color, align = Enum.TextXAlignment.Right })
	return r
end

local function fitColor(f)
	if f >= 80 then
		return C.accent
	elseif f >= 65 then
		return C.warn
	end
	return C.danger
end

local function colorOf(arr)
	if type(arr) == "table" then
		return Color3.fromRGB(arr[1] or 200, arr[2] or 200, arr[3] or 200)
	end
	return C.muted
end

---------------------------------------------------------------------
-- ESTRUTURA PRINCIPAL
---------------------------------------------------------------------
local bgGui = new("ScreenGui", { Name = "CL_Background", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1, Parent = playerGui })
new("Frame", { Parent = bgGui, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1) }, {
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(16, 22, 40), Color3.fromRGB(6, 8, 14)) }),
})

local gui = new("ScreenGui", {
	Name = "CL_Main",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	DisplayOrder = 2,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})
local root = new("Frame", { Name = "Root", Parent = gui, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) })
local uiScale = new("UIScale", { Parent = root })

local function updateScale()
	local abs = gui.AbsoluteSize
	if abs.X <= 0 or abs.Y <= 0 then
		return
	end
	local s = math.clamp(math.min(abs.X / DESIGN_W, abs.Y / DESIGN_H), 0.6, 1.6)
	uiScale.Scale = s
	root.Size = UDim2.fromScale(1 / s, 1 / s)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale)
updateScale()

-- Barra superior
local topBar = new("Frame", { Parent = root, Size = UDim2.new(1, -16, 0, 46), Position = UDim2.new(0, 8, 0, 4), BackgroundColor3 = C.panel }, { corner(10) })
new("TextLabel", {
	Parent = topBar,
	Size = UDim2.new(0, 36, 0, 36),
	Position = UDim2.new(0, 6, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	BackgroundColor3 = C.accent,
	Text = "CL",
	Font = FONT_B,
	TextSize = 18,
	TextColor3 = C.dark,
}, { corner(8) })
label(topBar, "CLUB LEGACY", { dim = UDim2.new(0, 150, 0, 20), pos = UDim2.new(0, 50, 0, 4), font = FONT_B, size = 15, wrap = false })
label(topBar, "Versão " .. Config.VERSION, { dim = UDim2.new(0, 150, 0, 16), pos = UDim2.new(0, 50, 0, 24), size = 11, color = C.muted, wrap = false })
local clubLbl = label(topBar, "", { dim = UDim2.new(0.42, 0, 0, 20), pos = UDim2.new(0.29, 0, 0, 4), font = FONT_B, size = 15, align = Enum.TextXAlignment.Center, wrap = false, truncate = true })
local infoLbl = label(topBar, "", { dim = UDim2.new(0.42, 0, 0, 16), pos = UDim2.new(0.29, 0, 0, 25), size = 12, color = C.muted, align = Enum.TextXAlignment.Center, wrap = false, truncate = true })
local budgetLbl = label(topBar, "", { dim = UDim2.new(0.28, -10, 0, 20), pos = UDim2.new(0.72, 0, 0, 4), font = FONT_B, size = 15, color = C.accent, align = Enum.TextXAlignment.Right, wrap = false })
local statusLbl = label(topBar, "", { dim = UDim2.new(0.28, -10, 0, 16), pos = UDim2.new(0.72, 0, 0, 25), size = 11, color = C.muted, align = Enum.TextXAlignment.Right, wrap = false, truncate = true })

-- Navegação lateral
local nav = new("ScrollingFrame", {
	Parent = root,
	Position = UDim2.new(0, 8, 0, 56),
	Size = UDim2.new(0, 148, 1, -62),
	BackgroundColor3 = C.panel,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 3,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	Visible = false,
}, {
	corner(10),
	padding(6),
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local NAV_ITEMS = {
	{ "hub", "Central" },
	{ "squad", "Elenco" },
	{ "lineup", "Escalação" },
	{ "tactics", "Táticas" },
	{ "calendar", "Calendário" },
	{ "standings", "Classificação" },
	{ "market", "Mercado" },
	{ "finances", "Finanças" },
	{ "menu", "Menu inicial" },
}
local navButtons = {}
for _, item in ipairs(NAV_ITEMS) do
	local key = item[1]
	navButtons[key] = button(nav, item[2], {
		dim = UDim2.new(1, 0, 0, 34),
		size = 14,
		onClick = function()
			navigate(key)
		end,
	})
end

local content = new("Frame", { Parent = root, BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 56), Size = UDim2.new(1, -16, 1, -62) })

local modal = new("TextButton", {
	Parent = root,
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.35,
	Text = "",
	AutoButtonColor = false,
	Visible = false,
	ZIndex = 50,
})

local toastLbl = new("TextLabel", {
	Parent = root,
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -12),
	Size = UDim2.new(0.6, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = C.panel3,
	TextColor3 = C.text,
	Font = FONT_B,
	TextSize = 14,
	TextWrapped = true,
	Text = "",
	Visible = false,
	ZIndex = 60,
}, { corner(8), padding(10) })

local toastToken = 0
local function toast(msg, color)
	toastToken += 1
	local my = toastToken
	toastLbl.Text = msg
	toastLbl.TextColor3 = color or C.text
	toastLbl.Visible = true
	task.delay(3.2, function()
		if toastToken == my then
			toastLbl.Visible = false
		end
	end)
end

local function updateChrome()
	local career = state and state.career
	local inGame = career ~= nil and currentScreen ~= "menu" and currentScreen ~= "newCareer" and currentScreen ~= "loading"
	nav.Visible = inGame
	if inGame then
		content.Position = UDim2.new(0, 164, 0, 56)
		content.Size = UDim2.new(1, -172, 1, -62)
	else
		content.Position = UDim2.new(0, 8, 0, 56)
		content.Size = UDim2.new(1, -16, 1, -62)
	end
	if career then
		clubLbl.Text = career.club.name
		infoLbl.Text = string.format("Temporada %d  •  Rodada %d/%d%s", career.season, career.round, career.totalRounds, career.seasonOver and " (encerrada)" or "")
		budgetLbl.Text = money(career.club.budget)
	else
		clubLbl.Text = "Simulador de carreira de treinador"
		infoLbl.Text = ""
		budgetLbl.Text = ""
	end
	local status = ""
	if pending then
		status = "Processando..."
	elseif state and state.saveBlocked then
		status = "Salvamento desativado"
	elseif state and state.unsaved then
		status = "Alterações ainda não salvas"
	elseif state and state.hasCareer then
		status = "Progresso salvo"
	end
	statusLbl.Text = status
	for key, b in pairs(navButtons) do
		b.BackgroundColor3 = (key == currentScreen) and C.accentDark or C.panel2
	end
end

---------------------------------------------------------------------
-- COMUNICAÇÃO COM O SERVIDOR
---------------------------------------------------------------------
call = function(action, payload, onDone)
	if pending then
		toast("Aguarde a ação anterior terminar...", C.warn)
		return
	end
	pending = true
	updateChrome()
	task.spawn(function()
		local ok, res = pcall(function()
			return requestFn:InvokeServer(action, payload or {})
		end)
		pending = false
		if not ok or type(res) ~= "table" then
			toast("Falha de comunicação com o servidor. Tente novamente.", C.danger)
			updateChrome()
			return
		end
		if type(res.state) == "table" then
			state = res.state
		end
		if type(res.msg) == "string" and res.msg ~= "" then
			toast(res.msg, res.ok and C.accent or C.danger)
		end
		if onDone then
			onDone(res)
		end
		render()
	end)
end

---------------------------------------------------------------------
-- MODAIS
---------------------------------------------------------------------
local function closeModal()
	for _, ch in ipairs(modal:GetChildren()) do
		ch:Destroy()
	end
	modal.Visible = false
end

local function openModal(title)
	closeModal()
	modal.Visible = true
	local panel = new("Frame", {
		Parent = modal,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.88, 0, 0.92, 0),
		BackgroundColor3 = C.panel,
	}, {
		corner(12),
		new("UIStroke", { Color = C.accent, Transparency = 0.4 }),
		new("UISizeConstraint", { MaxSize = Vector2.new(660, 560) }),
	})
	label(panel, title, { dim = UDim2.new(1, -20, 0, 30), pos = UDim2.new(0, 10, 0, 6), font = FONT_B, size = 17, color = C.accent, wrap = false, truncate = true })
	local body = new("ScrollingFrame", {
		Parent = panel,
		Position = UDim2.new(0, 10, 0, 40),
		Size = UDim2.new(1, -20, 1, -96),
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 5,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, {
		new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
		new("UIPadding", { PaddingRight = UDim.new(0, 8) }),
	})
	local footer = new("Frame", { Parent = panel, Position = UDim2.new(0, 10, 1, -50), Size = UDim2.new(1, -20, 0, 42), BackgroundTransparency = 1 }, {
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	return body, footer
end

local function confirmModal(title, msg, yesText, onYes)
	local body, footer = openModal(title)
	label(body, msg, { size = 14 })
	button(footer, "Cancelar", { dim = UDim2.new(0, 140, 1, 0), onClick = closeModal })
	button(footer, yesText, {
		dim = UDim2.new(0, 170, 1, 0),
		color = C.accentDark,
		onClick = function()
			closeModal()
			onYes()
		end,
	})
end

showReport = function()
	local career = state and state.career
	local r = career and career.lastReport
	if not r then
		return
	end
	local body, footer = openModal("Rodada " .. r.round .. " — Relatório da partida")
	local score = new("Frame", { Parent = body, Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = C.panel2 }, { corner(8) })
	label(score, r.homeName, { dim = UDim2.new(0.38, -8, 1, 0), pos = UDim2.new(0, 8, 0, 0), font = FONT_B, size = 15, align = Enum.TextXAlignment.Right })
	label(score, r.hg .. "  x  " .. r.ag, { dim = UDim2.new(0.22, 0, 1, 0), pos = UDim2.new(0.39, 0, 0, 0), font = FONT_B, size = 26, color = C.accent, align = Enum.TextXAlignment.Center })
	label(score, r.awayName, { dim = UDim2.new(0.38, -8, 1, 0), pos = UDim2.new(0.62, 0, 0, 0), font = FONT_B, size = 15 })

	local userGoals = r.userIsHome and r.hg or r.ag
	local oppGoals = r.userIsHome and r.ag or r.hg
	local verdict, vColor = "Empate", C.warn
	if userGoals > oppGoals then
		verdict, vColor = "Vitória!", C.accent
	elseif userGoals < oppGoals then
		verdict, vColor = "Derrota", C.danger
	end
	label(body, verdict, { font = FONT_B, size = 18, color = vColor, align = Enum.TextXAlignment.Center })
	label(body, string.format("Chances esperadas (xG simplificado): %.1f x %.1f", r.xgH, r.xgA), { size = 12, color = C.muted, align = Enum.TextXAlignment.Center })

	label(body, "Lances da partida", { font = FONT_B, size = 15, color = C.accent })
	if #r.events == 0 then
		label(body, "Partida sem gols nem cartões.", { size = 13, color = C.muted })
	end
	for _, e in ipairs(r.events) do
		local side = e.side == "home" and r.homeShort or r.awayShort
		local ev = row(body, 28, C.panel2)
		cell(ev, e.min .. "'", 0.1, { font = FONT_B })
		cell(ev, e.text, 0.72, { color = e.kind == "goal" and C.accent or C.warn })
		cell(ev, side, 0.16, { color = C.muted, align = Enum.TextXAlignment.Right })
	end
	label(body, "90'  Fim de jogo", { size = 13, color = C.muted })

	if r.others and #r.others > 0 then
		label(body, "Outros resultados da rodada", { font = FONT_B, size = 15, color = C.accent })
		for _, o in ipairs(r.others) do
			local orow = row(body, 28, C.panel2)
			cell(orow, o.homeName, 0.42, { align = Enum.TextXAlignment.Right })
			cell(orow, o.hg .. " x " .. o.ag, 0.16, { font = FONT_B, align = Enum.TextXAlignment.Center })
			cell(orow, o.awayName, 0.42)
		end
	end
	button(footer, "Classificação", {
		dim = UDim2.new(0, 150, 1, 0),
		onClick = function()
			closeModal()
			navigate("standings")
		end,
	})
	button(footer, "Fechar", { dim = UDim2.new(0, 130, 1, 0), color = C.accentDark, onClick = closeModal })
end

local function openSwapModal(slotInfo)
	local career = state.career
	local current = slotInfo.playerId
	local body, footer = openModal(string.format("Posição %s (titular %d): quem entra?", slotInfo.pos, slotInfo.slot))
	label(body, slotInfo.pos == "GOL" and "Somente goleiros podem ocupar esta posição." or "Jogadores da mesma posição aparecem primeiro. Fora de posição o rendimento cai.", { size = 12, color = C.muted })
	local list = {}
	for _, p in ipairs(career.squad) do
		local allowed = p.id ~= current
		if slotInfo.pos == "GOL" and p.pos ~= "GOL" then
			allowed = false
		end
		if slotInfo.slot ~= 1 and p.starterSlot == 1 then
			allowed = false
		end
		if allowed then
			table.insert(list, p)
		end
	end
	table.sort(list, function(a, b)
		local ea, eb = a.pos == slotInfo.pos, b.pos == slotInfo.pos
		if ea ~= eb then
			return ea
		end
		if a.ovr ~= b.ovr then
			return a.ovr > b.ovr
		end
		return a.id < b.id
	end)
	for _, p in ipairs(list) do
		local r = row(body, 40, C.panel2)
		posTag(r, p.pos, 0.1)
		cell(r, p.name, 0.32, { font = FONT_B })
		cell(r, "OVR " .. p.ovr, 0.12)
		cell(r, p.fit .. "%", 0.1, { color = fitColor(p.fit) })
		cell(r, p.starterSlot and ("Titular " .. p.starterSlot) or "Reserva", 0.14, { color = C.muted })
		button(r, p.starterSlot and "Trocar" or "Escalar", {
			dim = UDim2.new(0.2, -6, 0, 30),
			size = 13,
			color = C.accentDark,
			onClick = function()
				closeModal()
				call("swapLineup", { slot = slotInfo.slot, playerId = p.id })
			end,
		})
	end
	if #list == 0 then
		label(body, "Nenhum jogador disponível para esta posição.", { color = C.warn })
	end
	button(footer, "Cancelar", { dim = UDim2.new(0, 140, 1, 0), onClick = closeModal })
end

---------------------------------------------------------------------
-- TELAS
---------------------------------------------------------------------
SCREENS.menu = function(page)
	local hero = card(page, nil)
	label(hero, "CL - CLUB LEGACY", { font = FONT_B, size = 30 })
	label(hero, "Versão " .. Config.VERSION .. "  •  Simulador de carreira de treinador", { size = 14, color = C.muted })
	label(hero, "Assuma um clube, monte o elenco, defina a tática, negocie atletas e dispute a liga temporada após temporada.", { size = 14 })
	if state.saveBlocked then
		local w = card(page, "Aviso de salvamento", { titleColor = C.warn })
		label(w, state.saveMsg or "", { size = 13 })
	end
	local actions = card(page, "Começar")
	if state.career then
		local c = state.career
		label(actions, string.format("Carreira atual: %s — Temporada %d, rodada %d/%d", c.club.name, c.season, c.round, c.totalRounds), { size = 14, color = C.muted })
		button(actions, "Continuar carreira", {
			color = C.accentDark,
			onClick = function()
				navigate("hub")
			end,
		})
	else
		button(actions, "Continuar carreira (nenhuma carreira salva)", { disabled = true })
	end
	button(actions, "Nova carreira", {
		onClick = function()
			navigate("newCareer")
		end,
	})
end

SCREENS.newCareer = function(page)
	local top = card(page, "Nova carreira")
	label(top, "Escolha o clube que você vai comandar. Clubes de nível alto têm elencos fortes; clubes menores são um desafio maior.", { size = 13, color = C.muted })
	if state.career then
		label(top, "Atenção: iniciar uma nova carreira substituirá a carreira atual.", { size = 13, color = C.warn })
	end
	local list = card(page, "Clubes")
	for _, t in ipairs(state.clubTemplates or {}) do
		local selected = newCareerChoice == t.index
		local r = row(list, 46, selected and C.accentDark or C.panel2)
		new("Frame", { Parent = r, Size = UDim2.new(0, 12, 0, 30), BackgroundColor3 = colorOf(t.color) }, { corner(4) })
		new("Frame", { Parent = r, Size = UDim2.new(0, 10, 0, 1), BackgroundTransparency = 1 })
		cell(r, t.name, 0.4, { font = FONT_B, size = 14 })
		cell(r, "Nível " .. t.level, 0.15)
		cell(r, "Verba " .. money(t.budget), 0.2)
		button(r, selected and "Selecionado" or "Escolher", {
			dim = UDim2.new(0.18, 0, 0, 32),
			size = 13,
			color = selected and C.accent or C.panel3,
			textColor = selected and C.dark or C.text,
			onClick = function()
				newCareerChoice = t.index
				render()
			end,
		})
	end

	local nameCard = card(page, "Nome do clube (opcional)")
	label(nameCard, "Deixe em branco para manter o nome original. De 3 a 24 caracteres; o nome passa pelo filtro de texto do Roblox.", { size = 12, color = C.muted })
	local tb = new("TextBox", {
		Parent = nameCard,
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = C.panel2,
		Text = customNameText,
		PlaceholderText = "Ex.: Clube Legado",
		PlaceholderColor3 = C.muted,
		TextColor3 = C.text,
		Font = FONT_M,
		TextSize = 15,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, { corner(8), new("UIPadding", { PaddingLeft = UDim.new(0, 10) }) })
	tb:GetPropertyChangedSignal("Text"):Connect(function()
		customNameText = tb.Text
	end)

	local go = card(page, nil)
	button(go, "Iniciar carreira", {
		color = C.accentDark,
		dim = UDim2.new(1, 0, 0, 44),
		onClick = function()
			local function start()
				call("newCareer", { clubIndex = newCareerChoice, customName = customNameText, confirm = true }, function(res)
					if res.ok then
						currentScreen = "hub"
						scrollMemory.hub = 0
					end
				end)
			end
			if state.career then
				confirmModal("Substituir carreira?", "A carreira atual será substituída pela nova assim que ela for salva. Esta ação não pode ser desfeita.", "Substituir", start)
			else
				start()
			end
		end,
	})
	button(go, "Voltar", {
		onClick = function()
			navigate("menu")
		end,
	})
end

SCREENS.hub = function(page)
	local c = state.career
	label(page, "Treinador: " .. (c.managerName or player.DisplayName), { size = 13, color = C.muted })
	if c.seasonOver and c.seasonSummary then
		local s = c.seasonSummary
		local sc = card(page, "Temporada " .. s.season .. " encerrada", { titleColor = C.gold })
		label(sc, "Campeão: " .. s.champion, { font = FONT_B, size = 18 })
		label(sc, string.format("Seu clube terminou em %dº lugar com %d pontos.", s.userPos, s.userPts), { size = 14 })
		label(sc, "Premiação + cotas de TV recebidas: " .. money(s.prize), { size = 14, color = C.accent })
		label(sc, "Na nova temporada os jogadores envelhecem 1 ano, atletas com 37+ anos se aposentam, cada clube recebe um jovem da base, o mercado é renovado e a tabela é zerada. Elenco, finanças e histórico são mantidos.", { size = 12, color = C.muted })
		button(sc, "Iniciar temporada " .. (s.season + 1), {
			color = C.accentDark,
			dim = UDim2.new(1, 0, 0, 46),
			onClick = function()
				call("newSeason", {})
			end,
		})
	elseif c.nextMatch then
		local m = c.nextMatch
		local mc = card(page, string.format("Próxima partida — Rodada %d/%d", m.round, c.totalRounds))
		label(mc, m.homeName .. "  x  " .. m.awayName, { font = FONT_B, size = 20, align = Enum.TextXAlignment.Center })
		label(mc, m.isHome and "Você joga em casa (vantagem de mando e bilheteria)" or "Você joga fora de casa", { size = 13, color = C.muted, align = Enum.TextXAlignment.Center })
		local r1 = row(mc, 30, C.panel2)
		cell(r1, "Seu time", 0.22, { font = FONT_B })
		cell(r1, string.format("ATQ %.1f  •  DEF %.1f", c.strength.att, c.strength.def), 0.36)
		cell(r1, c.lineup.formation .. " / " .. c.lineup.strategy, 0.42, { color = C.muted })
		local r2 = row(mc, 30, C.panel2)
		cell(r2, m.oppShort .. " (rival)", 0.22, { font = FONT_B })
		cell(r2, string.format("ATQ %.1f  •  DEF %.1f", m.oppAtt, m.oppDef), 0.36)
		cell(r2, string.format("%s / %s  •  média %.1f", m.oppFormation, m.oppStrategy, m.oppAvg), 0.42, { color = C.muted })
		if c.tiredStarters > 0 then
			label(mc, string.format("%d titular(es) com condição física abaixo de 70%%. Considere trocá-los na Escalação.", c.tiredStarters), { size = 13, color = C.warn })
		end
		button(mc, "Simular rodada " .. m.round, {
			color = C.accentDark,
			dim = UDim2.new(1, 0, 0, 46),
			size = 17,
			onClick = function()
				call("playRound", { expectedRound = m.round }, function(res)
					if res.ok then
						showReport()
					end
				end)
			end,
		})
	end

	local st = card(page, "Situação do clube")
	kv(st, "Posição na liga", c.userPos .. "º  (" .. c.userPts .. " pts)", C.accent)
	kv(st, "Orçamento", money(c.club.budget), C.accent)
	kv(st, "Elenco", string.format("%d jogadores (mín. %d, máx. %d)", c.squadCount, c.squadMin, c.squadMax))
	kv(st, "Folha salarial por rodada", money(c.finance.wages), C.danger)

	if c.lastReport then
		local r = c.lastReport
		local lc = card(page, "Último jogo — Rodada " .. r.round)
		label(lc, string.format("%s %d x %d %s", r.homeName, r.hg, r.ag, r.awayName), { font = FONT_B, size = 16 })
		button(lc, "Ver relatório da partida", { onClick = showReport })
	end
end

SCREENS.squad = function(page)
	local c = state.career
	local info = card(page, "Elenco — " .. c.club.name)
	label(info, string.format("%d jogadores  •  mínimo %d  •  máximo %d. Vendas rendem %d%% do valor de mercado.", c.squadCount, c.squadMin, c.squadMax, 85), { size = 12, color = C.muted })
	local list = card(page, nil)
	local h = row(list, 26, C.panel)
	local W = { 0.08, 0.28, 0.08, 0.06, 0.08, 0.16, 0.09, 0.15 }
	local heads = { "POS", "JOGADOR", "OVR", "POT", "FÍS", "VALOR / SAL.", "STATUS", "" }
	for i, t in ipairs(heads) do
		cell(h, t, W[i], { size = 11, color = C.muted, font = FONT_B })
	end
	local canSell = c.squadCount > c.squadMin
	for _, p in ipairs(c.squad) do
		local r = row(list, 44, p.starterSlot and C.panel2 or C.panel)
		posTag(r, p.pos, W[1])
		twoLine(r, p.name, string.format("%d anos • %d jogos • %d gols", p.age, p.apps, p.goals), W[2])
		local deltaTxt = ""
		local deltaColor = C.text
		if p.delta > 0 then
			deltaTxt, deltaColor = " +" .. p.delta, C.accent
		elseif p.delta < 0 then
			deltaTxt, deltaColor = " " .. p.delta, C.danger
		end
		cell(r, p.ovr .. deltaTxt, W[3], { font = FONT_B, color = deltaColor })
		cell(r, tostring(p.pot), W[4])
		cell(r, p.fit .. "%", W[5], { color = fitColor(p.fit) })
		twoLine(r, money(p.value), money(p.wage) .. "/rod.", W[6])
		cell(r, p.starterSlot and "Titular" or "Reserva", W[7], { color = p.starterSlot and C.accent or C.muted, size = 12 })
		button(r, canSell and ("Vender " .. money(p.sellPrice)) or "Mínimo", {
			dim = UDim2.new(W[8], -4, 0, 32),
			size = 11,
			disabled = not canSell,
			onClick = function()
				confirmModal("Vender jogador?", string.format("Vender %s (%s, OVR %d) por %s? O jogador vai para o mercado.", p.name, p.pos, p.ovr, money(p.sellPrice)), "Vender", function()
					call("sellPlayer", { playerId = p.id })
				end)
			end,
		})
	end
end

SCREENS.lineup = function(page)
	local c = state.career
	local map = {}
	for _, p in ipairs(c.squad) do
		map[p.id] = p
	end
	local top = card(page, "Escalação — " .. c.lineup.formation .. " / " .. c.lineup.strategy)
	label(top, "Toque em \"Trocar\" ao lado de uma posição para escolher quem entra. A posição GOL exige um goleiro.", { size = 12, color = C.muted })
	label(top, string.format("Força atual: ATQ %.1f  •  DEF %.1f", c.strength.att, c.strength.def), { size = 14, font = FONT_B })
	local bar = hstack(top, 40)
	button(bar, "Escalação automática", {
		dim = UDim2.new(0.5, -3, 1, 0),
		color = C.accentDark,
		onClick = function()
			call("autoLineup", {})
		end,
	})
	button(bar, "Alterar táticas", {
		dim = UDim2.new(0.5, -3, 1, 0),
		onClick = function()
			navigate("tactics")
		end,
	})

	local list = card(page, "Titulares")
	for _, s in ipairs(c.lineup.slots) do
		local p = s.playerId and map[s.playerId]
		local r = row(list, 42, C.panel2)
		posTag(r, s.pos, 0.09)
		if p then
			cell(r, p.name, 0.3, { font = FONT_B })
			cell(r, "(" .. p.pos .. ")", 0.08, { color = C.muted })
			cell(r, "OVR " .. p.ovr, 0.11)
			cell(r, p.fit .. "%", 0.08, { color = fitColor(p.fit) })
			local inPos = s.factor >= 1
			cell(r, inPos and "Na posição" or string.format("Fora de posição (%d%%)", math.floor(s.factor * 100 + 0.5)), 0.18, { size = 11, color = inPos and C.accent or C.warn })
		else
			cell(r, "Vazio", 0.75, { color = C.danger })
		end
		button(r, "Trocar", {
			dim = UDim2.new(0.14, -4, 0, 30),
			size = 13,
			onClick = function()
				openSwapModal(s)
			end,
		})
	end

	local res = card(page, "Reservas")
	local any = false
	for _, p in ipairs(c.squad) do
		if not p.starterSlot then
			any = true
			local r = row(res, 34, C.panel)
			posTag(r, p.pos, 0.1)
			cell(r, p.name, 0.45)
			cell(r, "OVR " .. p.ovr, 0.2)
			cell(r, p.fit .. "%", 0.2, { color = fitColor(p.fit) })
		end
	end
	if not any then
		label(res, "Sem reservas.", { color = C.muted, size = 13 })
	end
end

SCREENS.tactics = function(page)
	local c = state.career
	local fc = card(page, "Formação")
	for _, f in ipairs(state.formations) do
		local active = c.lineup.formation == f.name
		local r = new("Frame", { Parent = fc, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44) })
		button(r, f.name, {
			dim = UDim2.new(0.25, 0, 1, -4),
			color = active and C.accent or C.panel3,
			textColor = active and C.dark or C.text,
			onClick = function()
				if not active then
					call("setFormation", { formation = f.name })
				end
			end,
		})
		label(r, f.desc, { dim = UDim2.new(0.73, 0, 1, 0), pos = UDim2.new(0.27, 0, 0, 0), size = 13, color = C.muted })
	end
	local sc = card(page, "Estratégia")
	for _, s in ipairs(state.strategies) do
		local active = c.lineup.strategy == s.name
		local r = new("Frame", { Parent = sc, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44) })
		button(r, s.name, {
			dim = UDim2.new(0.25, 0, 1, -4),
			color = active and C.accent or C.panel3,
			textColor = active and C.dark or C.text,
			onClick = function()
				if not active then
					call("setStrategy", { strategy = s.name })
				end
			end,
		})
		label(r, s.desc, { dim = UDim2.new(0.73, 0, 1, 0), pos = UDim2.new(0.27, 0, 0, 0), size = 13, color = C.muted })
	end
	local st = card(page, "Força calculada do seu time")
	kv(st, "Ataque", string.format("%.1f", c.strength.att), C.accent)
	kv(st, "Defesa", string.format("%.1f", c.strength.def), C.blue)
	label(st, "Como funciona: cada titular rende conforme o overall, a posição em que joga e a condição física. A formação e a estratégia somam bônus. A diferença entre o seu ataque e a defesa rival define a média de gols esperada; o placar final tem uma parte aleatória controlada.", { size = 12, color = C.muted })
end

SCREENS.calendar = function(page)
	local c = state.career
	for _, rd in ipairs(c.fixtures) do
		local status = ""
		if rd.round <= c.round then
			status = "  •  concluída"
		elseif rd.round == c.round + 1 and not c.seasonOver then
			status = "  •  próxima"
		end
		local cc = card(page, "Rodada " .. rd.round .. status, { titleColor = (rd.round == c.round + 1) and C.gold or C.accent })
		for _, m in ipairs(rd.matches) do
			local r = row(cc, 30, m.isUser and C.accentDark or C.panel2)
			cell(r, m.home, 0.42, { align = Enum.TextXAlignment.Right, font = m.isUser and FONT_B or FONT_M })
			cell(r, m.played and (m.hg .. " x " .. m.ag) or "vs", 0.16, { font = FONT_B, align = Enum.TextXAlignment.Center })
			cell(r, m.away, 0.42, { font = m.isUser and FONT_B or FONT_M })
		end
	end
end

SCREENS.standings = function(page)
	local c = state.career
	local tc = card(page, "Classificação — Temporada " .. c.season)
	local W = { 0.07, 0.37, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07 }
	local h = row(tc, 26, C.panel)
	for i, t in ipairs({ "#", "CLUBE", "PJ", "V", "E", "D", "GP", "GC", "SG", "PTS" }) do
		cell(h, t, W[i], { size = 11, color = C.muted, font = FONT_B })
	end
	for _, s in ipairs(c.standings) do
		local r = row(tc, 32, s.isUser and C.accentDark or C.panel2)
		cell(r, tostring(s.pos), W[1], { font = FONT_B, color = s.pos == 1 and C.gold or C.text })
		cell(r, s.name, W[2], { font = s.isUser and FONT_B or FONT_M })
		cell(r, tostring(s.played), W[3])
		cell(r, tostring(s.w), W[4])
		cell(r, tostring(s.d), W[5])
		cell(r, tostring(s.l), W[6])
		cell(r, tostring(s.gf), W[7])
		cell(r, tostring(s.ga), W[8])
		cell(r, (s.gd > 0 and "+" or "") .. s.gd, W[9])
		cell(r, tostring(s.pts), W[10], { font = FONT_B, color = C.accent })
	end
	label(tc, "Critérios de desempate: pontos, saldo de gols, gols marcados e vitórias.", { size = 12, color = C.muted })
end

SCREENS.market = function(page)
	local c = state.career
	local info = card(page, "Mercado de transferências")
	label(info, string.format("Orçamento: %s  •  Elenco: %d/%d", money(c.club.budget), c.squadCount, c.squadMax), { font = FONT_B, size = 14 })
	label(info, "O preço é o valor de mercado. O salário passa a ser descontado a cada rodada.", { size = 12, color = C.muted })
	local filters = { "Todos", "GOL", "ZAG", "LAT", "VOL", "MEI", "PON", "ATA" }
	local bar = hstack(info, 32)
	for _, f in ipairs(filters) do
		local active = marketFilter == f
		button(bar, f, {
			dim = UDim2.new(1 / #filters, -6, 1, 0),
			size = 12,
			color = active and C.accent or C.panel3,
			textColor = active and C.dark or C.text,
			onClick = function()
				marketFilter = f
				render()
			end,
		})
	end
	local list = card(page, nil)
	local full = c.squadCount >= c.squadMax
	local shown = 0
	for _, p in ipairs(c.market) do
		if marketFilter == "Todos" or p.pos == marketFilter then
			shown += 1
			local r = row(list, 44, C.panel2)
			posTag(r, p.pos, 0.08)
			twoLine(r, p.name, p.age .. " anos", 0.3)
			cell(r, "OVR " .. p.ovr, 0.11, { font = FONT_B })
			cell(r, "POT " .. p.pot, 0.1)
			twoLine(r, money(p.value), money(p.wage) .. "/rod.", 0.17)
			local affordable = c.club.budget >= p.value
			local txt = "Comprar"
			if full then
				txt = "Elenco cheio"
			elseif not affordable then
				txt = "Sem verba"
			end
			button(r, txt, {
				dim = UDim2.new(0.22, -4, 0, 32),
				size = 12,
				color = C.accentDark,
				disabled = full or not affordable,
				onClick = function()
					confirmModal("Contratar jogador?", string.format("Contratar %s (%s, %d anos, OVR %d / POT %d) por %s? Salário de %s por rodada.", p.name, p.pos, p.age, p.ovr, p.pot, money(p.value), money(p.wage)), "Contratar", function()
						call("buyPlayer", { playerId = p.id })
					end)
				end,
			})
		end
	end
	if shown == 0 then
		label(list, "Nenhum jogador disponível com este filtro.", { color = C.muted, size = 13 })
	end
end

SCREENS.finances = function(page)
	local c = state.career
	local f = c.finance
	local s = card(page, "Resumo financeiro")
	kv(s, "Orçamento disponível", money(f.budget), f.budget >= 0 and C.accent or C.danger)
	kv(s, "Folha salarial por rodada", money(f.wages), C.danger)
	kv(s, "Bilheteria por jogo em casa", money(f.gate))
	kv(s, "Cotas de TV no fim da temporada", money(f.tv))
	kv(s, "Valor de mercado do elenco", money(f.squadValue))

	local sv = card(page, "Salvamento", { titleColor = state.saveBlocked and C.warn or C.accent })
	label(sv, state.saveMsg or "", { size = 13 })
	if state.lastSave and state.lastSave > 0 then
		label(sv, "Último salvamento: " .. os.date("%d/%m/%Y %H:%M", state.lastSave), { size = 12, color = C.muted })
	end
	label(sv, "O jogo salva automaticamente após ações importantes e periodicamente.", { size = 12, color = C.muted })
	button(sv, state.saveBlocked and "Salvamento desativado" or "Salvar agora", {
		disabled = state.saveBlocked,
		color = C.accentDark,
		onClick = function()
			call("saveNow", {})
		end,
	})

	local hc = card(page, "Histórico de temporadas")
	if #f.history == 0 then
		label(hc, "Nenhuma temporada concluída ainda.", { size = 13, color = C.muted })
	end
	for _, h in ipairs(f.history) do
		local r = row(hc, 30, C.panel2)
		cell(r, "T" .. h.season, 0.1, { font = FONT_B })
		cell(r, h.userClub .. ": " .. h.userPos .. "º (" .. h.userPts .. " pts)", 0.5)
		cell(r, "Campeão: " .. h.champion, 0.4, { color = C.gold })
	end

	local lc = card(page, "Movimentações recentes")
	if #f.log == 0 then
		label(lc, "Sem movimentações.", { size = 13, color = C.muted })
	end
	for _, e in ipairs(f.log) do
		local r = row(lc, 30, C.panel2)
		cell(r, string.format("T%d R%d", e.season, e.round), 0.14, { color = C.muted, size = 12 })
		cell(r, e.desc, 0.6)
		local col = C.muted
		if e.amount > 0 then
			col = C.accent
		elseif e.amount < 0 then
			col = C.danger
		end
		cell(r, e.amount ~= 0 and money(e.amount) or "—", 0.26, { font = FONT_B, color = col, align = Enum.TextXAlignment.Right })
	end
end

---------------------------------------------------------------------
-- RENDERIZAÇÃO E NAVEGAÇÃO
---------------------------------------------------------------------
local currentPage, renderedScreen = nil, nil

local function makePage()
	return new("ScrollingFrame", {
		Parent = content,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = C.accent,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, {
		new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
		new("UIPadding", { PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 60) }),
	})
end

render = function()
	if not state then
		return
	end
	if not state.career and currentScreen ~= "menu" and currentScreen ~= "newCareer" then
		currentScreen = "menu"
	end
	if currentPage and renderedScreen then
		scrollMemory[renderedScreen] = currentPage.CanvasPosition.Y
	end
	for _, ch in ipairs(content:GetChildren()) do
		ch:Destroy()
	end
	updateChrome()
	local page = makePage()
	currentPage = page
	renderedScreen = currentScreen
	local builder = SCREENS[currentScreen] or SCREENS.menu
	local ok, err = pcall(builder, page)
	if not ok then
		warn("[CL] Erro ao desenhar tela:", err)
		label(page, "Erro ao desenhar esta tela: " .. tostring(err), { color = C.danger })
	end
	local y = scrollMemory[currentScreen]
	if y and y > 0 then
		task.delay(0.05, function()
			if currentPage == page then
				page.CanvasPosition = Vector2.new(0, y)
			end
		end)
	end
end

navigate = function(screen)
	scrollMemory[screen] = 0
	currentScreen = screen
	render()
end

---------------------------------------------------------------------
-- INICIALIZAÇÃO
---------------------------------------------------------------------
local loadingLbl = label(content, "Carregando sua carreira...", { dim = UDim2.new(1, 0, 0, 40), size = 18, align = Enum.TextXAlignment.Center })

task.spawn(function()
	for attempt = 1, 10 do
		local ok, res = pcall(function()
			return requestFn:InvokeServer("getState", {})
		end)
		if ok and type(res) == "table" and type(res.state) == "table" then
			state = res.state
			currentScreen = "menu"
			render()
			if state.saveBlocked and state.saveMsg then
				toast(state.saveMsg, C.warn)
			end
			return
		end
		if loadingLbl.Parent then
			loadingLbl.Text = "Conectando ao servidor... (tentativa " .. attempt .. "/10)"
		end
		task.wait(2)
	end
	if loadingLbl.Parent then
		loadingLbl.Text = "Não foi possível conectar ao servidor. Saia e entre novamente."
	end
end)
