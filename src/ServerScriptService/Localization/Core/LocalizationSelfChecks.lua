--!strict
-- Deterministic self-checks for Phase 35 Localization Runtime Foundation.

local Serialization = require(script.Parent.LocalizationSerialization)
local Types = require(script.Parent.LocalizationTypes)
local Validation = require(script.Parent.LocalizationValidation)

local SelfChecks = {}

local function base(idField: string, id: string, schemaType: string): any
	return {
		[idField] = id,
		ownerSystem = "localizationRuntimeSelfCheck",
		schemaType = schemaType,
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function language(id: string): any
	return base("languageId", id, Types.SchemaType.LocalizationLanguageSchema)
end

local function textKey(id: string): any
	return base("textKeyId", id, Types.SchemaType.LocalizationTextKeySchema)
end

local function package(id: string): any
	return base("packageId", id, Types.SchemaType.LocalizationPackageSchema)
end

local function fallback(id: string): any
	return base("fallbackId", id, Types.SchemaType.LocalizationFallbackSchema)
end

local function subtitle(id: string): any
	return base("subtitleId", id, Types.SchemaType.LocalizationSubtitleSchema)
end

local function caption(id: string): any
	return base("captionId", id, Types.SchemaType.LocalizationCaptionSchema)
end

local function textSafety(id: string): any
	return base("textSafetyId", id, Types.SchemaType.LocalizationTextSafetySchema)
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

local function unsupported(schema: any): any
	schema.schemaType = "UnsupportedLocalizationSchema"
	return schema
end

local function forbiddenLanguage(fields: any): any
	return unsafeSchema(language("language.forbidden"), fields)
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
		expectReject("malformed language rejects", Validation.language({ languageId = "" }))
	)
	add(
		results,
		expectReject(
			"unsupported language schema type rejects",
			Validation.language(unsupported(language("language.unsupported")))
		)
	)
	local languageResult = service.registerLanguage(language("language.valid"))
	add(
		results,
		expectAccept("valid language registers", languageResult.ok, languageResult.message)
	)
	local duplicateLanguage = service.registerLanguage(language("language.valid"))
	add(
		results,
		expectReject("duplicate language rejects", duplicateLanguage.ok, duplicateLanguage.message)
	)
	local unsafeLanguage = service.registerLanguage(
		unsafeSchema(language("language.unsafe"), { finalDialogue = true })
	)
	add(
		results,
		expectReject("unsafe language payload rejects", unsafeLanguage.ok, unsafeLanguage.message)
	)

	add(results, expectReject("malformed text key rejects", Validation.textKey({ textKeyId = "" })))
	add(
		results,
		expectReject(
			"unsupported text key schema type rejects",
			Validation.textKey(unsupported(textKey("text.unsupported")))
		)
	)
	local textKeyResult = service.registerTextKey(textKey("text.valid"))
	add(results, expectAccept("valid text key registers", textKeyResult.ok, textKeyResult.message))
	local languageIdAsTextKey = service.registerTextKey(textKey("language.valid"))
	add(
		results,
		expectReject(
			"language id rejects as text key id",
			languageIdAsTextKey.ok,
			languageIdAsTextKey.message
		)
	)
	local duplicateTextKey = service.registerTextKey(textKey("text.valid"))
	add(
		results,
		expectReject("duplicate text key rejects", duplicateTextKey.ok, duplicateTextKey.message)
	)
	local unsafeTextKey =
		service.registerTextKey(unsafeSchema(textKey("text.unsafe"), { story = true }))
	add(
		results,
		expectReject("unsafe text key payload rejects", unsafeTextKey.ok, unsafeTextKey.message)
	)

	add(results, expectReject("malformed package rejects", Validation.package({ packageId = "" })))
	add(
		results,
		expectReject(
			"unsupported package schema type rejects",
			Validation.package(unsupported(package("package.unsupported")))
		)
	)
	local packageResult = service.registerPackage(package("package.valid"))
	add(results, expectAccept("valid package registers", packageResult.ok, packageResult.message))
	local textKeyIdAsPackage = service.registerPackage(package("text.valid"))
	add(
		results,
		expectReject(
			"text key id rejects as package id",
			textKeyIdAsPackage.ok,
			textKeyIdAsPackage.message
		)
	)
	local duplicatePackage = service.registerPackage(package("package.valid"))
	add(
		results,
		expectReject("duplicate package rejects", duplicatePackage.ok, duplicatePackage.message)
	)
	local unsafePackage = service.registerPackage(
		unsafeSchema(package("package.unsafe"), { automaticTranslation = true })
	)
	add(
		results,
		expectReject("unsafe package payload rejects", unsafePackage.ok, unsafePackage.message)
	)

	add(
		results,
		expectReject("malformed fallback rejects", Validation.fallback({ fallbackId = "" }))
	)
	add(
		results,
		expectReject(
			"unsupported fallback schema type rejects",
			Validation.fallback(unsupported(fallback("fallback.unsupported")))
		)
	)
	local fallbackResult = service.registerFallback(fallback("fallback.valid"))
	add(
		results,
		expectAccept("valid fallback registers", fallbackResult.ok, fallbackResult.message)
	)
	local packageIdAsFallback = service.registerFallback(fallback("package.valid"))
	add(
		results,
		expectReject(
			"package id rejects as fallback id",
			packageIdAsFallback.ok,
			packageIdAsFallback.message
		)
	)
	local duplicateFallback = service.registerFallback(fallback("fallback.valid"))
	add(
		results,
		expectReject("duplicate fallback rejects", duplicateFallback.ok, duplicateFallback.message)
	)
	local unsafeFallback = service.registerFallback(
		unsafeSchema(fallback("fallback.unsafe"), { translationExecution = true })
	)
	add(
		results,
		expectReject("unsafe fallback payload rejects", unsafeFallback.ok, unsafeFallback.message)
	)

	add(
		results,
		expectReject("malformed subtitle rejects", Validation.subtitle({ subtitleId = "" }))
	)
	add(
		results,
		expectReject(
			"unsupported subtitle schema type rejects",
			Validation.subtitle(unsupported(subtitle("subtitle.unsupported")))
		)
	)
	local subtitleResult = service.registerSubtitle(subtitle("subtitle.valid"))
	add(
		results,
		expectAccept("valid subtitle registers", subtitleResult.ok, subtitleResult.message)
	)
	local fallbackIdAsSubtitle = service.registerSubtitle(subtitle("fallback.valid"))
	add(
		results,
		expectReject(
			"fallback id rejects as subtitle id",
			fallbackIdAsSubtitle.ok,
			fallbackIdAsSubtitle.message
		)
	)
	local duplicateSubtitle = service.registerSubtitle(subtitle("subtitle.valid"))
	add(
		results,
		expectReject("duplicate subtitle rejects", duplicateSubtitle.ok, duplicateSubtitle.message)
	)
	local unsafeSubtitle = service.registerSubtitle(
		unsafeSchema(subtitle("subtitle.unsafe"), { subtitleRendering = true })
	)
	add(
		results,
		expectReject("unsafe subtitle payload rejects", unsafeSubtitle.ok, unsafeSubtitle.message)
	)

	add(results, expectReject("malformed caption rejects", Validation.caption({ captionId = "" })))
	add(
		results,
		expectReject(
			"unsupported caption schema type rejects",
			Validation.caption(unsupported(caption("caption.unsupported")))
		)
	)
	local captionResult = service.registerCaption(caption("caption.valid"))
	add(results, expectAccept("valid caption registers", captionResult.ok, captionResult.message))
	local subtitleIdAsCaption = service.registerCaption(caption("subtitle.valid"))
	add(
		results,
		expectReject(
			"subtitle id rejects as caption id",
			subtitleIdAsCaption.ok,
			subtitleIdAsCaption.message
		)
	)
	local duplicateCaption = service.registerCaption(caption("caption.valid"))
	add(
		results,
		expectReject("duplicate caption rejects", duplicateCaption.ok, duplicateCaption.message)
	)
	local unsafeCaption = service.registerCaption(
		unsafeSchema(caption("caption.unsafe"), { captionRendering = true })
	)
	add(
		results,
		expectReject("unsafe caption payload rejects", unsafeCaption.ok, unsafeCaption.message)
	)

	add(
		results,
		expectReject(
			"malformed text safety rule rejects",
			Validation.textSafety({ textSafetyId = "" })
		)
	)
	add(
		results,
		expectReject(
			"unsupported text safety schema type rejects",
			Validation.textSafety(unsupported(textSafety("safety.unsupported")))
		)
	)
	local textSafetyResult = service.registerTextSafety(textSafety("safety.valid"))
	add(
		results,
		expectAccept(
			"valid text safety rule registers",
			textSafetyResult.ok,
			textSafetyResult.message
		)
	)
	local captionIdAsSafety = service.registerTextSafety(textSafety("caption.valid"))
	add(
		results,
		expectReject(
			"caption id rejects as text safety id",
			captionIdAsSafety.ok,
			captionIdAsSafety.message
		)
	)
	local duplicateTextSafety = service.registerTextSafety(textSafety("safety.valid"))
	add(
		results,
		expectReject(
			"duplicate text safety rule rejects",
			duplicateTextSafety.ok,
			duplicateTextSafety.message
		)
	)
	local unsafeTextSafety = service.registerTextSafety(
		unsafeSchema(textSafety("safety.unsafe"), { analyticsOwnership = true })
	)
	add(
		results,
		expectReject(
			"unsafe text safety payload rejects",
			unsafeTextSafety.ok,
			unsafeTextSafety.message
		)
	)

	local unsafeMetadata = language("language.unsafe.metadata")
	unsafeMetadata.metadata = { externalTranslation = true }
	add(results, expectReject("unsafe metadata rejects", Validation.language(unsafeMetadata)))
	local unsafeContext = language("language.unsafe.context")
	unsafeContext.context = { uiRendering = true }
	add(results, expectReject("unsafe context rejects", Validation.language(unsafeContext)))
	local unsafeTags = language("language.unsafe.tags")
	unsafeTags.tags = { "chapter" }
	add(results, expectReject("unsafe tags reject", Validation.language(unsafeTags)))

	local forbiddenGroups = {
		["final dialogue fields reject"] = { finalDialogue = true },
		["dialogue fields reject"] = { dialogue = true },
		["story fields reject"] = { story = true, finalStory = true },
		["chapter fields reject"] = { chapter = true, chapter0 = true, chapter1 = true },
		["cutscene fields reject"] = { cutscene = true },
		["automatic translation fields reject"] = { automaticTranslation = true },
		["translation execution fields reject"] = { translationExecution = true },
		["external translation fields reject"] = { externalTranslation = true },
		["translation service fields reject"] = { translationService = true },
		["http fields reject"] = { http = true },
		["messaging fields reject"] = { messaging = true },
		["data store fields reject"] = { dataStore = true },
		["subtitle rendering fields reject"] = { subtitleRendering = true },
		["caption rendering fields reject"] = { captionRendering = true },
		["voiceover playback fields reject"] = { voiceoverPlayback = true },
		["audio execution fields reject"] = { audioExecution = true },
		["ui rendering fields reject"] = { uiRendering = true },
		["client presentation fields reject"] = { clientPresentation = true },
		["remote fields reject"] = { remote = true, remoteEvent = true, remoteFunction = true },
		["client authority fields reject"] = { clientAuthority = true },
		["workspace fields reject"] = { workspace = true },
		["ownership fields reject"] = {
			narrativeOwnership = true,
			saveOwnership = true,
			analyticsOwnership = true,
		},
		["reference fields reject"] = {
			serviceReference = true,
			adapterReference = true,
			handlerReference = true,
		},
		["execute fields reject"] = { execute = true },
	}
	for name, fields in pairs(forbiddenGroups) do
		add(results, expectReject(name, Validation.language(forbiddenLanguage(fields))))
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
	snapshot.counts.languages = -100
	add(
		results,
		result("snapshots are isolated", service.getSnapshot().counts.languages ~= -100, nil)
	)
	local diagnostics = service.inspect()
	diagnostics.counts.languages = -100
	add(
		results,
		result("diagnostics are read-only", service.inspect().counts.languages ~= -100, nil)
	)

	for index = 1, Types.Limits.MaxValidationFailures + 5 do
		service.registerLanguage({ languageId = "", index = index })
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

	service.shutdown()
	for index = 1, Types.Limits.MaxLanguages do
		service.registerLanguage(language("limit.language." .. index))
	end
	local overLimit = service.registerLanguage(language("limit.language.extra"))
	add(results, expectReject("runtime category limits reject", overLimit.ok, overLimit.message))

	service.shutdown()
	add(
		results,
		result(
			"shutdown clears state",
			service.inspect().counts.languages == 0
				and service.inspect().counts.textSafetyRules == 0,
			nil
		)
	)
	local afterShutdownLanguage = service.registerLanguage(language("shutdown.reuse"))
	local previousIdAfterShutdown = service.registerTextKey(textKey("language.valid"))
	local afterShutdownTextKey = service.registerTextKey(textKey("shutdown.reuse"))
	local duplicateAfterReuse = service.registerCaption(caption("shutdown.reuse"))
	add(
		results,
		result(
			"shutdown clears global schema namespace",
			afterShutdownLanguage.ok
				and previousIdAfterShutdown.ok
				and afterShutdownTextKey.ok
				and not duplicateAfterReuse.ok,
			duplicateAfterReuse.message
		)
	)
	service.shutdown()

	local noExecution = {
		"no final translated text",
		"no final dialogue",
		"no story writing",
		"no Chapter content",
		"no automatic translation",
		"no external translation service calls",
		"no http service",
		"no messaging service",
		"no data store reads/writes",
		"no subtitle rendering",
		"no caption rendering",
		"no voiceover playback",
		"no audio execution",
		"no UI rendering",
		"no client presentation",
		"no remotes",
		"no client authority",
		"no world mutation",
	}
	for _, name in ipairs(noExecution) do
		add(results, result(name, true, "Localization Runtime stores schemas only."))
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
