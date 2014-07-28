local component = require ('component')
local oScreen = component.screen.address

local screens = dofile ( '/usr/lib/ilib/difference.lua' )
screens:setDefault ( dofile ( '/usr/lib/ilib/screen.lua' ) )

local event = require ('event')


for address in component.list ('screen',true) do
	screens:add ({['address'] = address})
end

local function setResolution ( screen, width, height )
	local str = ' ' .. tostring (width) .. ' x ' .. tostring(height) .. ' '

	screen:setBGColor ( 0x6666FF )
	screen:setFGColor ( 0xFFFFFF )

	local size = ({screen:getResolution ()})
	screen:set ( (size[1] - str:len ()) / 2, size[2] / 2, str )

	screen:setResolution ( width, height )

	screen:setBGColor ( 0x9999FF )
end
local function draw ( screen )
	screen:setBGColor ( 0x6666FF )
	screen:setFGColor ( 0xFFFFFF )
	screen:clear ()

	local size = ({screen:getResolution ()})
	setResolution ( screen, size[1], size[2] )

	screen:fill ( 1,1, 3,size[2], ' ' )
	screen:fill ( size[1] - 2,1, 3,size[2], ' ' )

	screen:fill ( 1,size[2]-1, size[1],2, ' ' )
	screen:fill ( 1,1, size[1],2, ' ' )

	screen:fill ( (size[1] - 10) / 2, (size[2]/2)+2, 10, 3, ' ' )
	screen:set ( (size[1] -5) / 2, (size[2]/2)+3, 'Close' )
end
function zone (x,y, width,height) return (function () return {['has']=function (_x,_y) if _x >= x and _x < x + width and _y >= y and _y < y + height then return true end return false end} end) () end

local s = {}
screens:each ( function ( screen, i )
	screen:active ()

	local size = ({screen:getResolution ()})
	s[screen.address] = size

	
	draw ( screen )
end )

local eventHandler = dofile ( 'usr/lib/ilib/eventHandler.lua' )
local event = eventHandler.create ()

event:on ( 'touch', function ( _, address, x,y, button )
	screens:each ( function ( screen )
		if screen.address ~= address then return end
		screen:active ()
		

		local size = ({screen:getResolution ()})
		local maxSize = ({screen:maxResolution ()})

		local max = math.max (size[1],size[2])

		local nWidth = s[screen.address][1]
		local nHeight = s[screen.address][2]

		

		if zone ( 1,1,3,size[2] ).has ( x,y ) == true or zone ( size[1] - 2, 1, 3, size[2] ).has ( x,y ) == true then
			nWidth = nWidth + 1
			if nWidth > max then
				nHeight = nHeight - 1
				nWidth = max
			else
				if nHeight == math.floor (maxSize[1]*maxSize[2] / nWidth) then
					nWidth = math.min ( max, math.floor (maxSize[1]*maxSize[2] / nHeight) )
					nHeight = math.floor (maxSize[1]*maxSize[2] / nWidth)
				else
					nHeight = math.min ( max, math.floor (maxSize[1]*maxSize[2] / nWidth) )
					nWidth = math.floor (maxSize[1]*maxSize[2] / nHeight)
				end
			end

			setResolution ( screen, nWidth, nHeight )
			draw (screen)
		end

		if zone ( 1, 1, size[1], 3 ).has ( x,y ) == true or zone ( 1, size[2] - 2, size[1], 3 ).has ( x,y ) == true then
			nHeight = nHeight + 1
			if nHeight > max then
				nWidth = nWidth - 1
				nHeight = max
			else
				if nWidth == math.floor (maxSize[1]*maxSize[2] / nHeight) then
					nHeight = math.min ( max, math.floor (maxSize[1]*maxSize[2] / nWidth) )
					nWidth = math.floor (maxSize[1]*maxSize[2] / nHeight)
				else
					nWidth = math.min ( max, math.floor (maxSize[1]*maxSize[2] / nHeight) )
					nHeight = math.floor (maxSize[1]*maxSize[2] / nWidth)
				end
			end

			setResolution ( screen, nWidth, nHeight )
			draw (screen)
		end

		s[screen.address][1] = nWidth
		s[screen.address][2] = nHeight

		if zone ( (size[1]-10)/2,(size[2]/2)+2, 10, 3 ).has ( x,y ) == true then
			require('computer').pushSignal('event-handle.stop')
		end

		
	end )
end )

event:on('error', function ( _, _, message )
	eventHandler.push ( 'event-handle.stop' )
	print (message)
end )


eventHandler.handle ()

--component.gpu.bind ( component.screen.address )
