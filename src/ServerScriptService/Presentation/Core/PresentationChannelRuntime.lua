--!strict
-- Presentation channel schema verification and storage.

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)
local Validation = require(script.Parent.PresentationValidation)

local ChannelRuntime = {}

local channelsByPresentation: { [string]: any } = {}
local channelOrder: { string } = {}

local function countStored(): number
	local count = 0
	for _, channels in pairs(channelsByPresentation) do
		for _ in pairs(channels) do
			count += 1
		end
	end
	return count
end

function ChannelRuntime.verify(presentationId: string, channels: any): (boolean, string?)
	local ok, reason = Validation.channels(channels)
	if not ok then
		return false, reason
	end
	channelsByPresentation[presentationId] = Serialization.deepCopy(channels)
	table.insert(channelOrder, presentationId)
	while #channelOrder > Types.Limits.MaxRequests do
		local id = table.remove(channelOrder, 1)
		if id ~= nil then
			channelsByPresentation[id] = nil
		end
	end
	return true, nil
end

function ChannelRuntime.inspect()
	return {
		channelCount = countStored(),
		channelsByPresentation = Serialization.deepCopy(channelsByPresentation),
	}
end

function ChannelRuntime.clear()
	table.clear(channelsByPresentation)
	table.clear(channelOrder)
end

return ChannelRuntime
