--!strict
-- Server-authoritative request, authorization, lifecycle, and evidence pipeline.

local Serialization = require(script.Parent.InteractionSerialization)
local Types = require(script.Parent.InteractionTypes)
local Validation = require(script.Parent.InteractionValidation)

local RequestRuntime = {}

local function playerKey(player: any, request: any): string
	local userId = if type(request.playerId) == "number" then request.playerId else nil
	if userId == nil and type(player) == "table" and type(player.UserId) == "number" then
		userId = player.UserId
	end
	return tostring(userId or "system")
end

local function sessionIdFor(request: any): string
	return string.sub(
		request.interactionId .. ":" .. request.requestId,
		1,
		Types.Limits.MaxSessionIdLength
	)
end

local function evidence(
	state: any,
	sessionId: string?,
	stage: string,
	status: string,
	reason: string?,
	request: any?
)
	state.recordEvidence({
		sessionId = sessionId,
		stage = stage,
		status = status,
		reason = reason,
		requestId = if type(request) == "table" then request.requestId else nil,
		interactionId = if type(request) == "table" then request.interactionId else nil,
		recordedAt = os.clock(),
	})
end

function RequestRuntime.evaluate(state: any, player: any, request: any)
	local valid, reason = Validation.request(request)
	if not valid then
		return false, Types.ResultCode.InvalidRequest, Types.EligibilityReason.UnsafeRequest, reason
	end

	local key = playerKey(player, request)
	if state.isDuplicateRequest(key, request.requestId) then
		return false,
			Types.ResultCode.DuplicateRequest,
			Types.EligibilityReason.UnsafeRequest,
			"duplicate requestId"
	end
	if state.isRateLimited(key) then
		return false,
			Types.ResultCode.RateLimited,
			Types.EligibilityReason.RateLimited,
			"request rate limit exceeded"
	end

	local interaction = state.getInteraction(request.interactionId)
	if interaction == nil then
		return false,
			Types.ResultCode.UnknownInteraction,
			Types.EligibilityReason.UnknownInteraction,
			"unknown interactionId"
	end
	if interaction.interactionStatus == Types.InteractionStatus.Disabled then
		return false,
			Types.ResultCode.NotEligible,
			Types.EligibilityReason.Disabled,
			"interaction disabled"
	end
	if interaction.targetId ~= nil then
		local target = state.getTarget(interaction.targetId)
		if target == nil then
			return false,
				Types.ResultCode.UnknownTarget,
				Types.EligibilityReason.UnknownTarget,
				"unknown targetId"
		end
		if request.targetId ~= nil and request.targetId ~= interaction.targetId then
			return false,
				Types.ResultCode.NotEligible,
				Types.EligibilityReason.TargetMismatch,
				"targetId mismatch"
		end
		if target.targetStatus == Types.TargetStatus.Unavailable then
			return false,
				Types.ResultCode.NotEligible,
				Types.EligibilityReason.UnknownTarget,
				"target unavailable"
		end
	end
	if interaction.eligibility ~= nil and interaction.eligibility.enabled == false then
		return false,
			Types.ResultCode.NotEligible,
			Types.EligibilityReason.Disabled,
			"eligibility disabled"
	end
	if state.hasContention(request.interactionId) and interaction.replayable ~= true then
		return false,
			Types.ResultCode.ContentionBlocked,
			Types.EligibilityReason.ContentionActive,
			"interaction contention active"
	end

	return true, Types.ResultCode.Ok, Types.EligibilityReason.Eligible, "eligible", interaction
end

