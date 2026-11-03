--!strict
-- Câmera cinematográfica: 10 tomadas reais, 8 s cada, em ordem fixa.
-- O fade fica abaixo do HomeHUD, preservando a leitura dos cinco botões.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local StadiumShots = require(game:GetService("ReplicatedStorage").CL27.StadiumShots)

local Cinematics = {}
local BASE_EXPOSURE = -0.05

local function element(className: string, parent: Instance, properties)
	local object = Instance.new(className)
	for key, value in pairs(properties) do
		(object :: any)[key] = value
	end
	object.Parent = parent
	return object
end

local function validate(registry: Instance)
	if registry:GetAttribute("Status") ~= "Ready"
		or registry:GetAttribute("AssetId") ~= StadiumShots.ASSET_ID then return nil end
	local folder = registry:FindFirstChild("CameraShots")
	if not folder then return nil end
	local shots = {}
	for _, item in ipairs(folder:GetChildren()) do
		if item:IsA("Folder") then
			local index = item:GetAttribute("Index")
			local begin = item:FindFirstChild("Inicio")
			local finish = item:FindFirstChild("Fim")
			if typeof(index) == "number" and index >= 1 and index <= 10
				and begin and begin:IsA("CFrameValue")
				and finish and finish:IsA("CFrameValue") then
				shots[index] = {
					name = item:GetAttribute("Label") or "",
					zone = item:GetAttribute("Zone") or "Gramado",
					start = begin.Value,
					finish = finish.Value,
					fov = item:GetAttribute("Fov") or 48,
					clock = item:GetAttribute("ClockTime") or 18,
				}
			end
		end
	end
	for index = 1, 10 do
		if not shots[index] then return nil end
	end
	return shots
end

function Cinematics.new(registry: Instance, settings)
	local shots = validate(registry)
	if not shots then return nil end
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not playerGui then return nil end

	local gui = element("ScreenGui", playerGui, {
		Name = "CL27_StadiumCinematics",
		DisplayOrder = 45,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	local fade = element("Frame", gui, {
		Name = "CorteCinematografico",
		Size = UDim2.fromScale(1,1),
		BackgroundColor3 = Color3.fromRGB(4,11,14),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ZIndex = 1,
		Active = false,
	})
	local self = setmetatable({
		shots = shots,
		gui = gui,
		fade = fade,
		settings = settings or {},
		shotIndex = 1,
		shotElapsed = 0,
		totalTime = 0,
		alive = true,
	}, {__index = Cinematics})
	return self
end

function Cinematics:Step(dt: number)
	if not self.alive then return nil end
	local duration = StadiumShots.DURATION
	local fadeTime = if self.settings.reducedMotion then 0.12 else StadiumShots.FADE
	self.shotElapsed += math.min(math.max(dt,0),0.12)
	self.totalTime += math.min(math.max(dt,0),0.12)
	if self.shotElapsed >= duration then
		self.shotElapsed -= duration
		self.shotIndex = self.shotIndex % #self.shots + 1
	end

	local shot = self.shots[self.shotIndex]
	local progress = math.clamp(self.shotElapsed / duration,0,1)
	local ease = progress * progress * (3-2*progress)
	if self.settings.reducedMotion then ease = 0 end
	local frame = shot.start:Lerp(shot.finish, ease)

	local visibility = 1
	if self.shotElapsed < fadeTime then
		visibility = self.shotElapsed / fadeTime
	elseif self.shotElapsed > duration - fadeTime then
		visibility = (duration-self.shotElapsed)/fadeTime
	end
	self.fade.BackgroundTransparency = math.clamp(visibility,0,1)

	-- A troca de horário ocorre quando a cena está encoberta.
	-- A grade de cor e o cenário 3D permanecem os mesmos.
	Lighting.ClockTime = shot.clock
	Lighting.ExposureCompensation = BASE_EXPOSURE
	Lighting.Brightness = if shot.clock >= 19 then 2.2 else 2.5
	return frame, frame.Position + frame.LookVector*25, shot.fov
end

function Cinematics:SetSettings(settings)
	self.settings = settings
end

function Cinematics:Destroy()
	if not self.alive then return end
	self.alive = false
	self.gui:Destroy()
end

return Cinematics
