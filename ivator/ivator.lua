local component = require( 'component' )
local shell = require ('shell' )
local unicode = require('unicode')

local serialize = dofile ('/usr/lib/ilib/serialize.lua')
local eventHandler = dofile ('/usr/lib/ilib/eventHandler.lua')
local event = eventHandler.create ()

local elevator = component.list ('elevator', true) ()
assert ( 'elevator not found' )

local floors = {}
event:timer(0, function ()
	-- Incase the mod ever desides going for more than 16 floors, support we shall have!
	if elevator ~= nil then
		local i,last = 1,1
		while i < last + 16 do
			floors [i], err = component.invoke ( elevator, 'doesFloorExist', i ) or nil

			if err ~= nil then last = i - 16 end
			if floors [i] == true then last = i end

			i = i + 1
		end
	end

	local function buildString ( f )
		local d = ''

		local continue = true
		while continue == true do
			local _, _, u, a = event:pull ( 'key_down' )

			if u ~= 0 then
				d = d .. unicode.char ( u )
				continue, d = f(d)
			end
		end

		return d
	end



	local config, reason = serialize.fromFile ('/usr/etc/ivator.cfg')
	if reason ~= nil then error (reason) end

	local boxes = {}

	local high = 1
	for k,v in pairs ( floors ) do high = math.max ( high, k ) end

	local system = {}
	system.gpu = dofile ('/usr/lib/ilib/gpu.lua')

	system.screens = dofile ('/usr/lib/ilib/difference.lua')
	system.screens:setDefault ( dofile ('/usr/lib/ilib/screen.lua') )
	system.zone = dofile ( '/usr/lib/ivator/zone.lua' )

	event:on ('component_added', function ( _, address, _type )
		if _type ~= 'gpu' then return end

		system.gpu:addGPU (address)
	end )
	event:on ('component_removed', function ( _, address, _type )
		if _type ~= 'gpu' then return end

		system.gpu:removeGPU (address)
	end )

	event:on ('component_added', function ( _, address, _type )
		if _type ~= 'screen' then return end


		local i = false
		system.screens:each ( function ( screen, _i ) if screen.address == address then _i = i end end )

		if i == false then
			i = system.screens:add ({
				['address'] = address,
				['gpu'] = system.gpu:get()
			})
		end

		local screen = system.screens [i]
		screen:active () screen:clear ()

		if config.debug == true then
			screen:set ( 1,1, 'GPU: ' .. tostring(screen.gpu) )

			local str = ' Screen:' .. screen.address
			screen:set ( ({screen:getResolution ()})[1] - str:len(), 1 , str )
		elseif type(config.debug) == 'table' then
			if config.debug.gpu == true then
				screen:set ( 1,1, 'GPU: ' .. tostring(screen.gpu) )
			end

			if config.debug.screen == true then
				local str = ' Screen:' .. screen.address
				screen:set ( ({screen:getResolution ()})[1] - str:len(), 1 , str )
			end
		end

		local width = screen:maxResolution ()
		local cWidth = width / config.box.columns or 3

		for i = 1,high do
			if boxes [i] == nil then
				local box = dofile('/usr/lib/ivator/box.lua')

				if config.box.width == nil or config.box.width < 1 then
					box.width = math.floor (cWidth * config.box.width or 0.9)
				else
					box.width = config.box.width
				end

				box.height = config.box.height or 5

				box.x = ((width / config.box.columns or 3) * ((i - 1) % config.box.columns or 3)) + 1 + (cWidth/2 - box.width/2)
				box.y =  ((box.height + 2) * math.ceil (i/config.box.columns)) - 3

				if config.names and config.names [i] ~= nil then
					box.name = config.names [i]
				else
					box.name = i
				end
				
				if floors [i] == nil then
					box.image = config.box.image.disabled
				else
					box.image = config.box.image.default
				end
				
				boxes[i] = box
				system.zone:add ( box.x,box.y, box.width,box.height, i )
			end

			boxes [i]:draw ( screen )
		end
	end )

	for address in component.list('screen',true) do event:push ('component_added', address, 'screen') end
	
	event:on ( 'elevator_stopped', function ( _, floor)
		system.screens:each ( function ( screen ) 
			for i=1,high do
				if floors [i] ~= nil and i ~= floor  and boxes [i].target == nil then
					screen:active ()

					boxes [i].image = config.box.image.default
					boxes [i]:draw ( screen )
				end
			end
			screen:active ()

			boxes [floor].image = config.box.image.currentlyAt
			boxes [floor]:draw ( screen )
		end )
	end )

	event:on ( 'key_down', function ( _,_, key )
		if unicode.char(key) == 'q' then
			system.screens:each ( function (screen) screen:active() screen:setBGColor ( 0x0000000 ) screen:setFGColor ( 0xFFFFFF ) screen:clear () end )	

			event:push ( 'event-handler.stop' )
		end
	end )

	while true do
		local e, _, x,y, button = event:pull('touch')

		if e == 'touch' then
			local result = system.zone:get (x,y)
			if result ~= nil and button == 0 and floors [result.values] ~= nil then
				component.invoke ( elevator, 'call', result.values )
				boxes [result.values].target = true
				local box = boxes [result.values]

				system.screens:each ( function ( screen )
					box.image = config.box.image.destination

					screen:active () 
					box:draw ( screen )
				end )

				local continue = true
				while continue == true do
					os.sleep(0.1)

					local floor = component.invoke ( elevator, 'getElevatorFloor' )
					if floors [floor] ~= nil then
						system.screens:each ( function ( screen )
							event:push ( 'elevator_stopped', floor )
						end )
					end

					if component.invoke ( elevator, 'isReady' ) == true then
						boxes [result.values].target = nil

						event:push ( 'elevator_stopped', result.values )
						continue = false
					end
				end
			elseif result ~= nil and button == 1 and floors [result.values] ~= nil then
				local box = boxes [result.values]
				box.name = 'Name: '
				box.image = config.box.image.editing

				system.screens:each ( function ( screen ) screen:active () box:draw ( screen ) end )
				local str = buildString ( function ( str )
					local r = true
					if string.byte (unicode.sub ( str, #str, #str )) == 8 then
						str = unicode.sub ( str, 1, #str - 2 )
					elseif string.byte (unicode.sub ( str, #str, #str )) == 13 then
						str = unicode.sub ( str, 1, #str - 1 )
						r = false
					end

					box.name = 'Name: ' .. str
					system.screens:each ( function ( screen )
						screen:active ()
						box:draw ( screen )
					end )

					return r, str
				end )

				if str == '' then str = result.values end
				box.name = str
				box.image = config.box.image.default
				system.screens:each ( function ( screen ) screen:active () box:draw ( screen ) end )

				if config.names == nil then config.names = {} end
				config.names [result.values] = str

				serialize.toFile ( '/usr/etc/ivator.cfg', config, true )
			end
		end
	end
end)

event:on ('error', function ( _, _, message )
	event:push ('event-handler.stop')	-- Lets stop.

	print ( 'Error caught:', message )
end )

eventHandler.handle ()
if component.gpu.getScreen ~= component.screen.address then component.gpu.bind ( component.screen.address ) end
