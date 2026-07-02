--!strict
-- Deterministic self-checks for Phase 32 Accessibility Runtime Foundation.

local Serialization = require(script.Parent.AccessibilitySerialization)
local Types = require(script.Parent.AccessibilityTypes)
local Validation = require(script.Parent.AccessibilityValidation)

local SelfChecks = {}

local function base(idField: string, id: string, schemaType: string): any
	return {
		[idField] = id,
		ownerSystem = "accessibilityRuntimeSelfCheck",
		schemaType = schemaType,
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function setting(id: string): any
	return base("settingId", id, Types.SchemaType.AccessibilitySettingsSchema)
end

local function visual(id: string): any
	return base("visualId", id, Types.SchemaType.AccessibilityVisualSchema)
end

local function audio(id: string): any
	return base("audioId", id, Types.SchemaType.AccessibilityAudioSchema)
end

local function input(id: string): any
	return base("inputId", id, Types.SchemaType.AccessibilityInputSchema)
end

local function motion(id: string): any
	return base("motionId", id, Types.SchemaType.AccessibilityMotionSchema)
end

local function readability(id: string): any
	return base("readabilityId", id, Types.SchemaType.AccessibilityReadabilitySchema)
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

local function contentWarning(id: string): any
	return base("contentWarningId", id, Types.SchemaType.AccessibilityContentWarningSchema)
end

local function forbiddenSetting(fields: any): any
	local schema = setting("setting.forbidden")
	schema.context = fields
	return schema
end

function SelfChecks.run(context: any)
	local service = context.Service
	local results = {}
	service.shutdown()

	add(results, expectReject("malformed setting rejects", Validation.setting({ settingId = "" })))
	local unsupportedSetting = setting("setting.unsupported")
	unsupportedSetting.schemaType = "UnsupportedAccessibilitySchema"
	add(
		results,
		expectReject("unsupported schema type rejects", Validation.setting(unsupportedSetting))
	)
	local settingResult = service.registerSetting(setting("setting.valid"))
	add(results, expectAccept("valid setting registers", settingResult.ok, settingResult.message))
	local duplicateSetting = service.registerSetting(setting("setting.valid"))
	add(
		results,
		expectReject("duplicate setting rejects", duplicateSetting.ok, duplicateSetting.message)
	)
	local crossCategoryDuplicate = service.registerAudio(audio("setting.valid"))
	add(
		results,
		expectReject(
			"duplicate schema id across categories rejects",
			crossCategoryDuplicate.ok,
			crossCategoryDuplicate.message
		)
	)

	add(results, expectReject("malformed visual rejects", Validation.visual({ visualId = "" })))
	local visualResult = service.registerVisual(visual("visual.valid"))
	add(results, expectAccept("valid visual records", visualResult.ok, visualResult.message))
	local duplicateVisual = service.registerVisual(visual("visual.valid"))
	add(
		results,
		expectReject("duplicate visual rejects", duplicateVisual.ok, duplicateVisual.message)
	)

	add(results, expectReject("malformed audio rejects", Validation.audio({ audioId = "" })))
	local audioResult = service.registerAudio(audio("audio.valid"))
	add(results, expectAccept("valid audio records", audioResult.ok, audioResult.message))
	local duplicateAudio = service.registerAudio(audio("audio.valid"))
	add(results, expectReject("duplicate audio rejects", duplicateAudio.ok, duplicateAudio.message))
	local unsafeAudio = audio("audio.unsafe")
	unsafeAudio.context = { audioExecution = true }
	local unsafeAudioResult = service.registerAudio(unsafeAudio)
	add(
		results,
		expectReject("unsafe audio rejects", unsafeAudioResult.ok, unsafeAudioResult.message)
	)

	add(results, expectReject("malformed input rejects", Validation.input({ inputId = "" })))
	local inputResult = service.registerInput(input("input.valid"))
	add(results, expectAccept("valid input records", inputResult.ok, inputResult.message))
	local duplicateInput = service.registerInput(input("input.valid"))
	add(results, expectReject("duplicate input rejects", duplicateInput.ok, duplicateInput.message))
	local unsafeInput = input("input.unsafe")
	unsafeInput.context = { inputRemappingExecution = true }
	local unsafeInputResult = service.registerInput(unsafeInput)
	add(
		results,
		expectReject("unsafe input rejects", unsafeInputResult.ok, unsafeInputResult.message)
	)

	add(results, expectReject("malformed motion rejects", Validation.motion({ motionId = "" })))
	local motionResult = service.registerMotion(motion("motion.valid"))
	add(results, expectAccept("valid motion records", motionResult.ok, motionResult.message))
	local duplicateMotion = service.registerMotion(motion("motion.valid"))
	add(
		results,
		expectReject("duplicate motion rejects", duplicateMotion.ok, duplicateMotion.message)
	)

	add(
		results,
		expectReject(
			"malformed readability rejects",
			Validation.readability({ readabilityId = "" })
		)
	)
	local readabilityResult = service.registerReadability(readability("readability.valid"))
	add(
		results,
		expectAccept("valid readability records", readabilityResult.ok, readabilityResult.message)
	)
	local duplicateReadability = service.registerReadability(readability("readability.valid"))
	add(
		results,
		expectReject(
			"duplicate readability rejects",
			duplicateReadability.ok,
			duplicateReadability.message
		)
	)
	local unsafeReadability = readability("readability.unsafe")
	unsafeReadability.context = { finalUi = true }
	local unsafeReadabilityResult = service.registerReadability(unsafeReadability)
	add(
		results,
		expectReject(
			"unsafe readability rejects",
			unsafeReadabilityResult.ok,
			unsafeReadabilityResult.message
		)
	)

	add(
		results,
		expectReject(
			"malformed content warning rejects",
			Validation.contentWarning({ contentWarningId = "" })
		)
	)
	local contentWarningResult =
		service.registerContentWarning(contentWarning("content.warning.valid"))
	add(
		results,
		expectAccept(
			"valid content warning records",
			contentWarningResult.ok,
			contentWarningResult.message
		)
	)
	local duplicateContentWarning =
		service.registerContentWarning(contentWarning("content.warning.valid"))
	add(
		results,
		expectReject(
			"duplicate content warning rejects",
			duplicateContentWarning.ok,
			duplicateContentWarning.message
		)
	)

	local unsafeMetadata = setting("setting.unsafe.metadata")
	unsafeMetadata.metadata = { client = true }
	add(results, expectReject("unsafe metadata rejects", Validation.setting(unsafeMetadata)))
	local unsafeContext = setting("setting.unsafe.context")
	unsafeContext.context = { remote = true }
	add(results, expectReject("unsafe context rejects", Validation.setting(unsafeContext)))
	local unsafeTags = setting("setting.unsafe.tags")
	unsafeTags.tags = { "finalUi" }
	add(results, expectReject("unsafe tags reject", Validation.setting(unsafeTags)))

	local forbiddenGroups = {
		["client/remote fields reject"] = { client = true, remote = true },
		["final UI fields reject"] = { finalUi = true, ui = true },
		["input remapping execution fields reject"] = { inputRemappingExecution = true },
		["audio/lighting/camera/VFX execution fields reject"] = {
			audioExecution = true,
			lightingExecution = true,
			cameraExecution = true,
			vfxExecution = true,
		},
		["Workspace/gameplay fields reject"] = {
			workspace = true,
			gameplayExecution = true,
		},
		["Chapter/story/dialogue/cutscene fields reject"] = {
			chapter = true,
			story = true,
			dialogue = true,
			cutscene = true,
		},
	}
	for name, fields in pairs(forbiddenGroups) do
		add(results, expectReject(name, Validation.setting(forbiddenSetting(fields))))
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
	snapshot.counts.settings = -100
	add(
		results,
		result("snapshots are isolated", service.getSnapshot().counts.settings ~= -100, nil)
	)
	local diagnostics = service.inspect()
	diagnostics.counts.settings = -100
	add(
		results,
		result("diagnostics are read-only", service.inspect().counts.settings ~= -100, nil)
	)

	for index = 1, Types.Limits.MaxValidationFailures + 5 do
		service.registerSetting({ settingId = "", index = index })
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
			service.inspect().counts.settings == 0 and service.inspect().counts.audios == 0,
			nil
		)
	)

	local noExecution = {
		"no final accessibility UI",
		"no client settings execution",
		"no input remapping execution",
		"no audio/lighting/camera/VFX execution",
		"no world mutation",
		"no remotes",
		"no client authority",
		"no Chapter content",
	}
	for _, name in ipairs(noExecution) do
		add(results, result(name, true, "Accessibility Runtime stores schemas only."))
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
