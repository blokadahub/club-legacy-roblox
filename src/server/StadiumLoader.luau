--!strict
-- Importador seguro para o modelo Bayern Stadium do Creator Store.
-- Não publica nem executa os scripts do autor. Mantém o lobby antigo caso
-- a permissão, a estrutura ou a geometria do gramado sejam incompatíveis.
local AssetService = game:GetService("AssetService")
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local StadiumShots = require(ReplicatedStorage.CL27.StadiumShots)

local Loader = {}
local ASSET_ID = StadiumShots.ASSET_ID
local MAX_PARTS = 15000
local TARGET_CENTER = Vector3.new(0, 0, -2500)

local function registry()
	local folder = ReplicatedStorage:FindFirstChild("CL27Stadium")
	if folder then return folder end
	folder = Instance.new("Folder")
	folder.Name = "CL27Stadium"
	folder:SetAttribute("Status", "Loading")
	folder:SetAttribute("AssetId", ASSET_ID)
	folder.Parent = ReplicatedStorage
	return folder
end

local function loadModel()
	local ok, result = pcall(function()
		return AssetService:LoadAssetAsync(ASSET_ID)
	end)
	if ok and typeof(result) == "Instance" and result:IsA("Model") then
		return result :: Model, "AssetService"
	end
	local assetError = tostring(result)
	-- Para o caso de o criador já ter adquirido e autorizado o asset.
	ok, result = pcall(function()
		return InsertService:LoadAsset(ASSET_ID)
	end)
	if ok and typeof(result) == "Instance" and result:IsA("Model") then
		return result :: Model, "InsertService"
	end
	return nil, "AssetService: " .. assetError .. "; InsertService: " .. tostring(result)
end

local function sanitized(model: Model): number
	-- Nenhum código, RemoteEvent, Prompt, som ou mecanismo externo é mantido.
	-- A limpeza é concluída ANTES de parentear o estádio ao Workspace.
	local count = 0
	for _, item in ipairs(model:GetDescendants()) do
		if item:IsA("LuaSourceContainer")
			or item:IsA("RemoteEvent")
			or item:IsA("RemoteFunction")
			or item:IsA("BindableEvent")
			or item:IsA("BindableFunction")
			or item:IsA("ProximityPrompt")
			or item:IsA("ClickDetector")
			or item:IsA("Sound")
			or item:IsA("Humanoid")
			or item:IsA("AnimationController")
			or item:IsA("Animator") then
			item:Destroy()
		elseif item:IsA("BasePart") then
			count += 1
			if count > MAX_PARTS then return count end
			item.Anchored = true
			item.CanCollide = false
			item.CanTouch = false
			item.CanQuery = true
			item.AssemblyLinearVelocity = Vector3.zero
			item.AssemblyAngularVelocity = Vector3.zero
		end
	end
	return count
end

local function contains(haystack: string, words): boolean
	for _, word in ipairs(words) do
		if string.find(haystack, word, 1, true) then return true end
	end
	return false
end

local function findPitch(model: Model)
	local best, highest = nil, 0
	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("BasePart") then
			local part = object :: BasePart
			local size = part.Size
			local upwards = math.abs(part.CFrame.UpVector:Dot(Vector3.yAxis))
			if upwards > 0.83 and size.Y < 18
				and math.max(size.X, size.Z) > 42
				and math.min(size.X, size.Z) > 24 then
				local names = string.lower(part.Name .. " " .. part.Parent.Name)
				local named = contains(names, {"grass","pitch","field","turf","gramado","campo","soccer","football"})
				local color = part.Color
				local green = color.G > 0.23 and color.G > color.R * 1.12 and color.G > color.B * 1.04
				local area = size.X * size.Z
				local score = area * (if named then 2.6 elseif green then 1.35 else 0.09)
				if score > highest and (named or green) then
					best, highest = part, score
				end
			end
		end
	end
	if not best then return nil end
	local lengthAxis = if best.Size.X >= best.Size.Z then best.CFrame.RightVector else best.CFrame.LookVector
	local widthAxis = if best.Size.X >= best.Size.Z then best.CFrame.LookVector else best.CFrame.RightVector
	local halfLength = math.max(best.Size.X,best.Size.Z)/2
	local halfWidth = math.min(best.Size.X,best.Size.Z)/2
	local y = best.Position.Y + best.Size.Y/2
	return {
		center = best.Position,
		lengthAxis = Vector3.new(lengthAxis.X,0,lengthAxis.Z),
		widthAxis = Vector3.new(widthAxis.X,0,widthAxis.Z),
		halfLength = halfLength,
		halfWidth = halfWidth,
		y = y,
		part = best,
	}
