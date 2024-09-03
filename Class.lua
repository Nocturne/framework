local RootClass = {
	_name = "RootClass"
}

local ClassCache = setmetatable({}, {__mode = "k"})

local Framework

function RootClass:__index(i)
 	local value = rawget(ClassCache[self], i)

	if not value then
		local super = rawget(ClassCache[self], "_super")

		if super then
			value = super[i]
			return value or Framework and Framework[i]
		end
	else
		return value
	end
end

function RootClass:__newindex(i, v)
	rawset(ClassCache[self], i, v)
end

function RootClass:__tostring()
	return rawget(ClassCache[self], "_name")
end

function RootClass.OnWrap(tbl)
	Framework = tbl
end

local RootObj = newproxy(true)
local MT = getmetatable(RootObj)

MT.__index = RootClass.__index
MT.__newindex = RootClass.__newindex
MT.__tostring = RootClass.__tostring

ClassCache[RootObj] = RootClass

local function GetClassByName(name)
	for i,v in pairs(ClassCache) do
		if v._name == name then
			return i
		end
	end
	return nil
end

local Class = {}

function Class.new(name, super)
	super = (typeof(super) == "string" and GetClassByName(super)) or ClassCache[super] or RootObj

	local Object = newproxy(true)
	local MT = getmetatable(Object)

	MT.__index = super.__index
	MT.__newindex = super.__newindex
	MT.__tostring = super.__tostring

	ClassCache[Object] = {
		_name = name,
		_super = super,

		__index = MT.__index,
		__newindex = MT.__newindex,
		__tostring = MT.__tostring

	}

	return Object
end

return Class
