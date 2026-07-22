--!strict
local Serialization = require(script.Parent.QuerySerialization)
local ReadModels = {}
local models = {}
function ReadModels.register(model: any)
	models[model.modelId] = Serialization.deepCopy(model)
	return { ok = true, code = "Ok" }
end
function ReadModels.inspect()
	return Serialization.deepCopy(models)
end
function ReadModels.clear()
	table.clear(models)
end
return ReadModels
