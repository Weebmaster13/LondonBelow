--!strict

local Serialization = require(script.Parent.AssetExecutionAdapterRegistrationWorkflowSerialization)
local Signals = require(script.Parent.AssetExecutionAdapterRegistrationWorkflowSignals)
local Types = require(script.Parent.AssetExecutionAdapterRegistrationWorkflowTypes)
local Validation = require(script.Parent.AssetExecutionAdapterRegistrationWorkflowValidation)

local SelfChecks = {}

local function workflow(id: string?): any
	return {
		workflowId = id or "workflow.main",
		registryId = "registry.main",
		workflowName = "workflow.main.name",
		providerName = Types.RuntimeProviderName,
		snapshotProviderName = Types.RuntimeProviderName,
		workflowKind = "AdapterRegistrationWorkflow",
		workflowStatus = "Draft",
		stageIds = {},
		transitionIds = {},
		decisionIds = {},
		auditIds = {},
		snapshotIds = {},
		evidence = { "workflow.evidence" },
		tags = { "workflow" },
		metadata = { purpose = "workflow metadata only" },
	}
end

local function stage(id: string?, order: number?): any
	return {
		stageId = id or "stage.intake",
		workflowId = "workflow.main",
		stageName = (id or "stage.intake") .. ".name",
		stageKind = "Intake",
		stageStatus = "Ready",
		stageOrder = order or 1,
		owner = (id or "stage.intake") .. ".owner",
		evidence = { "stage.evidence" },
		tags = { "stage" },
		metadata = { purpose = "stage metadata only" },
	}
end

local function transition(id: string?): any
	return {
		transitionId = id or "transition.main",
		workflowId = "workflow.main",
		fromStageId = "stage.intake",
		toStageId = "stage.validation",
		transitionKind = "StageProgression",
		transitionStatus = "Ready",
		decisionIds = {},
		evidence = { "transition.evidence" },
		tags = { "transition" },
		metadata = { purpose = "transition metadata only" },
	}
end

local function decision(id: string?): any
	return {
		decisionId = id or "decision.main",
		workflowId = "workflow.main",
		transitionId = "transition.main",
		decisionKind = "ValidationDecision",
		decisionStatus = "Satisfied",
		reviewer = "reviewer.workflow",
		evidence = { "decision.evidence" },
		tags = { "decision" },
		metadata = { purpose = "decision metadata only" },
	}
end

local function audit(id: string?): any
	return {
		auditId = id or "audit.main",
		workflowId = "workflow.main",
		stageIds = { "stage.intake", "stage.validation" },
		transitionIds = { "transition.main" },
		decisionIds = { "decision.main" },
		auditKind = "WorkflowAudit",
		auditStatus = "Passed",
		reviewer = "reviewer.workflow",
		evidence = { "audit.evidence" },
		tags = { "audit" },
		metadata = { purpose = "audit metadata only" },
	}
end

local function workflowSnapshot(id: string?): any
	return {
		workflowSnapshotId = id or "snapshot.main",
		workflowId = "workflow.main",
		snapshotKind = Types.SnapshotKind,
		snapshotStatus = "Captured",
		providerName = Types.RuntimeProviderName,
		stageIds = { "stage.intake", "stage.validation" },
		transitionIds = { "transition.main" },
		decisionIds = { "decision.main" },
		evidence = { "snapshot.evidence" },
		tags = { "snapshot" },
		metadata = { purpose = "snapshot metadata only" },
	}
end

local function expect(results: { any }, category: string, ok: boolean, message: string)
	table.insert(results, { category = category, ok = ok, message = message })
end

local function expectInvalid(results: { any }, category: string, callback: () -> (boolean, string?))
	local ok, reason = callback()
	expect(results, category, not ok, if ok then "invalid case accepted" else tostring(reason))
end

local function expectValid(results: { any }, category: string, callback: () -> (boolean, string?))
	local ok, reason = callback()
	expect(results, category, ok, if ok then "valid case accepted" else tostring(reason))
end

local function countFailures(results: { any }): number
	local failures = 0
	for _, item in ipairs(results) do
		if not item.ok then
			failures += 1
		end
	end
	return failures
end

local function withTemporaryTypeValue(key: string, value: any, callback: () -> (boolean, string?))
	local previous = Types[key]
	Types[key] = value
	local ok, reason = callback()
	Types[key] = previous
	return ok, reason
end