end

local function findLandmarks(model: Model)
	local hints = {}
	for _, item in ipairs(model:GetDescendants()) do
		if hints.bench and hints.tunnel then break end
		if item:IsA("Model") or item:IsA("BasePart") then
			local name = string.lower(item.Name)
			local bench = contains(name, {"dugout","substitute","substitution","banco","bench","technical area"})
			local tunnel = contains(name, {"tunnel","tunel","túnel","players entrance","player entrance"})
			if (bench and not hints.bench) or (tunnel and not hints.tunnel) then
				local position
				if item:IsA("Model") then
					local ok, pivot = pcall(function() return item:GetPivot() end)
					if ok then position = pivot.Position end
				else
					position = item.Position
				end
				if position then
					if bench and not hints.bench then hints.bench = position end
					if tunnel and not hints.tunnel then hints.tunnel = position end
				end
			end
		end
	end
	return hints
end

local function markers(folder: Instance, shots)
	local previous = folder:FindFirstChild("CameraShots")
	if previous then previous:Destroy() end
	local collection = Instance.new("Folder")
	collection.Name = "CameraShots"
	for index, shot in ipairs(shots) do
		local marker = Instance.new("Folder")
		marker.Name = string.format("Camera_%02d",index)
		marker:SetAttribute("Index",index)
		marker:SetAttribute("Label",shot.name)
		marker:SetAttribute("Zone",shot.zone)
		marker:SetAttribute("ClockTime",shot.clock)
		marker:SetAttribute("Fov",shot.fov)
		local begin = Instance.new("CFrameValue")
		begin.Name = "Inicio"
		begin.Value = shot.start
		begin.Parent = marker
		local finish = Instance.new("CFrameValue")
		finish.Name = "Fim"
		finish.Value = shot.finish
		finish.Parent = marker
		marker.Parent = collection
	end
	collection.Parent = folder
	folder:SetAttribute("ShotCount",#shots)
end

function Loader.start()
	local info = registry()
	task.spawn(function()
		if not info.Parent then return end
		local existing = Workspace:FindFirstChild("CL27_BayernStadium")
		local model, method
		if existing and existing:IsA("Model") then
			model,method = existing,"Workspace"
		else
			model,method = loadModel()
		end
		if not model then
			info:SetAttribute("Status","Unavailable")
			info:SetAttribute("Reason","PERMISSION_OR_ASSET_ERROR")
			warn("[CL27 Stadium] Bayern Stadium indisponível: " .. tostring(method))
			return
		end
		local owned = method ~= "Workspace"
		local ok, message = pcall(function()
			local count = sanitized(model :: Model)
			if count < 10 or count > MAX_PARTS then
				error("Número de peças incompatível: " .. tostring(count))
			end
			if owned then
				local bounds = (model :: Model):GetBoundingBox()
				local move = TARGET_CENTER - bounds.Position
				(model :: Model):PivotTo(CFrame.new(move) * (model :: Model):GetPivot())
			end
			local pitch = findPitch(model :: Model)
			if not pitch then
				error("Gramado não identificável: requer calibragem no Roblox Studio.")
			end
			local hints = findLandmarks(model :: Model)
			local shots = StadiumShots.build(pitch, hints)
			markers(info,shots)
			(model :: Model).Name = "CL27_BayernStadium"
			(model :: Model):SetAttribute("SourceAssetId",ASSET_ID)
			(model :: Model):SetAttribute("SafeVisualOnly",true)
			if not (model :: Model).Parent then (model :: Model).Parent = Workspace end
			info:SetAttribute("PartCount",count)
			info:SetAttribute("PitchDetected",true)
			info:SetAttribute("BenchDetected",hints.bench~=nil)
			info:SetAttribute("TunnelDetected",hints.tunnel~=nil)
			info:SetAttribute("Status","Ready")
			print(string.format("[CL27 Stadium] Pronto (%s): %d peças, 10 tomadas; banco=%s; túnel=%s",
				tostring(method),count,tostring(hints.bench~=nil),tostring(hints.tunnel~=nil)))
		end)
		if not ok then
			info:SetAttribute("Status","Unavailable")
			info:SetAttribute("Reason","GEOMETRY_OR_BUDGET")
			warn("[CL27 Stadium] O lobby original foi preservado: "..tostring(message))
			if owned and model then model:Destroy() end
		end
	end)
	return info
end
return Loader
