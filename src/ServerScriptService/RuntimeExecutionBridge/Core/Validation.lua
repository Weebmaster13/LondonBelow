--!strict

local Serialization = require(script.Parent.Serialization)
local Types = require(script.Parent.Types)

local Validation = {}

local function result(ok: boolean, reason: string?): (boolean, string?)
	return ok, if ok then nil else reason
end

local function exactFields(value: any, fields: { string }, label: string): (boolean, string?)
	if type(value) ~= "table" then
		return result(false, label .. " must be a table")
	end
	for _, field in ipairs(fields) do
		if value[field] == nil then
			return result(false, label .. " missing " .. field)
		end
	end
	for key in pairs(value) do
		if not table.find(fields, key) then
			return result(false, label .. " has unsupported field " .. tostring(key))
		end
	end
	return result(true, nil)
end

local function validateId(value: any, label: string): (boolean, string?)
	if type(value) ~= "string" or value == "" or string.find(value, "%s") ~= nil then
		return result(false, label .. " must be a stable id")
	end
	return Serialization.validateSafeString(value, label)
end

function Validation.session(session: any): (boolean, string?)
	local ok, reason = exactFields(session, Types.RequiredSessionFields, "runtime bridge session")
	if not ok then
		return ok, reason
	end
	for _, field in ipairs({
		"sessionId",
		"manifestId",
		"runnerId",
		"frameworkVersion",
		"repositoryCommit",
		"executionMode",
	}) do
		ok, reason = validateId(session[field], field)
		if not ok then
			return ok, reason
		end
	end
	if session.phase ~= 155 then
		return result(false, "phase must be 155")
	end
	if
		type(session.expectedOutputPath) ~= "string"
		or #session.expectedOutputPath > Types.Limits.MaxOutputPathLength
	then
		return result(false, "expectedOutputPath invalid")
	end
	if
		type(session.timeout) ~= "number"
		or session.timeout <= 0
		or session.timeout > Types.Limits.MaxTimeoutMilliseconds
	then
		return result(false, "timeout invalid")
	end
	if
		type(session.policies) ~= "table"
		or session.policies.certificationDecisionAllowed ~= false
	then
		return result(false, "certification decisions must be disabled")
	end
	return result(true, nil)
end

function Validation.evidence(evidence: any): (boolean, string?)
	local ok, reason = exactFields(evidence, Types.RunnerResultFields, "runtime bridge evidence")
	if not ok then
		return ok, reason
	end
	if evidence.schemaVersion ~= Types.SchemaVersion then
		return result(false, "schemaVersion unsupported")
	end
	if evidence.phase ~= 155 then
		return result(false, "phase mismatch")
	end
	if evidence.productionCertified ~= false then
		return result(false, "bridge cannot certify")
	end
	if
		evidence.status ~= Types.Status.Blocked
		and evidence.status ~= Types.Status.Passed
		and evidence.status ~= Types.Status.Failed
	then
		return result(false, "status unsupported")
	end
	if
		type(evidence.assertions) ~= "table"
		or #evidence.assertions > Types.Limits.MaxAssertions
	then
		return result(false, "assertions invalid")
	end
	return result(true, nil)
end

function Validation.validate(): (boolean, string?)
	if Types.RuntimeProviderName ~= "runtimeExecutionBridge" then
		return result(false, "provider name drift")
	end
	if Types.SnapshotKind ~= "runtimeExecutionBridgeSnapshot" then
		return result(false, "snapshot kind drift")
	end
	return result(true, nil)
end

return Validation
