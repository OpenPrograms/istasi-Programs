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
setmetatable ( screens, { -- So slow.
	['__index'] = function ( self, key )
		if type(key) == 'string' and self [1] ~= nil and self [1][key] ~= nil then
			return function ( ... )
				for _,screen in ipairs ( self ) do
					screen [key] ( screen, ... )
				end
			end
		else
			error ( 'call to invalid function' )
		end
	end,
} )

local gpu = component.list('gpu',true)
for address in component.list('screen',true) do
	local screen = dofile ( shell.resolve('/lib/iVator/screen.lua') )
	screen.address = address

	table.insert ( screens, screen )
end



local high = 1
for k,v in pairs ( floors ) do high = math.max ( high, k ) end

local box = dofile ( shell.resolve ('/lib/iVator/box.lua') )
local zone = dofile ( shell.resolve ( '/lib/iVator/zone.lua') )
local zoneSet = true

screens:each ( function ( screen )
	screen:active ()
	screen:clear ()
	box.screen = screen

	for i = 1,high do
		local width = screen:maxResolution ()

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
			box.image = {
				{
					{
						['char'] = ' ',
						['color'] = 0xFFFFFF,
						['background'] = 0x669966,
					},
				},
			}
		end
		box:draw ()

		if zoneSet == true then
			zone:add ( box.x,box.y, box.width,box.height, i )
		end
	end

	zoneSet = false
end )

local continue = true
while continue == true do
	local e, _, x,y, button = event.pull()

	if e == 'touch' then
		local result = zone:get (x,y)
		if result ~= nil then
			component.invoke ( elevator, 'call', result.values )
		end
	elseif e == 'key_down' and x == 113 then
		continue = false
	end
end

if component.gpu.getScreen ~= originalScreen then component.gpu.bind ( originalScreen ) end
