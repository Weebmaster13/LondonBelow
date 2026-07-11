--!strict

local Serialization = require(script.Parent.AssetExecutionGovernanceSerialization)
local Types = require(script.Parent.AssetExecutionGovernanceTypes)

local Validation = {}

local fieldLookup: { [string]: { [string]: boolean } } = {}
for schemaName, fields in pairs(Types.SchemaFields) do
	local lookup = {}
	for _, field in ipairs(fields) do
		lookup[field] = true
	end
	fieldLookup[schemaName] = lookup
end

local integrationFieldLookup: { [string]: boolean } = {}
for _, field in ipairs(Types.IntegrationReadinessDeclarationFields) do
	integrationFieldLookup[field] = true
end

local integrationMetadataFieldLookup: { [string]: boolean } = {}
for _, field in ipairs(Types.IntegrationReadinessMetadataFields) do
	integrationMetadataFieldLookup[field] = true
end

local authorizationFieldLookup: { [string]: boolean } = {}
for _, field in ipairs(Types.AuthorizationReadinessDeclarationFields) do
	authorizationFieldLookup[field] = true
end

local authorizationMetadataFieldLookup: { [string]: boolean } = {}
for _, field in ipairs(Types.AuthorizationReadinessMetadataFields) do
	authorizationMetadataFieldLookup[field] = true
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

local function validateRuntimeProviderSnapshot(schema: any): (boolean, string?)
	if schema.runtimeName ~= "AssetExecutionGovernance" then
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
	local safe, reason = Serialization.validateSerializable(schema)
	if not safe then
		return false, reason
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
	if type(schema.metadata) ~= "table" then
		return false, label .. " metadata is required"
	end
	return true, nil
end

