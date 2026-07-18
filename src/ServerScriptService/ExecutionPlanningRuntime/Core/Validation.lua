--!strict

local Serialization = require(script.Parent.Serialization)
local Types = require(script.Parent.Types)

local Validation = {}

local function enumContains(enum: { [string]: string }, value: string): boolean
	for _, enumValue in pairs(enum) do
		if enumValue == value then
			return true
		end
	end
	return false
end

local function result(ok: boolean, code: string, reason: string?): (boolean, string?)
	return ok, if ok then nil else code .. ": " .. tostring(reason)
end

local function isPlainObject(value: any): boolean
	return type(value) == "table"
end

local function validateId(value: any, label: string): (boolean, string?)
	if type(value) ~= "string" or value == "" or string.find(value, "%s") ~= nil then
		return result(
			false,
			Types.ResultCode.InvalidSchema,
			label .. " must be a stable non-empty id"
		)
	end
	return result(true, Types.ResultCode.Ok, nil)
end

local function exactFields(value: any, fields: { string }, label: string): (boolean, string?)
	if not isPlainObject(value) then
		return result(false, Types.ResultCode.InvalidSchema, label .. " must be a table")
	end
	for _, field in ipairs(fields) do
		if value[field] == nil then
			return result(false, Types.ResultCode.InvalidSchema, label .. " missing " .. field)
		end
	end
	for key in pairs(value) do
		if not table.find(fields, key) then
			return result(
				false,
				Types.ResultCode.InvalidSchema,
				label .. " has unsupported field " .. tostring(key)
			)
		end
	end
	return result(true, Types.ResultCode.Ok, nil)
end

local function validateMetadata(value: any): (boolean, string?)
	if type(value) ~= "table" then
		return result(false, Types.ResultCode.InvalidSchema, "metadata must be a table")
	end
	local unsafe, reason = Serialization.hasUnsafePayload(value)
	if unsafe then
		return result(false, Types.ResultCode.UnsafePayload, reason)
	end
	return result(true, Types.ResultCode.Ok, nil)
end

function Validation.node(node: any): (boolean, string?)
	local ok, reason = exactFields(node, Types.NodeFields, "planning node")
	if not ok then
		return ok, reason
	end
	ok, reason = validateId(node.nodeId, "nodeId")
	if not ok then
		return ok, reason
	end
	if not enumContains(Types.NodeKind, node.nodeKind) then
		return result(false, Types.ResultCode.InvalidSchema, "unsupported nodeKind")
	end
	if type(node.authorityOwner) ~= "string" or node.authorityOwner == "" then
		return result(false, Types.ResultCode.UnknownAuthority, "authorityOwner invalid")
	end
	if type(node.version) ~= "string" or node.version == "" then
		return result(false, Types.ResultCode.VersionMismatch, "version invalid")
	end
	if type(node.orderingKey) ~= "number" then
		return result(false, Types.ResultCode.InvalidSchema, "orderingKey must be numeric")
	end
	if not enumContains(Types.PlanningClassification, node.planningClassification) then
		return result(false, Types.ResultCode.InvalidSchema, "unsupported planningClassification")
	end
	return validateMetadata(node.metadata)
end

function Validation.dependency(dependency: any): (boolean, string?)
	local ok, reason = exactFields(dependency, Types.DependencyFields, "planning dependency")
	if not ok then
		return ok, reason
	end
	for _, field in ipairs({ "dependencyId", "fromNodeId", "toNodeId", "requiredVersion" }) do
		ok, reason = validateId(dependency[field], field)
		if not ok then
			return ok, reason
		end
	end
	if dependency.fromNodeId == dependency.toNodeId then
		return result(false, Types.ResultCode.CyclicDependency, "self dependency rejected")
	end
	if not enumContains(Types.DependencyKind, dependency.dependencyKind) then
		return result(false, Types.ResultCode.InvalidSchema, "unsupported dependencyKind")
	end
	return validateMetadata(dependency.metadata)
end

function Validation.constraint(constraint: any): (boolean, string?)
	local ok, reason = exactFields(constraint, Types.ConstraintFields, "planning constraint")
	if not ok then
		return ok, reason
	end
	for _, field in ipairs({ "constraintId", "nodeId" }) do
		ok, reason = validateId(constraint[field], field)
		if not ok then
			return ok, reason
		end
	end
	if not enumContains(Types.ConstraintKind, constraint.constraintKind) then
		return result(false, Types.ResultCode.InvalidSchema, "unsupported constraintKind")
	end
	if type(constraint.required) ~= "boolean" then
		return result(false, Types.ResultCode.InvalidSchema, "required must be boolean")
	end
	return validateMetadata(constraint.metadata)
end

function Validation.lifecycle(transitions: { any }): (boolean, string?)
	local expected = {
		Types.LifecycleState.Uninitialized,
		Types.LifecycleState.Bootstrapping,
		Types.LifecycleState.GraphBuilding,
		Types.LifecycleState.DependencyValidation,
		Types.LifecycleState.ConstraintValidation,
		Types.LifecycleState.EligibilityAnalysis,
		Types.LifecycleState.PlanFinalization,
		Types.LifecycleState.PlanPublication,
		Types.LifecycleState.Complete,
	}
	if #transitions ~= #expected then
		return result(false, Types.ResultCode.InvalidSchema, "lifecycle transition count invalid")
	end
	for index, state in ipairs(expected) do
		if transitions[index] ~= state then
			return result(
				false,
				Types.ResultCode.InvalidSchema,
				"lifecycle transition ordering invalid"
			)
		end
	end
	return result(true, Types.ResultCode.Ok, nil)
end

function Validation.validate(): (boolean, string?)
	if Types.RuntimeProviderName ~= "executionPlanningRuntime" then
		return result(false, Types.ResultCode.InvalidSchema, "provider drift")
	end
	if Types.SnapshotKind ~= "executionPlanningRuntimeSnapshot" then
		return result(false, Types.ResultCode.InvalidSchema, "snapshot drift")
	end
	if Types.RuntimeTruth.executionBlocked ~= true or Types.RuntimeTruth.runnerInvoked ~= false then
		return result(false, Types.ResultCode.InvalidSchema, "runtime truth drift")
	end
	return result(true, Types.ResultCode.Ok, nil)
end

return Validation
