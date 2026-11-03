--!strict
local UI=require(script.Parent.Parent.UI)
local Theme=require(game:GetService("ReplicatedStorage").CL27.Theme)
local Data=require(game:GetService("ReplicatedStorage").CL27.Data)
local entries={
	{"VISÃO GERAL","Overview","Seu legado começa aqui","Acompanhe o clube, os próximos compromissos e os destaques da temporada."},
	{"CENTRAL DO ELENCO","Squad","Cada posição. Uma história.","Conheça o elenco, ajuste a formação e encontre o equilíbrio da sua equipe."},
	{"SELEÇÃO DE CLUBES","Clubs","O encontro de duas identidades","Escolha os clubes e apresente seus uniformes na arena do CL 27."},
	{"CALENDÁRIO","Calendar","Uma temporada de possibilidades","Explore os compromissos da sua liga e as noites continentais."},
	{"MERCADO","Transfers","O próximo nome do seu legado","Explore perfis e organize a lista de atletas observados pelo clube."},
	{"DESENVOLVIMENTO","Development","Talento em movimento","Escolha o foco de desenvolvimento e acompanhe o potencial do elenco."},
	{"COMPETIÇÕES","Competitions","A grandeza está na jornada","Consulte a classificação e os caminhos até as próximas conquistas."},
	{"PERSONALIZAÇÃO","Customization","A sua assinatura","Explore a identidade visual do clube e os uniformes originais do CL 27."},
}
return function(root,ctx)
	local isTraining=ctx.state.screen=="HomeTraining"
	local selected=ctx.state.homeFocus or 3
	local current=entries[selected]
	local club=Data.clubs[ctx.state.homeClub or 1]
	-- A navegação ocupa somente o primeiro quarto; o atleta permanece no espaço real à direita.
	local shade=UI.frame(root,0,0,570,900,Color3.fromRGB(3,11,17),0.13)
	local grad=UI.gradient(shade,{Color3.new(1,1,1),Color3.new(1,1,1)})
	grad.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.05),NumberSequenceKeypoint.new(0.7,0.25),NumberSequenceKeypoint.new(1,1)})
	UI.logo(root,45,42,1.05)
	UI.text(root,"CLUB LEGACY",79,96,260,22,11,Theme.muted,Enum.Font.GothamBold)
	local rail=UI.panel(root,40,153,34,166,Theme.background,0.28)
	for i, icon in ipairs({"◈","◎","≡"}) do
		UI.button(rail,icon,0,(i-1)*51,34,42,function()
			ctx.go(({"Settings","Customization","Overview"})[i])
		end,ctx.scope,{quiet=true,textSize=23})
	end
	for i,item in ipairs(entries) do
		local y=159+(i-1)*63
		local button=UI.button(root,item[1],112,y,340,49,function()
			if ctx.state.homeFocus==i then ctx.go(item[2]) else ctx.state.homeFocus=i;ctx.rerender() end
		end,ctx.scope,{quiet=true,selected=i==selected,textSize=if i==selected then 25 else 19,
			textColor=if i==selected then Theme.white else Color3.fromRGB(184,196,197),hoverTextColor=Theme.white})
		button.TextXAlignment=Enum.TextXAlignment.Left
		if i==selected then
			UI.frame(root,96,y+13,3,23,UI.accent)
		end
	end
	if isTraining then
		-- One upper contextual block preserves the open skyline and building silhouette.
		UI.text(root,"CENTRO DE TREINAMENTO / "..string.upper(club.name),482,120,665,20,11,Theme.white,Enum.Font.GothamBold)
		local title=UI.text(root,current[3],480,149,665,70,30,Theme.white,Enum.Font.GothamBlack)
		title.TextWrapped=true
		title.TextStrokeColor3=Theme.background
		title.TextStrokeTransparency=0.82
		local details=UI.text(root,current[4],482,227,610,66,18,Theme.white)
		details.TextWrapped=true
		details.TextStrokeColor3=Theme.background
		details.TextStrokeTransparency=0.87
	else
		UI.text(root,"TEMPORADA 2026 / 27",482,350,510,24,14,UI.accent,Enum.Font.GothamBold)
		UI.text(root,current[3],480,386,570,91,39,Theme.white,Enum.Font.GothamBlack).TextWrapped=true
		UI.text(root,current[4],482,487,485,69,18,Color3.fromRGB(205,227,228)).TextWrapped=true
	end
	UI.button(root,"ENTRAR  →",482,619,282,56,function() ctx.go(current[2]) end,ctx.scope,{primary=true,textSize=20})
	UI.text(root,if isTraining then "02 / 02" else "01 / 02",482,697,95,25,13,Theme.muted)
	UI.button(root,if isTraining then "◈  AMBIENTE INTERNO" else "◈  CENTRO DE TREINAMENTO",581,689,336,41,function()
		ctx.go(if isTraining then "HomeInterior" else "HomeTraining")
	end,ctx.scope,{quiet=true,textSize=14})
	UI.text(root,string.upper(club.shortName).." / CENTRO DO CLUBE",1120,49,365,24,13,Theme.white,Enum.Font.GothamBold).TextXAlignment=Enum.TextXAlignment.Right
	UI.text(root,"NÍVEL 27   •   TEMPORADA 01",1120,77,365,24,12,Theme.muted).TextXAlignment=Enum.TextXAlignment.Right
	UI.text(root,"AMBIENTE "..(if isTraining then "02   /   CENTRO DE TREINAMENTO" else "01   /   GALERIA DO LEGADO"),1070,789,460,27,11,Theme.muted).TextXAlignment=Enum.TextXAlignment.Right
end
