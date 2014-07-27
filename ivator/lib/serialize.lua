-- Trololol, if a table links to another table, which links to the first table, forever loop until stack pointer issues, but look at the size of this thing, such lazy <3
-- Ninja level added, this gonna break shit.

local serialize = {}
function serialize.pack ( _table, level )
	level = level or 0
	if level > 100 then error ( 'Gone too deep!' ) end

	local str = '{\n '
	for k,v in pairs ( _table ) do
		if tostring(k):match ( '^%d+$') then
			str = str .. string.rep('\t', level ) .. '\t[' .. tostring(k) .. ']'
		else
			str = str .. string.rep('\t', level ) .. '\t["' .. tostring(k) .. '"]'
		end

		str = str .. ' = '
		if type(v) == 'number' then
			str = str .. tostring(v) .. ', \n'
		elseif type(v) == 'string' then
			str = str .. '"' .. tostring(v) .. '", \n'
		elseif type(v) == 'table' then
			str = str .. serialize.pack (v, level + 1) .. ', \n'
		else
			str = str .. '"", \n'
		end
	end

	return str .. '\n}'
end

function serialize.unpack ( str )
	local _table = {}

	if str:match ('^%{.*%}$') == nil then
		return false, 'not a valid string supplied.'
	end

	_table, reason = load('return ' .. str )
	if reason ~= nil then
		return false, 'not a valid string supplied.'
	end

	return _table ()
end

return serialize
