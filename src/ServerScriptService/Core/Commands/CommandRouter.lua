--!strict

local Evidence = require(script.Parent.CommandEvidence)
local Serialization = require(script.Parent.CommandSerialization)

local Router = {}

function Router.route(command: any, definition: any, handler: any?)
	local plan = {
		commandId = command.commandId,
		commandType = command.commandType,
		ownerRuntime = definition.ownerRuntime,
		handlerId = if handler ~= nil then handler.handlerId else nil,
		handlerRuntime = if handler ~= nil then handler.runtimeId else nil,
		routeFound = handler ~= nil,
		missingRoute = handler == nil,
		execute = if handler ~= nil then handler.execute else nil,
	}
	Evidence.record("command routed", {
		commandId = command.commandId,
		commandType = command.commandType,
		handlerId = plan.handlerId,
	})
	return Serialization.deepCopy(plan)
end

return Router