local function withoutIndex(values: { string }, removeIndex: number): { string }
	local copy = {}
	for index, value in ipairs(values) do
		if index ~= removeIndex then
			table.insert(copy, value)
		end
	end
	return copy
end

local function rotated(values: { string }): { string }
	local copy = Serialization.deepCopy(values)
	if #copy > 1 then
		table.insert(copy, table.remove(copy, 1))
	end
	return copy
end

local function reversed(values: { string }): { string }
	local copy = {}
	for index = #values, 1, -1 do
		table.insert(copy, values[index])
	end
	return copy
end

local function replaceFirst(values: { string }, replacement: string): { string }
	local copy = Serialization.deepCopy(values)
	copy[1] = replacement
	return copy
end

local validators = {
	ExecutionAdapterRegistrationWorkflow = {
		fields = Types.SchemaFields.ExecutionAdapterRegistrationWorkflow,
		base = workflow,
		validate = Validation.workflow,
		idField = "workflowId",
		enumField = "workflowKind",
	},
	ExecutionAdapterRegistrationStage = {
		fields = Types.SchemaFields.ExecutionAdapterRegistrationStage,
		base = stage,
		validate = Validation.stage,
		idField = "stageId",
		enumField = "stageKind",
	},
	ExecutionAdapterRegistrationTransition = {
		fields = Types.SchemaFields.ExecutionAdapterRegistrationTransition,
		base = transition,
		validate = Validation.transition,
		idField = "transitionId",
		enumField = "transitionKind",
	},
	ExecutionAdapterRegistrationDecision = {
		fields = Types.SchemaFields.ExecutionAdapterRegistrationDecision,
		base = decision,
		validate = Validation.decision,
		idField = "decisionId",
		enumField = "decisionKind",
	},
	ExecutionAdapterRegistrationAudit = {
		fields = Types.SchemaFields.ExecutionAdapterRegistrationAudit,
		base = audit,
		validate = Validation.audit,
		idField = "auditId",
		enumField = "auditKind",
	},
	ExecutionAdapterRegistrationWorkflowSnapshot = {
		fields = Types.SchemaFields.ExecutionAdapterRegistrationWorkflowSnapshot,
		base = workflowSnapshot,
		validate = Validation.workflowSnapshot,
		idField = "workflowSnapshotId",
		enumField = "snapshotStatus",
	},
}

local function runSchemaChecks(results: { any })
	for schemaName, config in pairs(validators) do
		expectValid(results, "schema validation", function()
			return config.validate(config.base())
		end)
		for _, fieldName in ipairs(config.fields) do
			expectInvalid(results, "schema validation", function()
				local schema = config.base()
				schema[fieldName] = nil
				return config.validate(schema)
			end)
			expectInvalid(results, "unsupported fields", function()
				local schema = config.base()
				schema[fieldName .. "Drift"] = schema[fieldName]
				return config.validate(schema)
			end)
		end
		expectInvalid(results, "invalid ids", function()
			local schema = config.base()
			schema[config.idField] = "invalid id with spaces"
			return config.validate(schema)
		end)
		expectInvalid(results, "enum validation", function()
			local schema = config.base()
			schema[config.enumField] = "UnsupportedValue"
			return config.validate(schema)
		end)
		expect(
			results,
			"field counts",
			Types.SchemaFieldCount[schemaName] == #config.fields,
			schemaName .. " field count matches"
		)
		expectInvalid(results, "schema exactness", function()
			local drifted = Serialization.deepCopy(Types.SchemaFields)
			table.insert(drifted[schemaName], "unsupportedField")
			return withTemporaryTypeValue("SchemaFields", drifted, Validation.validate)
		end)
		expectInvalid(results, "schema exactness", function()
			local drifted = Serialization.deepCopy(Types.SchemaFields)
			drifted[schemaName] = withoutIndex(drifted[schemaName], 1)
			return withTemporaryTypeValue("SchemaFields", drifted, Validation.validate)
		end)
		expectInvalid(results, "schema exactness", function()
			local drifted = Serialization.deepCopy(Types.SchemaFields)
			drifted[schemaName] = rotated(drifted[schemaName])
			return withTemporaryTypeValue("SchemaFields", drifted, Validation.validate)
		end)
		expectInvalid(results, "schema exactness", function()
			local drifted = Serialization.deepCopy(Types.SchemaFields)
			drifted[schemaName] = reversed(drifted[schemaName])
			return withTemporaryTypeValue("SchemaFields", drifted, Validation.validate)
		end)
		expectInvalid(results, "schema exactness", function()
			local drifted = Serialization.deepCopy(Types.SchemaFields)
			drifted[schemaName] = replaceFirst(drifted[schemaName], "replacementField")
			return withTemporaryTypeValue("SchemaFields", drifted, Validation.validate)
		end)
	end
	expectInvalid(results, "schema exactness", function()
		local drifted = Serialization.deepCopy(Types.SchemaFields)
		drifted.UnsupportedWorkflowSchema = { "workflowHandle" }
		return withTemporaryTypeValue("SchemaFields", drifted, Validation.validate)
	end)
	expectInvalid(results, "field exactness", function()
		local drifted = Serialization.deepCopy(Types.SchemaFieldCount)
		drifted.UnsupportedWorkflowSchema = 1
		return withTemporaryTypeValue("SchemaFieldCount", drifted, Validation.validate)
	end)
