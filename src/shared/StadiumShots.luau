--!strict
-- Plano de dez tomadas; utiliza SOMENTE geometria localizada no modelo.
-- Não pressupõe coordenadas fixas do Bayern Stadium nem inventa túneis.
local StadiumShots = {}
StadiumShots.ASSET_ID = 18593817379
StadiumShots.DURATION = 8
StadiumShots.FADE = 0.48

local function shot(name: string, zone: string, startPos: Vector3, endPos: Vector3, target: Vector3, clock: number, fov: number)
	return {
		name = name,
		zone = zone,
		start = CFrame.lookAt(startPos, target),
		finish = CFrame.lookAt(endPos, target),
		clock = clock,
		fov = fov,
	}
end

-- pitch: center, lengthAxis, widthAxis, halfLength, halfWidth, y.
-- hints: posições de banco/túnel, apenas quando detectadas pelo loader.
function StadiumShots.build(pitch, hints)
	assert(pitch and pitch.center and pitch.lengthAxis and pitch.widthAxis)
	assert(pitch.halfLength > 15 and pitch.halfWidth > 10, "Campo não identificado")
	local l, w = pitch.lengthAxis.Unit, pitch.widthAxis.Unit
	local hl, hw = pitch.halfLength, pitch.halfWidth
	local center = Vector3.new(pitch.center.X, pitch.y, pitch.center.Z)
	local function at(long: number, wide: number, height: number)
		return center + l * (long * hl) + w * (wide * hw) + Vector3.new(0, height, 0)
	end
	local cards = {}
	local function add(name,zone,a,b,look,clock,fov)
		table.insert(cards, shot(name,zone,a,b,look,clock,fov))
	end

	-- Planos de gramado e arquibancada são calculados relativamente ao
	-- gramado efetivamente detectado, sem posições globais improvisadas.
	add("Visão geral do gramado","Gramado",
		at(-0.40,1.55,19),at(0.22,1.45,17),at(0,0,1),16.3,53)
	add("Linha lateral","Gramado",
		at(-0.62,0.87,3.4),at(-0.22,0.91,3.8),at(0.16,0.04,1.5),17.15,47)
	add("Círculo central","Gramado",
		at(-0.22,0.31,2.8),at(0.13,0.33,2.9),at(0.55,-0.07,1.1),14.4,43)

	if hints.bench then
		local target = hints.bench
		add("Banco de reservas","Banco confirmado",
			target + w * 11 + Vector3.new(0,3.7,0),
			target + w * 8 + l * 2 + Vector3.new(0,3.8,0),
			target + Vector3.new(0,1.3,0),18.0,47)
	else
		add("Faixa técnica","Lateral do campo",
			at(0.55,-0.96,4.1),at(0.2,-1.04,4.5),at(0.02,-0.05,1),18.0,48)
	end

	add("Arquibancada principal","Arquibancada estimada pelo campo",
		at(-0.25,2.02,27),at(0.23,2.04,26),at(0,0,2),20.5,55)
	if hints.tunnel then
		local target = hints.tunnel
		local towardPitch = center - target
		local direction = if towardPitch.Magnitude > 0.01 then towardPitch.Unit else w
		add("Túnel de acesso","Túnel confirmado",
			target - direction*8 + Vector3.new(0,2.7,0),
			target - direction*3 + Vector3.new(0,2.7,0),
			target + direction*6 + Vector3.new(0,2.2,0),19.6,49)
	else
		add("Entrada do campo","Gramado — túnel não localizado",
			at(0.95,0.3,5),at(0.9,0.05,4.4),at(0.2,0,1),19.6,47)
	end

	add("Atrás da baliza","Gramado",
		at(1.17,0.27,5.8),at(1.2,-0.19,6.4),at(-0.12,0,1.8),21.1,54)
	add("Arquibancada oposta","Arquibancada estimada pelo campo",
		at(0.45,-1.95,25),at(0,-2.0,26),at(0,0,1.8),21.3,51)

	if hints.bench then
		local target = hints.bench
		add("Detalhe da área técnica","Banco confirmado",
			target + w*6 + l*3 + Vector3.new(0,2.9,0),
			target + w*5 - l*2 + Vector3.new(0,3,0),
			target + Vector3.new(0,1.3,0),16.0,44)
	else
		add("Bandeirinha e lateral","Gramado",
			at(-0.84,-0.86,3.5),at(-0.62,-0.89,4.1),at(0.22,-0.15,1),16.0,48)
	end

	add("Panorama do estádio","Arquibancadas e gramado",
		at(0.38,1.95,33),at(-0.3,1.92,31),at(0,0,0),20.0,58)
	assert(#cards == 10, "Plano cinematográfico incompleto")
	return cards
end
return StadiumShots