function RequestRuntime.request(state: any, player: any, request: any, handler: any?)
	local eligible, code, eligibilityReason, message, interaction =
		RequestRuntime.evaluate(state, player, request)
	if not eligible then
		evidence(state, nil, "Eligibility", "Rejected", message, request)
		return {
			ok = false,
			code = code,
			message = message,
			eligibilityReason = eligibilityReason,
			session = nil,
			result = nil,
		}
	end

	local sessionId = sessionIdFor(request)
	local session = {
		sessionId = sessionId,
		requestId = request.requestId,
		interactionId = request.interactionId,
		targetId = request.targetId or interaction.targetId,
		playerKey = playerKey(player, request),
		status = Types.SessionStatus.Planned,
		startedAt = os.clock(),
		authorizedAt = nil,
		completedAt = nil,
		cancelledAt = nil,
		eligibilityReason = eligibilityReason,
		authorization = {
			serverAuthorized = true,
			clientAuthorityAccepted = false,
		},
		plan = {
			handlerKind = interaction.handlerKind or "ReferenceSchemaHandler",
			mutationOwner = interaction.ownerSystem,
			runtimeMutatesWorkspace = false,
			runtimeCreatesRemotes = false,
		},
	}

	state.addSession(session)
	state.updateSession(sessionId, {
		status = Types.SessionStatus.Authorized,
		authorizedAt = os.clock(),
	})
	state.beginContention(request.interactionId, sessionId)
	evidence(state, sessionId, "Authorization", "Accepted", nil, request)

	local handlerResult = {
		ok = true,
		code = Types.ResultCode.Ok,
		message = "Interaction planned.",
		mutationApplied = false,
	}
	if handler ~= nil then
		if type(handler) ~= "table" or type(handler.execute) ~= "function" then
			state.updateSession(sessionId, {
				status = Types.SessionStatus.Rejected,
				completedAt = os.clock(),
			})
			state.endContention(request.interactionId, sessionId)
			evidence(
				state,
				sessionId,
				"Handler",
				"Rejected",
				"handler contract unavailable",
				request
			)
			return {
				ok = false,
				code = Types.ResultCode.HandlerRejected,
				message = "handler contract unavailable",
				eligibilityReason = Types.EligibilityReason.HandlerUnavailable,
				session = Serialization.deepCopy(session),
				result = nil,
			}
		end
		state.updateSession(sessionId, { status = Types.SessionStatus.Executing })
		local ok, executed = pcall(handler.execute, {
			player = player,
			request = Serialization.deepCopy(request),
			interaction = Serialization.deepCopy(interaction),
			sessionId = sessionId,
		})
		if not ok or type(executed) ~= "table" or executed.ok ~= true then
			local failure = if ok and type(executed) == "table"
				then executed.message
				else tostring(executed)
			state.updateSession(sessionId, {
				status = Types.SessionStatus.Failed,
				completedAt = os.clock(),
			})
			state.endContention(request.interactionId, sessionId)
			evidence(state, sessionId, "Handler", "Failed", failure, request)
			return {
				ok = false,
				code = Types.ResultCode.HandlerRejected,
				message = failure or "handler rejected interaction",
				eligibilityReason = Types.EligibilityReason.HandlerUnavailable,
				session = Serialization.deepCopy(session),
				result = nil,
			}
		end
		handlerResult = Serialization.deepCopy(executed)
	end

	state.updateSession(sessionId, {
		status = Types.SessionStatus.Completed,
		completedAt = os.clock(),
		result = handlerResult,
	})
	state.endContention(request.interactionId, sessionId)
	evidence(state, sessionId, "Execution", "Completed", nil, request)

	return {
		ok = true,
		code = Types.ResultCode.Ok,
		message = handlerResult.message or "Interaction accepted.",
		eligibilityReason = eligibilityReason,
		session = state.inspect().sessions[sessionId],
		result = handlerResult,
	}
end

function RequestRuntime.cancel(state: any, sessionId: string, reason: string?)
	local snapshot = state.inspect()
	local session = snapshot.sessions[sessionId]
	if session == nil then
		return false, Types.ResultCode.InvalidRequest, "unknown sessionId"
	end
	state.updateSession(sessionId, {
		status = Types.SessionStatus.Cancelled,
		cancelledAt = os.clock(),
		cancelReason = reason or "cancelled",
	})
	state.endContention(session.interactionId, sessionId)
	evidence(state, sessionId, "Cancellation", "Cancelled", reason, {
		requestId = session.requestId,
		interactionId = session.interactionId,
	})
	return true, Types.ResultCode.Cancelled, "interaction session cancelled"
end

return RequestRuntime
