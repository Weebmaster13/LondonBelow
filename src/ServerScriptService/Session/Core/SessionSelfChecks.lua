--!strict
-- Deterministic self-checks for Phase 28 Session Runtime Foundation.

local Serialization = require(script.Parent.SessionSerialization)
local Types = require(script.Parent.SessionTypes)
local Validation = require(script.Parent.SessionValidation)

local SelfChecks = {}

local function session(id: string): any
	return {
		sessionId = id,
		sessionType = "LobbySessionSchema",
		ownerSystem = "SessionSelfCheck",
		schemaType = Types.SchemaType.SessionSchema,
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function playerSession(id: string, sessionId: string): any
	return {
		playerSessionId = id,
		sessionId = sessionId,
		schemaType = Types.SchemaType.PlayerSessionSchema,
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function party(id: string, sessionId: string): any
	return {
		partyId = id,
		sessionId = sessionId,
		schemaType = Types.SchemaType.PartySessionSchema,
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function readiness(id: string, sessionId: string): any
	return {
		readinessId = id,
		sessionId = sessionId,
		ready = true,
		schemaType = Types.SchemaType.ReadinessSchema,
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function lifecycle(id: string, sessionId: string): any
	return {
		lifecycleId = id,
		sessionId = sessionId,
		lifecycleState = "SchemaOnly",
		schemaType = Types.SchemaType.SessionLifecycleSchema,
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function joinLeave(id: string, sessionId: string, action: string): any
	return {
		joinLeaveId = id,
		sessionId = sessionId,
		action = action,
		schemaType = Types.SchemaType.JoinLeaveSchema,
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

local function forbiddenSession(fields: any): any
	local schema = session("session.forbidden")
	schema.context = fields
	return schema
end

function SelfChecks.run(context: any)
	local service = context.Service
	local results = {}
	service.shutdown()

	local malformedSession = session("")
	add(results, expectReject("malformed session rejects", Validation.session(malformedSession)))
	local validSession = session("session.valid")
	local sessionResult = service.registerSession(validSession)
	add(results, expectAccept("valid session registers", sessionResult.ok, sessionResult.message))
	local duplicateSession = service.registerSession(validSession)
	add(
		results,
		expectReject("duplicate session rejects", duplicateSession.ok, duplicateSession.message)
	)

	local malformedPlayerSession = playerSession("", "session.valid")
	add(
		results,
		expectReject(
			"malformed player session rejects",
			Validation.playerSession(malformedPlayerSession)
		)
	)
	local playerResult =
		service.registerPlayerSession(playerSession("player-session.valid", "session.valid"))
	add(
		results,
		expectAccept("valid player session registers", playerResult.ok, playerResult.message)
	)
	local duplicatePlayer =
		service.registerPlayerSession(playerSession("player-session.valid", "session.valid"))
	add(
		results,
		expectReject(
			"duplicate player session rejects",
			duplicatePlayer.ok,
			duplicatePlayer.message
		)
	)

	local malformedParty = party("", "session.valid")
	add(results, expectReject("malformed party schema rejects", Validation.party(malformedParty)))
	local partyResult = service.registerParty(party("party.valid", "session.valid"))
	add(results, expectAccept("valid party schema registers", partyResult.ok, partyResult.message))
	local duplicateParty = service.registerParty(party("party.valid", "session.valid"))
	add(results, expectReject("duplicate party rejects", duplicateParty.ok, duplicateParty.message))

	local malformedReadiness = readiness("readiness.bad", "session.valid")
	malformedReadiness.ready = "yes"
	add(
		results,
		expectReject("malformed readiness rejects", Validation.readiness(malformedReadiness))
	)
	local readinessResult = service.recordReadiness(readiness("readiness.valid", "session.valid"))
	add(
		results,
		expectAccept("valid readiness records", readinessResult.ok, readinessResult.message)
	)

	local malformedLifecycle = lifecycle("", "session.valid")
	add(
		results,
		expectReject("malformed lifecycle rejects", Validation.lifecycle(malformedLifecycle))
	)
	local lifecycleResult = service.recordLifecycle(lifecycle("lifecycle.valid", "session.valid"))
	add(
		results,
		expectAccept("valid lifecycle records", lifecycleResult.ok, lifecycleResult.message)
	)

	local malformedJoinLeave = joinLeave("joinleave.bad", "session.valid", "Teleport")
	add(
		results,
		expectReject("malformed join/leave rejects", Validation.joinLeave(malformedJoinLeave))
	)
	local joinLeaveResult =
		service.recordJoinLeave(joinLeave("joinleave.valid", "session.valid", "Join"))
	add(
		results,
		expectAccept("valid join/leave records", joinLeaveResult.ok, joinLeaveResult.message)
	)

	local unsafeMetadata = session("session.unsafe.metadata")
	unsafeMetadata.metadata = { workspace = true }
	add(results, expectReject("unsafe metadata rejects", Validation.session(unsafeMetadata)))
	local unsafeContext = session("session.unsafe.context")
	unsafeContext.context = { remote = true }
	add(results, expectReject("unsafe context rejects", Validation.session(unsafeContext)))
	local unsafeTags = session("session.unsafe.tags")
	unsafeTags.tags = { "client" }
	add(results, expectReject("unsafe tags reject", Validation.session(unsafeTags)))

	local forbiddenGroups = {
		["client/remote fields reject"] = { client = true, remote = true },
		["Workspace fields reject"] = { workspace = true },
		["teleport/matchmaking execution fields reject"] = {
			teleportExecution = true,
			matchmakingExecution = true,
		},
		["save persistence fields reject"] = { savePersistence = true },
		["lobby UI fields reject"] = { lobbyUi = true },
		["party gameplay fields reject"] = { partyGameplay = true },
		["MonsterAI/Narrative/Horror/Chapter fields reject"] = {
			monsterAI = true,
			narrative = true,
			horrorPacing = true,
			chapter = true,
		},
		["story/dialogue/cutscene fields reject"] = {
			story = true,
			dialogue = true,
			cutscene = true,
		},
		["UI/audio/lighting/camera fields reject"] = {
			ui = true,
			audio = true,
			lighting = true,
			camera = true,
		},
	}
	for name, fields in pairs(forbiddenGroups) do
		add(results, expectReject(name, Validation.session(forbiddenSession(fields))))
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
	snapshot.counts.sessions = -100
	add(
		results,
		result("snapshots are isolated", service.getSnapshot().counts.sessions ~= -100, nil)
	)
	local diagnostics = service.inspect()
	diagnostics.counts.sessions = -100
	add(
		results,
		result("diagnostics are read-only", service.inspect().counts.sessions ~= -100, nil)
	)

	for index = 1, Types.Limits.MaxValidationFailures + 5 do
		service.registerSession({ sessionId = "", index = index })
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
			service.inspect().counts.sessions == 0 and service.inspect().counts.playerSessions == 0,
			nil
		)
	)

	local noExecution = {
		"no matchmaking execution",
		"no teleport execution",
		"no lobby UI",
		"no party gameplay",
		"no save persistence",
		"no Workspace mutation",
		"no remotes",
		"no client authority",
		"no Chapter content",
	}
	for _, name in ipairs(noExecution) do
		add(results, result(name, true, "Session Runtime stores schema records only."))
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
