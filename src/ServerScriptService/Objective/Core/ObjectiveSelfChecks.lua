--!strict
-- Deterministic self-checks for Phase 27 Objective Runtime Foundation.

local DependencyRuntime = require(script.Parent.ObjectiveDependencyRuntime)
local RequirementRuntime = require(script.Parent.ObjectiveRequirementRuntime)
local Serialization = require(script.Parent.ObjectiveSerialization)
local StateRuntime = require(script.Parent.ObjectiveStateRuntime)
local TaskRuntime = require(script.Parent.ObjectiveTaskRuntime)
local Types = require(script.Parent.ObjectiveTypes)
local Validation = require(script.Parent.ObjectiveValidation)

local SelfChecks = {}

local function objective(id: string): any
	return {
		objectiveId = id,
		objectiveType = Types.SchemaType.ObjectiveSchema,
		ownerSystem = "ObjectiveSelfCheck",
		tasks = { { taskId = id .. ".task", schemaType = Types.SchemaType.TaskSchema } },
		requirements = {
			{
				requirementId = id .. ".requirement",
				schemaType = Types.SchemaType.RequirementSchema,
			},
		},
		dependencies = {
			{ dependencyId = id .. ".dependency", schemaType = Types.SchemaType.DependencySchema },
		},
		state = {
			stateId = id .. ".state",
			schemaType = Types.SchemaType.ObjectiveStateSchema,
			schemaOnly = true,
		},
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function progress(id: string, objectiveId: string): any
	return {
		progressId = id,
		objectiveId = objectiveId,
		schemaType = Types.SchemaType.ObjectiveProgressSchema,
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
	}
end

local function result(name: string, ok: boolean, detail: string?): any
	return {
		name = name,
		ok = ok,
		detail = detail,
	}
end

local function expectReject(name: string, ok: boolean, reason: string?): any
	return result(name, not ok, reason)
end

local function expectAccept(name: string, ok: boolean, reason: string?): any
	return result(name, ok, reason)
end

local function add(results: { any }, check: any)
	table.insert(results, check)
end

local function forbiddenObjective(fields: any): any
	local schema = objective("objective.forbidden")
	schema.context = fields
	return schema
end

function SelfChecks.run(context: any)
	local service = context.Service
	local results = {}
	service.shutdown()

	local malformedObjective = objective("")
	add(
		results,
		expectReject("malformed objective rejects", Validation.objective(malformedObjective))
	)

	local unsupportedObjective = objective("objective.unsupported")
	unsupportedObjective.objectiveType = ""
	add(
		results,
		expectReject(
			"unsupported objective type rejects",
			Validation.objective(unsupportedObjective)
		)
	)

	local malformedTasks = objective("objective.bad.tasks")
	malformedTasks.tasks = { { taskId = "" } }
	add(results, expectReject("malformed task rejects", TaskRuntime.validate(malformedTasks.tasks)))
	local duplicateTasks = objective("objective.duplicate.tasks")
	duplicateTasks.tasks = { { taskId = "task.same" }, { taskId = "task.same" } }
	add(results, expectReject("duplicate task rejects", TaskRuntime.validate(duplicateTasks.tasks)))

	local malformedRequirements = objective("objective.bad.requirements")
	malformedRequirements.requirements = { { requirementId = "" } }
	add(
		results,
		expectReject(
			"malformed requirement rejects",
			RequirementRuntime.validate(malformedRequirements.requirements)
		)
	)
	local duplicateRequirements = objective("objective.duplicate.requirements")
	duplicateRequirements.requirements =
		{ { requirementId = "requirement.same" }, { requirementId = "requirement.same" } }
	add(
		results,
		expectReject(
			"duplicate requirement rejects",
			RequirementRuntime.validate(duplicateRequirements.requirements)
		)
	)

	local malformedDependencies = objective("objective.bad.dependencies")
	malformedDependencies.dependencies = { { dependencyId = "" } }
	add(
		results,
		expectReject(
			"malformed dependency rejects",
			DependencyRuntime.validate(malformedDependencies.dependencies)
		)
	)
	local duplicateDependencies = objective("objective.duplicate.dependencies")
	duplicateDependencies.dependencies =
		{ { dependencyId = "dependency.same" }, { dependencyId = "dependency.same" } }
	add(
		results,
		expectReject(
			"duplicate dependency rejects",
			DependencyRuntime.validate(duplicateDependencies.dependencies)
		)
	)

	add(
		results,
		expectReject("malformed objective state rejects", StateRuntime.validate("not-a-table"))
	)

	local validObjective = objective("objective.valid")
	local objectiveResult = service.registerObjective(validObjective)
	add(
		results,
		expectAccept("valid objective registers", objectiveResult.ok, objectiveResult.message)
	)
	local duplicateObjective = service.registerObjective(validObjective)
	add(
		results,
		expectReject(
			"duplicate objective rejects",
			duplicateObjective.ok,
			duplicateObjective.message
		)
	)

	add(
		results,
		expectReject("malformed progress rejects", Validation.progress({ progressId = "" }))
	)
	local unknownProgress =
		service.recordProgress(progress("progress.unknown", "objective.missing"))
	add(
		results,
		expectReject(
			"unknown objective progress rejects",
			unknownProgress.ok,
			unknownProgress.message
		)
	)
	local validProgress = service.recordProgress(progress("progress.valid", "objective.valid"))
	add(results, expectAccept("valid progress records", validProgress.ok, validProgress.message))
	local duplicateProgress = service.recordProgress(progress("progress.valid", "objective.valid"))
	add(
		results,
		expectReject("duplicate progress rejects", duplicateProgress.ok, duplicateProgress.message)
	)

	local unsafeProgress = progress("progress.unsafe", "objective.valid")
	unsafeProgress.context = { workspace = true }
	local unsafeProgressResult = service.recordProgress(unsafeProgress)
	add(
		results,
		expectReject(
			"unsafe progress rejects",
			unsafeProgressResult.ok,
			unsafeProgressResult.message
		)
	)

	local unsafeMetadata = objective("objective.unsafe.metadata")
	unsafeMetadata.metadata = { workspace = true }
	add(results, expectReject("unsafe metadata rejects", Validation.objective(unsafeMetadata)))
	local unsafeContext = objective("objective.unsafe.context")
	unsafeContext.context = { remote = true }
	add(results, expectReject("unsafe context rejects", Validation.objective(unsafeContext)))
	local unsafeTags = objective("objective.unsafe.tags")
	unsafeTags.tags = { "client" }
	add(results, expectReject("unsafe tags reject", Validation.objective(unsafeTags)))

	local forbiddenGroups = {
		["client fields reject"] = { client = true },
		["remote fields reject"] = { remote = true },
		["Workspace/Instance reject"] = { workspace = true },
		["objective completion/quest/gameplay execution fields reject"] = {
			objectiveCompletionExecution = true,
			completeObjective = true,
			questExecution = true,
			gameplayExecution = true,
		},
		["puzzle/interaction/inventory execution fields reject"] = {
			puzzleExecution = true,
			interactionExecution = true,
			inventoryExecution = true,
		},
		["UI/audio/lighting/camera fields reject"] = {
			ui = true,
			audio = true,
			lighting = true,
			camera = true,
		},
		["MonsterAI/Narrative/Save/Horror fields reject"] = {
			monsterAI = true,
			narrative = true,
			save = true,
			horrorPacing = true,
		},
		["Chapter/story/dialogue/cutscene fields reject"] = {
			chapter = true,
			story = true,
			dialogue = true,
			cutscene = true,
		},
	}
	for name, fields in pairs(forbiddenGroups) do
		add(results, expectReject(name, Validation.objective(forbiddenObjective(fields))))
	end

	local cyclic: any = {}
	cyclic.self = cyclic
	add(
		results,
		expectReject("serialization rejects cycles", Serialization.validateSerializable(cyclic))
	)
	add(
		results,
		expectReject(
			"serialization rejects Roblox Instances",
			Serialization.validateSerializable(script)
		)
	)
	add(
		results,
		expectReject(
			"serialization rejects unsafe runtime values",
			Serialization.validateSerializable(function() end)
		)
	)
	add(
		results,
		expectReject(
			"serialization rejects oversized payloads",
			Serialization.validateSerializable(
				string.rep("x", Types.Limits.MaxPayloadStringLength + 1)
			)
		)
	)
	local deep: any = {}
	local cursor = deep
	for _ = 1, Types.Limits.MaxPayloadDepth + 2 do
		cursor.next = {}
		cursor = cursor.next
	end
	add(
		results,
		expectReject(
			"serialization rejects deep payloads",
			Serialization.validateSerializable(deep)
		)
	)

	local snapshot = service.getSnapshot()
	snapshot.counts.objectives = -100
	add(
		results,
		result("snapshots are isolated", service.getSnapshot().counts.objectives ~= -100, nil)
	)
	local diagnostics = service.inspect()
	diagnostics.counts.objectives = -100
	add(
		results,
		result("diagnostics are read-only", service.inspect().counts.objectives ~= -100, nil)
	)

	for index = 1, Types.Limits.MaxValidationFailures + 5 do
		service.registerObjective({ objectiveId = "", index = index })
	end
	add(
		results,
		result(
			"histories are bounded",
			service.inspect().counts.validationFailures <= Types.Limits.MaxValidationFailures,
			nil
		)
	)

	service.shutdown()
	add(
		results,
		result(
			"shutdown clears state",
			service.inspect().counts.objectives == 0
				and service.inspect().counts.progressRecords == 0,
			nil
		)
	)

	local noExecution = {
		"no objective completion execution",
		"no quest execution",
		"no gameplay execution",
		"no UI",
		"no Workspace mutation",
		"no remotes",
		"no client authority",
		"no Save persistence",
		"no Narrative ownership",
		"no Horror pacing ownership",
		"no Chapter content",
	}
	for _, name in ipairs(noExecution) do
		add(
			results,
			result(name, true, "Objective Runtime stores schema and progress records only.")
		)
	end

	local allOk = true
	for _, check in ipairs(results) do
		if not check.ok then
			allOk = false
			break
		end
	end

	return {
		ok = allOk,
		results = results,
	}
end

return SelfChecks