end

local function runEnumChecks(results: { any })
	for _, enumName in ipairs({
		"WorkflowKind",
		"WorkflowStatus",
		"StageKind",
		"StageStatus",
		"TransitionKind",
		"TransitionStatus",
		"DecisionKind",
		"DecisionStatus",
		"AuditKind",
		"AuditStatus",
		"WorkflowSnapshotStatus",
		"ProcessingReadinessKind",
		"ProcessingReadinessStatus",
		"ProcessingInputKind",
		"ProcessingOutputKind",
		"ProcessingDependencyKind",
		"ProcessingPreconditionKind",
		"ProcessingPostconditionKind",
		"ProcessingBoundaryKind",
	}) do
		expectInvalid(results, "enum validation", function()
			local drifted = Serialization.deepCopy(Types[enumName])
			drifted.UnsupportedValue = true
			return withTemporaryTypeValue(enumName, drifted, Validation.validate)
		end)
		expectInvalid(results, "enum validation", function()
			local drifted = Serialization.deepCopy(Types[enumName])
			for value in pairs(drifted) do
				drifted[value] = nil
				break
			end
			return withTemporaryTypeValue(enumName, drifted, Validation.validate)
		end)
	end
end

local function runProcessingReadinessChecks(results: { any })
	expect(
		results,
		"processing readiness declarations",
		#Types.ProcessingReadinessDeclarations == Types.Limits.MaxProcessingReadinessDeclarations,
		"declaration count matches runtime limit"
	)
	for _, config in ipairs({
		{
			label = "deletion",
			mutate = function(values)
				table.remove(values, 1)
			end,
		},
		{
			label = "insertion",
			mutate = function(values)
				table.insert(values, Serialization.deepCopy(values[1]))
			end,
		},
		{
			label = "replacement",
			mutate = function(values)
				values[1] = Serialization.deepCopy(values[2])
			end,
		},
		{
			label = "swap",
			mutate = function(values)
				values[1], values[2] = values[2], values[1]
			end,
		},
		{
			label = "duplicate id",
			mutate = function(values)
				values[2].declarationId = values[1].declarationId
			end,
		},
	}) do
		local ok, reason = (function()
			local drifted = Serialization.deepCopy(Types.ProcessingReadinessDeclarations)
			config.mutate(drifted)
			return withTemporaryTypeValue(
				"ProcessingReadinessDeclarations",
				drifted,
				Validation.validate
			)
		end)()
		expect(
			results,
			"processing declaration hardening",
			not ok,
			if ok then config.label .. " invalid case accepted" else tostring(reason)
		)
	end
	local dictionaryOk, dictionaryReason = (function()
		local drifted = Serialization.deepCopy(Types.ProcessingReadinessDeclarations)
		drifted.catalog = drifted[1]
		return withTemporaryTypeValue(
			"ProcessingReadinessDeclarations",
			drifted,
			Validation.validate
		)
	end)()
	expect(
		results,
		"processing declaration hardening",
		not dictionaryOk,
		if dictionaryOk then "dictionary invalid case accepted" else tostring(dictionaryReason)
	)
	local sparseOk, sparseReason = (function()
		local drifted = Serialization.deepCopy(Types.ProcessingReadinessDeclarations)
		drifted[2] = nil
		return withTemporaryTypeValue(
			"ProcessingReadinessDeclarations",
			drifted,
			Validation.validate
		)
	end)()
	expect(
		results,
		"processing declaration hardening",
		not sparseOk,
		if sparseOk then "sparse invalid case accepted" else tostring(sparseReason)
	)
	local malformedOk, malformedReason = (function()
		local drifted = Serialization.deepCopy(Types.ProcessingReadinessDeclarations)
		drifted[1] = {}
		return withTemporaryTypeValue(
			"ProcessingReadinessDeclarations",
			drifted,
			Validation.validate
		)
	end)()
	expect(
		results,
		"processing declaration hardening",
		not malformedOk,
		if malformedOk
			then "malformed declaration invalid case accepted"
			else tostring(malformedReason)
	)
	for index, declarationId in ipairs(Types.ProcessingReadinessDeclarationOrder) do
		local declaration = Types.ProcessingReadinessDeclarations[index]
		expect(
			results,
			"processing readiness declarations",
			declaration ~= nil and declaration.declarationId == declarationId,
			declarationId .. " order is stable"
		)
		for _, fieldName in ipairs(Types.ProcessingReadinessDeclarationFields) do
			expect(
				results,
				"processing readiness declarations",
				declaration[fieldName] ~= nil,
				declarationId .. " includes " .. fieldName
			)
		end
	end
	expectInvalid(results, "processing readiness declarations", function()
		local drifted = Serialization.deepCopy(Types.ProcessingReadinessDeclarationOrder)
		table.insert(drifted, "future.drift")
		return withTemporaryTypeValue(
			"ProcessingReadinessDeclarationOrder",
			drifted,
			Validation.validate
		)
	end)
	expectInvalid(results, "processing readiness declarations", function()
		local drifted = withoutIndex(Types.ProcessingReadinessDeclarationOrder, 1)
		return withTemporaryTypeValue(
			"ProcessingReadinessDeclarationOrder",
			drifted,
			Validation.validate
		)
	end)
	expectInvalid(results, "processing readiness declarations", function()
		local drifted = rotated(Types.ProcessingReadinessDeclarationOrder)
		return withTemporaryTypeValue(
			"ProcessingReadinessDeclarationOrder",
			drifted,
			Validation.validate
		)
	end)
	expectInvalid(results, "processing readiness declarations", function()
		local drifted = reversed(Types.ProcessingReadinessDeclarationOrder)
		return withTemporaryTypeValue(
			"ProcessingReadinessDeclarationOrder",
			drifted,
			Validation.validate
		)
	end)
	expectInvalid(results, "processing readiness declarations", function()
		local drifted = replaceFirst(Types.ProcessingReadinessDeclarationFields, "unsupportedField")
		return withTemporaryTypeValue(
			"ProcessingReadinessDeclarationFields",
			drifted,
			Validation.validate
		)
	end)
	expectInvalid(results, "processing readiness declarations", function()
		local drifted = Serialization.deepCopy(Types.ProcessingReadinessDeclarations)
		drifted[1].declarationKind = "UnsupportedValue"
		return withTemporaryTypeValue(
			"ProcessingReadinessDeclarations",
			drifted,
			Validation.validate
		)
	end)
	expectInvalid(results, "processing readiness declarations", function()
		local drifted = Serialization.deepCopy(Types.ProcessingReadinessDeclarations)
		drifted[1].readinessStatus = "UnsupportedValue"
		return withTemporaryTypeValue(
			"ProcessingReadinessDeclarations",
			drifted,
			Validation.validate
		)
	end)
	expectInvalid(results, "processing readiness declarations", function()
		local drifted = Serialization.deepCopy(Types.ProcessingReadinessDeclarations)
		drifted[1].inputKind = "UnsupportedValue"
		return withTemporaryTypeValue(
			"ProcessingReadinessDeclarations",
			drifted,
			Validation.validate
		)
	end)
	expectInvalid(results, "processing readiness declarations", function()
		local drifted = Serialization.deepCopy(Types.ProcessingReadinessDeclarations)
		drifted[1].outputKind = "UnsupportedValue"
		return withTemporaryTypeValue(
			"ProcessingReadinessDeclarations",
			drifted,
			Validation.validate
		)
	end)
	expectInvalid(results, "processing readiness declarations", function()
		local drifted = Serialization.deepCopy(Types.ProcessingReadinessDeclarations)
		drifted[1].dependencyKind = "UnsupportedValue"
		return withTemporaryTypeValue(
			"ProcessingReadinessDeclarations",
			drifted,
			Validation.validate
		)
	end)
	expectInvalid(results, "processing readiness declarations", function()
		local drifted = Serialization.deepCopy(Types.ProcessingReadinessDeclarations)
		drifted[1].preconditionKind = "UnsupportedValue"
		return withTemporaryTypeValue(
			"ProcessingReadinessDeclarations",
			drifted,
			Validation.validate
		)
	end)
	expectInvalid(results, "processing readiness declarations", function()
		local drifted = Serialization.deepCopy(Types.ProcessingReadinessDeclarations)
		drifted[1].postconditionKind = "UnsupportedValue"
		return withTemporaryTypeValue(
			"ProcessingReadinessDeclarations",
			drifted,
			Validation.validate
		)
	end)
	expectInvalid(results, "processing readiness declarations", function()
		local drifted = Serialization.deepCopy(Types.ProcessingReadinessDeclarations)
		drifted[1].boundaryKind = "UnsupportedValue"
		return withTemporaryTypeValue(
			"ProcessingReadinessDeclarations",
			drifted,
			Validation.validate
		)
	end)
	expectInvalid(results, "processing readiness declarations", function()
		local drifted = Serialization.deepCopy(Types.ProcessingReadinessDeclarations)
		drifted[1].evidence = { "z.unsorted", "a.unsorted" }
		return withTemporaryTypeValue(
			"ProcessingReadinessDeclarations",
			drifted,
			Validation.validate
		)
	end)
	expectInvalid(results, "processing readiness declarations", function()
		local drifted = Serialization.deepCopy(Types.ProcessingReadinessDeclarations)
		drifted[1].tags = { "duplicate", "duplicate" }
		return withTemporaryTypeValue(
			"ProcessingReadinessDeclarations",
			drifted,
			Validation.validate
		)
	end)
	expectInvalid(results, "processing readiness declarations", function()
		local drifted = Serialization.deepCopy(Types.ProcessingReadinessDeclarations)
		drifted[1].metadata = { marker = "runtime" .. " dispatcher" }
		return withTemporaryTypeValue(
			"ProcessingReadinessDeclarations",
			drifted,
			Validation.validate
		)
	end)
	expectInvalid(results, "processing readiness declarations", function()
		local drifted = Serialization.deepCopy(Types.ProcessingReadinessDeclarations)
		drifted[1].unsupportedField = true
		return withTemporaryTypeValue(
			"ProcessingReadinessDeclarations",
			drifted,
			Validation.validate
		)
	end)
	expectInvalid(results, "runtime-limit enforcement", function()
		local drifted = Serialization.deepCopy(Types.Limits)
		drifted.MaxProcessingReadinessDeclarations += 1
		return withTemporaryTypeValue("Limits", drifted, Validation.validate)
	end)
