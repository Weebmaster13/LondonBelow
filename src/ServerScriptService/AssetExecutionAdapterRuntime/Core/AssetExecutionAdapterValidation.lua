--!strict

local Serialization = require(script.Parent.AssetExecutionAdapterSerialization)
local Types = require(script.Parent.AssetExecutionAdapterTypes)

local Validation = {}

local EXPECTED_SCHEMA_FIELDS = {
	ExecutionAdapter = {
		"adapterId",
		"adapterName",
		"contractId",
		"runtimeId",
		"adapterKind",
		"adapterStatus",
		"providerName",
		"snapshotProviderName",
		"capabilityIds",
		"compatibilityIds",
		"boundaryIds",
		"auditIds",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAdapterCapability = {
		"capabilityId",
		"adapterId",
		"capabilityKind",
		"capabilityStatus",
		"summary",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAdapterCompatibility = {
		"compatibilityId",
		"adapterId",
		"compatibilityKind",
		"compatibilityStatus",
		"targetRuntimeName",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAdapterBoundary = {
		"boundaryId",
		"adapterId",
		"boundaryKind",
		"boundaryStatus",
		"summary",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAdapterAudit = {
		"auditId",
		"adapterId",
		"capabilityIds",
		"compatibilityIds",
		"boundaryIds",
		"auditKind",
		"auditStatus",
		"reviewer",
		"evidence",
		"tags",
		"metadata",
	},
}

local EXPECTED_SCHEMA_NAMES = {
	"ExecutionAdapter",
	"ExecutionAdapterCapability",
	"ExecutionAdapterCompatibility",
	"ExecutionAdapterBoundary",
	"ExecutionAdapterAudit",
}

local EXPECTED_ENUMS = {
	AdapterKind = {
		"MetadataAdapter",
		"AssetAcquisitionAdapterMetadata",
		"AssetFormationAdapterMetadata",
		"AssetApplicationAdapterMetadata",
		"AssetPresentationAdapterMetadata",
		"AudioAdapterMetadata",
		"AnimationAdapterMetadata",
		"OperationBoundaryAdapterMetadata",
	},
	AdapterStatus = { "Declared", "Registered", "Compatible", "Deferred", "Warning", "Blocked" },
	CapabilityKind = {
		"AssetAcquisitionCapabilityMetadata",
		"AssetFormationCapabilityMetadata",
		"AssetApplicationCapabilityMetadata",
		"PresentationInstructionCapabilityMetadata",
		"AudioInstructionCapabilityMetadata",
		"AnimationInstructionCapabilityMetadata",
		"BoundaryDeclarationCapabilityMetadata",
		"NoExecutionCapability",
	},
	CapabilityStatus = { "Declared", "Compatible", "Deferred", "Warning", "Blocked" },
	CompatibilityKind = {
		"RuntimeCompatibility",
		"AuthorizationCompatibility",
		"GovernanceCompatibility",
		"ContractCompatibility",
		"ImplementationReadinessCompatibility",
		"ProviderCompatibility",
		"SnapshotCompatibility",
		"DiagnosticsCompatibility",
	},
	CompatibilityStatus = { "Declared", "Compatible", "Deferred", "Warning", "Blocked" },
	BoundaryKind = {
		"NoAssetLoading",
		"NoAssetPreloading",
		"NoAssetStreaming",
		"NoAssetSpawning",
		"NoAssetApplication",
		"NoAssetPlayback",
		"NoAnimationPlayback",
		"NoAudioPlayback",
		"NoModelCreation",
		"NoInterfaceSurface",
		"NoVisualEffects",
		"NoWorldMutation",
		"NoStorageMutation",
		"NoNetworkOwnership",
		"NoPhysicsExecution",
		"NoRouting",
		"NoDispatch",
		"NoQueueing",
		"NoScheduling",
		"NoOrchestration",
		"NoGameplay",
		"NoPresentation",
		"NoSave",
		"NoChapter",
	},
	BoundaryStatus = { "Declared", "Satisfied", "Deferred", "Warning", "Blocked" },
	AuditKind = {
		"AdapterAudit",
		"CapabilityAudit",
		"CompatibilityAudit",
		"BoundaryAudit",
		"ProductionAudit",
	},
	AuditStatus = { "Passed", "Failed", "Warning", "Deferred", "Blocked" },
}

local EXPECTED_LIMITS = {
	MaxAdapters = 160,
	MaxCapabilities = 480,
	MaxCompatibilities = 320,
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
	"assetExecutionAdapterRuntimePosture",
	"assetExecutionAdapterValidationPosture",
	"assetExecutionAdapterCompatibilityPosture",
	"assetExecutionAdapterLifecyclePosture",
	"assetExecutionAdapterCapabilityPosture",
	"assetExecutionAdapterBoundaryPosture",
	"assetExecutionAdapterAuditPosture",
	"assetExecutionAdapterCertificationPosture",
	"assetExecutionAdapterSchemaPosture",
	"assetExecutionAdapterEnumPosture",
	"assetExecutionAdapterReferencePosture",
	"assetExecutionAdapterArrayPosture",
	"assetExecutionAdapterLimitPosture",
	"assetExecutionAdapterRuntimeLimitPosture",
	"assetExecutionAdapterSignalPosture",
	"assetExecutionAdapterCoordinatorBoundaryPosture",
	"assetExecutionAdapterIsolationPosture",
	"assetExecutionAdapterDiagnosticsPosture",
	"assetExecutionAdapterSnapshotPosture",
	"assetExecutionAdapterHardeningPosture",
	"assetExecutionAdapterIdentityHardeningPosture",
	"assetExecutionAdapterOrderingHardeningPosture",
	"assetExecutionAdapterMetadataHardeningPosture",
	"assetExecutionAdapterEvidenceHardeningPosture",
	"assetExecutionAdapterTagHardeningPosture",
	"assetExecutionAdapterNoImplementationPosture",
	"assetExecutionAdapterNoRegistryPosture",
	"assetExecutionAdapterNoOperationPosture",
	"assetExecutionAdapterNoAuthorityPosture",
	"noExecution",
	"noAssetLoading",
	"noGameplay",
	"noPresentation",
	"noSave",
	"noNetworking",
	"noAnalytics",
	"noTelemetry",
}

local function validId(value: any): boolean
	return type(value) == "string" and value:match("^[%w%.%-_]+$") ~= nil and #value <= 96
end

local function validateExactArray(
	actual: any,
	expected: { string },
	label: string
): (boolean, string?)
	if type(actual) ~= "table" then
		return false, label .. " must be a table"
	end
	if #actual ~= #expected then
		return false, label .. " count drift"
	end
	for index, expectedValue in ipairs(expected) do
		if actual[index] ~= expectedValue then
			return false, label .. " order drift"
		end
	end
	for key in pairs(actual) do
		if type(key) ~= "number" or key < 1 or key > #expected or key % 1 ~= 0 then
			return false, label .. " contains unsupported key"
		end
	end
	return true, nil
end

local function validateExactBoolMap(actual: any, expectedValues: { string }, label: string)
	if type(actual) ~= "table" then
		return false, label .. " must be a table"
	end
	local expected: { [string]: boolean } = {}
	for _, value in ipairs(expectedValues) do
		expected[value] = true
		if actual[value] ~= true then
			return false, label .. " missing value"
		end
	end
	for key, value in pairs(actual) do
		if expected[key] ~= true or value ~= true then
			return false, label .. " contains unsupported value"
		end
	end
	return true, nil
end

local function validateExactStringMap(actual: any, expected: { [string]: string }, label: string)
	if type(actual) ~= "table" then
		return false, label .. " must be a table"
	end
	for key, expectedValue in pairs(expected) do
		if actual[key] ~= expectedValue then
			return false, label .. " drift"
		end
	end
	for key in pairs(actual) do
		if expected[key] == nil then
			return false, label .. " contains unsupported key"
		end
	end
	return true, nil
end

local function validateExactNumberMap(actual: any, expected: { [string]: number }, label: string)
	if type(actual) ~= "table" then
		return false, label .. " must be a table"
	end
	for key, expectedValue in pairs(expected) do
		if actual[key] ~= expectedValue then
			return false, label .. " drift"
		end
	end
	for key in pairs(actual) do
		if expected[key] == nil then
			return false, label .. " contains unsupported key"
		end
	end
	return true, nil
end

local function validateExactStringKeys(actual: any, expectedValues: { string }, label: string)
	if type(actual) ~= "table" then
		return false, label .. " must be a table"
	end
	local expected: { [string]: boolean } = {}
	for _, value in ipairs(expectedValues) do
		expected[value] = true
		if actual[value] == nil then
			return false, label .. " missing key"
		end
	end
	for key in pairs(actual) do
		if type(key) ~= "string" or expected[key] ~= true then
			return false, label .. " contains unsupported key"
		end
	end
	return true, nil
end

local function validateExactSchemaCatalog(): (boolean, string?)
	local schemaFieldsOk, schemaFieldsReason =
		validateExactStringKeys(Types.SchemaFields, EXPECTED_SCHEMA_NAMES, "schema fields")
	if not schemaFieldsOk then
		return false, schemaFieldsReason
	end
	local fieldCountsOk, fieldCountsReason = validateExactStringKeys(
		Types.SchemaFieldCount,
		EXPECTED_SCHEMA_NAMES,
		"schema field counts"
	)
	if not fieldCountsOk then
		return false, fieldCountsReason
	end
	for _, schemaName in ipairs(EXPECTED_SCHEMA_NAMES) do
		local expectedFields = EXPECTED_SCHEMA_FIELDS[schemaName]
		local fieldsOk, fieldsReason =
			validateExactArray(Types.SchemaFields[schemaName], expectedFields, schemaName)
		if not fieldsOk then
			return false, fieldsReason
		end
		if Types.SchemaFieldCount[schemaName] ~= #expectedFields then
			return false, schemaName .. " field count drift"
		end
	end
	return true, nil
end

local function validateArrayIds(values: any, limit: number, label: string): (boolean, string?)
	if type(values) ~= "table" then
		return false, label .. " must be an array"
	end
	if #values > limit then
		return false, label .. " exceeds limit"
	end
	local seen: { [string]: boolean } = {}
	local previous = ""
	for index, value in ipairs(values) do
		if not validId(value) then
			return false, label .. " contains invalid id"
		end
		if seen[value] then
			return false, label .. " contains duplicate id"
		end
		if index > 1 and value <= previous then
			return false, label .. " must be ordered"
		end
		seen[value] = true
		previous = value
	end
	for key in pairs(values) do
		if type(key) ~= "number" or key < 1 or key > #values or key % 1 ~= 0 then
			return false, label .. " contains unsupported key"
		end
	end
	return true, nil
end

local function validateEvidence(values: any): (boolean, string?)
	return validateArrayIds(values, Types.Limits.MaxEvidence, "evidence")
end

local function validateTags(values: any): (boolean, string?)
	return validateArrayIds(values, Types.Limits.MaxTags, "tags")
end

local function validateSchema(schema: any, idField: string, schemaType: string, schemaName: string)
	if type(schema) ~= "table" then
		return false, schemaName .. " schema must be a table"
	end
	local expectedFields = Types.SchemaFields[schemaType]
	local supported = {}
	for _, fieldName in ipairs(expectedFields) do
		supported[fieldName] = true
		if schema[fieldName] == nil then
			return false, fieldName .. " is required"
		end
	end
	for key in pairs(schema) do
		if type(key) ~= "string" or supported[key] ~= true then
			return false, schemaName .. " contains unsupported field"
		end
	end
	if not validId(schema[idField]) then
		return false, idField .. " is invalid"
	end
	local safe, safeReason = Serialization.validateSerializable(schema)
	if not safe then
		return false, safeReason
	end
	local evidenceOk, evidenceReason = validateEvidence(schema.evidence)
	if not evidenceOk then
		return false, evidenceReason
	end
	local tagsOk, tagsReason = validateTags(schema.tags)
	if not tagsOk then
		return false, tagsReason
	end
	return true, nil
end

local function validateSummary(value: any, label: string): (boolean, string?)
	if type(value) ~= "string" or value == "" or #value > Types.Limits.MaxSummaryLength then
		return false, label .. " summary is invalid"
	end
	return true, nil
end

function Validation.adapter(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "adapterId", Types.SchemaType.ExecutionAdapter, "adapter")
	if not ok then
		return false, reason
	end
	if not validId(schema.contractId) or not validId(schema.runtimeId) then
		return false, "adapter references are invalid"
	end
	if not validId(schema.adapterName) then
		return false, "adapterName is invalid"
	end
	if Types.AdapterKind[schema.adapterKind] ~= true then
		return false, "adapterKind is invalid"
	end
	if Types.AdapterStatus[schema.adapterStatus] ~= true then
		return false, "adapterStatus is invalid"
	end
	if schema.providerName ~= Types.RuntimeProviderName then
		return false, "providerName drift"
	end
	if schema.snapshotProviderName ~= Types.RuntimeProviderName then
		return false, "snapshotProviderName drift"
	end
	for _, group in ipairs({
		{ schema.capabilityIds, "capabilityIds" },
		{ schema.compatibilityIds, "compatibilityIds" },
		{ schema.boundaryIds, "boundaryIds" },
		{ schema.auditIds, "auditIds" },
	}) do
		local listOk, listReason =
			validateArrayIds(group[1], Types.Limits.MaxChildReferences, group[2])
		if not listOk then
			return false, listReason
		end
	end
	return true, nil
end

function Validation.capability(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"capabilityId",
		Types.SchemaType.ExecutionAdapterCapability,
		"capability"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.adapterId) then
		return false, "capability adapterId is invalid"
	end
	if Types.CapabilityKind[schema.capabilityKind] ~= true then
		return false, "capabilityKind is invalid"
	end
	if Types.CapabilityStatus[schema.capabilityStatus] ~= true then
		return false, "capabilityStatus is invalid"
	end
	return validateSummary(schema.summary, "capability")
end

function Validation.compatibility(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"compatibilityId",
		Types.SchemaType.ExecutionAdapterCompatibility,
		"compatibility"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.adapterId) then
		return false, "compatibility adapterId is invalid"
	end
	if Types.CompatibilityKind[schema.compatibilityKind] ~= true then
		return false, "compatibilityKind is invalid"
	end
	if Types.CompatibilityStatus[schema.compatibilityStatus] ~= true then
		return false, "compatibilityStatus is invalid"
	end
	if type(schema.targetRuntimeName) ~= "string" or schema.targetRuntimeName == "" then
		return false, "targetRuntimeName is invalid"
	end
	return true, nil
end

function Validation.boundary(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "boundaryId", Types.SchemaType.ExecutionAdapterBoundary, "boundary")
	if not ok then
		return false, reason
	end
	if not validId(schema.adapterId) then
		return false, "boundary adapterId is invalid"
	end
	if Types.BoundaryKind[schema.boundaryKind] ~= true then
		return false, "boundaryKind is invalid"
	end
	if Types.BoundaryStatus[schema.boundaryStatus] ~= true then
		return false, "boundaryStatus is invalid"
	end
	return validateSummary(schema.summary, "boundary")
end

function Validation.audit(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "auditId", Types.SchemaType.ExecutionAdapterAudit, "audit")
	if not ok then
		return false, reason
	end
	if not validId(schema.adapterId) or not validId(schema.reviewer) then
		return false, "audit references are invalid"
	end
	if Types.AuditKind[schema.auditKind] ~= true then
		return false, "auditKind is invalid"
	end
	if Types.AuditStatus[schema.auditStatus] ~= true then
		return false, "auditStatus is invalid"
	end
	for _, group in ipairs({
		{ schema.capabilityIds, "capabilityIds" },
		{ schema.compatibilityIds, "compatibilityIds" },
		{ schema.boundaryIds, "boundaryIds" },
	}) do
		local listOk, listReason =
			validateArrayIds(group[1], Types.Limits.MaxChildReferences, group[2])
		if not listOk then
			return false, listReason
		end
	end
	return true, nil
end

function Validation.validate(): (boolean, string?)
	if Types.RuntimeProviderName ~= "assetExecutionAdapterRuntime" then
		return false, "provider name drift"
	end
	if Types.SnapshotKind ~= "assetExecutionAdapterRuntimeSnapshot" then
		return false, "snapshot kind drift"
	end
	if Types.RuntimeName ~= "AssetExecutionAdapterRuntime" then
		return false, "runtime name drift"
	end
	if Types.CoordinatorName ~= "AssetExecutionAdapterCoordinator" then
		return false, "coordinator name drift"
	end
	local schemaCatalogOk, schemaCatalogReason = validateExactSchemaCatalog()
	if not schemaCatalogOk then
		return false, schemaCatalogReason
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
	local apiOk, apiReason = validateExactArray(Types.CoordinatorApiOrder, {
		"initialize",
		"start",
		"shutdown",
		"registerExecutionAdapter",
		"registerExecutionAdapterCapability",
		"registerExecutionAdapterCompatibility",
		"registerExecutionAdapterBoundary",
		"registerExecutionAdapterAudit",
		"inspect",
		"getSnapshot",
		"validate",
		"runSelfChecks",
	}, "coordinator API")
	if not apiOk then
		return false, apiReason
	end
	local signalsOk, signalsReason = validateExactStringMap(Types.SignalNames, {
		Initialized = "AssetExecutionAdapterRuntime.Initialized",
		Started = "AssetExecutionAdapterRuntime.Started",
		Shutdown = "AssetExecutionAdapterRuntime.Shutdown",
		ValidationFailed = "AssetExecutionAdapterRuntime.ValidationFailed",
	}, "signals")
	if not signalsOk then
		return false, signalsReason
	end
	local docsOk, docsReason = validateExactArray(Types.DocumentationFiles, {
		"ASSET_EXECUTION_ADAPTER_RUNTIME.md",
		"ASSET_EXECUTION_ADAPTER_VALIDATION.md",
		"ASSET_EXECUTION_ADAPTER_SERIALIZATION.md",
		"ASSET_EXECUTION_ADAPTER_DIAGNOSTICS.md",
		"ASSET_EXECUTION_ADAPTER_SNAPSHOTS.md",
		"ASSET_EXECUTION_ADAPTER_AUDIT.md",
		"ASSET_EXECUTION_ADAPTER_SELF_CHECKS.md",
		"ASSET_EXECUTION_ADAPTER_PRODUCTION_REVIEW.md",
	}, "documentation")
	if not docsOk then
		return false, docsReason
	end
	local bootstrapOk, bootstrapReason = validateExactArray(
		Types.BootstrapDependencyOrder,
		{ "AssetExecutionCoordinator" },
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
