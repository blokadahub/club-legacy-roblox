--!nonstrict
-- Official Luau CLI runs only the pure descriptor module, never Roblox stubs.
local Geometry = require("../src/TunnelGeometry")
local function json(value)
	if type(value) == "number" then return string.format("%.12g",value) end
	if type(value) == "boolean" then return tostring(value) end
	if type(value) == "string" then
		return '"'..value:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n')..'"'
	end
	assert(type(value) == "table","Unsupported export type")
	local chunks = {}
	if #value > 0 then
		for _, item in ipairs(value) do table.insert(chunks,json(item)) end
		return '['..table.concat(chunks,',')..']'
	end
	local keys = {}
	for key in pairs(value) do table.insert(keys,key) end
	table.sort(keys)
	for _, key in ipairs(keys) do table.insert(chunks,json(key)..':'..json(value[key])) end
	return '{'..table.concat(chunks,',')..'}'
end
local result = {camera=Geometry.lookAt(Geometry.CameraPosition,Geometry.CameraTarget),
	focus=Geometry.frame(table.unpack(Geometry.CameraTarget)),fov=Geometry.FieldOfView,profiles={}}
for _, quality in ipairs({"Low","Medium","High"}) do result.profiles[quality]=Geometry.build(quality) end
print(json(result))