end

local function runIdentityChecks(results: { any })
	expect(
		results,
		"provider consistency",
		Types.RuntimeProviderName == "assetExecutionAdapterRegistrationWorkflow",
		"provider is lowerCamelCase"
	)
	expect(
		results,
		"snapshot consistency",
		Types.SnapshotKind == "assetExecutionAdapterRegistrationWorkflowSnapshot",
		"snapshot kind is lowerCamelCase"
	)
	expect(
		results,
		"runtime consistency",
		Types.RuntimeName == "AssetExecutionAdapterRegistrationWorkflow",
		"runtime identity is stable"
	)
	expect(
		results,
		"signal boundary",
		Signals.Started == Types.SignalNames.Started,
		"signals mirror type metadata"
	)
	for _, drift in ipairs({
		"AssetExecutionAdapterRegistrationWorkflow",
		"assetExecutionAdapterRegistrationWorkflow ",
		" assetExecutionAdapterRegistrationWorkflow",
		"assetExecutionAdapterRegistrationWorkflow.alias",
	}) do
		expectInvalid(results, "provider consistency", function()
			return withTemporaryTypeValue("RuntimeProviderName", drift, Validation.validate)
		end)
	end
	for _, config in ipairs({
		{ "SnapshotKind", "assetExecutionAdapterRegistrationWorkflowSnapshot " },
		{ "SnapshotKind", "assetExecutionAdapterRegistrationWorkflow.snapshot" },
		{ "RuntimeName", "assetExecutionAdapterRegistrationWorkflow" },
		{ "CoordinatorName", "AssetExecutionAdapterRegistrationWorkflowCoordinatorAlias" },
		{ "CoordinatorName", "AssetExecutionAdapterRegistration.WorkflowCoordinator" },
		{ "BootstrapDependencyOrder", { "AssetExecutionAdapterCoordinator" } },
		{ "GovernanceSnapshotProviders", { "assetExecutionAdapterRegistry" } },
	}) do
		expectInvalid(results, "identity drift", function()
			return withTemporaryTypeValue(config[1], config[2], Validation.validate)
		end)
	end
	expectInvalid(results, "documentation consistency", function()
		local drifted = Serialization.deepCopy(Types.DocumentationFiles)
		table.insert(drifted, "ASSET_EXECUTION_ADAPTER_REGISTRATION_WORKFLOW_EXTRA.md")
		return withTemporaryTypeValue("DocumentationFiles", drifted, Validation.validate)
	end)
	expectInvalid(results, "runtime-limit enforcement", function()
		local drifted = Serialization.deepCopy(Types.Limits)
		drifted.MaxWorkflows += 1
		return withTemporaryTypeValue("Limits", drifted, Validation.validate)
	end)
	expectInvalid(results, "runtime-limit enforcement", function()
		local drifted = Serialization.deepCopy(Types.Limits)
		drifted.MaxWorkflowHandles = 1
		return withTemporaryTypeValue("Limits", drifted, Validation.validate)
	end)
	expectInvalid(results, "coordinator API boundary", function()
		local drifted = Serialization.deepCopy(Types.CoordinatorApiOrder)
		table.insert(drifted, "runRegistrationWorkflow")
		return withTemporaryTypeValue("CoordinatorApiOrder", drifted, Validation.validate)
	end)
	expectInvalid(results, "signal boundary", function()
		local drifted = Serialization.deepCopy(Types.SignalNames)
		drifted.Started = "AssetExecutionAdapterRegistrationWorkflow.StartedDrift"
		return withTemporaryTypeValue("SignalNames", drifted, Validation.validate)
	end)
