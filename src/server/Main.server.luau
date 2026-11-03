-- CL 27 é uma apresentação de interfaces. Nenhum personagem jogável é criado.
local Players = game:GetService("Players")
Players.CharacterAutoLoads = false

-- Remover um eventual personagem criado antes do bootstrap em uma sessão Studio.
for _, player in Players:GetPlayers() do
	if player.Character then
		player.Character:Destroy()
	end
end

-- Carrega somente UMA VEZ por servidor o modelo escolhido no Creator Store.
-- O cliente recebe uma cópia visual limpa pelo ReplicatedStorage.
-- Requer a opção Experience Settings > Security > Allow Loading Third Party Assets
-- quando a experiência não é dona do asset.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetService = game:GetService("AssetService")

local ACADEMY_SOCCER_BALL_ID = 17275757538
local templates = Instance.new("Folder")
templates.Name = "CL27Assets"
templates.Parent = ReplicatedStorage

task.spawn(function()
	local ok, result = pcall(function()
		return AssetService:LoadAssetAsync(ACADEMY_SOCCER_BALL_ID)
	end)
	if not ok or typeof(result) ~= "Instance" then
		warn("[CL27] Academy soccer ball indisponível. Verifique a permissão de assets de terceiros: " .. tostring(result))
		return
	end

	local source = result :: Instance
	local template = Instance.new("Model")
	template.Name = "AcademySoccerBall"
	template:SetAttribute("SourceAssetId", ACADEMY_SOCCER_BALL_ID)
	local count = 0

	-- Nunca replica scripts, remotes, sons ou interações vindos de um modelo público.
	-- A cópia preserva MeshParts, texturas e aparência visual original.
	for _, item in ipairs(source:GetDescendants()) do
		if item:IsA("BasePart") and count < 150 then
			local part = item:Clone()
			-- Descendentes que não são puramente visuais são descartados.
			for _, child in ipairs(part:GetDescendants()) do
				if not (child:IsA("Decal")
					or child:IsA("Texture")
					or child:IsA("SpecialMesh")
					or child:IsA("DataModelMesh")
					or child:IsA("SurfaceAppearance")) then
					child:Destroy()
				end
			end
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Parent = template
			count += 1
		end
	end
	source:Destroy()

	if count == 0 then
		warn("[CL27] Asset " .. tostring(ACADEMY_SOCCER_BALL_ID) .. " não contém BaseParts utilizáveis.")
		template:Destroy()
		return
	end

	-- Inicia a replicação somente depois da limpeza.
	template.Parent = templates
	print("[CL27] Bola Academy preparada: " .. tostring(count) .. " partes visuais.")
end)
