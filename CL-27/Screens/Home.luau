return function(ctx)
	local ui, data = ctx.ui, ctx.data
	local c = ui.theme
	local compact = ctx.compact
	local hero = ui.panel(ctx.parent,compact and 800 or 530,c.bg)
	hero.ClipsDescendants = true
	ui.new("UIGradient",{Color=ColorSequence.new(c.panelAlt,c.bg),Rotation=25},hero)
	local slash = ui.new("Frame",{BackgroundColor3=c.accent,BackgroundTransparency=0.94,Rotation=24,Position=UDim2.fromScale(0.65,-0.15),Size=UDim2.fromScale(0.27,1.4)},hero)
	ui.round(slash,10)
	local watermark = ui.label(hero,"27",compact and 250 or 430,c.line,450)
	watermark.Position = UDim2.new(0.47,0,0,-4)
	watermark.Size = UDim2.new(0.6,0,0,450)
	watermark.TextTransparency = 0.66
	watermark.Font = Enum.Font.GothamBlack
	local badge = ui.chip(hero,"NOVA TEMPORADA  /  2027",c.accent)
	badge.Position = UDim2.fromOffset(24,24)
	badge.Size = UDim2.fromOffset(220,28)
	local headline = ui.label(hero,"O CLUBE É SEU.\nO LEGADO TAMBÉM.",compact and 34 or math.clamp(ctx.width*0.045,32,48),c.text,150)
	headline.Font = Enum.Font.GothamBlack
	headline.Position = UDim2.fromOffset(24,78)
	headline.Size = UDim2.new(compact and 1 or 0.62,-48,0,150)
	headline.TextYAlignment = Enum.TextYAlignment.Top
	local description = ui.label(hero,"Uma nova identidade para quem vive o futebol além das quatro linhas.",15,c.muted,70)
	description.Position = UDim2.fromOffset(24,235)
	description.Size = UDim2.new(compact and 1 or 0.51,-48,0,70)
	local club = ui.label(hero,data.club.name .. "  /  " .. data.club.city,12,c.accent,26)
	club.Position = UDim2.fromOffset(24,320)
	club.Size = UDim2.new(compact and 1 or 0.53,-48,0,26)
	local enter = ui.button(hero,"ENTRAR NA CENTRAL   →",function() ctx.navigate("Overview") end,{primary=true})
	enter.Position = UDim2.fromOffset(24,365)
	enter.Size = UDim2.new(compact and 1 or 0.46,-48,0,52)
	local caption = ui.label(hero,"EDIÇÃO CL 27  ·  IDENTIDADE ORIGINAL",10,c.muted,22)
	caption.Position = UDim2.fromOffset(24,compact and 758 or 478)
	caption.Size = UDim2.new(1,-48,0,22)
	local avatar = ctx.avatar(hero,data.players[11],{fullBody=true,interactive=true})
	avatar.Position = compact and UDim2.new(0.10,0,0,425) or UDim2.fromScale(0.57,0.02)
	avatar.Size = compact and UDim2.new(0.8,0,0,330) or UDim2.fromScale(0.43,0.96)
	ui.section(ctx.parent,"O PRÓXIMO CAPÍTULO","Todas as decisões começam aqui.","Explore a identidade, conheça o elenco e prepare sua visão de clube.")
	local tiles = ui.grid(ctx.parent,250,162)
	for _, item in ipairs({
		{"01","O GRUPO","Conheça os nomes que vestem a sua camisa.","Squad"},
		{"02","SUA IDEIA DE JOGO","Desenhe a formação na prancheta tática.","Tactics"},
		{"03","IDENTIDADE","Crie o uniforme e escolha as cores do clube.","Customization"},
	}) do
		local tile = ui.button(tiles,"",function() ctx.navigate(item[4]) end,{height=162})
		local index = ui.label(tile,item[1] .. "   /",12,c.accent,22)
		index.Position = UDim2.fromOffset(18,14)
		index.Size = UDim2.new(1,-36,0,22)
		local title = ui.label(tile,item[2],18,c.text,38)
		title.Position = UDim2.fromOffset(18,44)
		title.Size = UDim2.new(1,-36,0,38)
		title.Font = Enum.Font.GothamBold
		local detail = ui.label(tile,item[3],12,c.muted,48)
		detail.Position = UDim2.fromOffset(18,88)
		detail.Size = UDim2.new(1,-36,0,48)
	end
end
