--!nonstrict
-- Only mapped by the independent experiment. No HUD, avatars or gameplay.
local Scene = require(script.Parent.TunnelScene)
local quality = script:GetAttribute("Quality") or "Medium"
local preview = workspace:FindFirstChild("CinematicTunnelPreview")
if preview then preview:Destroy() end
local scene = Scene.new({quality=quality,takeOverLighting=true,camera=true,
	animate=script:GetAttribute("Animate") == true,reducedMotion=script:GetAttribute("ReducedMotion") ~= false})
local connections = {}
local function motion()
	scene:SetMotion(script:GetAttribute("Animate") == true,script:GetAttribute("ReducedMotion") ~= false)
end
table.insert(connections,script:GetAttributeChangedSignal("Quality"):Connect(function()
	local ok, err = pcall(function() scene:ApplyQuality(script:GetAttribute("Quality") or "Medium") end)
	if not ok then warn("[Tunnel] "..tostring(err)) end
end))
table.insert(connections,script:GetAttributeChangedSignal("EffectsEnabled"):Connect(function()
	scene:SetEffectsEnabled(script:GetAttribute("EffectsEnabled") ~= false)
end))
for _, key in ipairs({"Animate","ReducedMotion"}) do
	table.insert(connections,script:GetAttributeChangedSignal(key):Connect(motion))
end
scene:SetEffectsEnabled(script:GetAttribute("EffectsEnabled") ~= false)
table.insert(connections,script.Destroying:Connect(function()
	for _, connection in ipairs(connections) do connection:Disconnect() end
	table.clear(connections)
	scene:Destroy()
end))
