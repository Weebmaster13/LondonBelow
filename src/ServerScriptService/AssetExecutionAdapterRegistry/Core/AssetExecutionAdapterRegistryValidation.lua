--!strict

local Serialization = require(script.Parent.AssetExecutionAdapterRegistrySerialization)
local Types = require(script.Parent.AssetExecutionAdapterRegistryTypes)

local Validation = {}

local EXPECTED_SCHEMA_FIELDS = {
	ExecutionAdapterRegistry = {
		"registryId",
		"registryName",
		"providerName",
		"snapshotProviderName",
		"registryKind",
		"registryStatus",
		"registrationIds",
		"compatibilityIds",
		"boundaryIds",
		"auditIds",
		"snapshotIds",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAdapterRegistration = {
		"registrationId",
		"registryId",
		"adapterId",
		"adapterName",
		"adapterProviderName",
		"adapterSnapshotProviderName",
		"contractId",
		"runtimeId",
		"registrationKind",
		"registrationStatus",
		"owner",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAdapterRegistrationAudit = {
		"auditId",
		"registryId",
		"registrationId",
		"boundaryIds",
		"compatibilityIds",
		"auditKind",
		"auditStatus",
		"reviewer",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAdapterRegistrationBoundary = {
		"boundaryId",
		"registryId",
		"registrationId",
		"boundaryKind",
		"boundaryStatus",
		"summary",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAdapterRegistrySnapshot = {
		"registrySnapshotId",
		"registryId",
		"snapshotKind",
		"snapshotStatus",
		"providerName",
		"registrationIds",
		"compatibilityIds",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAdapterRegistryCompatibility = {
		"compatibilityId",
		"registryId",
		"registrationId",
		"compatibilityKind",
		"compatibilityStatus",
		"targetRuntimeName",
		"evidence",
		"tags",
		"metadata",
	},
}
local EXPECTED_SCHEMA_NAMES = {
	"ExecutionAdapterRegistry",
	"ExecutionAdapterRegistration",
	"ExecutionAdapterRegistrationAudit",
	"ExecutionAdapterRegistrationBoundary",
	"ExecutionAdapterRegistrySnapshot",
	"ExecutionAdapterRegistryCompatibility",
}

local EXPECTED_ENUMS = {
	RegistryKind = {
		"AdapterMetadataRegistry",
		"CertifiedAdapterCatalog",
		"CompatibilityRegistry",
		"BoundaryRegistry",
	},
	RegistryStatus = { "Declared", "Open", "Certified", "Deferred", "Warning", "Blocked" },
	RegistrationKind = {
		"AdapterMetadataRegistration",
		"CapabilityRegistration",
		"CompatibilityRegistration",
		"BoundaryRegistration",
		"AuditRegistration",
	},
	RegistrationStatus = { "Declared", "Registered", "Certified", "Deferred", "Warning", "Blocked" },
	RegistrationBoundaryKind = {
		"NoAdapterImplementation",
		"NoAdapterActivation",
		"NoAdapterExecution",
		"NoAssetOperations",
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
	RegistrationBoundaryStatus = { "Declared", "Satisfied", "Deferred", "Warning", "Blocked" },
	RegistryCompatibilityKind = {
		"AdapterRuntimeCompatibility",
		"AssetExecutionRuntimeCompatibility",
		"AuthorizationCompatibility",
		"GovernanceCompatibility",
		"ContractCompatibility",
		"SnapshotCompatibility",
		"DiagnosticsCompatibility",
	},
	RegistryCompatibilityStatus = { "Declared", "Compatible", "Deferred", "Warning", "Blocked" },
	RegistrySnapshotStatus = {
		"Declared",
		"Captured",
		"Certified",
		"Deferred",
		"Warning",
		"Blocked",
	},
	RegistrationAuditKind = {
		"RegistryAudit",
		"RegistrationAudit",
		"BoundaryAudit",
		"CompatibilityAudit",
		"ProductionAudit",
	},
	RegistrationAuditStatus = { "Passed", "Failed", "Warning", "Deferred", "Blocked" },
}

local EXPECTED_LIMITS = {
	MaxRegistries = 32,
	MaxRegistrations = 240,
	MaxRegistrationBoundaries = 320,
	MaxRegistryCompatibilities = 240,
	MaxRegistrationAudits = 240,
	MaxRegistrySnapshots = 120,
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
	"assetExecutionAdapterRegistryRuntimePosture",
	"assetExecutionAdapterRegistryValidationPosture",
	"assetExecutionAdapterRegistryRegistrationPosture",
	"assetExecutionAdapterRegistryOwnershipPosture",
	"assetExecutionAdapterRegistryCompatibilityPosture",
	"assetExecutionAdapterRegistryBoundaryPosture",
	"assetExecutionAdapterRegistryAuditPosture",
	"assetExecutionAdapterRegistrySnapshotPosture",
	"assetExecutionAdapterRegistryCertificationPosture",
	"assetExecutionAdapterRegistrySchemaPosture",
	"assetExecutionAdapterRegistryEnumPosture",
	"assetExecutionAdapterRegistryReferencePosture",
	"assetExecutionAdapterRegistryArrayPosture",
	"assetExecutionAdapterRegistryLimitPosture",
	"assetExecutionAdapterRegistryRuntimeLimitPosture",
	"assetExecutionAdapterRegistryDiagnosticsPosture",
	"assetExecutionAdapterRegistryBootstrapPosture",
	"assetExecutionAdapterRegistryGovernancePosture",
	"assetExecutionAdapterRegistryHardeningPosture",
	"assetExecutionAdapterRegistryIdentityPosture",
	"assetExecutionAdapterRegistryOrderingPosture",
	"assetExecutionAdapterRegistryMetadataPosture",
	"assetExecutionAdapterRegistryEvidencePosture",
	"assetExecutionAdapterRegistryTagPosture",
	"assetExecutionAdapterRegistryNoImplementationPosture",
	"assetExecutionAdapterRegistryNoActivationPosture",
	"assetExecutionAdapterRegistryNoExecutionPosture",
	"assetExecutionAdapterRegistryNoOperationPosture",
	"assetExecutionAdapterRegistryNoAuthorityPosture",
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
	local fieldsOk, fieldsReason =
		validateExactStringKeys(Types.SchemaFields, EXPECTED_SCHEMA_NAMES, "schema fields")
	if not fieldsOk then
		return false, fieldsReason
	end
	local countOk, countReason = validateExactStringKeys(
		Types.SchemaFieldCount,
		EXPECTED_SCHEMA_NAMES,
		"schema field counts"
	)
	if not countOk then
		return false, countReason
	end
	for _, schemaName in ipairs(EXPECTED_SCHEMA_NAMES) do
		local expectedFields = EXPECTED_SCHEMA_FIELDS[schemaName]
		local schemaOk, schemaReason =
			validateExactArray(Types.SchemaFields[schemaName], expectedFields, schemaName)
		if not schemaOk then
			return false, schemaReason
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

local function validateSchema(schema: any, idField: string, schemaType: string, label: string)
	if type(schema) ~= "table" then
		return false, label .. " schema must be a table"
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
			return false, label .. " contains unsupported field"
		end
	end
	if not validId(schema[idField]) then
		return false, idField .. " is invalid"
	end
	local safe, safeReason = Serialization.validateSerializable(schema)
	if not safe then
		return false, safeReason
	end
	local evidenceOk, evidenceReason =
		validateArrayIds(schema.evidence, Types.Limits.MaxEvidence, "evidence")
	if not evidenceOk then
		return false, evidenceReason
	end
	local tagsOk, tagsReason = validateArrayIds(schema.tags, Types.Limits.MaxTags, "tags")
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

local function validateChildArrays(schema: any, groups: { any }): (boolean, string?)
	for _, group in ipairs(groups) do
		local ok, reason =
			validateArrayIds(schema[group[1]], Types.Limits.MaxChildReferences, group[1])
		if not ok then
			return false, reason
		end
	end
	return true, nil
end

function Validation.registry(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "registryId", Types.SchemaType.ExecutionAdapterRegistry, "registry")
	if not ok then
		return false, reason
	end
	if not validId(schema.registryName) then
		return false, "registryName is invalid"
	end
	if schema.providerName ~= Types.RuntimeProviderName then
		return false, "providerName drift"
	end
	if schema.snapshotProviderName ~= Types.RuntimeProviderName then
		return false, "snapshotProviderName drift"
	end
	if Types.RegistryKind[schema.registryKind] ~= true then
		return false, "registryKind is invalid"
	end
	if Types.RegistryStatus[schema.registryStatus] ~= true then
		return false, "registryStatus is invalid"
	end
	return validateChildArrays(schema, {
		{ "registrationIds" },
		{ "compatibilityIds" },
		{ "boundaryIds" },
		{ "auditIds" },
		{ "snapshotIds" },
	})
end

function Validation.registration(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"registrationId",
		Types.SchemaType.ExecutionAdapterRegistration,
		"registration"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.registryId) or not validId(schema.adapterId) then
		return false, "registration references are invalid"
	end
	if not validId(schema.adapterName) or not validId(schema.owner) then
		return false, "registration ownership is invalid"
	end
	if schema.adapterProviderName ~= "assetExecutionAdapterRuntime" then
		return false, "adapterProviderName drift"
	end
	if schema.adapterSnapshotProviderName ~= "assetExecutionAdapterRuntime" then
		return false, "adapterSnapshotProviderName drift"
	end
	if not validId(schema.contractId) or not validId(schema.runtimeId) then
		return false, "registration contract references are invalid"
	end
	if Types.RegistrationKind[schema.registrationKind] ~= true then
		return false, "registrationKind is invalid"
	end
	if Types.RegistrationStatus[schema.registrationStatus] ~= true then
		return false, "registrationStatus is invalid"
	end
	return true, nil
end

function Validation.boundary(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"boundaryId",
		Types.SchemaType.ExecutionAdapterRegistrationBoundary,
		"boundary"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.registryId) or not validId(schema.registrationId) then
		return false, "boundary references are invalid"
	end
	if Types.RegistrationBoundaryKind[schema.boundaryKind] ~= true then
		return false, "boundaryKind is invalid"
	end
	if Types.RegistrationBoundaryStatus[schema.boundaryStatus] ~= true then
		return false, "boundaryStatus is invalid"
	end
	return validateSummary(schema.summary, "boundary")
end

function Validation.compatibility(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"compatibilityId",
		Types.SchemaType.ExecutionAdapterRegistryCompatibility,
		"compatibility"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.registryId) or not validId(schema.registrationId) then
		return false, "compatibility references are invalid"
	end
	if Types.RegistryCompatibilityKind[schema.compatibilityKind] ~= true then
		return false, "compatibilityKind is invalid"
	end
	if Types.RegistryCompatibilityStatus[schema.compatibilityStatus] ~= true then
		return false, "compatibilityStatus is invalid"
	end
	if type(schema.targetRuntimeName) ~= "string" or schema.targetRuntimeName == "" then
		return false, "targetRuntimeName is invalid"
	end
	return true, nil
end

function Validation.audit(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"auditId",
		Types.SchemaType.ExecutionAdapterRegistrationAudit,
		"audit"
	)
	if not ok then
		return false, reason
	end
	if
		not validId(schema.registryId)
		or not validId(schema.registrationId)
		or not validId(schema.reviewer)
	then
		return false, "audit references are invalid"
	end
	if Types.RegistrationAuditKind[schema.auditKind] ~= true then
		return false, "auditKind is invalid"
	end
	if Types.RegistrationAuditStatus[schema.auditStatus] ~= true then
		return false, "auditStatus is invalid"
	end
	return validateChildArrays(schema, {
		{ "boundaryIds" },
		{ "compatibilityIds" },
	})
end

function Validation.registrySnapshot(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"registrySnapshotId",
		Types.SchemaType.ExecutionAdapterRegistrySnapshot,
		"registry snapshot"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.registryId) then
		return false, "registry snapshot reference is invalid"
	end
	if schema.snapshotKind ~= Types.SnapshotKind then
		return false, "snapshotKind drift"
	end
	if Types.RegistrySnapshotStatus[schema.snapshotStatus] ~= true then
		return false, "snapshotStatus is invalid"
	end
	if schema.providerName ~= Types.RuntimeProviderName then
		return false, "snapshot provider drift"
	end
	return validateChildArrays(schema, {
		{ "registrationIds" },
		{ "compatibilityIds" },
	})
end

function Validation.validate(): (boolean, string?)
	if Types.RuntimeProviderName ~= "assetExecutionAdapterRegistry" then
		return false, "provider name drift"
	end
	if Types.SnapshotKind ~= "assetExecutionAdapterRegistrySnapshot" then
		return false, "snapshot kind drift"
	end
	if Types.RuntimeName ~= "AssetExecutionAdapterRegistry" then
		return false, "runtime name drift"
	end
	if Types.CoordinatorName ~= "AssetExecutionAdapterRegistryCoordinator" then
		return false, "coordinator name drift"
	end
	local schemaOk, schemaReason = validateExactSchemaCatalog()
	if not schemaOk then
		return false, schemaReason
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
		"registerExecutionAdapterRegistry",
		"registerExecutionAdapterRegistration",
		"registerExecutionAdapterRegistrationBoundary",
		"registerExecutionAdapterRegistryCompatibility",
		"registerExecutionAdapterRegistrationAudit",
		"registerExecutionAdapterRegistrySnapshot",
		"inspect",
		"getSnapshot",
		"validate",
		"runSelfChecks",
	}, "coordinator API")
	if not apiOk then
		return false, apiReason
	end
	local signalsOk, signalsReason = validateExactStringMap(Types.SignalNames, {
		Initialized = "AssetExecutionAdapterRegistry.Initialized",
		Started = "AssetExecutionAdapterRegistry.Started",
		Shutdown = "AssetExecutionAdapterRegistry.Shutdown",
		ValidationFailed = "AssetExecutionAdapterRegistry.ValidationFailed",
	}, "signals")
	if not signalsOk then
		return false, signalsReason
	end
	local docsOk, docsReason = validateExactArray(Types.DocumentationFiles, {
		"ASSET_EXECUTION_ADAPTER_REGISTRY_RUNTIME.md",
		"ASSET_EXECUTION_ADAPTER_REGISTRY_VALIDATION.md",
		"ASSET_EXECUTION_ADAPTER_REGISTRY_SERIALIZATION.md",
		"ASSET_EXECUTION_ADAPTER_REGISTRY_DIAGNOSTICS.md",
		"ASSET_EXECUTION_ADAPTER_REGISTRY_SNAPSHOTS.md",
		"ASSET_EXECUTION_ADAPTER_REGISTRY_SELF_CHECKS.md",
		"ASSET_EXECUTION_ADAPTER_REGISTRY_AUDIT.md",
		"ASSET_EXECUTION_ADAPTER_REGISTRY_PRODUCTION_REVIEW.md",
	}, "documentation")
	if not docsOk then
		return false, docsReason
	end
	local bootstrapOk, bootstrapReason = validateExactArray(
		Types.BootstrapDependencyOrder,
		{ "AssetExecutionAdapterCoordinator" },
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
