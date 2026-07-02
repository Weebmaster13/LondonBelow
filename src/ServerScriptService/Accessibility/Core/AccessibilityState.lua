--!strict
-- Central bounded state store for the Accessibility Runtime Foundation.

local Serialization = require(script.Parent.AccessibilitySerialization)
local Types = require(script.Parent.AccessibilityTypes)
local Validation = require(script.Parent.AccessibilityValidation)

local State = {}

local settings: { [string]: any } = {}
local visuals: { [string]: any } = {}
local audios: { [string]: any } = {}
local inputs: { [string]: any } = {}
local motions: { [string]: any } = {}
local readabilities: { [string]: any } = {}
local contentWarnings: { [string]: any } = {}
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

function State.registerSetting(schema: any): (boolean, string?)
	local ok, reason = Validation.setting(schema)
	if not ok then
		return false, reason
	end
	if schemaIds[schema.settingId] == true then
		return false, "duplicate settingId"
	end
	if countMap(settings) >= Types.Limits.MaxSettings then
		return false, "setting limit exceeded"
	end
	schemaIds[schema.settingId] = true
	settings[schema.settingId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerVisual(schema: any): (boolean, string?)
	local ok, reason = Validation.visual(schema)
	if not ok then
		return false, reason
	end
	if schemaIds[schema.visualId] == true then
		return false, "duplicate visualId"
	end
	if countMap(visuals) >= Types.Limits.MaxVisuals then
		return false, "visual rule limit exceeded"
	end
	schemaIds[schema.visualId] = true
	visuals[schema.visualId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerAudio(schema: any): (boolean, string?)
	local ok, reason = Validation.audio(schema)
	if not ok then
		return false, reason
	end
	if schemaIds[schema.audioId] == true then
		return false, "duplicate audioId"
	end
	if countMap(audios) >= Types.Limits.MaxAudios then
		return false, "audio safety rule limit exceeded"
	end
	schemaIds[schema.audioId] = true
	audios[schema.audioId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerInput(schema: any): (boolean, string?)
	local ok, reason = Validation.input(schema)
	if not ok then
		return false, reason
	end
	if schemaIds[schema.inputId] == true then
		return false, "duplicate inputId"
	end
	if countMap(inputs) >= Types.Limits.MaxInputs then
		return false, "input assist limit exceeded"
	end
	schemaIds[schema.inputId] = true
	inputs[schema.inputId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerMotion(schema: any): (boolean, string?)
	local ok, reason = Validation.motion(schema)
	if not ok then
		return false, reason
	end
	if schemaIds[schema.motionId] == true then
		return false, "duplicate motionId"
	end
	if countMap(motions) >= Types.Limits.MaxMotions then
		return false, "motion comfort limit exceeded"
	end
	schemaIds[schema.motionId] = true
	motions[schema.motionId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerReadability(record: any): (boolean, string?)
	local ok, reason = Validation.readability(record)
	if not ok then
		return false, reason
	end
	if schemaIds[record.readabilityId] == true then
		return false, "duplicate readabilityId"
	end
	if countMap(readabilities) >= Types.Limits.MaxReadabilities then
		return false, "readability limit exceeded"
	end
	schemaIds[record.readabilityId] = true
	readabilities[record.readabilityId] = Serialization.deepCopy(record)
	return true, nil
end

function State.registerContentWarning(record: any): (boolean, string?)
	local ok, reason = Validation.contentWarning(record)
	if not ok then
		return false, reason
	end
	if schemaIds[record.contentWarningId] == true then
		return false, "duplicate contentWarningId"
	end
	if countMap(contentWarnings) >= Types.Limits.MaxContentWarnings then
		return false, "content warning limit exceeded"
	end
	schemaIds[record.contentWarningId] = true
	contentWarnings[record.contentWarningId] = Serialization.deepCopy(record)
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
		settings = settings,
		visuals = visuals,
		audios = audios,
		inputs = inputs,
		motions = motions,
		readabilities = readabilities,
		contentWarnings = contentWarnings,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			settings = countMap(settings),
			visuals = countMap(visuals),
			audios = countMap(audios),
			inputs = countMap(inputs),
			motions = countMap(motions),
			readabilities = countMap(readabilities),
			contentWarnings = countMap(contentWarnings),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(settings)
	table.clear(visuals)
	table.clear(audios)
	table.clear(inputs)
	table.clear(motions)
	table.clear(readabilities)
	table.clear(contentWarnings)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return State