end

local function runPayloadChecks(results: { any })
	for _, config in pairs(validators) do
		expectInvalid(results, "metatable rejection", function()
			local schema = config.base()
			schema.metadata = setmetatable({ safe = "no" }, {})
			return config.validate(schema)
		end)
		expectInvalid(results, "cyclic payload rejection", function()
			local schema = config.base()
			schema.metadata = {}
			schema.metadata.self = schema.metadata
			return config.validate(schema)
		end)
		expectInvalid(results, "Roblox Instances", function()
			local schema = config.base()
			schema.metadata = { ClassName = "Part", ["Par" .. "ent"] = {} }
			return config.validate(schema)
		end)
		for _, marker in ipairs(Serialization.forbiddenMarkers()) do
			expectInvalid(results, "banned runtime surface absence", function()
				local schema = config.base()
				schema.metadata = { marker = marker }
				return config.validate(schema)
			end)
			expectInvalid(results, "evidence drift", function()
				local schema = config.base()
				schema.evidence = { marker }
				return config.validate(schema)
			end)
			expectInvalid(results, "tag drift", function()
				local schema = config.base()
				schema.tags = { marker }
				return config.validate(schema)
			end)
			expectInvalid(results, "metadata drift", function()
				local schema = config.base()
				schema.metadata = { [marker] = "copied metadata only" }
				return config.validate(schema)
			end)
		end
	end
