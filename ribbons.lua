-- ribbons: folded euclidean arp
-- for arc
-- 1.0.0 @tehn
--
-- K3 emulates arc key
--    for old edition arcs

a = arc.connect(1)
out = midi.connect(1)
p = params

notes = {
	{0, 2, 3, 5, 7, 8, 11, 12},
	{0, 2, 3, 5, 7, 9, 11, 12},
	{0, 2, 3, 5, 7, 9, 10, 12},
	{0, 1, 3, 5, 7, 8, 10, 12},
	{0, 2, 4, 6, 7, 9, 11, 12},
	{0, 2, 4, 5, 7, 9, 10, 12},
	{0, 1, 3, 5, 6, 8, 10, 12}
}

function init()
	p:add_number("steps","steps",2,48,3)
	p:add_number("span","span",2,48,14)
	p:add_number("range","range",1,48,14)
	p:add_number("offset","offset",0,16,0)
	p:add_number("scale","scale",1,7,1)
	p:add_number("root","root",0,96,48)
	p:add_number("direction","direction",0,1,1)
	p:set_action("steps",regen)
	p:set_action("span",regen)
	p:set_action("range",regen)
	p:set_action("offset",regen)
	p:set_action("scale",regen)
	regen()
	clock.run(tick)
	clock.run(re)
end

function note(z)
	return notes[p:get('scale')][(z+6)%7+1] + math.floor((z-1)/7)*12
end

function er(k, n)
	w = w or 0
	local r = {}
	if k<1 then return r end
	local b = n
	for i=1,n do
		if b >= n then
			b = b - n
			local j = i
			while (j > n) do j = j - n end
			while (j < 1) do j = j + n end
			table.insert(r,j)
		end
		b = b + k
	end
	return r
end

alt = false
pol = true

ribbon = {{},{},{}}
now = {{},{},{}}
for i=1,3 do
	ribbon[i].notes = {}
	now[i].pos = 1
	now[i].on = false
	now[i].note = 0
end

function regen()
	x = 1
	if p:get('steps') > p:get('span') then p:set('steps',p:get('span')) end
	local n = er(p:get('steps'),p:get('span'))
	ribbon[x].notes = {}
	for i = 1,p:get('steps') do
		local z = ((n[i]+p:get('range')-1) % p:get('range') + 1) + p:get('offset')
		ribbon[x].notes[i] = note(z)
	end
end


function re()
	while true do
		if dirty then
			dirty = false
			aredraw()
		end
		clock.sleep(1/60)
	end
end

ticks = {0,0,0,0}
SENS = 32

function a.delta(n,d)
	ticks[n] = ticks[n] + d
	local val = 0
	if math.abs(ticks[n]) >= SENS then
		val= ticks[n] / SENS
		val= (val> 0) and math.floor(val) or math.ceil(val)
		ticks[n] = math.fmod(ticks[n],SENS)
	else
		val = 0
	end

	if val ~= 0 then
		if not alt then
			if n==1 then
				p:delta('offset',d)
			elseif n==2 then
				p:delta('steps',d)
				--p:set('steps',util.clamp(p:get('steps') + d, 2, p:get('span')))
			elseif n==3 then
				p:delta('range',d)
			elseif n==4 then
				p:delta('clock_tempo',d/4)
			end
		else
			if n==1 then
				p:delta('scale',d)
			elseif n==2 then
				p:delta('span',d)
				--p:set('span', util.clamp(p:get('span') + d, 2, 48))
				--p:set('steps',util.clamp(p:get('steps'), 2, p:get('span')))
			elseif n==3 then
				p:delta('direction',d)
			elseif n==4 then
				p:delta('root',d)
				regen()
			end
		end
		regen()
		dirty = true
	end
end

function a.key(n,z)
	if z == 1 then
		alt = true
	else
		alt = false
	end
	dirty = true
end

function key(n,z)
	if n==3 then a.key(1,z) end
end

function aredraw()
	a:all(0)

	if not alt then
		for i=1,p:get('steps') do
			a:led(1,(ribbon[1].notes[i]+40)%64+1,3)
		end
		a:led(1,(now[1].note-p:get('root')+40)%64+1,15)

		for i=1,p:get('span') do a:led(2,(i+40)%64+1,1) end
		for i=1,p:get('steps') do a:led(2,(i+40)%64+1,5) end
		a:led(2,(now[1].pos+40)%64+1,15)

		if p:get('range') <= p:get('span') then
			for i=1,p:get('span') do a:led(3,(i+40)%64+1,i>p:get('range') and 1 or 5) end
		else
			for i=1,p:get('span') do a:led(3,(i+40)%64+1,5) end
			a:led(3,(p:get('range')+40)%64+1,1)
		end

		point(4,p:get('clock_tempo')*3+480)

	else
		for i=1,p:get('steps') do a:led(1,(ribbon[1].notes[i]+40)%64+1,1) end
		a:led(1,(now[1].note-p:get('root')+40)%64+1,5)
		for i=1,7 do a:led(1,i+28,3) end
		a:led(1,p:get('scale')+28,15)
		for i=1,p:get('span') do a:led(2,(i+40)%64+1,3) end
		for i=1,p:get('steps') do a:led(2,(i+40)%64+1,5) end

		a:led(2,(now[1].pos+40)%64+1,15)
		if p:get('range') <= p:get('span') then
			for i=1,p:get('span') do a:led(3,(i+40)%64+1,i>p:get('range') and 1 or 5) end
		else
			for i=1,p:get('span') do a:led(3,(i+40)%64+1,5) end
			a:led(3,(p:get('range')+40)%64+1,1)
		end
		a:led(3,35,1)
		a:led(3,31,1)
		a:led(3,p:get('direction')==1 and 35 or 31, 9)

		a:led(4,(p:get('root')+ 18) % 64 + 1, 15)
	end
	a:refresh()
end

function tick()
	while true do
		if pol then
			now[1].pos = now[1].pos + (p:get('direction')*2-1)
			if now[1].pos > p:get('steps') then now[1].pos = 1
			elseif now[1].pos == 0 then now[1].pos = p:get('steps') end
			now[1].note = p:get('root')+ ribbon[1].notes[now[1].pos]
			now[1].on= true
			out:note_on(now[1].note)
		else
			now[1].on= false
			out:note_off(now[1].note)
		end
		pol = not pol
		dirty = true
		clock.sync(1/8)
	end
end

function point(n,y)
	x = math.floor(y)
	local c = x >> 4
	a:led(n,c%64+1,15)
	a:led(n,(c+1)%64+1,x%16)
	a:led(n,(c+63)%64+1,15-(x%16))
end

function redraw()
	screen.clear()
	screen.move(10,40)
	screen.text("ribbons")
	screen.update()
end


