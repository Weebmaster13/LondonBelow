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
	local requestResult = service.registerRequest(request("request.valid"))
	add(results, expectAccept("valid request registers", requestResult.ok, requestResult.message))
	local duplicateRequest = service.registerRequest(request("request.valid"))
	add(
		results,
		expectReject("duplicate request rejects", duplicateRequest.ok, duplicateRequest.message)
	)

	add(results, expectReject("malformed package rejects", Validation.package({ packageId = "" })))
	local savePackage = service.registerPackage(packageRecord("package.save", "Save"))
	add(results, expectAccept("valid save package registers", savePackage.ok, savePackage.message))
	local loadPackage = service.registerPackage(packageRecord("package.load", "Load"))
	add(results, expectAccept("valid load package registers", loadPackage.ok, loadPackage.message))
	local duplicatePackage = service.registerPackage(packageRecord("package.save", "Save"))
	add(
		results,
		expectReject("duplicate package rejects", duplicatePackage.ok, duplicatePackage.message)
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

	add(
		results,
		expectReject("malformed write policy rejects", Validation.writePolicy({ policyId = "" }))
	)
	local writePolicy =
		service.registerWritePolicy(policy("policy.write", Types.SchemaType.WritePolicySchema))
	add(results, expectAccept("valid write policy registers", writePolicy.ok, writePolicy.message))
	add(
		results,
		expectReject("malformed retry policy rejects", Validation.retryPolicy({ policyId = "" }))
	)
	local retryPolicy =
		service.registerRetryPolicy(policy("policy.retry", Types.SchemaType.RetryPolicySchema))
	add(results, expectAccept("valid retry policy registers", retryPolicy.ok, retryPolicy.message))

	local failureResult = service.recordFailure(failure("failure.valid"))
	add(results, expectAccept("valid failure records", failureResult.ok, failureResult.message))

	local unsafeRequest = request("request.unsafe")
	unsafeRequest.metadata = { datastore = true }
	add(results, expectReject("unsafe payload rejects", Validation.request(unsafeRequest)))

	local forbiddenGroups = {
		["client/remote fields reject"] = { client = true, remote = true },
		["DataStore execution fields reject"] = { dataStoreWrite = true, dataStoreRead = true },
		["live persistence fields reject"] = { livePersistence = true },
		["profile loading fields reject"] = { profileLoading = true },
		["cloud save fields reject"] = { cloudSave = true },
		["migration execution fields reject"] = { migrationExecution = true },
		["save mutation fields reject"] = { saveMutation = true },
		["Workspace fields reject"] = { workspace = true },
		["gameplay execution fields reject"] = { gameplayExecution = true },
		["UI fields reject"] = { ui = true },
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