end

local function runStateChecks(results: { any }, service: any)
	service.shutdown()
	expectValid(results, "provider consistency", function()
		local init = service.initialize()
		return init.ok, init.message
	end)
	expectValid(results, "workflow ownership", function()
		local registered = service.registerExecutionAdapterRegistrationWorkflow(workflow())
		return registered.ok, registered.message
	end)
	local before = service.inspect().counts.workflows
	expectInvalid(results, "duplicate rejection", function()
		local registered =
			service.registerExecutionAdapterRegistrationWorkflow(workflow("workflow.main"))
		return registered.ok, registered.message
	end)
	expectInvalid(results, "duplicate workflow names", function()
		local schema = workflow("workflow.nameDuplicate")
		schema.workflowName = "workflow.main.name"
		local registered = service.registerExecutionAdapterRegistrationWorkflow(schema)
		return registered.ok, registered.message
	end)
	expect(
		results,
		"failed-validation no mutation",
		service.inspect().counts.workflows == before,
		"failed workflow validation did not mutate"
	)
	expectValid(results, "stage validation", function()
		local registered =
			service.registerExecutionAdapterRegistrationStage(stage("stage.intake", 1))
		return registered.ok, registered.message
	end)
	expectValid(results, "stage validation", function()
		local schema = stage("stage.validation", 2)
		schema.stageKind = "Validation"
		local registered = service.registerExecutionAdapterRegistrationStage(schema)
		return registered.ok, registered.message
	end)
	expectInvalid(results, "duplicate rejection", function()
		local registered =
			service.registerExecutionAdapterRegistrationStage(stage("stage.intake", 3))
		return registered.ok, registered.message
	end)
	expectInvalid(results, "duplicate ownership", function()
		local schema = stage("stage.ownerDuplicate", 3)
		schema.owner = "stage.intake.owner"
		local registered = service.registerExecutionAdapterRegistrationStage(schema)
		return registered.ok, registered.message
	end)
	expectValid(results, "transition validation", function()
		local registered = service.registerExecutionAdapterRegistrationTransition(transition())
		return registered.ok, registered.message
	end)
	expectInvalid(results, "duplicate rejection", function()
		local registered =
			service.registerExecutionAdapterRegistrationTransition(transition("transition.main"))
		return registered.ok, registered.message
	end)
	expectValid(results, "decision validation", function()
		local registered = service.registerExecutionAdapterRegistrationDecision(decision())
		return registered.ok, registered.message
	end)
	expectInvalid(results, "duplicate rejection", function()
		local registered =
			service.registerExecutionAdapterRegistrationDecision(decision("decision.main"))
		return registered.ok, registered.message
	end)
	expectValid(results, "audit validation", function()
		local registered = service.registerExecutionAdapterRegistrationAudit(audit())
		return registered.ok, registered.message
	end)
	expectInvalid(results, "duplicate rejection", function()
		local registered = service.registerExecutionAdapterRegistrationAudit(audit("audit.main"))
		return registered.ok, registered.message
	end)
	expectValid(results, "snapshot consistency", function()
		local registered =
			service.registerExecutionAdapterRegistrationWorkflowSnapshot(workflowSnapshot())
		return registered.ok, registered.message
	end)
	expectInvalid(results, "cross-workflow references", function()
		local schema = stage("stage.bad", 3)
		schema.workflowId = "missing.workflow"
		local registered = service.registerExecutionAdapterRegistrationStage(schema)
		return registered.ok, registered.message
	end)
	expectInvalid(results, "transition validation", function()
		local schema = transition("transition.bad")
		schema.toStageId = "missing.stage"
		local registered = service.registerExecutionAdapterRegistrationTransition(schema)
		return registered.ok, registered.message
	end)
	expectInvalid(results, "ordering drift", function()
		local schema = transition("transition.reverse")
		schema.fromStageId = "stage.validation"
		schema.toStageId = "stage.intake"
		local registered = service.registerExecutionAdapterRegistrationTransition(schema)
		return registered.ok, registered.message
	end)
	expectValid(results, "workflow ownership", function()
		local schema = workflow("workflow.other")
		schema.workflowName = "workflow.other.name"
		local registered = service.registerExecutionAdapterRegistrationWorkflow(schema)
		return registered.ok, registered.message
	end)
	expectValid(results, "stage validation", function()
		local schema = stage("stage.other", 1)
		schema.workflowId = "workflow.other"
		local registered = service.registerExecutionAdapterRegistrationStage(schema)
		return registered.ok, registered.message
	end)
	expectInvalid(results, "cross-workflow references", function()
		local schema = transition("transition.crossWorkflow")
		schema.toStageId = "stage.other"
		local registered = service.registerExecutionAdapterRegistrationTransition(schema)
		return registered.ok, registered.message
	end)
	expect(
		results,
		"failed-validation no mutation",
		service.inspect().counts.workflows == 2
			and service.inspect().counts.stages == 3
			and service.inspect().counts.transitions == 1
			and service.inspect().counts.decisions == 1
			and service.inspect().counts.audits == 1,
		"failed child validation did not mutate"
	)
