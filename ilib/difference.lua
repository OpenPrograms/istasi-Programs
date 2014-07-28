local data = {}
local default = {}

local difference = {
	['default'] = nil,

	['setDefault'] = function ( self, _table )
		if type (_table) ~= 'table' then error ( 'Supplied argument is not a table' ) end

		default = _table
	end,
	['each'] = function ( self, callback )
		for i in ipairs ( data ) do
			local o = {}
			for k,v in pairs ( default ) do o[k]=v end
			for k,v in pairs ( data[i] ) do o[k]=v end

			callback (o)
		end
	end,
	['add'] = function ( self, _table )
		table.insert ( data, _table )
	end,
}

setmetatable (difference, {
	['__index'] = function ( self, key )
		if data [key] == nil then return nil end

		local o = {}
		for k,v in pairs ( default ) do o[k]=v end
		for k,v in pairs ( data[key] ) do o[k]=v end

		return o
	end,
})

return difference