function Validation.governance(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "governanceId", Types.SchemaType.ExecutionGovernance, "governance")
	if not ok then
		return false, reason
	end
	if not validId(schema.decisionId) then
		return false, "governance decisionId is invalid"
	end
	if not validId(schema.executionReadinessId) then
		return false, "governance executionReadinessId is invalid"
	end
	local runtimeOk, runtimeReason = validateRuntimeProviderSnapshot(schema)
	if not runtimeOk then
		return false, runtimeReason
	end
	if Types.GovernanceKind[schema.governanceKind] ~= true then
		return false, "governanceKind is invalid"
	end
	if Types.GovernanceStatus[schema.governanceStatus] ~= true then
		return false, "governanceStatus is invalid"
	end
	for _, group in ipairs({
		{ schema.requirementIds, "requirementIds" },
		{ schema.assessmentIds, "assessmentIds" },
		{ schema.findingIds, "findingIds" },
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
		Types.SchemaType.ExecutionGovernanceRequirement,
		"requirement"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.governanceId) then
		return false, "requirement governanceId is invalid"
	end
	local runtimeOk, runtimeReason = validateRuntimeProviderSnapshot(schema)
	if not runtimeOk then
		return false, runtimeReason
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

function Validation.assessment(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"assessmentId",
		Types.SchemaType.ExecutionGovernanceAssessment,
		"assessment"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.governanceId) then
		return false, "assessment governanceId is invalid"
	end
	if not validId(schema.requirementId) then
		return false, "assessment requirementId is invalid"
	end
	local runtimeOk, runtimeReason = validateRuntimeProviderSnapshot(schema)
	if not runtimeOk then
		return false, runtimeReason
	end
	if Types.AssessmentKind[schema.assessmentKind] ~= true then
		return false, "assessmentKind is invalid"
	end
	if Types.AssessmentStatus[schema.assessmentStatus] ~= true then
		return false, "assessmentStatus is invalid"
	end
	return validateEvidence(schema.evidence)
end

function Validation.finding(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "findingId", Types.SchemaType.ExecutionGovernanceFinding, "finding")
	if not ok then
		return false, reason
	end
	if not validId(schema.governanceId) then
		return false, "finding governanceId is invalid"
	end
	if not validId(schema.assessmentId) then
		return false, "finding assessmentId is invalid"
	end
	if Types.FindingKind[schema.findingKind] ~= true then
		return false, "findingKind is invalid"
	end
	if Types.FindingSeverity[schema.findingSeverity] ~= true then
		return false, "findingSeverity is invalid"
	end
	if Types.FindingStatus[schema.findingStatus] ~= true then
		return false, "findingStatus is invalid"
	end
	if
		type(schema.summary) ~= "string"
		or schema.summary == ""
		or #schema.summary > Types.Limits.MaxSummaryLength
	then
		return false, "finding summary is invalid"
	end
	return validateEvidence(schema.evidence)
end

function Validation.audit(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "auditId", Types.SchemaType.ExecutionGovernanceAudit, "audit")
	if not ok then
		return false, reason
	end
	if not validId(schema.governanceId) then
		return false, "audit governanceId is invalid"
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
		{ schema.assessmentIds, "assessmentIds" },
		{ schema.findingIds, "findingIds" },
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

local function valuesEqual(left: any, right: any): boolean
	if type(left) ~= type(right) then
		return false
	end
	if type(left) ~= "table" then
		return left == right
	end
	local leftCount = 0
	for key, leftValue in pairs(left) do
		leftCount += 1
		if not valuesEqual(leftValue, right[key]) then
			return false
		end
	end
	local rightCount = 0
	for _ in pairs(right) do
		rightCount += 1
	end
	return leftCount == rightCount
end

local function validateExactOrderedValue(
	values: { string },
	index: number,
	actual: any,
	label: string
): (boolean, string?)
	if values[index] ~= actual then
		return false, label .. " order drift"
	end
	return true, nil
end

local function validateIntegrationMetadata(declaration: any, expected: any?): (boolean, string?)
	local metadata = declaration.metadata
	if type(metadata) ~= "table" then
		return false, "integration metadata is required"
	end
	local fieldCount = 0
	for key in pairs(metadata) do
		fieldCount += 1
		if type(key) ~= "string" or integrationMetadataFieldLookup[key] ~= true then
			return false, "integration metadata contains unsupported field"
		end
	end
	if fieldCount ~= #Types.IntegrationReadinessMetadataFields then
		return false, "integration metadata field count is invalid"
	end
	if metadata.copied ~= true then
		return false, "integration metadata copied flag drift"
	end
	if
		type(metadata.order) ~= "number"
		or metadata.order ~= math.floor(metadata.order)
		or metadata.order < 1
		or metadata.order > Types.Limits.MaxIntegrationDeclarations
	then
		return false, "integration metadata order is invalid"
	end
	if not validId(metadata.compatibility) then
		return false, "integration metadata compatibility is invalid"
	end
	if expected ~= nil and not valuesEqual(metadata, expected.metadata) then
		return false, "integration metadata drift"
	end
	return true, nil
end

function Validation.integrationReadinessDeclaration(
	declaration: any,
	expected: any?
): (boolean, string?)
	if declaration == nil then
		return false, "integration readiness declaration is nil"
	end
	if type(declaration) ~= "table" then
		return false, "integration readiness declaration must be a table"
	end
	local safe, safeReason = Serialization.validateSerializable(declaration)
	if not safe then
		return false, safeReason
	end
	local fieldCount = 0
	for key in pairs(declaration) do
		fieldCount += 1
		if type(key) ~= "string" or integrationFieldLookup[key] ~= true then
			return false, "integration readiness declaration contains unsupported field"
		end
	end
	if fieldCount ~= #Types.IntegrationReadinessDeclarationFields then
		return false, "integration readiness declaration field count is invalid"
	end
	if not validId(declaration.integrationId) then
		return false, "integrationId is invalid"
	end
	if not validId(declaration.compatibilityId) then
		return false, "compatibilityId is invalid"
	end
	if not validId(declaration.integrationDeclarationId) then
		return false, "integrationDeclarationId is invalid"
	end
	if Types.IntegrationKind[declaration.integrationKind] ~= true then
		return false, "integrationKind is invalid"
	end
	if Types.IntegrationStatus[declaration.integrationStatus] ~= true then
		return false, "integrationStatus is invalid"
	end
	if Types.AuthorizationBoundaryKind[declaration.authorizationBoundaryKind] ~= true then
		return false, "authorizationBoundaryKind is invalid"
	end
	if declaration.runtimeName ~= Types.RuntimeIdentity.runtimeName then
		return false, "integration runtimeName drift"
	end
	if declaration.providerName ~= Types.RuntimeIdentity.providerName then
		return false, "integration providerName drift"
	end
	if declaration.snapshotProviderName ~= Types.RuntimeIdentity.snapshotProviderName then
		return false, "integration snapshotProviderName drift"
	end
	if declaration.coordinatorName ~= Types.RuntimeIdentity.coordinatorName then
		return false, "integration coordinatorName drift"
	end
	if declaration.diagnosticsProviderName ~= Types.RuntimeIdentity.diagnosticsProviderName then
		return false, "integration diagnosticsProviderName drift"
	end
	if declaration.bootstrapDependencyName ~= Types.RuntimeIdentity.bootstrapDependencyName then
		return false, "integration bootstrapDependencyName drift"
	end
	if
		declaration.engineGovernanceSnapshotProviderName
		~= Types.RuntimeIdentity.engineGovernanceSnapshotProviderName
	then
		return false, "integration engineGovernanceSnapshotProviderName drift"
	end
	if declaration.documentationReference ~= Types.RuntimeIdentity.documentationReference then
		return false, "integration documentationReference drift"
	end
	if declaration.decisionRuntimeName ~= Types.DecisionRuntimeIdentity.decisionRuntimeName then
		return false, "integration decisionRuntimeName drift"
	end
	if declaration.decisionProviderName ~= Types.DecisionRuntimeIdentity.decisionProviderName then
		return false, "integration decisionProviderName drift"
	end
	if
		declaration.decisionSnapshotProviderName
		~= Types.DecisionRuntimeIdentity.decisionSnapshotProviderName
	then
		return false, "integration decisionSnapshotProviderName drift"
	end
	if declaration.executionReadinessEvidenceKind ~= Types.ExecutionReadinessEvidenceKind then
		return false, "integration executionReadinessEvidenceKind drift"
	end
	if
		declaration.executionGovernanceRuntimeName
		~= Types.ExecutionGovernanceIdentity.executionGovernanceRuntimeName
	then
		return false, "integration executionGovernanceRuntimeName drift"
	end
	if
		declaration.executionGovernanceProviderName
		~= Types.ExecutionGovernanceIdentity.executionGovernanceProviderName
	then
		return false, "integration executionGovernanceProviderName drift"
	end
	if
		declaration.executionGovernanceSnapshotProviderName
		~= Types.ExecutionGovernanceIdentity.executionGovernanceSnapshotProviderName
	then
		return false, "integration executionGovernanceSnapshotProviderName drift"
	end
	if type(declaration.required) ~= "boolean" then
		return false, "integration required must be boolean"
	end
	local evidenceOk, evidenceReason = validateEvidence(declaration.evidence)
	if not evidenceOk then
		return false, evidenceReason
	end
	local tagsOk, tagsReason = validateTags(declaration.tags)
	if not tagsOk then
		return false, tagsReason
	end
	local metadataOk, metadataReason = validateIntegrationMetadata(declaration, expected)
	if not metadataOk then
		return false, metadataReason
	end
	if expected ~= nil and not valuesEqual(declaration, expected) then
		return false, "integration readiness declaration drift"
	end
	return true, nil
end

function Validation.integrationReadinessDeclarations(declarations: any): (boolean, string?)
	if declarations == nil then
		return false, "integration readiness declarations are nil"
	end
	if type(declarations) ~= "table" then
		return false, "integration readiness declarations must be a table"
	end
	local count = 0
	for key in pairs(declarations) do
		if type(key) ~= "number" or key ~= math.floor(key) or key < 1 then
			return false, "integration readiness declarations must be an ordered array"
		end
		count += 1
	end
	if count ~= #declarations then
		return false, "integration readiness declarations must not be sparse"
	end
	if count ~= Types.Limits.MaxIntegrationDeclarations then
		return false, "integration readiness declaration count drift"
	end
	if count ~= #Types.IntegrationReadinessDeclarations then
		return false, "integration readiness declaration source count drift"
	end
	local seenIds: { [string]: boolean } = {}
	local seenCompatibilities: { [string]: boolean } = {}
	local seenDeclarations: { [string]: boolean } = {}
	local seenKinds: { [string]: boolean } = {}
	for index, declaration in ipairs(declarations) do
		for _, ordered in ipairs({
			{
				Types.IntegrationReadinessDeclarationOrder,
				declaration.integrationId,
				"integrationId",
			},
			{
				Types.IntegrationReadinessCompatibilityOrder,
				declaration.compatibilityId,
				"compatibilityId",
			},
			{
				Types.IntegrationReadinessDeclarationIdOrder,
				declaration.integrationDeclarationId,
				"integrationDeclarationId",
			},
			{
				Types.IntegrationReadinessKindOrder,
				declaration.integrationKind,
				"integrationKind",
			},
			{
				Types.IntegrationReadinessStatusOrder,
				declaration.integrationStatus,
				"integrationStatus",
			},
			{
				Types.IntegrationReadinessBoundaryOrder,
				declaration.authorizationBoundaryKind,
				"authorizationBoundaryKind",
			},
		}) do
			local orderedOk, orderedReason =
				validateExactOrderedValue(ordered[1], index, ordered[2], ordered[3])
			if not orderedOk then
				return false, orderedReason
			end
		end
		local ok, reason = Validation.integrationReadinessDeclaration(
			declaration,
			Types.IntegrationReadinessDeclarations[index]
		)
		if not ok then
			return false, reason
		end
		if seenIds[declaration.integrationId] then
			return false, "integrationId duplicate"
		end
		if seenCompatibilities[declaration.compatibilityId] then
			return false, "compatibilityId duplicate"
		end
		if seenDeclarations[declaration.integrationDeclarationId] then
			return false, "integrationDeclarationId duplicate"
		end
		if seenKinds[declaration.integrationKind] then
			return false, "integrationKind duplicate"
		end
		if declaration.metadata.order ~= index then
			return false, "integration metadata order drift"
		end
		seenIds[declaration.integrationId] = true
		seenCompatibilities[declaration.compatibilityId] = true
		seenDeclarations[declaration.integrationDeclarationId] = true
		seenKinds[declaration.integrationKind] = true
	end
	return true, nil
end

local function validateAuthorizationMetadata(declaration: any, expected: any?): (boolean, string?)
	local metadata = declaration.metadata
	if type(metadata) ~= "table" then
		return false, "authorization readiness metadata is required"
	end
	local fieldCount = 0
	for key in pairs(metadata) do
		fieldCount += 1
		if type(key) ~= "string" or authorizationMetadataFieldLookup[key] ~= true then
			return false, "authorization readiness metadata contains unsupported field"
		end
	end
	if fieldCount ~= #Types.AuthorizationReadinessMetadataFields then
		return false, "authorization readiness metadata field count is invalid"
	end
	if metadata.copied ~= true then
		return false, "authorization readiness metadata copied flag drift"
	end
	if
		type(metadata.order) ~= "number"
		or metadata.order ~= math.floor(metadata.order)
		or metadata.order < 1
		or metadata.order > Types.Limits.MaxAuthorizationReadinessDeclarations
	then
		return false, "authorization readiness metadata order is invalid"
	end
	if not validId(metadata.compatibility) then
		return false, "authorization readiness metadata compatibility is invalid"
	end
	if not validId(metadata.dependency) then
		return false, "authorization readiness metadata dependency is invalid"
	end
	if expected ~= nil and not valuesEqual(metadata, expected.metadata) then
		return false, "authorization readiness metadata drift"
	end
	return true, nil
end

function Validation.authorizationReadinessDeclaration(
	declaration: any,
	expected: any?
): (boolean, string?)
	if declaration == nil then
		return false, "authorization readiness declaration is nil"
	end
	if type(declaration) ~= "table" then
		return false, "authorization readiness declaration must be a table"
	end
	local safe, safeReason = Serialization.validateSerializable(declaration)
	if not safe then
		return false, safeReason
	end
	local fieldCount = 0
	for key in pairs(declaration) do
		fieldCount += 1
		if type(key) ~= "string" or authorizationFieldLookup[key] ~= true then
			return false, "authorization readiness declaration contains unsupported field"
		end
	end
	if fieldCount ~= #Types.AuthorizationReadinessDeclarationFields then
		return false, "authorization readiness declaration field count is invalid"
	end
	for _, idField in ipairs({
		"authorizationReadinessId",
		"authorizationCompatibilityId",
		"authorizationDependencyId",
		"authorizationIdentityId",
		"authorizationBoundaryId",
		"governanceCompatibilityId",
	}) do
		if not validId(declaration[idField]) then
			return false, idField .. " is invalid"
		end
	end
	if Types.AuthorizationReadinessKind[declaration.authorizationReadinessKind] ~= true then
		return false, "authorizationReadinessKind is invalid"
	end
	if Types.AuthorizationReadinessStatus[declaration.authorizationReadinessStatus] ~= true then
		return false, "authorizationReadinessStatus is invalid"
	end
	if Types.AuthorizationReadinessBoundaryKind[declaration.authorizationBoundaryKind] ~= true then
		return false, "authorizationBoundaryKind is invalid"
	end
	if declaration.runtimeName ~= Types.RuntimeIdentity.runtimeName then
		return false, "authorization readiness runtimeName drift"
	end
	if declaration.providerName ~= Types.RuntimeIdentity.providerName then
		return false, "authorization readiness providerName drift"
	end
	if declaration.snapshotProviderName ~= Types.RuntimeIdentity.snapshotProviderName then
		return false, "authorization readiness snapshotProviderName drift"
	end
	if declaration.coordinatorName ~= Types.RuntimeIdentity.coordinatorName then
		return false, "authorization readiness coordinatorName drift"
	end
	if declaration.diagnosticsProviderName ~= Types.RuntimeIdentity.diagnosticsProviderName then
		return false, "authorization readiness diagnosticsProviderName drift"
	end
	if declaration.bootstrapDependencyName ~= Types.RuntimeIdentity.bootstrapDependencyName then
		return false, "authorization readiness bootstrapDependencyName drift"
	end
	if
		declaration.engineGovernanceSnapshotProviderName
		~= Types.RuntimeIdentity.engineGovernanceSnapshotProviderName
	then
		return false, "authorization readiness engineGovernanceSnapshotProviderName drift"
	end
	if declaration.documentationReference ~= "ASSET_EXECUTION_GOVERNANCE_RUNTIME.md" then
		return false, "authorization readiness documentationReference drift"
	end
	if declaration.executionReadinessEvidenceKind ~= Types.ExecutionReadinessEvidenceKind then
		return false, "authorization readiness executionReadinessEvidenceKind drift"
	end
	if
		declaration.futureAuthorizationRuntimeName
		~= Types.FutureAuthorizationIdentity.futureAuthorizationRuntimeName
	then
		return false, "authorization readiness futureAuthorizationRuntimeName drift"
	end
	if
		declaration.futureAuthorizationProviderName
		~= Types.FutureAuthorizationIdentity.futureAuthorizationProviderName
	then
		return false, "authorization readiness futureAuthorizationProviderName drift"
	end
	if
		declaration.futureAuthorizationSnapshotKind
		~= Types.FutureAuthorizationIdentity.futureAuthorizationSnapshotKind
	then
		return false, "authorization readiness futureAuthorizationSnapshotKind drift"
	end
	if
		declaration.futureExecutionRuntimeName
		~= Types.FutureExecutionIdentity.futureExecutionRuntimeName
	then
		return false, "authorization readiness futureExecutionRuntimeName drift"
	end
	if
		declaration.futureExecutionProviderName
		~= Types.FutureExecutionIdentity.futureExecutionProviderName
	then
		return false, "authorization readiness futureExecutionProviderName drift"
	end
	if type(declaration.required) ~= "boolean" then
		return false, "authorization readiness required must be boolean"
	end
	local evidenceOk, evidenceReason = validateEvidence(declaration.evidence)
	if not evidenceOk then
		return false, evidenceReason
	end
	local tagsOk, tagsReason = validateTags(declaration.tags)
	if not tagsOk then
		return false, tagsReason
	end
	local metadataOk, metadataReason = validateAuthorizationMetadata(declaration, expected)
	if not metadataOk then
		return false, metadataReason
	end
	if expected ~= nil and not valuesEqual(declaration, expected) then
		return false, "authorization readiness declaration drift"
	end
	return true, nil
end

function Validation.authorizationReadinessDeclarations(declarations: any): (boolean, string?)
	if declarations == nil then
		return false, "authorization readiness declarations are nil"
	end
	if type(declarations) ~= "table" then
		return false, "authorization readiness declarations must be a table"
	end
	local count = 0
	for key in pairs(declarations) do
		if type(key) ~= "number" or key ~= math.floor(key) or key < 1 then
			return false, "authorization readiness declarations must be an ordered array"
		end
		count += 1
	end
	if count ~= #declarations then
		return false, "authorization readiness declarations must not be sparse"
	end
	if count ~= Types.Limits.MaxAuthorizationReadinessDeclarations then
		return false, "authorization readiness declaration count drift"
	end
	if count ~= #Types.AuthorizationReadinessDeclarations then
		return false, "authorization readiness declaration source count drift"
	end
	local seenReadinessIds: { [string]: boolean } = {}
	local seenCompatibilityIds: { [string]: boolean } = {}
	local seenDependencyIds: { [string]: boolean } = {}
	local seenIdentityIds: { [string]: boolean } = {}
	local seenBoundaryIds: { [string]: boolean } = {}
	local seenKinds: { [string]: boolean } = {}
	for index, declaration in ipairs(declarations) do
		for _, ordered in ipairs({
			{
				Types.AuthorizationReadinessDeclarationOrder,
				declaration.authorizationReadinessId,
				"authorizationReadinessId",
			},
			{
				Types.AuthorizationReadinessCompatibilityOrder,
				declaration.authorizationCompatibilityId,
				"authorizationCompatibilityId",
			},
			{
				Types.AuthorizationReadinessDependencyOrder,
				declaration.authorizationDependencyId,
				"authorizationDependencyId",
			},
			{
				Types.AuthorizationReadinessIdentityOrder,
				declaration.authorizationIdentityId,
				"authorizationIdentityId",
			},
			{
				Types.AuthorizationReadinessBoundaryOrder,
				declaration.authorizationBoundaryId,
				"authorizationBoundaryId",
			},
			{
				Types.AuthorizationReadinessKindOrder,
				declaration.authorizationReadinessKind,
				"authorizationReadinessKind",
			},
			{
				Types.AuthorizationReadinessStatusOrder,
				declaration.authorizationReadinessStatus,
				"authorizationReadinessStatus",
			},
			{
				Types.AuthorizationReadinessBoundaryKindOrder,
				declaration.authorizationBoundaryKind,
				"authorizationBoundaryKind",
			},
		}) do
			local orderedOk, orderedReason =
				validateExactOrderedValue(ordered[1], index, ordered[2], ordered[3])
			if not orderedOk then
				return false, orderedReason
			end
		end
		local ok, reason = Validation.authorizationReadinessDeclaration(
			declaration,
			Types.AuthorizationReadinessDeclarations[index]
		)
		if not ok then
			return false, reason
		end
		if seenReadinessIds[declaration.authorizationReadinessId] then
			return false, "authorizationReadinessId duplicate"
		end
		if seenCompatibilityIds[declaration.authorizationCompatibilityId] then
			return false, "authorizationCompatibilityId duplicate"
		end
		if seenDependencyIds[declaration.authorizationDependencyId] then
			return false, "authorizationDependencyId duplicate"
		end
		if seenIdentityIds[declaration.authorizationIdentityId] then
			return false, "authorizationIdentityId duplicate"
		end
		if seenBoundaryIds[declaration.authorizationBoundaryId] then
			return false, "authorizationBoundaryId duplicate"
		end
		if seenKinds[declaration.authorizationReadinessKind] then
			return false, "authorizationReadinessKind duplicate"
		end
		if declaration.metadata.order ~= index then
			return false, "authorization readiness metadata order drift"
		end
		seenReadinessIds[declaration.authorizationReadinessId] = true
		seenCompatibilityIds[declaration.authorizationCompatibilityId] = true
		seenDependencyIds[declaration.authorizationDependencyId] = true
		seenIdentityIds[declaration.authorizationIdentityId] = true
		seenBoundaryIds[declaration.authorizationBoundaryId] = true
		seenKinds[declaration.authorizationReadinessKind] = true
	end
	return true, nil
end

function Validation.validate(): (boolean, string?)
	if Types.RuntimeProviderName ~= "assetExecutionGovernanceRuntime" then
		return false, "provider name drift"
	end
	if Types.SnapshotKind ~= "assetExecutionGovernanceRuntimeSnapshot" then
		return false, "snapshot kind drift"
	end
	if
		Types.IntegrationReadinessDocumentationReferencePolicy
		~= "SharedIntegrationReadinessDocument"
	then
		return false, "integration documentation reference policy drift"
	end
	if
		Types.AuthorizationReadinessDocumentationReferencePolicy
		~= "SharedAuthorizationReadinessDocument"
	then
		return false, "authorization readiness documentation reference policy drift"
	end
	local integrationOk, integrationReason =
		Validation.integrationReadinessDeclarations(Types.IntegrationReadinessDeclarations)
	if not integrationOk then
		return false, integrationReason
	end
	return Validation.authorizationReadinessDeclarations(Types.AuthorizationReadinessDeclarations)
end

Validation.validId = validId

return Validation
