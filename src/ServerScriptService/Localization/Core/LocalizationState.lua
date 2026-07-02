--!strict
-- Central bounded state store for the Localization Runtime Foundation.

local Serialization = require(script.Parent.LocalizationSerialization)
local Types = require(script.Parent.LocalizationTypes)
local Validation = require(script.Parent.LocalizationValidation)

local State = {}

local languages: { [string]: any } = {}
local textKeys: { [string]: any } = {}
local packages: { [string]: any } = {}
local fallbacks: { [string]: any } = {}
local subtitles: { [string]: any } = {}
local captions: { [string]: any } = {}
local textSafetyRules: { [string]: any } = {}
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

function State.registerLanguage(schema: any): (boolean, string?)
	local ok, reason = Validation.language(schema)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason = rejectDuplicate(schema.languageId, "duplicate languageId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(languages) >= Types.Limits.MaxLanguages then
		return false, "language limit exceeded"
	end
	schemaIds[schema.languageId] = true
	languages[schema.languageId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerTextKey(schema: any): (boolean, string?)
	local ok, reason = Validation.textKey(schema)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason = rejectDuplicate(schema.textKeyId, "duplicate textKeyId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(textKeys) >= Types.Limits.MaxTextKeys then
		return false, "text key limit exceeded"
	end
	schemaIds[schema.textKeyId] = true
	textKeys[schema.textKeyId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerPackage(schema: any): (boolean, string?)
	local ok, reason = Validation.package(schema)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason = rejectDuplicate(schema.packageId, "duplicate packageId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(packages) >= Types.Limits.MaxPackages then
		return false, "package limit exceeded"
	end
	schemaIds[schema.packageId] = true
	packages[schema.packageId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerFallback(schema: any): (boolean, string?)
	local ok, reason = Validation.fallback(schema)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason = rejectDuplicate(schema.fallbackId, "duplicate fallbackId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(fallbacks) >= Types.Limits.MaxFallbacks then
		return false, "fallback limit exceeded"
	end
	schemaIds[schema.fallbackId] = true
	fallbacks[schema.fallbackId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerSubtitle(schema: any): (boolean, string?)
	local ok, reason = Validation.subtitle(schema)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason = rejectDuplicate(schema.subtitleId, "duplicate subtitleId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(subtitles) >= Types.Limits.MaxSubtitles then
		return false, "subtitle limit exceeded"
	end
	schemaIds[schema.subtitleId] = true
	subtitles[schema.subtitleId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerCaption(schema: any): (boolean, string?)
	local ok, reason = Validation.caption(schema)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason = rejectDuplicate(schema.captionId, "duplicate captionId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(captions) >= Types.Limits.MaxCaptions then
		return false, "caption limit exceeded"
	end
	schemaIds[schema.captionId] = true
	captions[schema.captionId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerTextSafety(schema: any): (boolean, string?)
	local ok, reason = Validation.textSafety(schema)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason = rejectDuplicate(schema.textSafetyId, "duplicate textSafetyId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(textSafetyRules) >= Types.Limits.MaxTextSafetyRules then
		return false, "text safety rule limit exceeded"
	end
	schemaIds[schema.textSafetyId] = true
	textSafetyRules[schema.textSafetyId] = Serialization.deepCopy(schema)
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
		languages = languages,
		textKeys = textKeys,
		packages = packages,
		fallbacks = fallbacks,
		subtitles = subtitles,
		captions = captions,
		textSafetyRules = textSafetyRules,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			languages = countMap(languages),
			textKeys = countMap(textKeys),
			packages = countMap(packages),
			fallbacks = countMap(fallbacks),
			subtitles = countMap(subtitles),
			captions = countMap(captions),
			textSafetyRules = countMap(textSafetyRules),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(languages)
	table.clear(textKeys)
	table.clear(packages)
	table.clear(fallbacks)
	table.clear(subtitles)
	table.clear(captions)
	table.clear(textSafetyRules)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return State
