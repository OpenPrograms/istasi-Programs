local zone = {}
zone = {
	['offset'] = {
		['x'] = 1,
		['y'] = 1,
	},
	['map'] = {},
	['add'] = function ( self, x, y, width, height, values, levelIndex )
		levelIndex = levelIndex or 1
		if self.map [levelIndex] == nil then self.map [levelIndex] = {} end

		-- Do we have overlap?
		for h = 1, height do
			for w = 1, width do
				if self:get ((x - 1) + h, (y - 1) + h, levelIndex) ~= nil then
					return self:add ( x, y, width, height, values, levelIndex + 1 )
				end
			end
		end

		if self ['map'][levelIndex] == nil then self ['map'][levelIndex] = {} end
		local zoneId = levelIndex .. '.' .. #self ['map'][levelIndex]

		table.insert ( self ['map'][levelIndex], {
			['x'] = x,
			['y'] = y,
			['width'] = width,
			['height'] = height,
			['values'] = values,
			['zoneId'] = zoneId,
		})

		return self, zoneId
	end,
	['get'] = function ( self, x, y, levelIndex )
		x = (x - self.offset ['x']) + 1
		y = (y - self.offset ['y']) + 1

		local idMap = {}
		if levelIndex == nil then
			for id in pairs ( self.map ) do table.insert ( idMap, id ) end

			table.sort ( idMap )
		else
			table.insert ( idMap, levelIndex )
		end

		for id in ipairs ( idMap ) do
			for _,map in ipairs ( self.map [id] ) do
				if map ~= nil and 
					x >= map.x and 
					x <= map.x + map.width and 
					y >= map.y and 
					y <= map.y + map.height then
					return map
				end
			end
		end
		return nil, 'not found'
	end,
	['remove'] = function ( self, zoneId )
		local levelIndex, id = zoneId:match ('([^%.])*%.(.*)')
		if levelIndex == nil then return false, 'unable to parse zoneId' end

		if self.map [levelIndex] == nil then
			return self, 'levelIndex is nil, already removed?'
		end

		if self.map [levelIndex][id] == nil then
			return self, 'not found, already removed?'
		end

		self.map [levelIndex][id] = nil
		return self
	end,
	['clear'] = function ( self, x, y )
		self.offset.y = y
		self.offset.x = x

		self.map = {}
		return self
	end,
}

return zone
