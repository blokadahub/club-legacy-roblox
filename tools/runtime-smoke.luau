-- Runtime harness, never a renderer or a Roblox API compatibility substitute.
-- The official Luau VM executes the real UI, Rig, Scope, Data and screen modules.
-- Small in-memory stubs cover only the API surface those modules use.
local nativeTypeof = typeof
local function typeof(value)
	return type(value) == "table" and rawget(value, "_kind") or nativeTypeof(value)
end
local function typed(kind, values, meta)
	values._kind = kind
	return setmetatable(values, meta)
end
local vectorMeta = {}
vectorMeta.__index = function(self, key)
	if key == "Magnitude" then return math.sqrt(self.X ^ 2 + self.Y ^ 2 + (self.Z or 0) ^ 2) end
	if key == "Unit" then local n = self.Magnitude; return self / math.max(n, 0.0001) end
	return nil
end
vectorMeta.__add = function(a, b) return typed(a._kind, {X = a.X + b.X, Y = a.Y + b.Y, Z = (a.Z or 0) + (b.Z or 0)}, vectorMeta) end
vectorMeta.__sub = function(a, b) return typed(a._kind, {X = a.X - b.X, Y = a.Y - b.Y, Z = (a.Z or 0) - (b.Z or 0)}, vectorMeta) end
vectorMeta.__mul = function(a, b) if type(a) == "number" then a, b = b, a end; return typed(a._kind, {X = a.X * b, Y = a.Y * b, Z = (a.Z or 0) * b}, vectorMeta) end
vectorMeta.__div = function(a, b) return a * (1 / b) end
vectorMeta.__unm = function(a) return a * -1 end
local Vector2 = {new = function(x, y) return typed("Vector2", {X = x or 0, Y = y or 0}, vectorMeta) end}
local Vector3 = {new = function(x, y, z) return typed("Vector3", {X = x or 0, Y = y or 0, Z = z or 0}, vectorMeta) end}
Vector3.zero = Vector3.new()
local Color3 = {
	new = function(r, g, b) return typed("Color3", {R = r or 0, G = g or 0, B = b or 0}) end,
	fromRGB = function(r, g, b) return typed("Color3", {R = r / 255, G = g / 255, B = b / 255}) end,
}
local UDim = {new = function(s, o) return typed("UDim", {Scale = s, Offset = o}) end}
local UDim2 = {new = function(xs, xo, ys, yo) return typed("UDim2", {X = UDim.new(xs, xo), Y = UDim.new(ys, yo)}) end}
UDim2.fromOffset = function(x, y) return UDim2.new(0, x, 0, y) end
UDim2.fromScale = function(x, y) return UDim2.new(x, 0, y, 0) end
local cfMeta = {}
cfMeta.__mul = function(a, b) return typed("CFrame", {Position = a.Position + b.Position}, cfMeta) end
cfMeta.__index = {Lerp = function(a, b, alpha) return typed("CFrame", {Position = a.Position * (1 - alpha) + b.Position * alpha}, cfMeta) end}
local CFrame = {}
CFrame.new = function(x, y, z) return typed("CFrame", {Position = if typeof(x) == "Vector3" then x else Vector3.new(x, y, z)}, cfMeta) end
CFrame.Angles = function() return CFrame.new() end
CFrame.lookAt = function(position) return CFrame.new(position) end
CFrame.identity = CFrame.new()
local function enumNode(path)
	return setmetatable({}, {__index = function(self, key)
		local node = enumNode(path .. "." .. key)
		rawset(self, key, node)
		return node
	end, __tostring = function() return path end})
end
local Enum = enumNode("Enum")
local function sequence(value) return value end
local ColorSequence = {new = sequence}
local NumberSequence = {new = sequence}
local ColorSequenceKeypoint = {new = function(t, value) return {Time = t, Value = value} end}
local NumberSequenceKeypoint = {new = function(t, value) return {Time = t, Value = value} end}
local TweenInfo = {new = function(duration) return {Time = duration} end}

local function signal()
	local listeners = {}
	local object = {}
	function object:Connect(fn)
		local connection = {_kind = "RBXScriptConnection", Connected = true, callback = fn}
		function connection:Disconnect() self.Connected = false end
		table.insert(listeners, connection)
		return connection
	end
	function object:Once(fn)
		local connection
		connection = self:Connect(function(...)
			connection:Disconnect()
			fn(...)
		end)
		return connection
	end
	function object:Fire(...)
		for _, connection in ipairs(table.clone(listeners)) do
			if connection.Connected then connection.callback(...) end
		end
	end
	function object:DisconnectAll() for _, connection in ipairs(listeners) do connection:Disconnect() end end
	return object
