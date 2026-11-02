-- CL_SCAFFOLD_PLACEHOLDER
-- Base tecnica. Substitua este arquivo integralmente pela interface do CL - Club Legacy.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
print(("[CL - Club Legacy] Cliente preparado: %s"):format(Config.VERSION))