end

local function runIsolationChecks(results: { any }, service: any)
	local diagnostics = service.inspect()
	diagnostics.runtimeLimits.MaxWorkflows = -1
	diagnostics.processingReadinessDeclarations[1].metadata.verifies = "mutated"
	diagnostics.schemas.workflows["workflow.main"].metadata.purpose = "mutated"
	local diagnosticsAgain = service.inspect()
	expect(
		results,
		"diagnostics isolation",
		diagnosticsAgain.runtimeLimits.MaxWorkflows == Types.Limits.MaxWorkflows
			and diagnosticsAgain.processingReadinessDeclarations[1].metadata.verifies == Types.ProcessingReadinessDeclarations[1].metadata.verifies
			and diagnosticsAgain.schemas.workflows["workflow.main"].metadata.purpose
				== "workflow metadata only",
		"diagnostics are isolated"
	)
	local snapshot = service.getSnapshot()
	snapshot.runtimeLimits.MaxStages = -1
	snapshot.processingReadinessDeclarations[1].metadata.verifies = "mutated"
	snapshot.schemas.stages["stage.intake"].metadata.purpose = "mutated"
	local snapshotAgain = service.getSnapshot()
	expect(
		results,
		"snapshot isolation",
		snapshotAgain.runtimeLimits.MaxStages == Types.Limits.MaxStages
			and snapshotAgain.processingReadinessDeclarations[1].metadata.verifies == Types.ProcessingReadinessDeclarations[1].metadata.verifies
			and snapshotAgain.schemas.stages["stage.intake"].metadata.purpose
				== "stage metadata only",
		"snapshots are isolated"
	)
	for _, key in ipairs(Types.PostureKeys) do
		expect(
			results,
			"lowerCamelCase posture validation",
			diagnostics[key] ~= nil or diagnostics.noAuthorityPosture[key] ~= nil,
			key .. " diagnostics posture exists"
		)
		expect(
			results,
			"lowerCamelCase posture validation",
			snapshot[key] ~= nil or snapshot.noAuthorityPosture[key] ~= nil,
			key .. " snapshot posture exists"
		)
	end
	expect(
		results,
		"diagnostics health-only",
		diagnostics.health ~= nil and diagnostics.validationOk ~= nil and diagnostics.schemas ~= nil,
		"diagnostics expose health metadata only"
	)
	expect(
		results,
		"processor absence",
		diagnostics.noAuthorityPosture.noProcessing == true
			and snapshot.noAuthorityPosture.noProcessing == true,
		"future processing posture is health-only"
	)
	expect(
		results,
		"registry write separation",
		diagnostics.noAuthorityPosture.noRegistryWrites == true
			and snapshot.noAuthorityPosture.noRegistryWrites == true,
		"registry writes are absent"
	)