end
local events = {
	Activated = true, MouseEnter = true, MouseLeave = true, SelectionGained = true,
	SelectionLost = true, FocusLost = true, InputBegan = true, InputEnded = true, ChildAdded = true, Changed = true,
	Destroying = true,
}
local methods = {}
local instanceMeta = {}
instanceMeta.__index = function(self, key)
	if methods[key] then return methods[key] end
	if events[key] then
		if not self._events[key] then self._events[key] = signal() end
		return self._events[key]
	end
	local value = self._props[key]
	if value ~= nil then return value end
	if key == "Position" and self._props.CFrame then return self._props.CFrame.Position end
	for _, child in ipairs(self._children) do if child.Name == key then return child end end
	return nil
end
instanceMeta.__newindex = function(self, key, value)
	if key == "Parent" then
		local previous = self._props.Parent
		if previous then local at = table.find(previous._children, self); if at then table.remove(previous._children, at) end end
		if value then assert(typeof(value) == "Instance", "Parent must be an Instance"); table.insert(value._children, self) end
	elseif key == "Text" then assert(type(value) == "string", "Text must be a string")
	elseif key == "BackgroundColor3" or key == "TextColor3" or key == "Color" and self._props.ClassName == "Part" then
		assert(typeof(value) == "Color3", key .. " must be Color3")
	end
	self._props[key] = value
end
local Instance = {}
Instance.new = function(className)
	return setmetatable({_kind = "Instance", _props = {ClassName = className, Name = className, CFrame = CFrame.new(), BackgroundTransparency = 0}, _children = {}, _events = {}, _attributes = {}}, instanceMeta)
end
function methods:IsA(className)
	local name = self.ClassName
	return name == className or className == "BasePart" and name == "Part" or className == "GuiButton" and (name == "TextButton" or name == "ImageButton")
end
function methods:GetChildren() return table.clone(self._children) end
function methods:GetDescendants()
	local result = {}
	local function visit(parent) for _, child in ipairs(parent._children) do table.insert(result, child); visit(child) end end
	visit(self)
	return result
end
function methods:FindFirstChild(name, recursive)
	for _, child in ipairs(if recursive then self:GetDescendants() else self._children) do if child.Name == name then return child end end
	return nil
end
function methods:WaitForChild(name) return assert(self:FindFirstChild(name), "Missing stub child: " .. name) end
function methods:SetAttribute(key, value) self._attributes[key] = value end
function methods:GetAttribute(key) return self._attributes[key] end
function methods:PivotTo(value) self._props.Pivot = value end
function methods:GetPivot() return self._props.Pivot or CFrame.identity end
function methods:Destroy()
	if self._props.Destroyed then return end
	if self._events.Destroying then self._events.Destroying:Fire() end
	for _, child in ipairs(self:GetChildren()) do child:Destroy() end
	for _, event in pairs(self._events) do event:DisconnectAll() end
	self.Parent = nil
	self._props.Destroyed = true
end
function methods:Clone()
	local result = Instance.new(self.ClassName)
	for key, value in pairs(self._props) do if key ~= "Parent" then result[key] = value end end
	for _, child in ipairs(self._children) do local copy = child:Clone(); copy.Parent = result end
	return result
end
local services = {ReplicatedStorage = Instance.new("ReplicatedStorage"), UserInputService = {InputBegan = signal()}, TweenService = {}}
services.Players = {LocalPlayer = Instance.new("Player")}
services.Players.LocalPlayer.Name = "RealUserTest"
function services.TweenService:Create(object, info, goals)
	local tween = {Completed = signal(), PlaybackState = Enum.PlaybackState.Begin, goals = goals, target = object}
	function tween:Play()
		self.PlaybackState = Enum.PlaybackState.Playing
		for key, value in pairs(self.goals) do self.target[key] = value end
	end
	function tween:Cancel() self.PlaybackState = Enum.PlaybackState.Cancelled; self.Completed:Fire(self.PlaybackState) end
	return tween
end
local game = {GetService = function(_, key) return assert(services[key], "Unexpected service " .. key) end}
local scheduled = {}
local task = {
	delay = function(_, fn) local job = {callback = fn}; table.insert(scheduled, job); return job end,
	cancel = function(job) job.cancelled = true end,
}

