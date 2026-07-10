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

local function validateReadinessDeclaration(declaration: any): (boolean, string?)
	if type(declaration) ~= "table" then
		return false, "integration readiness declaration must be a table"
	end
	local safe, reason = Validation.safePayload(declaration)
	if not safe then
		return false, reason
	end
	if not validId(declaration.readinessId) then
		return false, "integration readiness id is invalid"
	end
	if Types.ReadinessKind[declaration.readinessKind] ~= true then
		return false, "integration readiness kind is invalid"
	end
	if Types.ReadinessStatus[declaration.readinessStatus] ~= true then
		return false, "integration readiness status is invalid"
	end
	local runtimeOrder = Types.RuntimeName[declaration.runtimeName]
	if runtimeOrder == nil then
		return false, "integration readiness runtimeName is unsupported"
	end
	if Types.ProviderName[declaration.providerName] ~= runtimeOrder then
		return false, "integration readiness providerName does not match runtimeName"
	end
	if Types.SnapshotProviderName[declaration.snapshotProviderName] ~= runtimeOrder then
		return false, "integration readiness snapshotProviderName does not match runtimeName"
	end
	if Types.CoordinatorName[declaration.coordinatorName] ~= runtimeOrder then
		return false, "integration readiness coordinatorName does not match runtimeName"
	end
	if declaration.diagnosticsProviderName ~= declaration.coordinatorName .. ".inspect" then
		return false, "integration readiness diagnosticsProviderName is invalid"
	end
	if
		type(declaration.documentationReference) ~= "string"
		or declaration.documentationReference == ""
	then
		return false, "integration readiness documentationReference is invalid"
	end
	if type(declaration.metadata) ~= "table" then
		return false, "integration readiness metadata is required"
	end
	if declaration.metadata.copiedMetadataOnly ~= true then
		return false, "integration readiness metadata must be copied only"
	end
	return true, nil
end

local function validateReadinessDeclarations(declarations: any): (boolean, string?)
	if type(declarations) ~= "table" then
		return false, "integration readiness declarations must be a table"
	end
	if #declarations ~= #Types.IntegrationReadinessDeclarations then
		return false, "integration readiness declaration count is invalid"
	end
	local readinessIds: { [string]: boolean } = {}
	local runtimeNames: { [string]: boolean } = {}
	local providerNames: { [string]: boolean } = {}
	local snapshotProviderNames: { [string]: boolean } = {}
	local coordinatorNames: { [string]: boolean } = {}
	local diagnosticsProviderNames: { [string]: boolean } = {}
	for index, declaration in ipairs(declarations) do
		local ok, reason = validateReadinessDeclaration(declaration)
		if not ok then
			return false, reason
		end
		local expected = Types.IntegrationReadinessDeclarations[index]
		if expected == nil then
			return false, "integration readiness declaration index is invalid"
		end
		for _, field in ipairs({
			"readinessId",
			"readinessKind",
			"readinessStatus",
			"runtimeName",
			"providerName",
			"snapshotProviderName",
			"coordinatorName",
			"diagnosticsProviderName",
			"documentationReference",
		}) do
			if declaration[field] ~= expected[field] then
				return false, "integration readiness " .. field .. " mismatch"
			end
		end
		for _, duplicateGroup in ipairs({
			{ readinessIds, declaration.readinessId, "duplicate integration readiness id" },
			{
				runtimeNames,
				declaration.runtimeName,
				"duplicate integration readiness runtimeName",
			},
			{
				providerNames,
				declaration.providerName,
				"duplicate integration readiness providerName",
			},
			{
				snapshotProviderNames,
				declaration.snapshotProviderName,
				"duplicate integration readiness snapshotProviderName",
			},
			{
				coordinatorNames,
				declaration.coordinatorName,
				"duplicate integration readiness coordinatorName",
			},
			{
				diagnosticsProviderNames,
				declaration.diagnosticsProviderName,
				"duplicate integration readiness diagnosticsProviderName",
			},
		}) do
			local seen = duplicateGroup[1]
			local value = duplicateGroup[2]
			if seen[value] then
				return false, duplicateGroup[3]
			end
			seen[value] = true
		end
	end
	return true, nil
end

local function validateDecisionReadinessDeclaration(declaration: any): (boolean, string?)
	if type(declaration) ~= "table" then
		return false, "decision readiness declaration must be a table"
	end
	local safe, reason = Validation.safePayload(declaration)
	if not safe then
		return false, reason
	end
	if not validId(declaration.decisionReadinessId) then
		return false, "decision readiness id is invalid"
	end
	if not validId(declaration.decisionCompatibilityId) then
		return false, "decision compatibility id is invalid"
	end
	if not validId(declaration.decisionDeclarationId) then
		return false, "decision declaration id is invalid"
	end
	if Types.DecisionReadinessKind[declaration.decisionReadinessKind] ~= true then
		return false, "decision readiness kind is invalid"
	end
	if Types.DecisionReadinessStatus[declaration.decisionReadinessStatus] ~= true then
		return false, "decision readiness status is invalid"
	end
	local runtimeOrder = Types.RuntimeName[declaration.runtimeName]
	if runtimeOrder == nil then
		return false, "decision readiness runtimeName is unsupported"
	end
	if Types.ProviderName[declaration.providerName] ~= runtimeOrder then
		return false, "decision readiness providerName does not match runtimeName"
	end
	if Types.SnapshotProviderName[declaration.snapshotProviderName] ~= runtimeOrder then
		return false, "decision readiness snapshotProviderName does not match runtimeName"
	end
	if Types.CoordinatorName[declaration.coordinatorName] ~= runtimeOrder then
		return false, "decision readiness coordinatorName does not match runtimeName"
	end
	if declaration.diagnosticsProviderName ~= declaration.coordinatorName .. ".inspect" then
		return false, "decision readiness diagnosticsProviderName is invalid"
	end
	if declaration.bootstrapDependencyName ~= declaration.coordinatorName then
		return false, "decision readiness bootstrapDependencyName is invalid"
	end
	if declaration.governanceSnapshotProviderName ~= declaration.providerName then
		return false, "decision readiness governanceSnapshotProviderName is invalid"
	end
	if
		type(declaration.documentationReference) ~= "string"
		or declaration.documentationReference == ""
	then
		return false, "decision readiness documentationReference is invalid"
	end
	if type(declaration.metadata) ~= "table" then
		return false, "decision readiness metadata is required"
	end
	for _, field in ipairs({
		"copiedMetadataOnly",
		"copiedEvidenceOnly",
		"decisionReady",
		"observationOnly",
		"validationBeforeMutation",
		"documentationAligned",
		"noDecisionAuthority",
		"noRepairAuthority",
		"noExecutionAuthority",
		"noRuntimeMutation",
	}) do
		if declaration.metadata[field] ~= true then
			return false, "decision readiness metadata " .. field .. " is required"
		end
	end
	return true, nil
