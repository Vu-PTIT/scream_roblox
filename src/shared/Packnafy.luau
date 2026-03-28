--!strict
-- Packnafy.luau
-- A lightweight utility to "pack" and "unpack" arguments into a compact array.
-- This reduces network overhead by avoiding dictionary keys and using a flat structure.

local Packnafy = {}

-- Pack arguments into a flat array
function Packnafy.Pack(...: any): { any }
	return { ... }
end

-- Unpack a flat array into arguments
function Packnafy.Unpack(data: { any }): ...any
	return table.unpack(data)
end

return Packnafy
