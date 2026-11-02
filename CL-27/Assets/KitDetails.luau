-- Grafismos geométricos próprios: renderizam em ViewportFrame sem SurfaceGui.
local KitDetails = {}
local digits = {
	[0]={1,2,3,4,5,6}, [1]={2,3}, [2]={1,2,7,5,4}, [3]={1,2,3,4,7},
	[4]={6,7,2,3}, [5]={1,6,7,3,4}, [6]={1,6,5,4,3,7},
	[7]={1,2,3}, [8]={1,2,3,4,5,6,7}, [9]={1,2,3,4,6,7},
}
local segments = {
	{0,0.34,true},{0.2,0.17,false},{0.2,-0.17,false},{0,-0.34,true},
	{-0.2,-0.17,false},{-0.2,0.17,false},{0,0,true},
}

function KitDetails.number(model, number, center, color, scale, createPart)
	local text=tostring(number)
	for index=1,#text do
		local digit=tonumber(text:sub(index,index))
		for _, segment in ipairs(digits[digit]) do
			local s=segments[segment]
			local x=(index-(#text+1)/2)*0.58+s[1]
			local size=s[3] and Vector3.new(0.35,0.055,0.025) or Vector3.new(0.055,0.27,0.025)
			createPart(model,"Numero",size*scale,center*CFrame.new(x*scale,s[2]*scale,0),color)
		end
	end
end

function KitDetails.crest(model, identity, createPart)
	local base=CFrame.new(-0.48,3.28,-0.46)
	createPart(model,"Emblema",Vector3.new(0.30,0.34,0.035),base,identity.secondary,identity.crest=="Círculo" and Enum.PartType.Ball or Enum.PartType.Block)
	if identity.crest=="Monograma" then
		for _, side in ipairs({-1,1}) do
			createPart(model,"Monograma",Vector3.new(0.025,0.20,0.02),base*CFrame.new(side*0.045,0,-0.03)*CFrame.Angles(0,0,side*-0.35),identity.primary)
		end
		createPart(model,"Travessao",Vector3.new(0.13,0.025,0.02),base*CFrame.new(0,-0.015,-0.03),identity.primary)
	else
		createPart(model,"Assinatura",Vector3.new(0.14,0.035,0.02),base*CFrame.new(0,0.04,-0.03),identity.primary)
		createPart(model,"Assinatura",Vector3.new(0.10,0.035,0.02),base*CFrame.new(0,-0.04,-0.03),identity.primary)
	end
end

return KitDetails