-- The Python runner inserts real modules and node hierarchy at this marker.
-- MODULES

local Data = require(moduleNodes["src/shared/Data.luau"])
local Scope = require(moduleNodes["src/client/Scope.luau"])
local Rig = require(moduleNodes["src/client/Rig.luau"])
local function deepClone(value)
	if type(value) ~= "table" or typeof(value) ~= "table" then return value end
	local copy = {}; for key, item in pairs(value) do copy[key] = deepClone(item) end; return copy
end
local baseState = {homeClub = 1, awayClub = 2, homeKit = 1, awayKit = 2, selectedPlayer = 8, formation = 1, screen = "HomeInterior", settings = {quality = "Alta", reducedMotion = false}}
local routeSet = {}
local routes = {"HomeInterior", "HomeTraining", "Overview", "Squad", "Tactics", "Assignments", "Calendar", "Transfers", "Finance", "Development", "Competitions", "Customization", "Settings", "Clubs", "Kits"}
for _, id in ipairs(routes) do routeSet[id] = true end
local assertions, mounts, callbacks = 0, 0, 0
local function check(value, message) assert(value, message); assertions += 1 end
local function mounted(id, state)
	state = state or deepClone(baseState)
	state.screen = id
	local scope = Scope.new()
	local root = Instance.new("Frame")
	root.Name = "Screen_" .. id
	root.Parent = Instance.new("ScreenGui")
	local ctx = {state = state, scope = scope, notifications = {}, rerenders = 0, scene = {}}
	function ctx.scene:UpdateClubs(home, away, homeKit, awayKit)
		check(home and away and home.kits[homeKit] and away.kits[awayKit], "Invalid scene selection")
		self.last = {home, away, homeKit, awayKit}
	end
	ctx.go = function(route) check(routeSet[route], "Unknown route: " .. tostring(route)); ctx.lastRoute = route end
	ctx.rerender = function() ctx.rerenders += 1 end
	ctx.notify = function(text) check(type(text) == "string" and #text > 0, "Empty notification"); table.insert(ctx.notifications, text) end
	local name = if string.sub(id, 1, 4) == "Home" then "Home" else id
	require(moduleNodes["src/client/Screens/" .. name .. ".luau"])(root, ctx)
	mounts += 1
	return root, ctx
end
local function buttons(root)
	local result = {}
	for _, item in ipairs(root:GetDescendants()) do if item:IsA("GuiButton") then table.insert(result, item) end end
	return result
end
local function dispose(root, ctx) ctx.scope:Destroy(); root:Destroy() end
local function clickByText(root, text, occurrence)
	local found = 0
	for _, item in ipairs(buttons(root)) do
		if item.Text == text then
			found += 1
			if found == (occurrence or 1) then item.Activated:Fire(); callbacks += 1; return end
		end
	end
	error("Button not found: " .. text)
end

-- Mount each route and invoke every default-state button against an isolated state.
-- Remount after every callback, catching state/conditional layout contract errors.
for _, id in ipairs(routes) do
	local root, ctx = mounted(id)
	local count = #buttons(root)
	check(count > 0, id .. " has no buttons")
	dispose(root, ctx)
	for index = 1, count do
		root, ctx = mounted(id)
		local button = buttons(root)[index]
		button.MouseEnter:Fire(); button.MouseLeave:Fire()
		button.Activated:Fire(); callbacks += 1
		local nextState = ctx.state
		dispose(root, ctx)
		root, ctx = mounted(id, nextState)
		dispose(root, ctx)
	end
	print("PASS route " .. id .. ": " .. count .. " callbacks")
end

-- Contrato do menu FC: cinco opções selecionáveis, nenhuma rota fictícia.
do
	local root, ctx = mounted("HomeInterior")
	local list = root:FindFirstChild("MenuPrincipalFC", true)
	check(list ~= nil and list:IsA("ScrollingFrame"), "Menu inicial não contém a coluna rolável")
	check(root:FindFirstChild("Configuracoes", true) ~= nil and root:FindFirstChild("Acessibilidade", true) ~= nil,
		"Ícones superiores do menu inicial ausentes")
	check(root:FindFirstChild("NomeRealJogador", true).Text == services.Players.LocalPlayer.Name,
		"Menu não mostra o username verdadeiro")
	check(root:FindFirstChild("NivelRealJogador", true).Text == "Nível —",
		"Menu inventou um nível inexistente")
	for i = 1, 5 do
		check(list:FindFirstChild("Opcao_" .. tostring(i)) ~= nil, "Menu perdeu uma das cinco opções")
	end
	check(list:FindFirstChild("Texto_3").Text == "Kick Off"
		and list:FindFirstChild("Texto_3").TextTransparency == 0,
		"Kick Off deve começar selecionado")
	local first = list:FindFirstChild("Opcao_1")
	first.MouseEnter:Fire()
	check(list:FindFirstChild("Texto_1").TextTransparency == 0
		and list:FindFirstChild("Texto_1").Text == "CL News",
		"Hover não deixa a opção branca")
	first.MouseLeave:Fire()
	check(list:FindFirstChild("Texto_1").TextTransparency > 0,
		"Opção inativa não voltou a ficar translúcida")
	local fourth = list:FindFirstChild("Opcao_4")
	fourth.Activated:Fire()
	check(ctx.state.homeFocus == 4 and ctx.lastRoute == nil,
		"Seleção de Clubes tentou navegar sem conteúdo")
	check(list:FindFirstChild("Texto_4").TextTransparency == 0,
		"Item clicado não permaneceu ativo")
	dispose(root, ctx)
	services.Players.LocalPlayer:SetAttribute("Level", 12)
	root, ctx = mounted("HomeInterior")
	check(root:FindFirstChild("NivelRealJogador", true).Text == "Nível 12",
		"Menu deve ler o nível real do atributo do jogador")
	dispose(root, ctx)
	services.Players.LocalPlayer:SetAttribute("Level", nil)
end

-- Additional branches and important stateful sequences.
for _, id in ipairs({"Settings", "Competitions", "Finance", "Tactics"}) do
	for variant = 1, (if id == "Settings" or id == "Tactics" then 3 else 2) do
		local state = deepClone(baseState)
		if id == "Settings" then state.settingsTab = variant elseif id == "Competitions" then state.competitionTab = variant elseif id == "Finance" then state.financeTab = variant else state.formation = variant end
		local root, ctx = mounted(id, state)
		for _, button in ipairs(buttons(root)) do button.Activated:Fire(); callbacks += 1 end
		dispose(root, ctx)
	end
end
do
	local root, ctx = mounted("Squad")
	local playerButton = root:FindFirstChild("Jogador_22", true)
	check(playerButton ~= nil, "Reserve player card missing")
	playerButton.Activated:Fire(); callbacks += 1
	check(ctx.state.selectedPlayer == 22, "Reserve selection did not update state")
	check(root:FindFirstChild("FichaDoJogador", true):FindFirstChild("Retrato_22", true) ~= nil, "Reserve selection did not replace portrait")
	dispose(root, ctx)
end
do
	local root, ctx = mounted("Kits")
	clickByText(root, "APRESENTAR UNIFORMES")
	check(not ctx.state.kitPresentation and #ctx.notifications == 1, "Unconfirmed kits should require both selections")
	clickByText(root, "CONFIRMAR", 1); clickByText(root, "CONFIRMAR", 2)
	local state = ctx.state; dispose(root, ctx)
	root, ctx = mounted("Kits", state)
	clickByText(root, "APRESENTAR UNIFORMES")
	check(ctx.state.kitPresentation == true, "Confirmed kit presentation failed")
	dispose(root, ctx)
end
do
	local root, ctx = mounted("Clubs")
	services.UserInputService.InputBegan:Fire({KeyCode = Enum.KeyCode.Right}, false)
	check(ctx.state.homeClub == 2, "Keyboard club cycling failed")
	local before = ctx.state.homeClub
	dispose(root, ctx)
	services.UserInputService.InputBegan:Fire({KeyCode = Enum.KeyCode.Right}, false)
	check(ctx.state.homeClub == before, "Disposed screen still receives input")
end
do
	local state = deepClone(baseState)
	state.homeKit, state.homeReady = 3, true
	local root, ctx = mounted("Clubs", state)
	clickByText(root, "PAÍS    Todos   ›")
	check(state.clubFilters.home.country == "Brasil", "Country filter did not advance")
	check(Data.clubs[state.homeClub].country == state.clubFilters.home.country, "Country filter selected incompatible club")
	check(state.homeKit == 1 and not state.homeReady, "Changing club filter did not reset kit confirmation")
	dispose(root, ctx)
	root, ctx = mounted("Clubs", state)
	clickByText(root, "LIGA    Todos   ›")
	check(Data.clubs[state.homeClub].league == state.clubFilters.home.league, "League filter selected incompatible club")
	dispose(root, ctx)
end
for roleIndex, key in ipairs({"captain", "penalties", "shortFreeKicks", "longFreeKicks", "leftCorners", "rightCorners"}) do
	local state = deepClone(baseState); state.assignmentRole = roleIndex
	local root, ctx = mounted("Assignments", state)
	local candidate
	for _, item in ipairs(root:GetDescendants()) do
		if item:IsA("TextLabel") and item.Text == Data.players[22].name and item.Parent:IsA("GuiButton") then candidate = item.Parent end
	end
	check(candidate ~= nil, "Candidate missing from assignment list")
	candidate.Activated:Fire(); callbacks += 1
	check(state.assignments[key] == 22, "Role assignment did not update " .. key)
	dispose(root, ctx)
end
-- Personalização visual somente: grade 4x2 e seleção não altera preferências.
do
	local state = deepClone(baseState)
	local root, ctx = mounted("Settings", state)
	local grid = root:FindFirstChild("GradeConfiguracoes", true)
	check(grid ~= nil and grid.Size.X.Offset == 1018, "Grade de Configurações com proporção inesperada")
	local count = 0
	for i = 1, 8 do
		local card = grid:FindFirstChild("Cartao_" .. tostring(i))
		check(card ~= nil, "Faltou cartão visual " .. tostring(i))
		check(card:FindFirstChild("TituloCartao") ~= nil, "Cartão sem título " .. tostring(i))
		check(card:FindFirstChild("Icone_" .. ({"settings","profile","online","playtime","edit","sheets","create","music"})[i]) ~= nil,
			"Cartão sem iconografia própria " .. tostring(i))
		count += 1
	end
	check(count == 8, "Devem existir oito cartões")
	local before = state.settings.quality
	grid:FindFirstChild("Cartao_7").Activated:Fire()
	check(state.settingsCard == 7 and state.settings.quality == before and ctx.lastRoute == nil,
		"Clicar num cartão deve apenas trocar seleção, sem abrir sistema")
	root:FindFirstChild("FecharConfiguracoes", true).Activated:Fire()
	check(ctx.lastRoute == "HomeInterior", "Voltar precisa retornar ao menu principal")
	dispose(root, ctx)
end
do
	local root, ctx = mounted("Transfers")
	local input = root:FindFirstChild("BuscaDeAtleta", true)
	input.Text = "nenhum atleta com este nome"
	input.FocusLost:Fire()
	check(ctx.state.transferQuery == input.Text and ctx.rerenders == 1, "Search input did not update query")
	local state = ctx.state; dispose(root, ctx)
	root, ctx = mounted("Transfers", state)
	check(#buttons(root:FindFirstChild("Relatorios", true)) == 0, "Empty search should produce zero report cards")
	dispose(root, ctx)
end

-- Selecting the last visible row must not send long athlete lists to the top.
for _, case in ipairs({
	{"Development", "AtletasEmDesenvolvimento", "developmentScrollY"},
	{"Assignments", "AtletasParaAtribuicao", "assignmentScrollY"},
	{"Transfers", "Relatorios", "transferScrollY"},
}) do
	local root, ctx = mounted(case[1])
	local scroll = root:FindFirstChild(case[2], true)
	scroll.CanvasPosition = Vector2.new(0, 500)
	local candidates = buttons(scroll)
	candidates[#candidates].Activated:Fire(); callbacks += 1
	local state = ctx.state
	dispose(root, ctx)
	check(state[case[3]] == 500, case[1] .. " discarded the list position during cleanup")
	root, ctx = mounted(case[1], state)
	check(root:FindFirstChild(case[2], true).CanvasPosition.Y == 500, case[1] .. " reset a selected athlete list to the top")
	dispose(root, ctx)
end
do
	local state = deepClone(baseState)
	state.transferScrollY, state.transferQuery = 500, "nenhum atleta com este nome"
	local root, ctx = mounted("Transfers", state)
	check(root:FindFirstChild("Relatorios", true).CanvasPosition.Y == 0, "Filtered empty list retained an out-of-range scroll offset")
	dispose(root, ctx)
end
do
	local state = deepClone(baseState); state.month, state.year = 11, 2027
	local root, ctx = mounted("Calendar", state)
	local eventMarkers = 0
	for _, item in ipairs(root:GetDescendants()) do if item:IsA("TextLabel") and item.Text == "COMPETIÇÃO" then eventMarkers += 1 end end
	check(eventMarkers == 0, "Calendar repeated a 2026 fixture in 2027")
	dispose(root, ctx)
end
do
	local root, ctx = mounted("Squad")
	local scroll = root:FindFirstChild("ListaDeReservas", true)
	local last = scroll:FindFirstChild("Jogador_22")
	check(last.Position.Y.Offset + last.Size.Y.Offset <= scroll.Size.Y.Offset, "Second reserve row clips its player name at rest")
	dispose(root, ctx)
end

do
	local state = deepClone(baseState)
	state.training, state.developmentPlan, state.developmentPlayer = {[8] = 3}, 2, 1
	local root, ctx = mounted("Development", state)
	check(state.developmentPlan == 3, "Entering development did not restore the selected athlete's saved plan")
	dispose(root, ctx)
	state.selectedPlayer = 22
	root, ctx = mounted("Development", state)
	check(state.developmentPlan == 1, "A different athlete inherited another player's development plan")
	dispose(root, ctx)
end
do
	local state = deepClone(baseState)
	state.homeReady, state.kitPresentation = true, true
	local root, ctx = mounted("Customization", state)
	local alternative
	for _, item in ipairs(root:GetDescendants()) do
		if item:IsA("TextLabel") and item.Text == Data.clubs[1].kits[3].name and item.Parent:IsA("GuiButton") then alternative = item.Parent end
	end
	check(alternative ~= nil, "Alternative customization kit is missing")
	alternative.Activated:Fire(); callbacks += 1
	check(state.homeKit == 3 and not state.homeReady and not state.kitPresentation, "Changing a customization kit retained a stale confirmation")
	dispose(root, ctx)
end

-- Verify real Rig construction/kit replacement without claiming rendering or physics.
do
	local model = Rig.create(Data.players[1], Data.clubs[1], 1)
	local bodyCount = 0
	for _, item in ipairs(model:GetChildren()) do if item:IsA("BasePart") then bodyCount += 1 end end
	check(model:FindFirstChild("Humanoid").RigType == Enum.HumanoidRigType.R15, "Rig is not R15")
	check(model:FindFirstChild("Humanoid").EvaluateStateMachine == false, "Presentation rig still evaluates locomotion states")
	check(bodyCount >= 16, "Rig body parts missing")
	for _, name in ipairs({"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"}) do
		check(model:FindFirstChild(name) ~= nil, "R15 segment missing: " .. name)
	end
	Rig.applyKit(model, Data.clubs[2], 2)
	check(model:GetAttribute("Uniforme") == Data.clubs[2].kits[2].name, "Kit metadata did not update")
	check(model.UpperTorso.Color == Data.clubs[2].kits[2].shirt, "Kit palette did not update")
	Rig.pose(model, "Presentation"); Rig.animate(model, 1, false); Rig.animate(model, 2, true)
	model:Destroy()
end

-- Scope disposal, cancelled tween callbacks and delayed work use real Scope logic.
do
	local scope, count = Scope.new(), 0
	local input = signal()
	local connection = scope:Connect(input, function() count += 1 end)
	local host, object = Instance.new("Frame"), Instance.new("Frame"); object.Parent = host
	local first = scope:Tween(object, {BackgroundTransparency = 0.5}, 0.3)
	local second = scope:Tween(object, {BackgroundTransparency = 1}, 0.3)
	check(first.PlaybackState == Enum.PlaybackState.Cancelled, "Replacing tween should cancel previous tween")
	check(scope.tweens[object] == second, "Cancelled completion removed replacement tween")
	scope:Delay(1, function() count += 100 end)
	input:Fire(); scope:Destroy(); input:Fire()
	for _, job in ipairs(scheduled) do if not job.cancelled then job.callback() end end
	check(count == 1 and connection.Connected == false, "Scope leaked event or delayed callback")
	check(second.PlaybackState == Enum.PlaybackState.Cancelled and not scope.alive, "Scope did not cancel active animation")
	check(scope:Tween(object, {}, 1) == nil, "Destroyed scope starts animations")
end
print(string.format("PASS runtime smoke: %d mounts, %d callbacks, %d assertions. STUBS ONLY; no Roblox render/API certification.", mounts, callbacks, assertions))
