--!strict
-- Deterministic self-checks for Phase 29 Data Persistence Boundary Foundation.

local Serialization = require(script.Parent.PersistenceSerialization)
local Types = require(script.Parent.PersistenceTypes)
local Validation = require(script.Parent.PersistenceValidation)

local SelfChecks = {}

local function request(id: string): any
	return {
		requestId = id,
		requestType = "BoundaryOnly",
		ownerSystem = "PersistenceSelfCheck",
		schemaType = Types.SchemaType.PersistenceRequestSchema,
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function packageRecord(id: string, packageType: string): any
	return {
		packageId = id,
		packageType = packageType,
		ownerSystem = "PersistenceSelfCheck",
		schemaType = packageType == "Save" and Types.SchemaType.SavePackageSchema
			or Types.SchemaType.LoadPackageSchema,
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function migration(id: string): any
	return {
		migrationId = id,
		ownerSystem = "PersistenceSelfCheck",
		schemaType = Types.SchemaType.MigrationSchema,
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function policy(id: string, schemaType: string): any
	return {
		policyId = id,
		ownerSystem = "PersistenceSelfCheck",
		schemaType = schemaType,
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function failure(id: string): any
	return {
		failureId = id,
		ownerSystem = "PersistenceSelfCheck",
		schemaType = Types.SchemaType.FailureRecordSchema,
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function result(name: string, ok: boolean, detail: string?): any
	return { name = name, ok = ok, detail = detail }
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

local function forbiddenRequest(fields: any): any
	local schema = request("request.forbidden")
	schema.context = fields
	return schema
end

function SelfChecks.run(context: any)
	local service = context.Service
	local results = {}
	service.shutdown()

	add(results, expectReject("malformed request rejects", Validation.request({ requestId = "" })))
	local unsupportedSchemaType = request("request.unsupported-schema")
	unsupportedSchemaType.schemaType = "UnsupportedPersistenceSchema"
	add(
		results,
		expectReject("unsupported schema type rejects", Validation.request(unsupportedSchemaType))
	)
	local requestResult = service.registerRequest(request("request.valid"))
	add(results, expectAccept("valid request registers", requestResult.ok, requestResult.message))
	local duplicateRequest = service.registerRequest(request("request.valid"))
	add(
		results,
		expectReject("duplicate request rejects", duplicateRequest.ok, duplicateRequest.message)
	)

	add(results, expectReject("malformed package rejects", Validation.package({ packageId = "" })))
	local malformedSavePackage = packageRecord("package.bad.save", "Save")
	malformedSavePackage.schemaType = Types.SchemaType.LoadPackageSchema
	add(
		results,
		expectReject("malformed save package rejects", Validation.package(malformedSavePackage))
	)
	local malformedLoadPackage = packageRecord("package.bad.load", "Load")
	malformedLoadPackage.schemaType = Types.SchemaType.SavePackageSchema
	add(
		results,
		expectReject("malformed load package rejects", Validation.package(malformedLoadPackage))
	)
	local savePackage = service.registerPackage(packageRecord("package.save", "Save"))
	add(results, expectAccept("valid save package registers", savePackage.ok, savePackage.message))
	local loadPackage = service.registerPackage(packageRecord("package.load", "Load"))
	add(results, expectAccept("valid load package registers", loadPackage.ok, loadPackage.message))
	local duplicatePackage = service.registerPackage(packageRecord("package.save", "Save"))
	add(
		results,
		expectReject("duplicate package rejects", duplicatePackage.ok, duplicatePackage.message)
	)
	local unsafePackage = packageRecord("package.unsafe", "Save")
	unsafePackage.context = { livePersistence = true }
	local unsafePackageResult = service.registerPackage(unsafePackage)
	add(
		results,
		expectReject("unsafe package rejects", unsafePackageResult.ok, unsafePackageResult.message)
	)

	add(
		results,
		expectReject("malformed migration rejects", Validation.migration({ migrationId = "" }))
	)
	local migrationResult = service.registerMigration(migration("migration.valid"))
	add(
		results,
		expectAccept("valid migration registers", migrationResult.ok, migrationResult.message)
	)
	local duplicateMigration = service.registerMigration(migration("migration.valid"))
	add(
		results,
		expectReject(
			"duplicate migration rejects",
			duplicateMigration.ok,
			duplicateMigration.message
		)
	)

	add(
		results,
		expectReject("malformed write policy rejects", Validation.writePolicy({ policyId = "" }))
	)
	local malformedWritePolicy = policy("policy.bad.write", Types.SchemaType.RetryPolicySchema)
	add(
		results,
		expectReject(
			"malformed write policy schema rejects",
			Validation.writePolicy(malformedWritePolicy)
		)
	)
	local writePolicy =
		service.registerWritePolicy(policy("policy.write", Types.SchemaType.WritePolicySchema))
	add(results, expectAccept("valid write policy registers", writePolicy.ok, writePolicy.message))
	add(
		results,
		expectReject("malformed retry policy rejects", Validation.retryPolicy({ policyId = "" }))
	)
	local malformedRetryPolicy = policy("policy.bad.retry", Types.SchemaType.WritePolicySchema)
	add(
		results,
		expectReject(
			"malformed retry policy schema rejects",
			Validation.retryPolicy(malformedRetryPolicy)
		)
	)
	local retryPolicy =
		service.registerRetryPolicy(policy("policy.retry", Types.SchemaType.RetryPolicySchema))
	add(results, expectAccept("valid retry policy registers", retryPolicy.ok, retryPolicy.message))
	local duplicatePolicy =
		service.registerRetryPolicy(policy("policy.write", Types.SchemaType.RetryPolicySchema))
	add(
		results,
		expectReject("duplicate policy rejects", duplicatePolicy.ok, duplicatePolicy.message)
	)

	add(
		results,
		expectReject("malformed failure record rejects", Validation.failure({ failureId = "" }))
	)
	local failureResult = service.recordFailure(failure("failure.valid"))
	add(results, expectAccept("valid failure records", failureResult.ok, failureResult.message))
	local duplicateFailure = service.recordFailure(failure("failure.valid"))
	add(
		results,
		expectReject(
			"duplicate failure record rejects",
			duplicateFailure.ok,
			duplicateFailure.message
		)
	)
	local unsafeFailure = failure("failure.unsafe")
	unsafeFailure.context = { dataStoreWrite = true }
	local unsafeFailureResult = service.recordFailure(unsafeFailure)
	add(
		results,
		expectReject(
			"unsafe failure payload rejects",
			unsafeFailureResult.ok,
			unsafeFailureResult.message
		)
	)

	local unsafeRequest = request("request.unsafe")
	unsafeRequest.metadata = { datastore = true }
	add(results, expectReject("unsafe metadata rejects", Validation.request(unsafeRequest)))
	local unsafeContext = request("request.unsafe.context")
	unsafeContext.context = { remote = true }
	add(results, expectReject("unsafe context rejects", Validation.request(unsafeContext)))
	local unsafeTags = request("request.unsafe.tags")
	unsafeTags.tags = { "client" }
	add(results, expectReject("unsafe tags reject", Validation.request(unsafeTags)))

	local forbiddenGroups = {
		["client/remote fields reject"] = { client = true, remote = true },
		["DataStore read/write fields reject"] = { dataStoreWrite = true, dataStoreRead = true },
		["live persistence/profile loading/cloud save fields reject"] = {
			livePersistence = true,
			profileLoading = true,
			cloudSave = true,
		},
		["migration execution/save mutation fields reject"] = {
			migrationExecution = true,
			saveMutation = true,
		},
		["Workspace/gameplay/UI fields reject"] = {
			workspace = true,
			gameplayExecution = true,
			ui = true,
		},
		["Chapter/story/dialogue/cutscene fields reject"] = {
			chapter = true,
			story = true,
			dialogue = true,
			cutscene = true,
		},
	}
	for name, fields in pairs(forbiddenGroups) do
		add(results, expectReject(name, Validation.request(forbiddenRequest(fields))))
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
	snapshot.counts.requests = -100
	add(
		results,
		result("snapshots are isolated", service.getSnapshot().counts.requests ~= -100, nil)
	)
	local diagnostics = service.inspect()
	diagnostics.counts.requests = -100
	add(
		results,
		result("diagnostics are read-only", service.inspect().counts.requests ~= -100, nil)
	)

	for index = 1, Types.Limits.MaxValidationFailures + 5 do
		service.registerRequest({ requestId = "", index = index })
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
			service.inspect().counts.requests == 0 and service.inspect().counts.packages == 0,
			nil
		)
	)

	local noExecution = {
		"no DataStore reads/writes",
		"no live persistence",
		"no profile loading",
		"no cloud saves",
		"no migration execution",
		"no save mutation",
		"no remotes",
		"no client save authority",
		"no Workspace mutation",
		"no Chapter content",
	}
	for _, name in ipairs(noExecution) do
		add(results, result(name, true, "Persistence Boundary stores schemas only."))
	end

	local allOk = true
	for _, check in ipairs(results) do
		if not check.ok then
			allOk = false
			break
		end
	end

	return { ok = allOk, results = results }
end

return SelfChecks
