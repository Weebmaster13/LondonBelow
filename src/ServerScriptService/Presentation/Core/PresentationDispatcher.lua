--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Dispatcher = {}

local routes: { any } = {}

local CHANNELS = {
	[Types.PresentationType.ShowPrompt] = Types.ChannelType.UI,
	[Types.PresentationType.HidePrompt] = Types.ChannelType.UI,
	[Types.PresentationType.UpdatePrompt] = Types.ChannelType.UI,
	[Types.PresentationType.ShowInteractionBusy] = Types.ChannelType.UI,
	[Types.PresentationType.HideInteractionBusy] = Types.ChannelType.UI,
	[Types.PresentationType.PlayAudio] = Types.ChannelType.Audio,
	[Types.PresentationType.StopAudio] = Types.ChannelType.Audio,
	[Types.PresentationType.PlayAnimation] = Types.ChannelType.System,
	[Types.PresentationType.StopAnimation] = Types.ChannelType.System,
	[Types.PresentationType.UpdateCursor] = Types.ChannelType.UI,
	[Types.PresentationType.ShowMessage] = Types.ChannelType.Accessibility,
	[Types.PresentationType.HideMessage] = Types.ChannelType.Accessibility,
	[Types.PresentationType.HighlightObject] = Types.ChannelType.VFX,
	[Types.PresentationType.RemoveHighlight] = Types.ChannelType.VFX,
}

local function trim()
	while #routes > Types.Limits.MaxRoutingRecords do
		table.remove(routes, 1)
	end
end

function Dispatcher.route(command: any)
	local route = {
		commandId = command.commandId,
		objectId = command.objectId,
		presentationType = command.presentationType,
		channelType = CHANNELS[command.presentationType] or Types.ChannelType.System,
		routedAt = os.clock(),
		wouldExecuteGameplay = false,
		wouldCreateRemote = false,
		wouldPlayAudio = false,
		wouldPlayAnimation = false,
		wouldMutateWorkspace = false,
	}
	table.insert(routes, route)
	trim()
	return Serialization.deepCopy(route)
end

function Dispatcher.inspect()
	return {
		routeCount = #routes,
		routes = Serialization.deepCopy(routes),
	}
end

function Dispatcher.clear()
	table.clear(routes)
end

return Dispatcher
