--!strict

local Serialization = require(script.Parent.AssetExecutionSerialization)
local Types = require(script.Parent.AssetExecutionTypes)

local Validation = {}

local EXPECTED_SCHEMA_FIELDS = {
	ExecutionRuntime = {
		"runtimeId",
		"authorizationId",
		"readinessId",
		"runtimeKind",
		"runtimeStatus",
		"providerName",
		"snapshotProviderName",
		"requestIds",
		"boundaryIds",
		"auditIds",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionRequest = {
		"requestId",
		"runtimeId",
		"requestKind",
		"requestStatus",
		"requestedBy",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionBoundary = {
		"boundaryId",
		"runtimeId",
		"boundaryKind",
		"boundaryStatus",
		"summary",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAudit = {
		"auditId",
		"runtimeId",
		"requestIds",
		"boundaryIds",
		"auditKind",
		"auditStatus",
		"reviewer",
		"evidence",
		"tags",
		"metadata",
	},
}

local EXPECTED_ENUMS = {
	RuntimeKind = {
		"MetadataRuntime",
		"RequestRuntime",
		"BoundaryRuntime",
		"AuditRuntime",
		"FuturePipelineRuntime",
	},
	RuntimeStatus = {
		"Declared",
		"Ready",
		"Deferred",
		"Warning",
		"Blocked",
	},
	RequestKind = {
		"RuntimeMetadataRequest",
		"ReadinessMetadataRequest",
		"BoundaryMetadataRequest",
		"AuditMetadataRequest",
		"FuturePipelineRequest",
	},
	RequestStatus = {
		"Declared",
		"Validated",
		"Deferred",
		"Warning",
		"Blocked",
	},
	BoundaryKind = {
		"NoAssetLoading",
		"NoAssetStreaming",
		"NoAssetSpawning",
		"NoAssetApplication",
		"NoAssetPlayback",
		"NoPresentation",
		"NoSave",
		"NoGameplay",
		"NoNetworking",
		"NoWorldMutation",
		"NoPersistence",
		"NoRouting",
		"NoDispatch",
		"NoQueueing",
		"NoScheduling",
		"NoOrchestration",
	},
	BoundaryStatus = {
		"Declared",
		"Satisfied",
		"Deferred",
		"Warning",
		"Blocked",
	},
	AuditKind = {
		"RuntimeAudit",
		"RequestAudit",
		"BoundaryAudit",
		"ProductionAudit",
	},
	AuditStatus = {
		"Passed",
		"Failed",
		"Warning",
		"Deferred",
		"Blocked",
	},
	IntegrationKind = {
		"AuthorizationRuntimeCompatibility",
		"AuthorizationProviderCompatibility",
		"AuthorizationSnapshotCompatibility",
		"ExecutionReadinessCompatibility",
		"ExecutionRuntimeCompatibility",
		"ExecutionProviderCompatibility",
		"ExecutionSnapshotCompatibility",
		"ExecutionCoordinatorCompatibility",
		"BootstrapCompatibility",
		"EngineGovernanceCompatibility",
		"DocumentationCompatibility",
		"SchemaCompatibility",
		"EnumCompatibility",
		"ReferenceIntegrityCompatibility",
		"SerializationCompatibility",
		"DiagnosticsCompatibility",
		"SnapshotIsolationCompatibility",
		"RuntimeLimitCompatibility",
		"SignalBoundaryCompatibility",
		"CoordinatorBoundaryCompatibility",
		"LifecycleCompatibility",
		"FutureAdapterSeparation",
		"FutureAssetOperationSeparation",
		"FutureGameplaySeparation",
	},
	IntegrationStatus = {
		"Declared",
		"Compatible",
		"IntegrationReady",
		"BoundaryReady",
		"ObservationOnly",
		"Deferred",
		"Warning",
		"Blocked",
	},
	AdapterBoundaryKind = {
		"NoExecutionAdapter",
		"NoAssetLoaderAdapter",
		"NoAssetSpawnAdapter",
		"NoAssetApplicationAdapter",
		"NoAssetPlaybackAdapter",
		"NoRoutingAdapter",
		"NoDispatchAdapter",
		"NoQueueAdapter",
		"NoSchedulerAdapter",
		"NoOrchestrationAdapter",
		"FutureAdapterSeparate",
	},
	AssetOperationBoundaryKind = {
		"NoAssetLoading",
		"NoAssetPreloading",
		"NoAssetStreaming",
		"NoAssetSpawning",
		"NoAssetCloning",
		"NoAssetInsertion",
		"NoAssetApplication",
		"NoAssetDisplay",
		"NoAssetPlayback",
		"NoAnimationPlayback",
		"NoAudioPlayback",
		"NoWorldMutation",
		"NoStorageMutation",
		"NoNetworkOwnership",
		"NoPhysicsExecution",
		"NoGameplayExecution",
		"FutureAssetOperationsSeparate",
		"FutureGameplaySeparate",
	},
}

local EXPECTED_LIMITS = {
	MaxRuntimes = 160,
	MaxRequests = 480,
	MaxBoundaries = 320,
	MaxAudits = 240,
	MaxValidationFailures = 220,
	MaxSnapshotHistory = 60,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 520,
	MaxStringLength = 280,
	MaxTags = 32,
	MaxEvidence = 56,
	MaxChildReferences = 220,
	MaxSummaryLength = 180,
}

local EXPECTED_POSTURE_KEYS = {
	"assetExecutionRuntimePosture",
	"assetExecutionRequestPosture",
	"assetExecutionBoundaryPosture",
	"assetExecutionAuditPosture",
	"assetExecutionIntegrationReadinessPosture",
	"assetExecutionCompatibilityPosture",
	"assetExecutionSchemaPosture",
	"assetExecutionEnumPosture",
	"assetExecutionReferencePosture",
	"assetExecutionArrayPosture",
	"assetExecutionLimitPosture",
	"assetExecutionSignalPosture",
	"assetExecutionCoordinatorBoundaryPosture",
	"assetExecutionFutureAdapterSeparationPosture",
	"assetExecutionFutureAssetOperationSeparationPosture",
	"assetExecutionFutureGameplaySeparationPosture",
	"assetExecutionIsolationPosture",
	"assetExecutionValidationPosture",
	"assetExecutionLifecyclePosture",
	"assetExecutionNoAuthorityPosture",
	"noExecution",
	"noAssetLoading",
	"noGameplay",
	"noPresentation",
	"noSave",
	"noNetworking",
	"noAnalytics",
	"noTelemetry",
}

local EXPECTED_COORDINATOR_API = {
	"initialize",
	"start",
	"shutdown",
	"registerExecutionRuntime",
	"registerExecutionRequest",
	"registerExecutionBoundary",
	"registerExecutionAudit",
	"inspect",
	"getSnapshot",
	"validate",
	"runSelfChecks",
}

local EXPECTED_SIGNAL_NAMES = {
	Initialized = "AssetExecutionRuntime.Initialized",
	Started = "AssetExecutionRuntime.Started",
	Shutdown = "AssetExecutionRuntime.Shutdown",
	ValidationFailed = "AssetExecutionRuntime.ValidationFailed",
}

local EXPECTED_INTEGRATION_DECLARATION_FIELDS = {
	"integrationId",
	"compatibilityId",
	"integrationDeclarationId",
	"integrationKind",
	"integrationStatus",
	"runtimeName",
	"providerName",
	"snapshotProviderName",
	"coordinatorName",
	"diagnosticsProviderName",
	"bootstrapDependencyName",
	"engineGovernanceSnapshotProviderName",
	"documentationReference",
	"authorizationRuntimeName",
	"authorizationProviderName",
	"authorizationSnapshotProviderName",
	"readinessEvidenceKind",
	"executionRuntimeName",
	"executionProviderName",
	"executionSnapshotProviderName",
	"executionCoordinatorName",
	"adapterBoundaryKind",
	"assetOperationBoundaryKind",
	"required",
	"evidence",
	"tags",
	"metadata",
}

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

local function validateExactBoolMap(
	values: { [string]: boolean },
	expected: { string },
	label: string
): (boolean, string?)
	local count = 0
	for key, value in pairs(values) do
		count += 1
		if value ~= true then
			return false, label .. " value drift"
		end
		local found = false
		for _, expectedKey in ipairs(expected) do
			if key == expectedKey then
				found = true
				break
			end
		end
		if not found then
			return false, label .. " unsupported value"
		end
	end
	if count ~= #expected then
		return false, label .. " count drift"
	end
	for _, expectedKey in ipairs(expected) do
		if values[expectedKey] ~= true then
			return false, label .. " missing value"
		end
	end
	return true, nil
end

local function validateExactNumberMap(
	values: { [string]: number },
	expected: { [string]: number },
	label: string
): (boolean, string?)
	local count = 0
	for key, value in pairs(values) do
		count += 1
		if expected[key] == nil then
			return false, label .. " unsupported key"
		end
		if value ~= expected[key] then
			return false, label .. " value drift"
		end
	end
	local expectedCount = 0
	for key in pairs(expected) do
		expectedCount += 1
		if values[key] ~= expected[key] then
			return false, label .. " missing value"
		end
	end
	if count ~= expectedCount then
		return false, label .. " count drift"
	end
	return true, nil
end

local function validateExactStringMap(
	values: { [string]: string },
	expected: { [string]: string },
	label: string
): (boolean, string?)
	local count = 0
	for key, value in pairs(values) do
		count += 1
		if expected[key] == nil then
			return false, label .. " unsupported key"
		end
		if value ~= expected[key] then
			return false, label .. " value drift"
		end
	end
	local expectedCount = 0
	for key in pairs(expected) do
		expectedCount += 1
		if values[key] ~= expected[key] then
			return false, label .. " missing value"
		end
	end
	if count ~= expectedCount then
		return false, label .. " count drift"
	end
	return true, nil
end

local function orderNameForField(fieldName: string): string
	return string.upper(string.sub(fieldName, 1, 1)) .. string.sub(fieldName, 2) .. "Order"
end

local function validateExactDeclarationArray(
	values: any,
	expected: { string },
	label: string
): (boolean, string?)
	if type(values) ~= "table" then
		return false, label .. " must be a table"
	end
	for key in pairs(values) do
		if type(key) ~= "number" or key ~= math.floor(key) or key < 1 then
			return false, label .. " must be an ordered array"
		end
	end
	return validateExactArray(values, expected, label)
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
	local metadataOk, metadataReason = validateMetadata(schema.metadata, label)
	if not metadataOk then
		return false, metadataReason
	end
	local tagsOk, tagsReason = validateTags(schema.tags)
	if not tagsOk then
		return false, tagsReason
	end
	return validateEvidence(schema.evidence)
end

local function validateIntegrationMetadata(
	metadata: any,
	expectedOrder: string,
	compatibility: string
)
	if type(metadata) ~= "table" then
		return false, "integration metadata is required"
	end
	local expected = {
		copied = "true",
		order = expectedOrder,
		compatibility = compatibility,
		boundary = "metadata.only",
		isolation = "copied",
		futureAdapterAbsent = "true",
		futureAssetOperationsAbsent = "true",
		authoritySeparated = "true",
		executionSeparated = "true",
		gameplaySeparated = "true",
	}
	return validateExactStringMap(metadata, expected, "integration metadata")
end

local function validateIntegrationReadinessDeclarations(): (boolean, string?)
	local declarations = Types.AssetExecutionIntegrationReadinessDeclarations
	if type(declarations) ~= "table" then
		return false, "integration declarations must be a table"
	end
	local orders = Types.IntegrationReadinessDeclarationOrder
	if type(orders) ~= "table" then
		return false, "integration order must be a table"
	end
	local fieldsOk, fieldsReason = validateExactArray(
		Types.IntegrationReadinessDeclarationFields,
		EXPECTED_INTEGRATION_DECLARATION_FIELDS,
		"integration fields"
	)
	if not fieldsOk then
		return false, fieldsReason
	end
	for _, fieldName in ipairs(Types.IntegrationReadinessDeclarationFields) do
		if fieldName ~= "evidence" and fieldName ~= "tags" and fieldName ~= "metadata" then
			local orderName = orderNameForField(fieldName)
			local expectedOrder = orders[orderName]
			local orderOk, orderReason =
				validateExactDeclarationArray(expectedOrder, expectedOrder, orderName)
			if not orderOk then
				return false, orderReason
			end
		end
	end
	for key in pairs(declarations) do
		if type(key) ~= "number" or key ~= math.floor(key) or key < 1 then
			return false, "integration declarations must be an ordered array"
		end
	end
	local expectedCount = #orders.IntegrationIdOrder
	if #declarations ~= expectedCount then
		return false, "integration declaration count drift"
	end
	local seen: { [string]: boolean } = {}
	for index, declaration in ipairs(declarations) do
		if type(declaration) ~= "table" then
			return false, "integration declaration must be a table"
		end
		local safe, safeReason = Serialization.validateSerializable(declaration)
		if not safe then
			return false, safeReason
		end
		local fieldCount = 0
		local integrationFieldLookup = {}
		for _, fieldName in ipairs(Types.IntegrationReadinessDeclarationFields) do
			integrationFieldLookup[fieldName] = true
		end
		for key in pairs(declaration) do
			fieldCount += 1
			if type(key) ~= "string" or integrationFieldLookup[key] ~= true then
				return false, "integration declaration contains unsupported field"
			end
		end
		if fieldCount ~= #Types.IntegrationReadinessDeclarationFields then
			return false, "integration declaration field count drift"
		end
		for _, idField in ipairs({
			"integrationId",
			"compatibilityId",
			"integrationDeclarationId",
		}) do
			if not validId(declaration[idField]) then
				return false, idField .. " is invalid"
			end
			if seen[declaration[idField]] then
				return false, idField .. " is duplicate"
			end
			seen[declaration[idField]] = true
		end
		for _, fieldName in ipairs(Types.IntegrationReadinessDeclarationFields) do
			if fieldName ~= "evidence" and fieldName ~= "tags" and fieldName ~= "metadata" then
				local expected = orders[orderNameForField(fieldName)][index]
				if declaration[fieldName] ~= expected then
					return false, fieldName .. " order drift"
				end
			end
		end
		if Types.IntegrationKind[declaration.integrationKind] ~= true then
			return false, "integrationKind is invalid"
		end
		if Types.IntegrationStatus[declaration.integrationStatus] ~= true then
			return false, "integrationStatus is invalid"
		end
		if Types.AdapterBoundaryKind[declaration.adapterBoundaryKind] ~= true then
			return false, "adapterBoundaryKind is invalid"
		end
		if Types.AssetOperationBoundaryKind[declaration.assetOperationBoundaryKind] ~= true then
			return false, "assetOperationBoundaryKind is invalid"
		end
		if declaration.required ~= true then
			return false, "integration required drift"
		end
		local evidenceOk, evidenceReason = validateEvidence(declaration.evidence)
		if not evidenceOk then
			return false, evidenceReason
		end
		local tagsOk, tagsReason = validateTags(declaration.tags)
		if not tagsOk then
			return false, tagsReason
		end
		local metadataOk, metadataReason = validateIntegrationMetadata(
			declaration.metadata,
			string.sub(declaration.integrationId, 29, 30),
			string.sub(declaration.integrationId, 32)
		)
		if not metadataOk then
			return false, metadataReason
		end
	end
	return true, nil
end

function Validation.runtime(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "runtimeId", Types.SchemaType.ExecutionRuntime, "runtime")
	if not ok then
		return false, reason
	end
	if not validId(schema.authorizationId) or not validId(schema.readinessId) then
		return false, "runtime references are invalid"
	end
	if Types.RuntimeKind[schema.runtimeKind] ~= true then
		return false, "runtimeKind is invalid"
	end
	if Types.RuntimeStatus[schema.runtimeStatus] ~= true then
		return false, "runtimeStatus is invalid"
	end
	if schema.providerName ~= Types.RuntimeProviderName then
		return false, "providerName drift"
	end
	if schema.snapshotProviderName ~= Types.RuntimeProviderName then
		return false, "snapshotProviderName drift"
	end
	for _, group in ipairs({
		{ schema.requestIds, "requestIds" },
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
	return true, nil
end

function Validation.request(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "requestId", Types.SchemaType.ExecutionRequest, "request")
	if not ok then
		return false, reason
	end
	if not validId(schema.runtimeId) or not validId(schema.requestedBy) then
		return false, "request references are invalid"
	end
	if Types.RequestKind[schema.requestKind] ~= true then
		return false, "requestKind is invalid"
	end
	if Types.RequestStatus[schema.requestStatus] ~= true then
		return false, "requestStatus is invalid"
	end
	return true, nil
end

function Validation.boundary(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "boundaryId", Types.SchemaType.ExecutionBoundary, "boundary")
	if not ok then
		return false, reason
	end
	if not validId(schema.runtimeId) then
		return false, "boundary runtimeId is invalid"
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
	return true, nil
end

function Validation.audit(schema: any): (boolean, string?)
	local ok, reason = validateSchema(schema, "auditId", Types.SchemaType.ExecutionAudit, "audit")
	if not ok then
		return false, reason
	end
	if not validId(schema.runtimeId) or not validId(schema.reviewer) then
		return false, "audit references are invalid"
	end
	if Types.AuditKind[schema.auditKind] ~= true then
		return false, "auditKind is invalid"
	end
	if Types.AuditStatus[schema.auditStatus] ~= true then
		return false, "auditStatus is invalid"
	end
	for _, group in ipairs({
		{ schema.requestIds, "requestIds" },
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
	return true, nil
end

function Validation.validate(): (boolean, string?)
	if Types.RuntimeProviderName ~= "assetExecutionRuntime" then
		return false, "provider name drift"
	end
	if Types.SnapshotKind ~= "assetExecutionRuntimeSnapshot" then
		return false, "snapshot kind drift"
	end
	if Types.RuntimeName ~= "AssetExecutionRuntime" then
		return false, "runtime name drift"
	end
	if Types.CoordinatorName ~= "AssetExecutionCoordinator" then
		return false, "coordinator name drift"
	end
	for schemaName, expectedFields in pairs(EXPECTED_SCHEMA_FIELDS) do
		local fieldsOk, fieldsReason =
			validateExactArray(Types.SchemaFields[schemaName], expectedFields, schemaName)
		if not fieldsOk then
			return false, fieldsReason
		end
		if Types.SchemaFieldCount[schemaName] ~= #expectedFields then
			return false, schemaName .. " field count drift"
		end
	end
	for enumName, expectedValues in pairs(EXPECTED_ENUMS) do
		local enumOk, enumReason = validateExactBoolMap(Types[enumName], expectedValues, enumName)
		if not enumOk then
			return false, enumReason
		end
	end
	local limitsOk, limitsReason = validateExactNumberMap(Types.Limits, EXPECTED_LIMITS, "limits")
	if not limitsOk then
		return false, limitsReason
	end
	local postureOk, postureReason =
		validateExactArray(Types.PostureKeys, EXPECTED_POSTURE_KEYS, "posture keys")
	if not postureOk then
		return false, postureReason
	end
	local apiOk, apiReason =
		validateExactArray(Types.CoordinatorApiOrder, EXPECTED_COORDINATOR_API, "coordinator API")
	if not apiOk then
		return false, apiReason
	end
	local signalsOk, signalsReason =
		validateExactStringMap(Types.SignalNames, EXPECTED_SIGNAL_NAMES, "signals")
	if not signalsOk then
		return false, signalsReason
	end
	local docsOk, docsReason = validateExactArray(Types.DocumentationFiles, {
		"ASSET_EXECUTION_RUNTIME.md",
		"ASSET_EXECUTION_VALIDATION.md",
		"ASSET_EXECUTION_SERIALIZATION.md",
		"ASSET_EXECUTION_DIAGNOSTICS.md",
		"ASSET_EXECUTION_RUNTIME_LIMITS.md",
		"ASSET_EXECUTION_SELF_CHECKS.md",
		"ASSET_EXECUTION_PRODUCTION_REVIEW.md",
		"ASSET_EXECUTION_AUDIT.md",
		"ASSET_EXECUTION_RUNTIME_INTEGRATION_READINESS.md",
		"EXECUTION_RUNTIME.md",
		"EXECUTION_REQUEST_RUNTIME.md",
		"EXECUTION_BOUNDARY_RUNTIME.md",
		"EXECUTION_AUDIT_RUNTIME.md",
	}, "documentation")
	if not docsOk then
		return false, docsReason
	end
	local bootstrapOk, bootstrapReason = validateExactArray(
		Types.BootstrapDependencyOrder,
		{ "AssetExecutionAuthorizationCoordinator" },
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
	local integrationOk, integrationReason = validateIntegrationReadinessDeclarations()
	if not integrationOk then
		return false, integrationReason
	end
	return true, nil
end

Validation.validId = validId
Validation.integrationReadiness = validateIntegrationReadinessDeclarations

return Validation
