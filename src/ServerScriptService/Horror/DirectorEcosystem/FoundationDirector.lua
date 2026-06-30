--!strict
--[[
	Reusable standard Director implementation for foundation Directors.

	This creates architecture-only Directors with capabilities, lifecycle,
	diagnostics, snapshots, approval hooks, and observation intake. It does not
	execute gameplay behavior.
]]

local Types = require(script.Parent.DirectorTypes)

local FoundationDirector = {}

type DirectorDescription = Types.DirectorDescription
type DirectorRequest = Types.DirectorRequest
type ApprovalResponse = Types.ApprovalResponse

local function now(): number
	return os.clock()
end

local function copyCapabilities(
	capabilities: { Types.DirectorCapability }
): { Types.DirectorCapability }
	local copied = {}

	for _, capability in ipairs(capabilities) do
		table.insert(copied, {
			id = capability.id,
			description = capability.description,
			requestKinds = table.clone(capability.requestKinds),
		})
	end

	return copied
end

function FoundationDirector.new(description: DirectorDescription): Types.Director
	local initialized = false
	local started = false
	local startedAt = 0
	local observationCount = 0
	local approvalCount = 0
	local cancelCount = 0
	local lastObservation: any = nil
	local lastRequest: DirectorRequest? = nil
	local lastError: string? = nil

	local director = {}

	function director:Initialize()
		initialized = true
	end

	function director:Start()
		if not initialized then
			self:Initialize()
		end

		started = true
		startedAt = now()
	end

	function director:Shutdown()
		started = false
	end

	function director:Observe(observation: any)
		observationCount += 1
		lastObservation = observation
	end

	function director:RequestApproval(request: DirectorRequest): ApprovalResponse
		approvalCount += 1
		lastRequest = request

		return {
			requestId = request.id,
			state = "Deferred",
			reason = "Foundation Director records request but does not execute behavior yet.",
			modifications = nil,
			decidedAt = now(),
			decidedBy = description.name,
		}
	end

	function director:CancelRequest(requestId: string, reason: string?): ApprovalResponse
		cancelCount += 1

		return {
			requestId = requestId,
			state = "Cancelled",
			reason = reason or "Request cancelled.",
			modifications = nil,
			decidedAt = now(),
			decidedBy = description.name,
		}
	end

	function director:GetHealth(): Types.DirectorHealth
		return {
			name = description.name,
			status = if started then "Running" elseif initialized then "Ready" else "NotInitialized",
			healthy = lastError == nil,
			message = nil,
			uptime = if startedAt > 0 then now() - startedAt else 0,
			lastError = lastError,
		}
	end

	function director:GetSnapshot()
		return {
			description = self:Describe(),
			health = self:GetHealth(),
			lastObservation = lastObservation,
			lastRequest = lastRequest,
		}
	end

	function director:GetDiagnostics()
		return {
			name = description.name,
			initialized = initialized,
			started = started,
			observationCount = observationCount,
			approvalCount = approvalCount,
			cancelCount = cancelCount,
			capabilityCount = #description.capabilities,
		}
	end

	function director:GetCapabilities()
		return copyCapabilities(description.capabilities)
	end

	function director:Validate(): (boolean, string?)
		if description.name == nil or description.displayName == "" then
			return false, "Director description is invalid"
		end

		if #description.responsibilities == 0 or #description.doesNotOwn == 0 then
			return false, "Director requires responsibilities and non-ownership"
		end

		return true, nil
	end

	function director:Describe(): DirectorDescription
		return {
			name = description.name,
			displayName = description.displayName,
			responsibilities = table.clone(description.responsibilities),
			doesNotOwn = table.clone(description.doesNotOwn),
			capabilities = copyCapabilities(description.capabilities),
			priority = description.priority,
		}
	end

	return director :: any
end

return FoundationDirector