end

local function validateDecisionReadinessDeclarations(declarations: any): (boolean, string?)
	if type(declarations) ~= "table" then
		return false, "decision readiness declarations must be a table"
	end
	if #declarations ~= #Types.DecisionReadinessDeclarations then
		return false, "decision readiness declaration count is invalid"
	end
	local decisionReadinessIds: { [string]: boolean } = {}
	local decisionCompatibilityIds: { [string]: boolean } = {}
	local decisionDeclarationIds: { [string]: boolean } = {}
	local runtimeNames: { [string]: boolean } = {}
	local providerNames: { [string]: boolean } = {}
	local snapshotProviderNames: { [string]: boolean } = {}
	local coordinatorNames: { [string]: boolean } = {}
	local diagnosticsProviderNames: { [string]: boolean } = {}
	local bootstrapDependencyNames: { [string]: boolean } = {}
	local governanceSnapshotProviderNames: { [string]: boolean } = {}
	local documentationReferences: { [string]: boolean } = {}
	for index, declaration in ipairs(declarations) do
		local ok, reason = validateDecisionReadinessDeclaration(declaration)
		if not ok then
			return false, reason
		end
		local expected = Types.DecisionReadinessDeclarations[index]
		if expected == nil then
			return false, "decision readiness declaration index is invalid"
		end
		for _, field in ipairs({
			"decisionReadinessId",
			"decisionCompatibilityId",
			"decisionDeclarationId",
			"decisionReadinessKind",
			"decisionReadinessStatus",
			"runtimeName",
			"providerName",
			"snapshotProviderName",
			"coordinatorName",
			"diagnosticsProviderName",
			"bootstrapDependencyName",
			"governanceSnapshotProviderName",
			"documentationReference",
		}) do
			if declaration[field] ~= expected[field] then
				return false, "decision readiness " .. field .. " mismatch"
			end
		end
		for _, duplicateGroup in ipairs({
			{
				decisionReadinessIds,
				declaration.decisionReadinessId,
				"duplicate decision readiness id",
			},
			{
				decisionCompatibilityIds,
				declaration.decisionCompatibilityId,
				"duplicate decision compatibility id",
			},
			{
				decisionDeclarationIds,
				declaration.decisionDeclarationId,
				"duplicate decision declaration id",
			},
			{ runtimeNames, declaration.runtimeName, "duplicate decision readiness runtimeName" },
			{
				providerNames,
				declaration.providerName,
				"duplicate decision readiness providerName",
			},
			{
				snapshotProviderNames,
				declaration.snapshotProviderName,
				"duplicate decision readiness snapshotProviderName",
			},
			{
				coordinatorNames,
				declaration.coordinatorName,
				"duplicate decision readiness coordinatorName",
			},
			{
				diagnosticsProviderNames,
				declaration.diagnosticsProviderName,
				"duplicate decision readiness diagnosticsProviderName",
			},
			{
				bootstrapDependencyNames,
				declaration.bootstrapDependencyName,
				"duplicate decision readiness bootstrapDependencyName",
			},
			{
				governanceSnapshotProviderNames,
				declaration.governanceSnapshotProviderName,
				"duplicate decision readiness governanceSnapshotProviderName",
			},
			{
				documentationReferences,
				declaration.documentationReference,
				"duplicate decision readiness documentationReference",
			},
		}) do
			local seen = duplicateGroup[1]
			local value = duplicateGroup[2]
			if seen[value] then
				return false, duplicateGroup[3]
			end
			seen[value] = true
		end
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
	if Types.FindingSeverity[schema.findingSeverity] ~= true then
		return false, "finding severity is invalid"
	end
	if Types.FindingStatus[schema.findingStatus] ~= true then
		return false, "finding status is invalid"
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
	local integrationOk, integrationReason =
		validateReadinessDeclarations(Types.IntegrationReadinessDeclarations)
	if not integrationOk then
		return false, integrationReason
	end
	return validateDecisionReadinessDeclarations(Types.DecisionReadinessDeclarations)
end

Validation.integrationReadinessDeclaration = validateReadinessDeclaration
Validation.integrationReadinessDeclarations = validateReadinessDeclarations
Validation.decisionReadinessDeclaration = validateDecisionReadinessDeclaration
Validation.decisionReadinessDeclarations = validateDecisionReadinessDeclarations

return Validation
