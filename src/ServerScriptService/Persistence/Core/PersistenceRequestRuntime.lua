--!strict
-- Central bounded state store for the Persistence Boundary Foundation.

local Serialization = require(script.Parent.PersistenceSerialization)
local Types = require(script.Parent.PersistenceTypes)
local Validation = require(script.Parent.PersistenceValidation)

local Runtime = {}

local requests: { [string]: any } = {}
local packages: { [string]: any } = {}
local migrations: { [string]: any } = {}
local policies: { [string]: any } = {}
local policyIds: { [string]: boolean } = {}
local failures: { [string]: any } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}

local function boundedInsert(list: { any }, value: any, limit: number)
	table.insert(list, value)
	while #list > limit do
		table.remove(list, 1)
	end
end

local function countMap(map: { [string]: any }): number
	local count = 0
	for _ in pairs(map) do
		count += 1
	end
	return count
end

function Runtime.registerRequest(schema: any): (boolean, string?)
	local ok, reason = Validation.request(schema)
	if not ok then
		return false, reason
	end
	if requests[schema.requestId] ~= nil then
		return false, "duplicate requestId"
	end
	if countMap(requests) >= Types.Limits.MaxRequests then
		return false, "request limit exceeded"
	end
	requests[schema.requestId] = Serialization.deepCopy(schema)
	return true, nil
end

function Runtime.registerPackage(schema: any): (boolean, string?)
	local ok, reason = Validation.package(schema)
	if not ok then
		return false, reason
	end
	if packages[schema.packageId] ~= nil then
		return false, "duplicate packageId"
	end
	if countMap(packages) >= Types.Limits.MaxPackages then
		return false, "package limit exceeded"
	end
	packages[schema.packageId] = Serialization.deepCopy(schema)
	return true, nil
end

function Runtime.registerMigration(schema: any): (boolean, string?)
	local ok, reason = Validation.migration(schema)
	if not ok then
		return false, reason
	end
	if migrations[schema.migrationId] ~= nil then
		return false, "duplicate migrationId"
	end
	if countMap(migrations) >= Types.Limits.MaxMigrations then
		return false, "migration limit exceeded"
	end
	migrations[schema.migrationId] = Serialization.deepCopy(schema)
	return true, nil
end

function Runtime.registerWritePolicy(schema: any): (boolean, string?)
	local ok, reason = Validation.writePolicy(schema)
	if not ok then
		return false, reason
	end
	if policyIds[schema.policyId] == true then
		return false, "duplicate policyId"
	end
	if countMap(policies) >= Types.Limits.MaxPolicies then
		return false, "policy limit exceeded"
	end
	local id = "write:" .. schema.policyId
	policyIds[schema.policyId] = true
	policies[id] = Serialization.deepCopy(schema)
	return true, nil
end

function Runtime.registerRetryPolicy(schema: any): (boolean, string?)
	local ok, reason = Validation.retryPolicy(schema)
	if not ok then
		return false, reason
	end
	if policyIds[schema.policyId] == true then
		return false, "duplicate policyId"
	end
	if countMap(policies) >= Types.Limits.MaxPolicies then
		return false, "policy limit exceeded"
	end
	local id = "retry:" .. schema.policyId
	policyIds[schema.policyId] = true
	policies[id] = Serialization.deepCopy(schema)
	return true, nil
end

function Runtime.recordFailure(record: any): (boolean, string?)
	local ok, reason = Validation.failure(record)
	if not ok then
		return false, reason
	end
	if failures[record.failureId] ~= nil then
		return false, "duplicate failureId"
	end
	if countMap(failures) >= Types.Limits.MaxFailures then
		return false, "failure record limit exceeded"
	end
	failures[record.failureId] = Serialization.deepCopy(record)
	return true, nil
end

function Runtime.recordValidationFailure(reason: string, payload: any?)
	boundedInsert(validationFailures, {
		reason = reason,
		payload = Serialization.diagnosticCopy(payload),
	}, Types.Limits.MaxValidationFailures)
end

function Runtime.recordSnapshot(snapshot: any)
	boundedInsert(
		snapshotHistory,
		Serialization.diagnosticCopy(snapshot),
		Types.Limits.MaxSnapshotHistory
	)
end

function Runtime.inspect()
	return Serialization.deepCopy({
		requests = requests,
		packages = packages,
		migrations = migrations,
		policies = policies,
		failures = failures,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			requests = countMap(requests),
			packages = countMap(packages),
			migrations = countMap(migrations),
			policies = countMap(policies),
			failures = countMap(failures),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function Runtime.clear()
	table.clear(requests)
	table.clear(packages)
	table.clear(migrations)
	table.clear(policies)
	table.clear(policyIds)
	table.clear(failures)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return Runtime
