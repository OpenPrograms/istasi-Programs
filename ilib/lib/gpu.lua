local component = require('component')

local gpuBoundTo = {}
local addresses = {}
local assigned = {}

local gpu = {
	['get'] = function ( self )
		local o = setmetatable ({
			['address'] = addresses[1],
			-- Keeping track myself, since bad people are using getScreen to iterate between all gpu's to figure which gpu is bound to the wanted screen.
			-- and since, if i do a gpu.getScreen () its a 1tick call, even if i only need to ask my single assigned gpu, 1 tick per call will quickly add up
			-- besides, the difference in code needed is what?, 3 lines?
			['getScreen'] = function ( self ) return gpuBoundTo [self.address] end,
			['bind'] = function ( self, address )
				if self:getScreen () == address then return end 


				component.invoke ( self.address, 'bind', address )
				gpuBoundTo [self.address] = address
			end,
		},{
			['__tostring'] = function ( self )
				return self.address
			end,
		})

		table.insert ( assigned, o )
		self:refresh ()

		return o
	end,
	['refresh'] = function ( self )
		local screensPerGPU = math.max ( math.ceil (#assigned / #addresses), 1 )

		for i,o in ipairs ( assigned ) do
			o.address = addresses[ math.ceil ( i / screensPerGPU ) ]
		end

		return o
	end,
	['addGPU'] = function ( self, _address )
		table.insert ( addresses, _address )

		self:refresh ()
	end,
	['removeGPU'] = function ( self, _address )
		for i,address in ipairs ( addresses ) do
			if address == _address then
				table.remove ( addressses, i )
			end
		end

		self:refresh ()
	end,
}

for address in component.list ('gpu',true) do gpu:addGPU (address) end
return gpu