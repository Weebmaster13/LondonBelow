--!strict
local Serialization = require(script.Parent.QuerySerialization)
local Projections = {}
local projections = {}
function Projections.register(projection: any)
	projections[projection.projectionId] = Serialization.deepCopy(projection)
	return { ok = true, code = "Ok" }
end
function Projections.inspect()
	return Serialization.deepCopy(projections)
end
function Projections.clear()
	table.clear(projections)
end
return Projections
