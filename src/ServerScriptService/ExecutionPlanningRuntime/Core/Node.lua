--!strict

local Types = require(script.Parent.Types)
local Validation = require(script.Parent.Validation)

local Node = {}

function Node.create(schema: any): (boolean, any)
	local ok, reason = Validation.node(schema)
	if not ok then
		return false, reason
	end
	return true,
		{
			nodeId = schema.nodeId,
			nodeKind = schema.nodeKind,
			authorityOwner = schema.authorityOwner,
			version = schema.version,
			orderingKey = schema.orderingKey,
			planningClassification = schema.planningClassification,
			eligibilityState = Types.EligibilityState.Unknown,
			publicationState = Types.PublicationState.Draft,
			metadata = schema.metadata,
		}
end

return Node
