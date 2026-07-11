--!strict

local Serialization = require(script.Parent.AssetExecutionAuthorizationSerialization)
local Types = require(script.Parent.AssetExecutionAuthorizationTypes)

local Validation = {}

local fieldLookup: { [string]: { [string]: boolean } } = {}
for schemaName, fields in pairs(Types.SchemaFields) do
	local lookup = {}
	for _, field in ipairs(fields) do
		lookup[field] = true
	end
	fieldLookup[schemaName] = lookup
end

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
	local count = 0
	for key in pairs(values) do
		if type(key) ~= "number" or key ~= math.floor(key) or key < 1 then
			return false, label .. " must be an ordered array"
		end
		count += 1
	end
	if count ~= #values then
		return false, label .. " must not be sparse"
	end
	if count > limit then
		return false, label .. " exceeds limit"
	end
	local seen: { [string]: boolean } = {}
	local previous = ""
	for _, value in ipairs(values) do
		if not validId(value) then
			return false, label .. " contains invalid id"
		end
		if seen[value] then
			return false, label .. " contains duplicate id"
		end
		if previous ~= "" and value < previous then
			return false, label .. " must be deterministic ascending order"
		end
		previous = value
		seen[value] = true
	end
	return true, nil
end

local function validateMetadata(metadata: any, label: string): (boolean, string?)
	if type(metadata) ~= "table" then
		return false, label .. " metadata is required"
	end
	for key in pairs(metadata) do
		if type(key) ~= "string" or not validId(key) then
			return false, label .. " metadata key is invalid"
		end
	end
	return true, nil
end

local function validateExactArray(
	values: { string },
	expected: { string },
	label: string
): (boolean, string?)
	if #values ~= #expected then
		return false, label .. " count drift"
	end
	for index, value in ipairs(values) do
		if value ~= expected[index] then
			return false, label .. " ordering drift"
		end
	end
	return true, nil
end

local function validateEvidence(values: any): (boolean, string?)
	if values == nil then
		return false, "evidence is required"
	end
	return validateArrayIds(values, Types.Limits.MaxEvidence, "evidence")
end

local function validateTags(tags: any): (boolean, string?)
	if tags == nil then
		return false, "tags are required"
	end
	return validateArrayIds(tags, Types.Limits.MaxTags, "tags")
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
	local safe, safeReason = Serialization.validateSerializable(schema)
	if not safe then
		return false, safeReason
	end
	local fieldCount = 0
	for key in pairs(schema) do
		fieldCount += 1
		if type(key) ~= "string" or fieldLookup[expectedType][key] ~= true then
			return false, label .. " contains unsupported field"
		end
	end
	if fieldCount ~= Types.SchemaFieldCount[expectedType] then
		return false, label .. " field count is invalid"
	end
	if not validId(schema[idField]) then
		return false, label .. " id is invalid"
	end
	local tagsOk, tagsReason = validateTags(schema.tags)
	if not tagsOk then
		return false, tagsReason
	end
	return validateMetadata(schema.metadata, label)
end

local function validateRuntimeIdentity(schema: any): (boolean, string?)
	if schema.runtimeName ~= Types.RuntimeName then
		return false, "runtimeName is unsupported"
	end
	if schema.providerName ~= Types.RuntimeProviderName then
		return false, "providerName is unsupported"
	end
	if schema.snapshotProviderName ~= Types.RuntimeProviderName then
		return false, "snapshotProviderName is unsupported"
	end
	return true, nil
end

function Validation.authorization(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"authorizationId",
		Types.SchemaType.ExecutionAuthorization,
		"authorization"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.governanceId) or not validId(schema.readinessId) then
		return false, "authorization upstream ids are invalid"
	end
	local runtimeOk, runtimeReason = validateRuntimeIdentity(schema)
	if not runtimeOk then
		return false, runtimeReason
	end
	if Types.AuthorizationKind[schema.authorizationKind] ~= true then
		return false, "authorizationKind is invalid"
	end
	if Types.AuthorizationStatus[schema.authorizationStatus] ~= true then
		return false, "authorizationStatus is invalid"
	end
	for _, group in ipairs({
		{ schema.requirementIds, "requirementIds" },
		{ schema.evaluationIds, "evaluationIds" },
		{ schema.boundaryIds, "boundaryIds" },
		{ schema.auditIds, "auditIds" },
	}) do
		if group[1] == nil then
			return false, group[2] .. " are required"
		end
		local listOk, listReason =
			validateArrayIds(group[1], Types.Limits.MaxChildReferences, group[2])
		if not listOk then
			return false, listReason
		end
	end
	return validateEvidence(schema.evidence)
end

function Validation.requirement(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"requirementId",
		Types.SchemaType.ExecutionAuthorizationRequirement,
		"requirement"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.authorizationId) then
		return false, "requirement authorizationId is invalid"
	end
	if Types.RequirementKind[schema.requirementKind] ~= true then
		return false, "requirementKind is invalid"
	end
	if Types.RequirementStatus[schema.requirementStatus] ~= true then
		return false, "requirementStatus is invalid"
	end
	if type(schema.required) ~= "boolean" then
		return false, "required must be boolean"
	end
	return validateEvidence(schema.evidence)
