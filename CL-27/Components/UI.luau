local Theme = require(script.Parent.Parent.Config.Theme)
local Audio = require(script.Parent.Audio)
local UI = {}

function UI.newContext(scope, settings, compact, focusArea)
	local ui = { theme = Theme }
	local buttonId = 0
	local function new(class, props, parent)
		local instance = Instance.new(class)
		if instance:IsA("GuiObject") then instance.BorderSizePixel = 0 end
		for key, value in pairs(props or {}) do instance[key] = value end
		instance.Parent = parent
		return instance
	end
	ui.new = new
	function ui.round(object, radius)
		return new("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, object)
	end
	function ui.stroke(object, color, transparency)
		return new("UIStroke", { Color = color or Theme.line, Transparency = transparency or 0.3, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, object)
	end
	function ui.pad(parent, n)
		n = n or 18
		return new("UIPadding", { PaddingLeft = UDim.new(0,n), PaddingRight = UDim.new(0,n), PaddingTop = UDim.new(0,n), PaddingBottom = UDim.new(0,n) }, parent)
	end
	function ui.stack(parent, gap, horizontal)
		return new("UIListLayout", { FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical, Padding = UDim.new(0,gap or 12), SortOrder = Enum.SortOrder.LayoutOrder }, parent)
	end
	function ui.row(parent, height)
		return new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1,0,0,height or 48) }, parent)
	end
	function ui.label(parent, text, size, color, height)
		local label = new("TextLabel", { Text = tostring(text), BackgroundTransparency = 1, Size = UDim2.new(1,0,0,height or 28), Font = Enum.Font.GothamMedium, TextSize = (size or 15) * settings.textScale, TextColor3 = color or Theme.text, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center }, parent)
		label:SetAttribute("CL27TextSize", size or 15)
		return label
	end
	function ui.panel(parent, height, color)
		local frame = new("Frame", { Size = UDim2.new(1,0,0,height or 180), BackgroundColor3 = color or Theme.panel }, parent)
		ui.round(frame, 12)
		ui.stroke(frame)
		return frame
	end
	function ui.button(parent, text, callback, opts)
		opts = opts or {}
		local selected = opts.primary or opts.selected
		local base = selected and Theme.accent or Theme.panelAlt
		local width = opts.width
		local size = typeof(width) == "UDim2" and width or UDim2.new(width and 0 or 1,width or 0,0,opts.height or 44)
		local button = new("TextButton", { Text = text, Size = size, BackgroundColor3 = base, TextColor3 = selected and Theme.bg or Theme.text, Font = Enum.Font.GothamBold, TextSize = 13 * settings.textScale, TextWrapped = true, AutoButtonColor = false, Selectable = true }, parent)
		buttonId += 1
		button:SetAttribute("CL27FocusKey",(focusArea or "Chrome")..tostring(buttonId))
		button:SetAttribute("CL27TextSize", 13)
		ui.round(button, 7)
		local outline = ui.stroke(button, selected and Theme.accent or Theme.line, selected and 0.1 or 0.45)
		local scale = new("UIScale",{Scale=1},button)
		local function focus()
			scope:tween(button, { BackgroundColor3 = selected and Theme.accent:Lerp(Color3.new(1,1,1),0.16) or Theme.line }, 0.14)
			outline.Transparency = 0
			scope:tween(scale,{Scale=1.015},0.14)
		end
		local function blur()
			scope:tween(button, { BackgroundColor3 = base }, 0.16)
			outline.Transparency = selected and 0.1 or 0.45
			scope:tween(scale,{Scale=1},0.14)
		end
		scope:connect(button.MouseEnter, focus)
		scope:connect(button.MouseLeave, blur)
		scope:connect(button.SelectionGained, focus)
		scope:connect(button.SelectionLost, blur)
		scope:connect(button.Activated, function() Audio.play(); callback() end)
		return button
	end
	function ui.chip(parent, text, color)
		local chip = ui.label(parent, text, 11, color or Theme.accent, 26)
		chip.Size = UDim2.fromOffset(144,26)
		chip.BackgroundColor3 = Theme.panelAlt
		chip.BackgroundTransparency = 0
		chip.TextXAlignment = Enum.TextXAlignment.Center
		ui.round(chip, 4)
		return chip
	end
	function ui.section(parent, eyebrow, title, subtitle)
		local section = ui.row(parent, subtitle and (compact and 148 or 114) or (compact and 108 or 88))
		local over = ui.label(section, eyebrow, 10, Theme.accent, 18)
		over.Position = UDim2.fromOffset(0,0)
		local heading = ui.label(section, title, compact and 23 or 27, Theme.text, compact and 64 or 44)
		heading.Position = UDim2.fromOffset(0,20)
		heading.Font = Enum.Font.GothamBold
		if subtitle then
			local sub = ui.label(section, subtitle, 12, Theme.muted, compact and 52 or 42)
			sub.Position = UDim2.fromOffset(0,compact and 88 or 66)
		end
		return section
	end
	function ui.bar(parent, text, value, max, color)
		local row = ui.row(parent, 48)
		local label = ui.label(row, text, 12, Theme.muted, 24)
		label.Size = UDim2.new(1,-60,0,24)
		local number = ui.label(row, tostring(value), 13, color or Theme.accent, 24)
		number.Position = UDim2.new(1,-56,0,0)
		number.Size = UDim2.fromOffset(56,24)
		number.TextXAlignment = Enum.TextXAlignment.Right
		local track = new("Frame", { Position = UDim2.fromOffset(0,32), Size = UDim2.new(1,0,0,4), BackgroundColor3 = Theme.line }, row)
		ui.round(track, 3)
		local fill = new("Frame", { Size = UDim2.fromScale(math.clamp(value/(max or 100),0,1),1), BackgroundColor3 = color or Theme.accent }, track)
		ui.round(fill, 3)
		return row
	end
	function ui.metric(parent, name, value, detail)
		local panel = ui.panel(parent,104)
		ui.pad(panel,14)
		ui.stack(panel,1)
		ui.label(panel,name,10,Theme.muted,18)
		local valueLabel = ui.label(panel,value,25,Theme.text,32)
		valueLabel.Font = Enum.Font.GothamBold
		ui.label(panel,detail or "",10,Theme.accent,20)
		return panel
	end
	function ui.grid(parent, cellWidth, cellHeight)
		local frame = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y }, parent)
		local layout = new("UIGridLayout", { CellPadding = UDim2.fromOffset(12,12), CellSize = UDim2.fromOffset(cellWidth,cellHeight), SortOrder = Enum.SortOrder.LayoutOrder }, frame)
		local function resize()
			local available = frame.AbsoluteSize.X
			if available < 1 then return end
			local columns = math.max(1,math.floor((available+12)/(cellWidth+12)))
			layout.CellSize = UDim2.new(1/columns,-12*(columns-1)/columns,0,cellHeight)
		end
		scope:connect(frame:GetPropertyChangedSignal("AbsoluteSize"),resize)
		resize()
		return frame
	end
	function ui.playerCard(parent, player, callback, selected)
		local button = ui.button(parent,"",callback,{selected=selected,height=144})
		button.Size = UDim2.fromOffset(220,144)
		local ink = selected and Theme.bg or Theme.text
		local over = ui.label(button,tostring(player.overall),33,selected and Theme.bg or Theme.accent,44)
		over.Position = UDim2.fromOffset(14,9)
		over.Size = UDim2.fromOffset(66,44)
		over.Font = Enum.Font.GothamBold
		local role = ui.label(button,player.position,11,ink,22)
		role.Position = UDim2.new(1,-66,0,16)
		role.Size = UDim2.fromOffset(54,22)
		role.TextXAlignment = Enum.TextXAlignment.Right
		local name = ui.label(button,player.name,15,ink,40)
		name.Position = UDim2.fromOffset(14,58)
		name.Size = UDim2.new(1,-28,0,40)
		name.Font = Enum.Font.GothamBold
		local meta = ui.label(button,player.nation .. " · " .. tostring(player.age) .. " anos",11,ink,26)
		meta.Position = UDim2.fromOffset(14,107)
		meta.Size = UDim2.new(1,-28,0,26)
		return button
	end
	return ui
end

return UI
