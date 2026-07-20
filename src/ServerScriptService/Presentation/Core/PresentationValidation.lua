--!strict
-- Validation boundary for server-owned presentation intent schemas.

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"animate",
	"audioExecution",
	"cameraExecution",
	"chapter",
	"chapter0",
	"chapter1",
	"client",
	"cutscene",
	"dialogue",
	"execute",
	"finalAudio",
	"finalLighting",
	"finalUI",
	"gameplay",
	"horrorPacing",
	"instance",
	"lightingExecution",
	"monsterAI",
	"narrative",
	"particle",
	"particles",
	"play",
	"remote",
	"save",
	"story",
	"uiExecution",
	"vfxExecution",
	"workspace",
}

local FORBIDDEN_LOOKUP: { [string]: boolean } = {}

for _, field in ipairs(FORBIDDEN_FIELDS) do
	FORBIDDEN_LOOKUP[string.lower(field)] = true
end

local function validId(value: any): boolean
	return type(value) == "string"
		and value ~= ""
		and #value <= 140
		and string.match(value, "^[%w%._%-:]+$") ~= nil
end

local function supportedPresentationType(value: any): boolean
	for _, presentationType in pairs(Types.PresentationType) do
		if value == presentationType then
			return true
		end
	end
	return false
end

local function validCursor(value: any): boolean
	for _, cursor in pairs(Types.CursorState) do
		if value == cursor then
			return true
		end
	end
	return false
end

local function supportedChannel(value: any): boolean
	for _, channel in pairs(Types.ChannelType) do
		if value == channel then
			return true
		end
	end
	return false
end

local function forbidden(payload: any, depth: number): (boolean, string?)
	if type(payload) ~= "table" then
		return true, nil
	end
	if depth > Types.Limits.MaxPayloadDepth then
		return false, "presentation payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "presentation payload contains forbidden field: " .. key
		end
	end
	for _, nested in pairs(payload) do
		local ok, reason = forbidden(nested, depth + 1)
		if not ok then
			return false, reason
		end
	end
	return true, nil
end

function Validation.safePayload(payload: any): (boolean, string?)
	local ok, reason = Serialization.validateSerializable(payload)
	if not ok then
		return false, reason
	end
	return forbidden(payload, 0)
end

function Validation.id(value: any): boolean
	return validId(value)
end

function Validation.channels(channels: any): (boolean, string?)
	if type(channels) ~= "table" or next(channels) == nil then
		return false, "missing channels"
	end
	local count = 0
	local seenChannels: { [string]: boolean } = {}
	for _, channel in pairs(channels) do
		count += 1
		local channelType = if type(channel) == "table" then channel.channelType else channel
		if not supportedChannel(channelType) then
			return false, "invalid channel"
		end
		if seenChannels[channelType] == true then
			return false, "duplicate channel"
		end
		seenChannels[channelType] = true
	end
	if count > Types.Limits.MaxChannelsPerRequest then
		return false, "channel count exceeds limit"
	end
	return true, nil
end

function Validation.request(request: any, currentTime: number): (boolean, string?)
	if type(request) ~= "table" then
		return false, "presentation request must be a table"
	end
	local safe, safeReason = Validation.safePayload(request)
	if not safe then
		return false, safeReason
	end
	if not validId(request.presentationId) then
		return false, "presentationId is required"
	end
	if not validId(request.requester) then
		return false, "requester is required"
	end
	if not validId(request.sourceSystem) then
		return false, "sourceSystem is required"
	end
	if not supportedPresentationType(request.presentationType) then
		return false, "unsupported presentation type"
	end
	if type(request.priority) ~= "number" or request.priority ~= request.priority then
		return false, "priority must be a number"
	end
	if request.priority < 0 or request.priority > Types.Limits.MaxPriority then
		return false, "priority is outside bounds"
	end
	if type(request.createdAt) ~= "number" or request.createdAt ~= request.createdAt then
		return false, "createdAt must be a number"
	end
	if type(request.expiresAt) ~= "number" or request.expiresAt ~= request.expiresAt then
		return false, "expiresAt must be a number"
	end
	if request.expiresAt <= currentTime then
		return false, "presentation request is expired"
	end
	if type(request.approvals) ~= "table" or next(request.approvals) == nil then
		return false, "missing approvals"
	end
	return Validation.channels(request.channels)
end

function Validation.prompt(payload: any): (boolean, string?)
	if type(payload) ~= "table" then
		return false, "prompt payload must be a table"
	end
	if not validId(payload.promptId) or not validId(payload.objectId) then
		return false, "prompt ids are required"
	end
	if type(payload.enabled) ~= "boolean" or type(payload.busy) ~= "boolean" then
		return false, "prompt enabled and busy states are required"
	end
	if type(payload.accessibilityMetadata) ~= "table" then
		return false, "accessibility metadata is required"
	end
	if not validId(payload.titleKey) or not validId(payload.actionKey) then
		return false, "prompt localization keys are required"
	end
	return true, nil
end

function Validation.command(command: any): (boolean, string?)
	if type(command) ~= "table" then
		return false, "presentation command must be a table"
	end
	local safe, safeReason = Validation.safePayload(command)
	if not safe then
		return false, safeReason
	end
	if
		not validId(command.commandId)
		or not validId(command.sourceRuntime)
		or not validId(command.objectId)
	then
		return false, "command identity fields are required"
	end
	if not supportedPresentationType(command.presentationType) then
		return false, "unsupported presentation command type"
	end
	if command.playerId ~= nil and type(command.playerId) ~= "number" then
		return false, "playerId must be numeric when present"
	end
	if type(command.priority) ~= "number" or command.priority ~= command.priority then
		return false, "command priority must be a number"
	end
	if type(command.revision) ~= "number" or command.revision <= 0 then
		return false, "command revision must be positive"
	end
	if type(command.timestamp) ~= "number" or type(command.expiresAt) ~= "number" then
		return false, "command timestamps are required"
	end
	if command.expiresAt <= command.timestamp then
		return false, "presentation command is expired"
	end
	local payload = command.payload or {}
	if
		command.presentationType == Types.PresentationType.ShowPrompt
		or command.presentationType == Types.PresentationType.UpdatePrompt
	then
		return Validation.prompt(payload)
	elseif command.presentationType == Types.PresentationType.PlayAudio then
		if not validId(payload.audioKey) then
			return false, "audioKey is required"
		end
	elseif command.presentationType == Types.PresentationType.PlayAnimation then
		if not validId(payload.animationKey) then
			return false, "animationKey is required"
		end
	elseif command.presentationType == Types.PresentationType.UpdateCursor then
		if not validCursor(payload.cursorState) then
			return false, "cursorState is invalid"
		end
	elseif command.presentationType == Types.PresentationType.ShowMessage then
		if not validId(payload.messageId) or not validId(payload.messageKey) then
			return false, "message localization keys are required"
		end
	end
	return true, nil
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativePresentationSchemaRuntime" then
		return false, "Presentation Runtime must remain server-authoritative schema runtime"
	end
	return true, nil
end

return Validation
