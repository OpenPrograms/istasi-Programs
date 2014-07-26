local component = require( 'component' )
local shell = require ('shell' )
local unicode = require('unicode')
local event = require('event')

local originalScreen = component.screen.address

local elevator = component.list ('elevator', true) ()
local floors = {}

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

local screens = { ['each'] = function ( self, callback ) for _,screen in ipairs ( self ) do callback ( screen ) end end }

local s = require('ivator/screen')
local gpu = component.list('gpu',true)

for address in component.list('screen',true) do
	local o = dofile ( '/usr/lib/ivator/screen.lua' )
	o.address = address

	table.insert ( screens, o )
end



local high = 1
for k,v in pairs ( floors ) do high = math.max ( high, k ) end

local boxes = {['default'] = dofile ( '/usr/lib/ivator/box.lua' )}
local box = dofile ( '/usr/lib/ivator/box.lua' )
local zone = dofile ( '/usr/lib/ivator/zone.lua' )
local first = true

screens:each ( function ( screen )
	screen:active ()
	screen:clear ()
	

	for i = 1,high do
		local width = screen:maxResolution ()
		if first == true then
			boxes [i] = dofile ( '/usr/lib/ivator/box.lua' )
		end
		local box = boxes [i]
		box.screen = screen

		box.width = width / 4
		box.height = 5

		box.x = (width / 3) * ((i - 1) % 3) + ((width/3 - width/4) / 2)
		box.y =  ((box.height + 2) * math.ceil (i/3)) - 3

		box.name = i
		if floors [i] == nil then
			box.image = {
				{
					{
						['char'] = ' ',
						['color'] = 0xFFFFFF,
						['background'] = 0x666666,
					},
				},
			}
		else
			box.image = boxes['default'].image
		end
		box:draw ()

		if first == true then
			zone:add ( box.x,box.y, box.width,box.height, i )
		end
	end

	first = false
end )

local trollEvent = {
	['elevator_stopped'] = function (floor)
		screens:each ( function (screen ) 
			screen:active ()

			for i=1,high do
				if floors [i] ~= nil and i ~= floor  and boxes [i].target == nil then
					boxes [i].image = boxes['default'].image
					boxes [i]:draw ()
				end
			end

			boxes [floor].image = {
				{
					{
						['char'] = ' ',
						['color'] = 0xFFFFFF,
						['background'] = 0x666699,
					},
				},
			}
			boxes [floor]:draw ( screen )
		end)
	end,
}

local continue = true
while continue == true do
	local e, _, x,y, button = event.pull()

	if e == 'touch' then
		local result = zone:get (x,y)
		if result ~= nil and floors [result.values] ~= nil then
			component.invoke ( elevator, 'call', result.values )
			boxes [result.values].target = true

			screens:each ( function ( screen )
				local box = boxes [result.values]
				box.image = {
					{
						{
							['char'] = ' ',
							['color'] = 0xFFFFFF,
							['background'] = 0x996666,
						},
					},
				}

				screen:active () 
				box:draw ( screen )
			end )

			local continue = true
			while continue == true do
				os.sleep(0.1)

				local floor = component.invoke ( elevator, 'getElevatorFloor' )
				if floors [floor] ~= nil then
					screens:each ( function ( screen ) 
						trollEvent ['elevator_stopped'] (floor)
					end )
				end

				if component.invoke ( elevator, 'isReady' ) == true then
					boxes [result.values].target = nil

					trollEvent ['elevator_stopped'] (result.values)
					continue = false
				end
			end
		end
	elseif e == 'key_down' and x == 113 then
		continue = false
	end
end

screens:each ( function (screen) screen:active () screen:setFGColor ( 0xFFFFFF ) end )
screens:each ( function (screen) screen:active () screen:setBGColor ( 0x0000000 ) end )
screens:each ( function (screen) screen:active () screen:clear () end )

if component.gpu.getScreen ~= originalScreen then component.gpu.bind ( originalScreen ) end
