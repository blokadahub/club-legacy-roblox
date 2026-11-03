-- CL 27 é uma apresentação de interfaces. Nenhum personagem jogável é criado.
local Players = game:GetService("Players")
Players.CharacterAutoLoads = false

-- Remover um eventual personagem criado antes do bootstrap em uma sessão Studio.
for _, player in Players:GetPlayers() do
	if player.Character then
		player.Character:Destroy()
	end
end
