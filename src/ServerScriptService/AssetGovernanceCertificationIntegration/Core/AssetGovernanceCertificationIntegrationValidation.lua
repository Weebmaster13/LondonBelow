--!strict

local Serialization = require(script.Parent.AssetGovernanceCertificationIntegrationSerialization)
local Types = require(script.Parent.AssetGovernanceCertificationIntegrationTypes)

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

local function validateRuntimeNames(values: any): (boolean, string?)
	if values == nil then
		return false, "runtimeNames are required"
	end
	local ok, reason = validateArrayIds(values, Types.Limits.MaxChainEntries, "runtimeNames")
	if not ok then
		return false, reason
	end
	if #values ~= #Types.CertifiedRuntimeOrder then
		return false, "runtimeNames must include the complete certified governance chain"
	end
	for order, runtimeName in ipairs(values) do
		if Types.RuntimeName[runtimeName] ~= order then
			return false, "runtimeNames must match certified governance chain order"
		end
	end
	return true, nil
end

local function validateProviderNames(values: any): (boolean, string?)
	if values == nil then
		return false, "providerNames are required"
	end
	local ok, reason = validateArrayIds(values, Types.Limits.MaxChainEntries, "providerNames")
	if not ok then
		return false, reason
	end
	if #values ~= #Types.CertifiedRuntimeOrder then
		return false, "providerNames must include the complete certified governance chain"
	end
	for order, providerName in ipairs(values) do
		if Types.ProviderName[providerName] ~= order then
			return false, "providerNames must match certified governance chain order"
		end
	end
	return true, nil
end

local function validateReadinessIds(values: any): (boolean, string?)
	if values == nil then
		return false, "readinessIds are required"
	end
	local ok, reason = validateArrayIds(values, Types.Limits.MaxChainEntries, "readinessIds")
	if not ok then
		return false, reason
	end
	if #values ~= #Types.CertifiedRuntimeOrder then
		return false, "readinessIds must include the complete certified governance chain"
	end
	for order, readinessId in ipairs(values) do
		if Types.ReadinessId[readinessId] ~= order then
			return false, "readinessIds must match certified governance chain order"
		end
	end
	return true, nil
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

function Validation.integration(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"integrationId",
		Types.SchemaType.GovernanceCertificationIntegration,
		"integration"
	)
	if not ok then
		return false, reason
	end
	if Types.IntegrationKind[schema.integrationKind] ~= true then
		return false, "integration kind is invalid"
	end
	if Types.IntegrationStatus[schema.integrationStatus] ~= true then
		return false, "integration status is invalid"
	end
	if not validId(schema.certificationId) then
		return false, "integration certificationId is invalid"
	end
	if not validId(schema.chainId) then
		return false, "integration chainId is invalid"
	end
	if not validId(schema.coordinator) then
		return false, "integration coordinator is invalid"
	end
	if schema.coordinator ~= "AssetGovernanceCertificationIntegrationCoordinator" then
		return false, "integration coordinator is unsupported"
	end
	if type(schema.integrationVersion) ~= "string" or schema.integrationVersion == "" then
		return false, "integration version is invalid"
	end
	for _, group in ipairs({
		{ schema.reviewIds, "reviewIds" },
		{ schema.auditIds, "auditIds" },
	}) do
		local listOk, listReason =
			validateArrayIds(group[1], Types.Limits.MaxIntegrationChildren, group[2])
		if not listOk then
			return false, listReason
		end
	end
	return true, nil
end

function Validation.chain(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"chainId",
		Types.SchemaType.GovernanceCertificationIntegrationChain,
		"chain"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.integrationId) then
		return false, "chain integrationId is invalid"
	end
	if Types.ChainKind[schema.chainKind] ~= true then
		return false, "chain kind is invalid"
	end
	if Types.ChainStatus[schema.chainStatus] ~= true then
		return false, "chain status is invalid"
	end
	if type(schema.required) ~= "boolean" then
		return false, "chain required must be boolean"
	end
	if type(schema.summary) ~= "string" or schema.summary == "" then
		return false, "chain summary is invalid"
	end
	local runtimeOk, runtimeReason = validateRuntimeNames(schema.runtimeNames)
	if not runtimeOk then
		return false, runtimeReason
	end
	local providerOk, providerReason = validateProviderNames(schema.providerNames)
	if not providerOk then
		return false, providerReason
	end
	return validateReadinessIds(schema.readinessIds)
end

function Validation.review(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"reviewId",
		Types.SchemaType.GovernanceCertificationIntegrationReview,
		"review"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.integrationId) then
		return false, "review integrationId is invalid"
	end
	if Types.RuntimeName[schema.runtimeName] == nil then
		return false, "review runtimeName is unsupported"
	end
	if Types.ProviderName[schema.providerName] ~= Types.RuntimeName[schema.runtimeName] then
		return false, "review providerName does not match runtimeName"
	end
	if Types.ReviewKind[schema.reviewKind] ~= true then
		return false, "review kind is invalid"
	end
	if Types.ReviewStatus[schema.reviewStatus] ~= true then
		return false, "review status is invalid"
	end
	if type(schema.summary) ~= "string" or schema.summary == "" then
		return false, "review summary is invalid"
	end
	return validateArrayIds(schema.evidence, Types.Limits.MaxReviewEvidence, "evidence")
end

function Validation.audit(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"auditId",
		Types.SchemaType.GovernanceCertificationIntegrationAudit,
		"audit"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.integrationId) then
		return false, "audit integrationId is invalid"
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
