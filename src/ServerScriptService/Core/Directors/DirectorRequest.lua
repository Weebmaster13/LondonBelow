--!strict

local HttpService = game:GetService("HttpService")

local DirectorConfig = require(script.Parent.DirectorConfig)
local Types = require(script.Parent.DirectorTypes)

local DirectorRequest = {}

function DirectorRequest.create(fields: {
	sourceDirector: Types.DirectorName,
	targetDirector: Types.DirectorName,
	requestKind: string,
	priority: Types.RequestPriority?,
	reason: string,
	supportingObservationIds: { string }?,
	context: { [string]: any }?,
	metadata: { [string]: any }?,
	requiresApproval: boolean?,
	conflictGroup: string?,
	tags: { string }?,
	expiresIn: number?,
}): Types.DirectorRequest
	local createdAt = os.clock()
	local expiresIn = fields.expiresIn or DirectorConfig.DefaultRequestExpirationSeconds

	return {
		requestId = HttpService:GenerateGUID(false),
		sourceDirector = fields.sourceDirector,
		targetDirector = fields.targetDirector,
		requestKind = fields.requestKind,
		priority = fields.priority or "Normal",
		reason = fields.reason,
		createdAt = createdAt,
		expiresAt = createdAt + expiresIn,
		supportingObservationIds = fields.supportingObservationIds or {},
		context = fields.context or {},
		metadata = fields.metadata or {},
		requiresApproval = if fields.requiresApproval == nil then true else fields.requiresApproval,
		conflictGroup = fields.conflictGroup,
		tags = fields.tags or {},
	}
end

function DirectorRequest.validate(request: any): (boolean, string?)
	if type(request) ~= "table" then
		return false, "Request must be a table"
	end

	local requiredStrings =
		{ "requestId", "sourceDirector", "targetDirector", "requestKind", "priority", "reason" }

	for _, field in ipairs(requiredStrings) do
		if type(request[field]) ~= "string" or request[field] == "" then
			return false, "Request missing " .. field
		end
	end

	if type(request.createdAt) ~= "number" or type(request.expiresAt) ~= "number" then
		return false, "Request requires createdAt and expiresAt"
	end

	if request.expiresAt <= request.createdAt then
		return false, "Request expiresAt must be after createdAt"
	end

	if
		type(request.supportingObservationIds) ~= "table"
		or type(request.context) ~= "table"
		or type(request.metadata) ~= "table"
	then
		return false, "Request requires supportingObservationIds, context, and metadata tables"
	end

	if type(request.requiresApproval) ~= "boolean" then
		return false, "Request requires requiresApproval boolean"
	end

	if type(request.tags) ~= "table" then
		return false, "Request requires tags table"
	end

	return true, nil
end

return DirectorRequest
