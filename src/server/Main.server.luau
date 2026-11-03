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
-- Primeiro tenta o modelo adquirido pelo titular da experiência (inventário).
-- Se não houver autorização, a API alternativa depende da configuração do Studio.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetService = game:GetService("AssetService")
local InsertService = game:GetService("InsertService")

local ACADEMY_SOCCER_BALL_ID = 17275757538
local templates = Instance.new("Folder")
templates.Name = "CL27Assets"
templates.Parent = ReplicatedStorage

task.spawn(function()
	-- InsertService aceita assets do inventário do criador da experiência,
	-- independentemente da opção global de modelos públicos de terceiros.
	local ok, result = pcall(function()
		return InsertService:LoadAsset(ACADEMY_SOCCER_BALL_ID)
	end)
	local method = "InsertService (inventário)"
	if not ok or typeof(result) ~= "Instance" then
		-- Compatibilidade com o carregamento de modelos públicos, caso a
		-- configuração Allow Loading Third Party Assets já esteja habilitada.
		local inventoryError = tostring(result)
		ok, result = pcall(function()
			return AssetService:LoadAssetAsync(ACADEMY_SOCCER_BALL_ID)
		end)
		method = "AssetService"
		if not ok or typeof(result) ~= "Instance" then
			warn("[CL27] Academy soccer ball indisponível. A experiência precisa ser da conta que adquiriu o modelo, ou ter acesso autorizado. InsertService: " .. inventoryError .. "; AssetService: " .. tostring(result))
			return
		end
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
	print("[CL27] Bola Academy preparada via " .. method .. ": " .. tostring(count) .. " partes visuais.")
end)

-- Bayern Stadium é carregado em segundo plano e isolado do lobby anterior.
-- Uma falha na permissão de modelos terceiros NÃO altera a experiência.
local StadiumLoader = require(script.Parent.StadiumLoader)
StadiumLoader.start()
