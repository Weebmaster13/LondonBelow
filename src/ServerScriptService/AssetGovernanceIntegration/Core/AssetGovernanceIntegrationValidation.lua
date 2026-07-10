--!strict

local Serialization = require(script.Parent.AssetGovernanceIntegrationSerialization)
local Types = require(script.Parent.AssetGovernanceIntegrationTypes)

local Validation = {}

local function validId(value: any): boolean
	return type(value) == "string"
		and value ~= ""
		and #value <= 150
		and string.match(value, "^[%w%._%-:]+$") ~= nil
end

local function validateArrayIds(values: any, limit: number, label: string): (boolean, string?)
	if values == nil then
		return true, nil
	end
	if type(values) ~= "table" then
		return false, label .. " must be a table"
	end
	if #values > limit then
		return false, label .. " exceeds limit"
	end
	local seen: { [string]: boolean } = {}
	for _, value in ipairs(values) do
		if not validId(value) then
			return false, label .. " contains invalid id"
		end
		if seen[value] then
			return false, label .. " contains duplicate id"
		end
		seen[value] = true
	end
	return true, nil
end

local function validateTags(tags: any): (boolean, string?)
	return validateArrayIds(tags, Types.Limits.MaxTags, "tags")
end

function Validation.safePayload(payload: any): (boolean, string?)
	return Serialization.validateSerializable(payload)
end

local function validateSchema(
	schema: any,
	idField: string,
	expectedType: string,
	label: string
): (boolean, string?)
	if schema == nil then
		return false, label .. " schema is nil"
	end
	if type(schema) ~= "table" then
		return false, label .. " schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema[idField]) then
		return false, label .. " id is invalid"
	end
	if schema.schemaType ~= nil and schema.schemaType ~= expectedType then
		return false, "unsupported " .. label .. " schema type"
	end
	return validateTags(schema.tags)
end

function Validation.chain(schema: any): (boolean, string?)
	local ok, reason = validateSchema(schema, "chainId", Types.SchemaType.GovernanceChain, "chain")
	if not ok then
		return false, reason
	end
	if Types.ChainKind[schema.chainKind] ~= true then
		return false, "chain kind is invalid"
	end
	if Types.ChainStatus[schema.chainStatus] ~= true then
		return false, "chain status is invalid"
	end
	for _, group in ipairs({
		{ schema.runtimeNodeIds, "runtimeNodeIds" },
		{ schema.referenceReviewIds, "referenceReviewIds" },
		{ schema.auditIds, "auditIds" },
	}) do
		local listOk, listReason =
			validateArrayIds(group[1], Types.Limits.MaxChainChildren, group[2])
		if not listOk then
			return false, listReason
		end
	end
	return true, nil
end

function Validation.runtimeNode(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "nodeId", Types.SchemaType.GovernanceRuntimeNode, "runtime node")
	if not ok then
		return false, reason
	end
	if not validId(schema.chainId) then
		return false, "runtime node chainId is invalid"
	end
	if Types.RuntimeName[schema.runtimeName] == nil then
		return false, "runtime node runtimeName is unsupported"
	end
	if Types.ProviderName[schema.providerName] == nil then
		return false, "runtime node providerName is unsupported"
	end
	if Types.CoordinatorName[schema.coordinatorName] == nil then
		return false, "runtime node coordinatorName is unsupported"
	end
	local expectedRuntimeOrder = Types.RuntimeName[schema.runtimeName]
	if
		Types.ProviderName[schema.providerName] ~= expectedRuntimeOrder
		or Types.CoordinatorName[schema.coordinatorName] ~= expectedRuntimeOrder
	then
		return false, "runtime node provider/coordinator does not match runtimeName"
	end
	if
		type(schema.expectedOrder) ~= "number"
		or schema.expectedOrder % 1 ~= 0
		or schema.expectedOrder < 1
	then
		return false, "runtime node expectedOrder is invalid"
	end
	if schema.expectedOrder ~= expectedRuntimeOrder then
		return false, "runtime node expectedOrder does not match certified order"
	end
	if type(schema.required) ~= "boolean" then
		return false, "runtime node required must be boolean"
	end
	if Types.NodeStatus[schema.nodeStatus] ~= true then
		return false, "runtime node status is invalid"
	end
	return true, nil
end

function Validation.referenceReview(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"reviewId",
		Types.SchemaType.GovernanceReferenceReview,
		"reference review"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.chainId) then
		return false, "reference review chainId is invalid"
	end
	if
		Types.RuntimeName[schema.sourceRuntimeName] == nil
		or Types.RuntimeName[schema.targetRuntimeName] == nil
	then
		return false, "reference review runtime names are unsupported"
	end
	if Types.ReferenceKind[schema.referenceKind] ~= true then
		return false, "reference kind is invalid"
	end
	if Types.ReferenceStatus[schema.referenceStatus] ~= true then
		return false, "reference status is invalid"
	end
	if type(schema.summary) ~= "string" or schema.summary == "" then
		return false, "reference review summary is invalid"
	end
	return true, nil
end

function Validation.audit(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "auditId", Types.SchemaType.GovernanceIntegrationAudit, "audit")
	if not ok then
		return false, reason
	end
	if not validId(schema.chainId) then
		return false, "audit chainId is invalid"
	end
	if Types.AuditKind[schema.auditKind] ~= true then
		return false, "audit kind is invalid"
	end
	if not validId(schema.reviewer) then
		return false, "audit reviewer is invalid"
	end
	if Types.AuditStatus[schema.status] ~= true then
		return false, "audit status is invalid"
	end
	return validateArrayIds(schema.findings, Types.Limits.MaxAuditFindings, "findings")
end

function Validation.validate(): (boolean, string?)
	return true, nil
end

return Validation
