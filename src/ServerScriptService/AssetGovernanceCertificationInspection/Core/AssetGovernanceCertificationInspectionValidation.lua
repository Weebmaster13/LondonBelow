--!strict

local Serialization = require(script.Parent.AssetGovernanceCertificationInspectionSerialization)
local Types = require(script.Parent.AssetGovernanceCertificationInspectionTypes)

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
	if tags == nil then
		return false, "tags are required"
	end
	return validateArrayIds(tags, Types.Limits.MaxTags, "tags")
end

local function validateEvidence(values: any): (boolean, string?)
	if values == nil then
		return false, "evidence is required"
	end
	return validateArrayIds(values, Types.Limits.MaxEvidence, "evidence")
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
	local tagsOk, tagsReason = validateTags(schema.tags)
	if not tagsOk then
		return false, tagsReason
	end
	if type(schema.metadata) ~= "table" then
		return false, label .. " metadata is required"
	end
	return true, nil
end

local function validateRuntimeProviderSnapshot(schema: any): (boolean, string?)
	local runtimeOrder = Types.RuntimeName[schema.runtimeName]
	if runtimeOrder == nil then
		return false, "runtimeName is unsupported"
	end
	if Types.ProviderName[schema.providerName] ~= runtimeOrder then
		return false, "providerName does not match runtimeName"
	end
	if schema.snapshotProviderName == nil then
		return false, "snapshotProviderName is required"
	end
	if Types.SnapshotProviderName[schema.snapshotProviderName] ~= runtimeOrder then
		return false, "snapshotProviderName does not match runtimeName"
	end
	return true, nil
end

function Validation.safePayload(payload: any): (boolean, string?)
	return Serialization.validateSerializable(payload)
end

function Validation.inspection(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "inspectionId", Types.SchemaType.GovernanceInspection, "inspection")
	if not ok then
		return false, reason
	end
	if Types.InspectionKind[schema.inspectionKind] ~= true then
		return false, "inspection kind is invalid"
	end
	if Types.InspectionStatus[schema.inspectionStatus] ~= true then
		return false, "inspection status is invalid"
	end
	if not validId(schema.integrationId) then
		return false, "inspection integrationId is invalid"
	end
	if not validId(schema.certificationId) then
		return false, "inspection certificationId is invalid"
	end
	if not validId(schema.coverageId) then
		return false, "inspection coverageId is invalid"
	end
	if not validId(schema.inspector) then
		return false, "inspection inspector is invalid"
	end
	if type(schema.inspectionVersion) ~= "string" or schema.inspectionVersion == "" then
		return false, "inspection version is invalid"
	end
	if schema.observationIds == nil then
		return false, "observationIds are required"
	end
	if schema.findingIds == nil then
		return false, "findingIds are required"
	end
	if schema.auditIds == nil then
		return false, "auditIds are required"
	end
	for _, group in ipairs({
		{ schema.observationIds, "observationIds" },
		{ schema.findingIds, "findingIds" },
		{ schema.auditIds, "auditIds" },
	}) do
		local listOk, listReason =
			validateArrayIds(group[1], Types.Limits.MaxInspectionChildren, group[2])
		if not listOk then
			return false, listReason
		end
	end
	return true, nil
end

function Validation.observation(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"observationId",
		Types.SchemaType.GovernanceInspectionObservation,
		"observation"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.inspectionId) then
		return false, "observation inspectionId is invalid"
	end
	local runtimeOk, runtimeReason = validateRuntimeProviderSnapshot(schema)
	if not runtimeOk then
		return false, runtimeReason
	end
	if Types.ObservationKind[schema.observationKind] ~= true then
		return false, "observation kind is invalid"
	end
	if Types.ObservationStatus[schema.observationStatus] ~= true then
		return false, "observation status is invalid"
	end
	if Types.Health[schema.health] ~= true then
		return false, "observation health is invalid"
	end
	return validateEvidence(schema.evidence)
end

function Validation.finding(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "findingId", Types.SchemaType.GovernanceInspectionFinding, "finding")
	if not ok then
		return false, reason
	end
	if not validId(schema.inspectionId) then
		return false, "finding inspectionId is invalid"
	end
	if not validId(schema.observationId) then
		return false, "finding observationId is invalid"
	end
	local runtimeOk, runtimeReason = validateRuntimeProviderSnapshot(schema)
	if not runtimeOk then
		return false, runtimeReason
	end
	if Types.FindingKind[schema.findingKind] ~= true then
		return false, "finding kind is invalid"
	end
	if Types.Severity[schema.severity] ~= true then
		return false, "finding severity is invalid"
	end
	if type(schema.summary) ~= "string" or schema.summary == "" then
		return false, "finding summary is invalid"
	end
	return validateEvidence(schema.evidence)
end

function Validation.audit(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "auditId", Types.SchemaType.GovernanceInspectionAudit, "audit")
	if not ok then
		return false, reason
	end
	if not validId(schema.inspectionId) then
		return false, "audit inspectionId is invalid"
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
	if schema.findingIds == nil then
		return false, "findingIds are required"
	end
	local findingOk, findingReason =
		validateArrayIds(schema.findingIds, Types.Limits.MaxInspectionChildren, "findingIds")
	if not findingOk then
		return false, findingReason
	end
	if schema.findings == nil then
		return false, "findings are required"
	end
	return validateArrayIds(schema.findings, Types.Limits.MaxAuditFindings, "findings")
end

function Validation.validate(): (boolean, string?)
	return true, nil
end

return Validation
