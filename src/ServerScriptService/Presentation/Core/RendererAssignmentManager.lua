--!strict

local Evidence = require(script.Parent.RenderingRuntimeEvidence)
local Metrics = require(script.Parent.RenderingRuntimeMetrics)
local Renderers = require(script.Parent.RendererRuntimeRegistry)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.RenderingSessionRegistry)
local Types = require(script.Parent.PresentationTypes)

local Manager = {}
local assignments = {}
local nextOrdinal = 0

local function compatible(renderer: any, session: any): boolean
	if
		renderer.status ~= Types.RenderingRuntimeRendererStatus.Available
		and renderer.status ~= Types.RenderingRuntimeRendererStatus.Registered
	then
		return false
	end
	if renderer.currentLoad >= renderer.capacity then
		return false
	end
	local supportsKind = false
	for _, kind in ipairs(renderer.supportedRenderingKinds) do
		if kind == session.renderingKind then
			supportsKind = true
			break
		end
	end
	return supportsKind
end

function Manager.assign(sessionId: string)
	if #assignments >= Types.RenderingRuntimeLimits.MaxAssignments then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.LimitExceeded,
			message = "assignment limit exceeded",
		}
	end
	local session = Sessions.get(sessionId)
	if session == nil then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.UnknownSession,
			message = "unknown rendering session",
		}
	end
	local candidates = {}
	for _, renderer in ipairs(Renderers.inspect()) do
		if compatible(renderer, session) then
			candidates[#candidates + 1] = renderer
		end
	end
	table.sort(candidates, function(left, right)
		if left.priority ~= right.priority then
			return left.priority > right.priority
		end
		if left.currentLoad ~= right.currentLoad then
			return left.currentLoad < right.currentLoad
		end
		if left.registrationOrdinal ~= right.registrationOrdinal then
			return left.registrationOrdinal < right.registrationOrdinal
		end
		return left.rendererId < right.rendererId
	end)
	local selected = candidates[1]
	if selected == nil then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.RendererUnavailable,
			message = "no compatible renderer",
		}
	end
	local assigned = Renderers.assign(selected.rendererId)
	if not assigned.ok then
		return assigned
	end
	nextOrdinal += 1
	local assignment = {
		rendererId = selected.rendererId,
		renderingSessionId = sessionId,
		assignmentOrdinal = nextOrdinal,
		assignmentReason = "compatible renderer selected deterministically",
		runtimeMetadata = {},
	}
	assignments[#assignments + 1] = assignment
	Sessions.update(sessionId, {
		rendererId = selected.rendererId,
		assignmentState = Types.RenderingRuntimeAssignmentState.Assigned,
	})
	Metrics.increment("assignments")
	Evidence.record("renderer assignment", assignment)
	return { ok = true, code = "Ok", assignment = Serialization.deepCopy(assignment) }
end

function Manager.inspect()
	return Serialization.deepCopy(assignments)
end

function Manager.clear()
	table.clear(assignments)
	nextOrdinal = 0
end

return Manager
