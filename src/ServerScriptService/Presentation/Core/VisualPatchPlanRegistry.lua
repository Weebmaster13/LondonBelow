--!strict

local Runtime = require(script.Parent.RuntimeRobloxVisualCompositionExecution)

local Module = {}
Module.moduleName = "VisualPatchPlanRegistry"
Module.ownership = "patch plan registry"

function Module.inspect()
	return Runtime.inspect()
end

function Module.validate(): (boolean, string?)
	return Runtime.validate()
end

return Module
