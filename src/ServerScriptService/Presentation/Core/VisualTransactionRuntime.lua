--!strict

local Runtime = require(script.Parent.RuntimeRobloxVisualCompositionExecution)

local Module = {}
Module.moduleName = "VisualTransactionRuntime"
Module.ownership = "transaction runtime"

function Module.inspect()
	return Runtime.inspect()
end

function Module.validate(): (boolean, string?)
	return Runtime.validate()
end

return Module