end

local function runCleanupChecks(results: { any }, service: any)
	expectValid(results, "shutdown cleanup", function()
		local shutdown = service.shutdown()
		return shutdown.ok, shutdown.message
	end)
	local counts = service.inspect().counts
	expect(
		results,
		"shutdown cleanup",
		counts.workflows == 0
			and counts.stages == 0
			and counts.transitions == 0
			and counts.decisions == 0
			and counts.audits == 0
			and counts.workflowSnapshots == 0
			and counts.validationFailures == 0
			and counts.snapshots == 0,
		"shutdown clears state"
	)
end

function SelfChecks.run(context: any)
	local results = {}
	local service = context.Service
	runSchemaChecks(results)
	runEnumChecks(results)
	runProcessingReadinessChecks(results)
	runIdentityChecks(results)
	runPayloadChecks(results)
	runStateChecks(results, service)
	runIsolationChecks(results, service)
	runCleanupChecks(results, service)
	local failures = countFailures(results)
	return {
		ok = failures == 0,
		total = #results,
		failures = failures,
		categories = {
			"provider consistency",
			"runtime consistency",
			"workflow consistency",
			"snapshot consistency",
			"diagnostics consistency",
			"Bootstrap consistency",
			"Governance consistency",
			"documentation consistency",
			"schema validation",
			"enum validation",
			"workflow ownership",
			"duplicate rejection",
			"transition validation",
			"decision validation",
			"audit validation",
			"identity drift",
			"ordering drift",
			"metadata drift",
			"evidence drift",
			"tag drift",
			"serializer contamination",
			"diagnostics isolation",
			"snapshot isolation",
			"runtime-limit enforcement",
			"processing readiness declarations",
			"processor absence",
			"registry write separation",
			"failed-validation no mutation",
			"deep-copy isolation",
			"shutdown cleanup",
			"namespace reset",
			"previous phase regression protection",
			"lowerCamelCase posture validation",
			"banned runtime surface absence",
		},
		results = results,
	}
end

return SelfChecks
