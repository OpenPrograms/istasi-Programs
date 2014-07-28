local component = require('component')

local screen = {
	['address'] = component.list('screen', true) (),
	['gpu'] = setmetatable ({
		['address'] = component.list('gpu') (),
		['bound'] = '',
		['bind'] = function ( self, address )
			if self.bound == address then return end
			
			component.invoke ( self.address, 'bind', address )
			self.bound = address
		end
	}, {['__tostring'] = function ( self ) return self.address end}),

	['bgColor'] = 0x000000,
	['fgColor'] = 0xFFFFFF,

	['active'] = function ( self )
		self.gpu:bind ( self.address )
	end,

	['clear'] = function ( self )
		local size = ({self:maxResolution()})

		self:setBGColor () self:setFGColor ()
		component.invoke ( tostring(self.gpu), 'fill', 1,1, size[1],size[2], ' ' )
		
		return self
	end,
	['set'] = function ( self, x,y, message, vertical )
		self:setBGColor () self:setFGColor ()
		component.invoke ( tostring(self.gpu), 'set', x,y, message )
		return self
	end,
	['fill'] = function ( self, x,y, width,height, char )
		self:setBGColor () self:setFGColor ()
		component.invoke ( tostring(self.gpu), 'fill', x,y, width,height, char )
		return self
	end,
	['setBGColor'] = function ( self, color )
		if color == nil then
			if component.invoke ( tostring(self.gpu), 'getBackground' ) ~= self.bgColor then
				component.invoke ( tostring(self.gpu), 'setBackground', self.bgColor ) 
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
			if component.invoke ( tostring(self.gpu), 'getForeground' ) ~= self.fgColor then
				component.invoke ( tostring(self.gpu), 'setForeground', self.fgColor ) 
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

	['setResolution'] = function ( self, width,height )
		return component.invoke ( tostring(self.gpu), 'setResolution', width,height )
	end,
	['getResolution'] = function ( self )
		return component.invoke ( tostring(self.gpu), 'getResolution' )
	end,
	['maxResolution'] = function ( self )
		return component.invoke ( tostring(self.gpu), 'maxResolution' )
	end,
}

return screen
