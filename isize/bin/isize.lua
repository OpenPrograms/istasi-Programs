local component = require ('component')
local oScreen = component.screen.address

local screens = dofile ( '/usr/lib/ilib/difference.lua' )
screens:setDefault ( dofile ( '/usr/lib/ilib/screen.lua' ) )

for address in component.list ('screen',true) do
	screens:add ({['address'] = address})
end

screens:each ( function ( screen )
	screen:active ()

	screen:set ( 1,1, 'yolo' )
end )


component.gpu.bind ( component.screen.address )
