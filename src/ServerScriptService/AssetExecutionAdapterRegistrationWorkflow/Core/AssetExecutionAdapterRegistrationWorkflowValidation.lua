--!strict

local Serialization = require(script.Parent.AssetExecutionAdapterRegistrationWorkflowSerialization)
local Types = require(script.Parent.AssetExecutionAdapterRegistrationWorkflowTypes)

local Validation = {}

local EXPECTED_SCHEMA_NAMES = {
	"ExecutionAdapterRegistrationWorkflow",
	"ExecutionAdapterRegistrationStage",
	"ExecutionAdapterRegistrationTransition",
	"ExecutionAdapterRegistrationDecision",
	"ExecutionAdapterRegistrationAudit",
	"ExecutionAdapterRegistrationWorkflowSnapshot",
}

local EXPECTED_SCHEMA_FIELDS = Serialization.deepCopy(Types.SchemaFields)
local EXPECTED_LIMITS = Serialization.deepCopy(Types.Limits)
local EXPECTED_POSTURE_KEYS = Serialization.deepCopy(Types.PostureKeys)
local EXPECTED_API = Serialization.deepCopy(Types.CoordinatorApiOrder)
local EXPECTED_DOCS = Serialization.deepCopy(Types.DocumentationFiles)

local EXPECTED_ENUMS = {
	WorkflowKind = {
		"AdapterRegistrationWorkflow",
		"CertificationWorkflow",
		"BoundaryWorkflow",
		"CompatibilityWorkflow",
	},
	WorkflowStatus = { "Declared", "Draft", "Certified", "Deferred", "Warning", "Blocked" },
	StageKind = {
		"Intake",
		"Validation",
		"BoundaryReview",
		"CompatibilityReview",
		"Certification",
		"Audit",
	},
	StageStatus = { "Declared", "Ready", "Certified", "Deferred", "Warning", "Blocked" },
	TransitionKind = {
		"StageProgression",
		"ValidationGate",
		"BoundaryGate",
		"CompatibilityGate",
		"CertificationGate",
	},
	TransitionStatus = { "Declared", "Ready", "Certified", "Deferred", "Warning", "Blocked" },
	DecisionKind = {
		"ValidationDecision",
		"BoundaryDecision",
		"CompatibilityDecision",
		"CertificationDecision",
		"AuditDecision",
	},
	DecisionStatus = { "Declared", "Satisfied", "Certified", "Deferred", "Warning", "Blocked" },
	AuditKind = {
		"WorkflowAudit",
		"StageAudit",
		"TransitionAudit",
		"DecisionAudit",
		"ProductionAudit",
	},
	AuditStatus = { "Passed", "Failed", "Warning", "Deferred", "Blocked" },
	WorkflowSnapshotStatus = {
		"Declared",
		"Captured",
		"Certified",
		"Deferred",
		"Warning",
		"Blocked",
	},
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

local function validateExactStringKeys(
	actual: any,
	expectedValues: { string },
	label: string
): (boolean, string?)
	if type(actual) ~= "table" then
		return false, label .. " must be a table"
	end
	local expected = {}
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

local function validateExactBoolMap(
	actual: any,
	expectedValues: { string },
	label: string
): (boolean, string?)
	if type(actual) ~= "table" then
		return false, label .. " must be a table"
	end
	local expected = {}
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

local function validateExactMap(actual: any, expected: any, label: string): (boolean, string?)
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
		local fields = EXPECTED_SCHEMA_FIELDS[schemaName]
		local ok, reason = validateExactArray(Types.SchemaFields[schemaName], fields, schemaName)
		if not ok then
			return false, reason
		end
		if Types.SchemaFieldCount[schemaName] ~= #fields then
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
	local seen = {}
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

local function validateSchema(
	schema: any,
	idField: string,
	schemaType: string,
	label: string
): (boolean, string?)
	if type(schema) ~= "table" then
		return false, label .. " schema must be a table"
	end
	local supported = {}
	for _, fieldName in ipairs(Types.SchemaFields[schemaType]) do
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

local function validateChildArrays(schema: any, names: { string }): (boolean, string?)
	for _, name in ipairs(names) do
		local ok, reason = validateArrayIds(schema[name], Types.Limits.MaxChildReferences, name)
		if not ok then
			return false, reason
		end
	end
	return true, nil
end

function Validation.workflow(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"workflowId",
		Types.SchemaType.ExecutionAdapterRegistrationWorkflow,
		"workflow"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.registryId) or not validId(schema.workflowName) then
		return false, "workflow identity is invalid"
	end
	if
		schema.providerName ~= Types.RuntimeProviderName
		or schema.snapshotProviderName ~= Types.RuntimeProviderName
	then
		return false, "workflow provider drift"
	end
	if Types.WorkflowKind[schema.workflowKind] ~= true then
		return false, "workflowKind is invalid"
	end
	if Types.WorkflowStatus[schema.workflowStatus] ~= true then
		return false, "workflowStatus is invalid"
	end
	return validateChildArrays(
		schema,
		{ "stageIds", "transitionIds", "decisionIds", "auditIds", "snapshotIds" }
	)
end

function Validation.stage(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"stageId",
		Types.SchemaType.ExecutionAdapterRegistrationStage,
		"stage"
	)
	if not ok then
		return false, reason
	end
	if
		not validId(schema.workflowId)
		or not validId(schema.stageName)
		or not validId(schema.owner)
	then
		return false, "stage ownership is invalid"
	end
	if
		type(schema.stageOrder) ~= "number"
		or schema.stageOrder < 1
		or schema.stageOrder > Types.Limits.MaxStageOrder
		or schema.stageOrder % 1 ~= 0
	then
		return false, "stageOrder is invalid"
	end
	if Types.StageKind[schema.stageKind] ~= true then
		return false, "stageKind is invalid"
	end
	if Types.StageStatus[schema.stageStatus] ~= true then
		return false, "stageStatus is invalid"
	end
	return true, nil
end

function Validation.transition(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"transitionId",
		Types.SchemaType.ExecutionAdapterRegistrationTransition,
		"transition"
	)
	if not ok then
		return false, reason
	end
	if
		not validId(schema.workflowId)
		or not validId(schema.fromStageId)
		or not validId(schema.toStageId)
	then
		return false, "transition references are invalid"
	end
	if schema.fromStageId == schema.toStageId then
		return false, "transition cannot self-reference"
	end
	if Types.TransitionKind[schema.transitionKind] ~= true then
		return false, "transitionKind is invalid"
	end
	if Types.TransitionStatus[schema.transitionStatus] ~= true then
		return false, "transitionStatus is invalid"
	end
	return validateChildArrays(schema, { "decisionIds" })
end

function Validation.decision(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"decisionId",
		Types.SchemaType.ExecutionAdapterRegistrationDecision,
		"decision"
	)
	if not ok then
		return false, reason
	end
	if
		not validId(schema.workflowId)
		or not validId(schema.transitionId)
		or not validId(schema.reviewer)
	then
		return false, "decision references are invalid"
	end
	if Types.DecisionKind[schema.decisionKind] ~= true then
		return false, "decisionKind is invalid"
	end
	if Types.DecisionStatus[schema.decisionStatus] ~= true then
		return false, "decisionStatus is invalid"
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
	if not validId(schema.workflowId) or not validId(schema.reviewer) then
		return false, "audit references are invalid"
	end
	if Types.AuditKind[schema.auditKind] ~= true then
		return false, "auditKind is invalid"
	end
	if Types.AuditStatus[schema.auditStatus] ~= true then
		return false, "auditStatus is invalid"
	end
	return validateChildArrays(schema, { "stageIds", "transitionIds", "decisionIds" })
end

function Validation.workflowSnapshot(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"workflowSnapshotId",
		Types.SchemaType.ExecutionAdapterRegistrationWorkflowSnapshot,
		"workflow snapshot"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.workflowId) then
		return false, "workflow snapshot reference is invalid"
	end
	if
		schema.snapshotKind ~= Types.SnapshotKind
		or schema.providerName ~= Types.RuntimeProviderName
	then
		return false, "snapshot identity drift"
	end
	if Types.WorkflowSnapshotStatus[schema.snapshotStatus] ~= true then
		return false, "snapshotStatus is invalid"
	end
	return validateChildArrays(schema, { "stageIds", "transitionIds", "decisionIds" })
end

function Validation.validate(): (boolean, string?)
	if Types.RuntimeProviderName ~= "assetExecutionAdapterRegistrationWorkflow" then
		return false, "provider name drift"
	end
	if Types.SnapshotKind ~= "assetExecutionAdapterRegistrationWorkflowSnapshot" then
		return false, "snapshot kind drift"
	end
	if Types.RuntimeName ~= "AssetExecutionAdapterRegistrationWorkflow" then
		return false, "runtime name drift"
	end
	if Types.CoordinatorName ~= "AssetExecutionAdapterRegistrationWorkflowCoordinator" then
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
	for _, check in ipairs({
		{ Types.Limits, EXPECTED_LIMITS, "limits" },
		{
			Types.SignalNames,
			{
				Initialized = "AssetExecutionAdapterRegistrationWorkflow.Initialized",
				Started = "AssetExecutionAdapterRegistrationWorkflow.Started",
				Shutdown = "AssetExecutionAdapterRegistrationWorkflow.Shutdown",
				ValidationFailed = "AssetExecutionAdapterRegistrationWorkflow.ValidationFailed",
			},
			"signals",
		},
	}) do
		local ok, reason = validateExactMap(check[1], check[2], check[3])
		if not ok then
			return false, reason
		end
	end
	for _, check in ipairs({
		{ Types.PostureKeys, EXPECTED_POSTURE_KEYS, "posture keys" },
		{ Types.CoordinatorApiOrder, EXPECTED_API, "coordinator API" },
		{ Types.DocumentationFiles, EXPECTED_DOCS, "documentation" },
		{
			Types.BootstrapDependencyOrder,
			{ "AssetExecutionAdapterRegistryCoordinator" },
			"Bootstrap dependency",
		},
		{
			Types.GovernanceSnapshotProviders,
			{ Types.RuntimeProviderName },
			"Governance snapshot provider",
		},
	}) do
		local ok, reason = validateExactArray(check[1], check[2], check[3])
		if not ok then
			return false, reason
		end
	end
	return true, nil
end

Validation.validId = validId
Validation.validateArrayIds = validateArrayIds

return Validation
