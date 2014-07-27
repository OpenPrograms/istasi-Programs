local component = require('component')

local screen = {
	['address'] = component.list('screen', true) (),
	['gpu'] = component.list('gpu') (),

	['bgColor'] = 0x000000,
	['fgColor'] = 0xFFFFFF,

	['active'] = function ( self )
		component.invoke ( self.gpu, 'bind', self.address )
	end,

	['clear'] = function ( self )
		local size = ({self:maxResolution()})

		self:setBGColor () self:setFGColor ()
		component.invoke ( self.gpu, 'fill', 1,1, size[1],size[2], ' ' )
		
		return self
	end,
	['set'] = function ( self, x,y, message, vertical )
		self:setBGColor () self:setFGColor ()
		component.invoke ( self.gpu, 'set', x,y, message )
		return self
	end,
	['fill'] = function ( self, x,y, width,height, char )
		self:setBGColor () self:setFGColor ()
		component.invoke ( self.gpu, 'fill', x,y, width,height, char )
		return self
	end,
	['setBGColor'] = function ( self, color )
		if color == nil then
			if component.invoke ( self.gpu, 'getBackground' ) ~= self.bgColor then
				component.invoke ( self.gpu, 'setBackground', self.bgColor ) 
			end
			return true
		end
		if type(color) == 'string' then
			local tmp = color:match ( '0x([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])' )
			assert ( tmp, 'screen.setBGColor, bad color recieved, unable to parse' )
			
			color = tonumber(tmp,16)
		end
	
		self.bgColor = color
	end,
	['setFGColor'] = function ( self, color )
		if color == nil then
			if component.invoke ( self.gpu, 'getForeground' ) ~= self.fgColor then
				component.invoke ( self.gpu, 'setForeground', self.fgColor ) 
			end
			return true
		end
		if type(color) == 'string' then
			local tmp = color:match ( '0x([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])' )
			assert ( tmp, 'screen.setFGColor, bad color recieved, unable to parse' )
			
			color = tonumber(tmp,16)
		end

		self.fgColor = color
	end,
	['maxResolution'] = function ( self )
		return component.invoke ( self.gpu, 'maxResolution' )
	end,
}

return screen
