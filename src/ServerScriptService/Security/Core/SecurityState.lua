--!strict
-- Central bounded state store for the Security / Anti-Exploit Boundary Foundation.

local Serialization = require(script.Parent.SecuritySerialization)
local Types = require(script.Parent.SecurityTypes)
local Validation = require(script.Parent.SecurityValidation)

local State = {}

local trustPolicies: { [string]: any } = {}
local authorityRules: { [string]: any } = {}
local exploitSignals: { [string]: any } = {}
local clientRejections: { [string]: any } = {}
local remoteSafetyContracts: { [string]: any } = {}
local rateLimits: { [string]: any } = {}
local audits: { [string]: any } = {}
local schemaIds: { [string]: boolean } = {}
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

local function rejectDuplicate(schemaId: string, duplicateReason: string): (boolean, string?)
	if schemaIds[schemaId] == true then
		return false, duplicateReason
	end
	return true, nil
end

function State.registerTrustPolicy(schema: any): (boolean, string?)
	local ok, reason = Validation.trustPolicy(schema)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason = rejectDuplicate(schema.trustPolicyId, "duplicate trustPolicyId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(trustPolicies) >= Types.Limits.MaxTrustPolicies then
		return false, "trust policy limit exceeded"
	end
	schemaIds[schema.trustPolicyId] = true
	trustPolicies[schema.trustPolicyId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerAuthorityRule(schema: any): (boolean, string?)
	local ok, reason = Validation.authorityRule(schema)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason =
		rejectDuplicate(schema.authorityRuleId, "duplicate authorityRuleId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(authorityRules) >= Types.Limits.MaxAuthorityRules then
		return false, "authority rule limit exceeded"
	end
	schemaIds[schema.authorityRuleId] = true
	authorityRules[schema.authorityRuleId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerExploitSignal(schema: any): (boolean, string?)
	local ok, reason = Validation.exploitSignal(schema)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason =
		rejectDuplicate(schema.exploitSignalId, "duplicate exploitSignalId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(exploitSignals) >= Types.Limits.MaxExploitSignals then
		return false, "exploit signal limit exceeded"
	end
	schemaIds[schema.exploitSignalId] = true
	exploitSignals[schema.exploitSignalId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerClientRejection(schema: any): (boolean, string?)
	local ok, reason = Validation.clientRejection(schema)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason =
		rejectDuplicate(schema.clientRejectionId, "duplicate clientRejectionId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(clientRejections) >= Types.Limits.MaxClientRejections then
		return false, "client rejection limit exceeded"
	end
	schemaIds[schema.clientRejectionId] = true
	clientRejections[schema.clientRejectionId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerRemoteSafety(schema: any): (boolean, string?)
	local ok, reason = Validation.remoteSafety(schema)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason =
		rejectDuplicate(schema.remoteSafetyId, "duplicate remoteSafetyId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(remoteSafetyContracts) >= Types.Limits.MaxRemoteSafetyContracts then
		return false, "remote safety contract limit exceeded"
	end
	schemaIds[schema.remoteSafetyId] = true
	remoteSafetyContracts[schema.remoteSafetyId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerRateLimit(schema: any): (boolean, string?)
	local ok, reason = Validation.rateLimit(schema)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason = rejectDuplicate(schema.rateLimitId, "duplicate rateLimitId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(rateLimits) >= Types.Limits.MaxRateLimits then
		return false, "rate limit policy limit exceeded"
	end
	schemaIds[schema.rateLimitId] = true
	rateLimits[schema.rateLimitId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerAudit(record: any): (boolean, string?)
	local ok, reason = Validation.audit(record)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason = rejectDuplicate(record.auditId, "duplicate auditId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(audits) >= Types.Limits.MaxAudits then
		return false, "audit record limit exceeded"
	end
	schemaIds[record.auditId] = true
	audits[record.auditId] = Serialization.deepCopy(record)
	return true, nil
end

function State.recordValidationFailure(reason: string, payload: any?)
	boundedInsert(validationFailures, {
		reason = reason,
		payload = Serialization.diagnosticCopy(payload),
	}, Types.Limits.MaxValidationFailures)
end

function State.recordSnapshot(snapshot: any)
	boundedInsert(
		snapshotHistory,
		Serialization.diagnosticCopy(snapshot),
		Types.Limits.MaxSnapshotHistory
	)
end

function State.inspect()
	return Serialization.deepCopy({
		trustPolicies = trustPolicies,
		authorityRules = authorityRules,
		exploitSignals = exploitSignals,
		clientRejections = clientRejections,
		remoteSafetyContracts = remoteSafetyContracts,
		rateLimits = rateLimits,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			trustPolicies = countMap(trustPolicies),
			authorityRules = countMap(authorityRules),
			exploitSignals = countMap(exploitSignals),
			clientRejections = countMap(clientRejections),
			remoteSafetyContracts = countMap(remoteSafetyContracts),
			rateLimits = countMap(rateLimits),
			audits = countMap(audits),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(trustPolicies)
	table.clear(authorityRules)
	table.clear(exploitSignals)
	table.clear(clientRejections)
	table.clear(remoteSafetyContracts)
	table.clear(rateLimits)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return State
