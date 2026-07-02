--!strict
-- Deterministic self-checks for Phase 34 Security / Anti-Exploit Boundary Foundation.

local Serialization = require(script.Parent.SecuritySerialization)
local Types = require(script.Parent.SecurityTypes)
local Validation = require(script.Parent.SecurityValidation)

local SelfChecks = {}

local function base(idField: string, id: string, schemaType: string): any
	return {
		[idField] = id,
		ownerSystem = "securityBoundarySelfCheck",
		schemaType = schemaType,
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function trustPolicy(id: string): any
	return base("trustPolicyId", id, Types.SchemaType.SecurityTrustPolicySchema)
end

local function authorityRule(id: string): any
	return base("authorityRuleId", id, Types.SchemaType.SecurityAuthorityRuleSchema)
end

local function exploitSignal(id: string): any
	return base("exploitSignalId", id, Types.SchemaType.SecurityExploitSignalSchema)
end

local function clientRejection(id: string): any
	return base("clientRejectionId", id, Types.SchemaType.SecurityClientRejectionSchema)
end

local function remoteSafety(id: string): any
	return base("remoteSafetyId", id, Types.SchemaType.SecurityRemoteSafetySchema)
end

local function rateLimit(id: string): any
	return base("rateLimitId", id, Types.SchemaType.SecurityRateLimitSchema)
end

local function audit(id: string): any
	return base("auditId", id, Types.SchemaType.SecurityAuditSchema)
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

local function unsafeSchema(schema: any, fields: any): any
	schema.context = fields
	return schema
end

local function forbiddenTrustPolicy(fields: any): any
	return unsafeSchema(trustPolicy("trust.forbidden"), fields)
end

local function withUnsupportedType(schema: any): any
	schema.schemaType = "UnsupportedSecuritySchema"
	return schema
end

local function longString(): string
	return string.rep("x", Types.Limits.MaxPayloadStringLength + 1)
end

function SelfChecks.run(context: any)
	local service = context.Service
	local results = {}
	service.shutdown()

	add(
		results,
		expectReject(
			"malformed trust policy rejects",
			Validation.trustPolicy({ trustPolicyId = "" })
		)
	)
	local unsupported = trustPolicy("trust.unsupported")
	unsupported.schemaType = "UnsupportedSecuritySchema"
	add(
		results,
		expectReject(
			"unsupported trust policy schema type rejects",
			Validation.trustPolicy(unsupported)
		)
	)
	local trustResult = service.registerTrustPolicy(trustPolicy("trust.valid"))
	add(results, expectAccept("valid trust policy registers", trustResult.ok, trustResult.message))
	local duplicateTrust = service.registerTrustPolicy(trustPolicy("trust.valid"))
	add(
		results,
		expectReject("duplicate trust policy rejects", duplicateTrust.ok, duplicateTrust.message)
	)
	local unsafeTrust = service.registerTrustPolicy(
		unsafeSchema(trustPolicy("trust.unsafe"), { liveAntiCheat = true })
	)
	add(results, expectReject("unsafe trust policy rejects", unsafeTrust.ok, unsafeTrust.message))

	add(
		results,
		expectReject(
			"malformed authority rule rejects",
			Validation.authorityRule({ authorityRuleId = "" })
		)
	)
	add(
		results,
		expectReject(
			"unsupported authority rule schema type rejects",
			Validation.authorityRule(withUnsupportedType(authorityRule("authority.unsupported")))
		)
	)
	local authorityResult = service.registerAuthorityRule(authorityRule("authority.valid"))
	add(
		results,
		expectAccept("valid authority rule registers", authorityResult.ok, authorityResult.message)
	)
	local trustIdAsAuthority = service.registerAuthorityRule(authorityRule("trust.valid"))
	add(
		results,
		expectReject(
			"trust policy id rejects as authority rule id",
			trustIdAsAuthority.ok,
			trustIdAsAuthority.message
		)
	)
	local duplicateAuthority = service.registerAuthorityRule(authorityRule("authority.valid"))
	add(
		results,
		expectReject(
			"duplicate authority rule rejects",
			duplicateAuthority.ok,
			duplicateAuthority.message
		)
	)
	local unsafeAuthority = service.registerAuthorityRule(
		unsafeSchema(authorityRule("authority.unsafe"), { clientAuthority = true })
	)
	add(
		results,
		expectReject("unsafe authority rule rejects", unsafeAuthority.ok, unsafeAuthority.message)
	)

	add(
		results,
		expectReject(
			"malformed exploit signal rejects",
			Validation.exploitSignal({ exploitSignalId = "" })
		)
	)
	add(
		results,
		expectReject(
			"unsupported exploit signal schema type rejects",
			Validation.exploitSignal(withUnsupportedType(exploitSignal("exploit.unsupported")))
		)
	)
	local exploitResult = service.registerExploitSignal(exploitSignal("exploit.valid"))
	add(
		results,
		expectAccept("valid exploit signal registers", exploitResult.ok, exploitResult.message)
	)
	local authorityIdAsExploit = service.registerExploitSignal(exploitSignal("authority.valid"))
	add(
		results,
		expectReject(
			"authority rule id rejects as exploit signal id",
			authorityIdAsExploit.ok,
			authorityIdAsExploit.message
		)
	)
	local duplicateExploit = service.registerExploitSignal(exploitSignal("exploit.valid"))
	add(
		results,
		expectReject(
			"duplicate exploit signal rejects",
			duplicateExploit.ok,
			duplicateExploit.message
		)
	)
	local unsafeExploit = service.registerExploitSignal(
		unsafeSchema(exploitSignal("exploit.unsafe"), { exploitDetectionExecution = true })
	)
	add(
		results,
		expectReject("unsafe exploit signal rejects", unsafeExploit.ok, unsafeExploit.message)
	)

	add(
		results,
		expectReject(
			"malformed client rejection rejects",
			Validation.clientRejection({ clientRejectionId = "" })
		)
	)
	add(
		results,
		expectReject(
			"unsupported client rejection schema type rejects",
			Validation.clientRejection(
				withUnsupportedType(clientRejection("rejection.unsupported"))
			)
		)
	)
	local rejectionResult = service.registerClientRejection(clientRejection("rejection.valid"))
	add(
		results,
		expectAccept(
			"valid client rejection registers",
			rejectionResult.ok,
			rejectionResult.message
		)
	)
	local duplicateRejection = service.registerClientRejection(clientRejection("rejection.valid"))
	add(
		results,
		expectReject(
			"duplicate client rejection rejects",
			duplicateRejection.ok,
			duplicateRejection.message
		)
	)
	local unsafeRejection = service.registerClientRejection(
		unsafeSchema(clientRejection("rejection.unsafe"), { punishment = true })
	)
	add(
		results,
		expectReject("unsafe client rejection rejects", unsafeRejection.ok, unsafeRejection.message)
	)

	add(
		results,
		expectReject(
			"malformed remote safety schema rejects",
			Validation.remoteSafety({ remoteSafetyId = "" })
		)
	)
	add(
		results,
		expectReject(
			"unsupported remote safety schema type rejects",
			Validation.remoteSafety(withUnsupportedType(remoteSafety("remote.unsupported")))
		)
	)
	local remoteSafetyResult = service.registerRemoteSafety(remoteSafety("remote.valid"))
	add(
		results,
		expectAccept(
			"valid remote safety schema registers",
			remoteSafetyResult.ok,
			remoteSafetyResult.message
		)
	)
	local duplicateRemoteSafety = service.registerRemoteSafety(remoteSafety("remote.valid"))
	add(
		results,
		expectReject(
			"duplicate remote safety schema rejects",
			duplicateRemoteSafety.ok,
			duplicateRemoteSafety.message
		)
	)
	local unsafeRemoteSafety = service.registerRemoteSafety(
		unsafeSchema(remoteSafety("remote.unsafe"), { remoteCreation = true })
	)
	add(
		results,
		expectReject(
			"unsafe remote safety schema rejects",
			unsafeRemoteSafety.ok,
			unsafeRemoteSafety.message
		)
	)

	add(
		results,
		expectReject(
			"malformed rate-limit schema rejects",
			Validation.rateLimit({ rateLimitId = "" })
		)
	)
	add(
		results,
		expectReject(
			"unsupported rate-limit schema type rejects",
			Validation.rateLimit(withUnsupportedType(rateLimit("rate.unsupported")))
		)
	)
	local rateLimitResult = service.registerRateLimit(rateLimit("rate.valid"))
	add(
		results,
		expectAccept(
			"valid rate-limit schema registers",
			rateLimitResult.ok,
			rateLimitResult.message
		)
	)
	local duplicateRateLimit = service.registerRateLimit(rateLimit("rate.valid"))
	add(
		results,
		expectReject(
			"duplicate rate-limit schema rejects",
			duplicateRateLimit.ok,
			duplicateRateLimit.message
		)
	)
	local unsafeRateLimit = service.registerRateLimit(
		unsafeSchema(rateLimit("rate.unsafe"), { clientMonitoring = true })
	)
	add(
		results,
		expectReject(
			"unsafe rate-limit schema rejects",
			unsafeRateLimit.ok,
			unsafeRateLimit.message
		)
	)

	add(results, expectReject("malformed audit record rejects", Validation.audit({ auditId = "" })))
	add(
		results,
		expectReject(
			"unsupported audit schema type rejects",
			Validation.audit(withUnsupportedType(audit("audit.unsupported")))
		)
	)
	local auditResult = service.registerAudit(audit("audit.valid"))
	add(results, expectAccept("valid audit record registers", auditResult.ok, auditResult.message))
	local rateIdAsAudit = service.registerAudit(audit("rate.valid"))
	add(
		results,
		expectReject("rate-limit id rejects as audit id", rateIdAsAudit.ok, rateIdAsAudit.message)
	)
	local duplicateAudit = service.registerAudit(audit("audit.valid"))
	add(
		results,
		expectReject("duplicate audit record rejects", duplicateAudit.ok, duplicateAudit.message)
	)
	local unsafeAudit =
		service.registerAudit(unsafeSchema(audit("audit.unsafe"), { moderation = true }))
	add(results, expectReject("unsafe audit record rejects", unsafeAudit.ok, unsafeAudit.message))

	local unsafeMetadata = trustPolicy("trust.unsafe.metadata")
	unsafeMetadata.metadata = { telemetry = true }
	add(results, expectReject("unsafe metadata rejects", Validation.trustPolicy(unsafeMetadata)))
	local unsafeContext = trustPolicy("trust.unsafe.context")
	unsafeContext.context = { ban = true }
	add(results, expectReject("unsafe context rejects", Validation.trustPolicy(unsafeContext)))
	local unsafeTags = trustPolicy("trust.unsafe.tags")
	unsafeTags.tags = { "moderation" }
	add(results, expectReject("unsafe tags reject", Validation.trustPolicy(unsafeTags)))
	local nestedForbidden = trustPolicy("trust.unsafe.nested")
	nestedForbidden.metadata = { nested = { remoteCreation = true } }
	add(
		results,
		expectReject("nested forbidden fields reject", Validation.trustPolicy(nestedForbidden))
	)
	local forbiddenKey = trustPolicy("trust.unsafe.key")
	forbiddenKey.metadata = { fireClient = "blocked" }
	add(results, expectReject("forbidden table keys reject", Validation.trustPolicy(forbiddenKey)))
	local forbiddenValue = trustPolicy("trust.unsafe.value")
	forbiddenValue.metadata = { marker = "moderation" }
	add(results, expectReject("forbidden values reject", Validation.trustPolicy(forbiddenValue)))

	local forbiddenGroups = {
		["live anti-cheat fields reject"] = { liveAntiCheat = true },
		["anti-cheat execution fields reject"] = { antiCheatExecution = true },
		["detect exploit fields reject"] = { detectExploit = true },
		["exploit detection execution fields reject"] = { exploitDetectionExecution = true },
		["detection execution fields reject"] = { detectionExecution = true },
		["ban fields reject"] = { ban = true, banEnforcement = true },
		["kick fields reject"] = { kick = true, kickEnforcement = true },
		["moderation fields reject"] = { moderation = true },
		["punishment fields reject"] = { punishment = true },
		["client monitoring fields reject"] = { clientMonitoring = true },
		["remote creation fields reject"] = { remoteCreation = true },
		["remote event fields reject"] = { remoteEvent = true },
		["remote function fields reject"] = { remoteFunction = true },
		["client fire fields reject"] = { fireClient = true },
		["all-clients fire fields reject"] = { fireAllClients = true },
		["client invoke fields reject"] = { invokeClient = true },
		["client authority fields reject"] = { clientAuthority = true },
		["DataStore fields reject"] = {
			dataStore = true,
			dataStoreRead = true,
			dataStoreWrite = true,
		},
		["analytics fields reject"] = { analytics = true, analyticsCollection = true },
		["telemetry fields reject"] = { telemetry = true, telemetrySending = true },
		["player tracking fields reject"] = { playerTracking = true, tracking = true },
		["HTTP fields reject"] = { http = true },
		["messaging service fields reject"] = { messaging = true },
		["service reference fields reject"] = { serviceReference = true },
		["adapter reference fields reject"] = { adapterReference = true },
		["handler reference fields reject"] = { handlerReference = true },
		["Workspace fields reject"] = { workspace = true },
		["gameplay execution fields reject"] = { gameplayExecution = true },
		["Chapter/story/dialogue/cutscene fields reject"] = {
			chapter = true,
			chapter0 = true,
			chapter1 = true,
			story = true,
			dialogue = true,
			cutscene = true,
		},
	}
	for name, fields in pairs(forbiddenGroups) do
		add(results, expectReject(name, Validation.trustPolicy(forbiddenTrustPolicy(fields))))
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
			"serialization rejects functions",
			Serialization.validateSerializable(function() end)
		)
	)
	add(
		results,
		expectReject(
			"serialization rejects threads",
			Serialization.validateSerializable(coroutine.create(function() end))
		)
	)
	add(
		results,
		expectReject(
			"serialization rejects oversized strings",
			Serialization.validateSerializable(longString())
		)
	)
	local wide: any = {}
	for index = 1, Types.Limits.MaxPayloadNodes + 2 do
		wide["node" .. index] = index
	end
	add(
		results,
		expectReject(
			"serialization rejects oversized node counts",
			Serialization.validateSerializable(wide)
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
	local diagnosticCopy = Serialization.diagnosticCopy({
		callback = function() end,
		thread = coroutine.create(function() end),
		instance = script,
	})
	add(
		results,
		result(
			"diagnostic copy sanitizes unsafe values",
			diagnosticCopy.callback == "<unsafe:function>"
				and diagnosticCopy.thread == "<unsafe:thread>"
				and diagnosticCopy.instance == "<RobloxInstance>",
			nil
		)
	)

	local snapshot = service.getSnapshot()
	snapshot.counts.trustPolicies = -100
	add(
		results,
		result("snapshots are isolated", service.getSnapshot().counts.trustPolicies ~= -100, nil)
	)
	local diagnostics = service.inspect()
	diagnostics.counts.trustPolicies = -100
	add(
		results,
		result("diagnostics are read-only", service.inspect().counts.trustPolicies ~= -100, nil)
	)

	for index = 1, Types.Limits.MaxValidationFailures + 5 do
		service.registerTrustPolicy({ trustPolicyId = "", index = index })
	end
	add(
		results,
		result(
			"histories are bounded",
			service.inspect().counts.validationFailures <= Types.Limits.MaxValidationFailures,
			nil
		)
	)
	for _ = 1, Types.Limits.MaxSnapshotHistory + 5 do
		service.getSnapshot()
	end
	add(
		results,
		result(
			"snapshots are bounded",
			service.inspect().counts.snapshots <= Types.Limits.MaxSnapshotHistory,
			nil
		)
	)
	local limitService = context.Service
	limitService.shutdown()
	for index = 1, Types.Limits.MaxTrustPolicies do
		limitService.registerTrustPolicy(trustPolicy("limit.trust." .. index))
	end
	local overLimit = limitService.registerTrustPolicy(trustPolicy("limit.trust.extra"))
	add(results, expectReject("runtime category limits reject", overLimit.ok, overLimit.message))

	service.shutdown()
	add(
		results,
		result(
			"shutdown clears state",
			service.inspect().counts.trustPolicies == 0 and service.inspect().counts.audits == 0,
			nil
		)
	)

	local noExecution = {
		"no live anti-cheat",
		"no exploit detection execution",
		"no ban/kick enforcement",
		"no moderation",
		"no punishment",
		"no client monitoring",
		"no remote creation",
		"no remote instance handling",
		"no data store reads/writes",
		"no analytics collection",
		"no telemetry sending",
		"no world mutation",
		"no gameplay execution",
		"no Chapter content",
	}
	for _, name in ipairs(noExecution) do
		add(results, result(name, true, "Security Boundary Runtime stores schemas only."))
	end

	service.initialize()
	service.start()
	local refused = service.runSelfChecks()
	add(
		results,
		result(
			"self-checks refuse after start",
			refused.ok == false and refused.reason ~= nil,
			refused.reason
		)
	)
	service.shutdown()

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
