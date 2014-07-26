local unicode = require('unicode')

local box = {
	['screen'] = nil,

	['x'] = 1,
	['y'] = 1,
	['name'] = 'box',
	['function'] = {},
	
	['width'] = 16,
	['height'] = 7,
	['image'] = {
		{
			{
				['char'] = ' ',
				['color'] = 0xFFFFFF,
				['background'] = 0x669966,
			},
		},
	},
	['border'] = {
		['lt'] = 0x250C,
		['rt'] = 0x2510,
		['t']  = 0x2500,
		['l']  = 0x2502,
		['r']  = 0x2502,
		['lb'] = 0x2514,
		['rb'] = 0x2518,
		['b']  = 0x2500,
	},
	['text'] = {
		['halign'] = 'center',
		['valign'] = 'center',
	},
	['draw'] = function ( self )
		local last = false
		for y = 1, self.height do
			local draw = ''
			local at = 1

			for x = 1, self.width do
				local l = self.image [ (y % #self.image) + 1 ][ (x % #self.image [ (y % #self.image) + 1 ]) + 1 ]

				if last == false then
					last = l
				end

				if last.color == l.color and last.background == l.background then
					draw = draw .. l.char
				else
					self.screen:setFGColor ( last.color )
					self.screen:setBGColor ( last.background )

					self.screen:set ( self.x + at - 1, self.y + y - 1, draw )

					at = draw:len ()
					draw = ''
				end

				last = l
			end

			if draw:len () > 0 then
				self.screen:setFGColor ( last.color )
				self.screen:setBGColor ( last.background )

				self.screen:set ( self.x + at - 1, self.y + y - 1, draw )
			end
		end

		local x = 1
		local y = 1

		if self.text.valign == 'center' then
			y = math.floor (self.height / 2) + 1
		elseif self.text.valign == 'bottom' then
			if self.border ['b'] then
				y = self.height - 1
			else
				y = self.height
			end
		else
			if self.border['t'] then
				y = 2
			end
		end

		if self.text.halign == 'center' then
			x = math.floor ( (self.width - tostring(self.name):len()) / 2 ) + 1
		elseif self.text.halign == 'right' then
			if self.border ['r'] then
				x = math.floor ( self.width - tostring(self.name):len() ) - 1
			else
				x = math.floor ( self.width - tostring(self.name):len() )
			end
		else
			if self.border ['l'] then
				x = 2
			end
		end

		self.screen:set ( self.x + x - 1,self.y + y - 1, tostring(self.name) )

		if self.border.color then
			self.screen:setFGColor ( self.border.color )
		end
		if self.border.background then
			self.screen:setBGColor ( self.border.background )
		end

		-- Overly complex border drawing, you know, so i use as few screen operations as possible.
		-- this costs between 0 and 4 set (), 0 and 2 fill (), depending on self. which at most draws, takes 0.75 of 1 tick.
		if self.border ['lt'] then
			if self.border ['t'] then
				if self.border ['rt'] then
					self.screen:set ( self.x, self.y, unicode.char ( self.border ['lt'] ) .. string.rep ( unicode.char ( self.border ['t'] ), self.width - 2 ) .. unicode.char ( self.border ['rt'] ) )
				else
					self.screen:set ( self.x, self.y, unicode.char ( self.border ['lt'] ) .. string.rep ( unicode.char ( self.border ['t'] ), self.width - 2 ) )
				end
			else
				if self.border ['rt'] then
					self.screen:set ( self.x + self.width - 1, self.y, unicode.char ( self.border ['rt'] ) )
				end
				self.screen:set ( self.x, self.y, unicode.char ( self.border ['lt'] ) )
			end
		elseif self.border ['t'] then
			if self.border ['rt'] then
				self.screen:set ( self.x + 1, self.y, string.rep ( unicode.char ( self.border ['t'] ), self.width - 2 ) .. unicode.char ( self.border ['rt'] ) )
			else
				self.screen:set ( self.x + self.width - 1, self.y, unicode.char ( self.border ['rt'] ) )
			end
		end

		if self.border ['lb'] then
			if self.border ['b'] then
				if self.border ['rb'] then
					self.screen:set ( self.x, self.y + self.height - 1, unicode.char ( self.border ['lb'] ) .. string.rep ( unicode.char ( self.border ['b'] ), self.width - 2 ) .. unicode.char ( self.border ['rb'] ) )
				else
					self.screen:set ( self.x, self.y + self.height - 1, unicode.char ( self.border ['lb'] ) .. string.rep ( unicode.char ( self.border ['b'] ), self.width - 2 ) )
				end
			else
				if self.border ['rb'] then
					self.screen:set ( self.x + self.width, self.y + self.height - 1, unicode.char ( self.border ['rb'] ) )
				end
				self.screen:set ( self.x, self.y + self.height - 1, unicode.char ( self.border ['lb'] ) )
			end
		elseif self.border ['b'] then
			if self.border ['rb'] then
				self.screen:set ( self.x + 1, self.y + self.height - 1, string.rep ( unicode.char ( self.border ['b'] ), self.width - 2 ) .. unicode.char ( self.border ['rb'] ) )
			else
				self.screen:set ( self.x + self.width - 1, self.y + self.height - 1, unicode.char ( self.border ['rb'] ) )
			end
		end

		if self.border ['l'] then
			self.screen:fill ( self.x, self.y + 1, 1, self.height - 2, unicode.char ( self.border ['l'] ) )
		end
		if self.border ['r'] then
			self.screen:fill ( self.x + self.width - 1, self.y + 1, 1, self.height - 2, unicode.char ( self.border ['l'] ) )
		end
	end,
}

return box