end

function Validation.evaluation(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"evaluationId",
		Types.SchemaType.ExecutionAuthorizationEvaluation,
		"evaluation"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.authorizationId) or not validId(schema.requirementId) then
		return false, "evaluation references are invalid"
	end
	if Types.EvaluationKind[schema.evaluationKind] ~= true then
		return false, "evaluationKind is invalid"
	end
	if Types.EvaluationStatus[schema.evaluationStatus] ~= true then
		return false, "evaluationStatus is invalid"
	end
	if not validId(schema.evaluator) then
		return false, "evaluation evaluator is invalid"
	end
	return validateEvidence(schema.evidence)
end

function Validation.boundary(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"boundaryId",
		Types.SchemaType.ExecutionAuthorizationBoundary,
		"boundary"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.authorizationId) then
		return false, "boundary authorizationId is invalid"
	end
	if Types.BoundaryKind[schema.boundaryKind] ~= true then
		return false, "boundaryKind is invalid"
	end
	if Types.BoundaryStatus[schema.boundaryStatus] ~= true then
		return false, "boundaryStatus is invalid"
	end
	if
		type(schema.summary) ~= "string"
		or schema.summary == ""
		or #schema.summary > Types.Limits.MaxSummaryLength
	then
		return false, "boundary summary is invalid"
	end
	return validateEvidence(schema.evidence)
end

function Validation.audit(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "auditId", Types.SchemaType.ExecutionAuthorizationAudit, "audit")
	if not ok then
		return false, reason
	end
	if not validId(schema.authorizationId) then
		return false, "audit authorizationId is invalid"
	end
	if Types.AuditKind[schema.auditKind] ~= true then
		return false, "auditKind is invalid"
	end
	if Types.AuditStatus[schema.auditStatus] ~= true then
		return false, "auditStatus is invalid"
	end
	if not validId(schema.reviewer) then
		return false, "audit reviewer is invalid"
	end
	for _, group in ipairs({
		{ schema.evaluationIds, "evaluationIds" },
		{ schema.boundaryIds, "boundaryIds" },
	}) do
		if group[1] == nil then
			return false, group[2] .. " are required"
		end
		local listOk, listReason =
			validateArrayIds(group[1], Types.Limits.MaxChildReferences, group[2])
		if not listOk then
			return false, listReason
		end
	end
	return validateEvidence(schema.evidence)
end

function Validation.validate(): (boolean, string?)
	if Types.RuntimeProviderName ~= "assetExecutionAuthorizationRuntime" then
		return false, "provider name drift"
	end
	if Types.SnapshotKind ~= "assetExecutionAuthorizationRuntimeSnapshot" then
		return false, "snapshot kind drift"
	end
	if Types.RuntimeName ~= "AssetExecutionAuthorization" then
		return false, "runtime name drift"
	end
	if Types.CoordinatorName ~= "AssetExecutionAuthorizationCoordinator" then
		return false, "coordinator name drift"
	end
	local docsOk, docsReason = validateExactArray(Types.DocumentationFiles, {
		"ASSET_EXECUTION_AUTHORIZATION_RUNTIME.md",
		"ASSET_EXECUTION_AUTHORIZATION_VALIDATION.md",
		"ASSET_EXECUTION_AUTHORIZATION_SERIALIZATION.md",
		"ASSET_EXECUTION_AUTHORIZATION_DIAGNOSTICS.md",
		"ASSET_EXECUTION_AUTHORIZATION_SELF_CHECKS.md",
		"ASSET_EXECUTION_AUTHORIZATION_RUNTIME_LIMITS.md",
		"ASSET_EXECUTION_AUTHORIZATION_PRODUCTION_REVIEW.md",
		"ASSET_EXECUTION_AUTHORIZATION_AUDIT.md",
		"AUTHORIZATION_RUNTIME.md",
		"AUTHORIZATION_REQUIREMENT_RUNTIME.md",
		"AUTHORIZATION_EVALUATION_RUNTIME.md",
		"AUTHORIZATION_BOUNDARY_RUNTIME.md",
		"AUTHORIZATION_AUDIT_RUNTIME.md",
	}, "documentation")
	if not docsOk then
		return false, docsReason
	end
	local bootstrapOk, bootstrapReason = validateExactArray(
		Types.BootstrapDependencyOrder,
		{ "AssetExecutionGovernanceCoordinator" },
		"Bootstrap dependency"
	)
	if not bootstrapOk then
		return false, bootstrapReason
	end
	local governanceOk, governanceReason = validateExactArray(
		Types.GovernanceSnapshotProviders,
		{ Types.RuntimeProviderName },
		"Governance snapshot provider"
	)
	if not governanceOk then
		return false, governanceReason
	end
	return true, nil
end

Validation.validId = validId

return Validation
