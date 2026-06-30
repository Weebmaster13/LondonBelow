--!strict
--[[
	Context builder for enriched observations.

	Owns the mutable chapter/environment context snapshot that gets injected into
	each accepted observation.

	Does not own chapter systems, weather systems, Monster AI, objectives, or
	Horror Director interpretation. Those systems may update context through this
	module later, but the Observation Engine only snapshots what it knows.
]]

local Types = require(script.Parent.ObservationTypes)

local ObservationContext = {}

type Context = Types.ObservationContext

local contextState: Context = {
	chapterId = nil,
	chapterPhase = nil,
	roomId = nil,
	areaId = nil,
	buildingZone = nil,
	weather = nil,
	lighting = nil,
	objectiveId = nil,
	puzzleId = nil,
	nearbyPlayerCount = 0,
	nearbyMonsterCount = 0,
	timeSinceLastScare = nil,
	tensionState = nil,
	areaTags = {},
	roomTags = {},
}

local function copyArray(values: { string }): { string }
	return table.clone(values)
end

local function copyContext(): Context
	return {
		chapterId = contextState.chapterId,
		chapterPhase = contextState.chapterPhase,
		roomId = contextState.roomId,
		areaId = contextState.areaId,
		buildingZone = contextState.buildingZone,
		weather = contextState.weather,
		lighting = contextState.lighting,
		objectiveId = contextState.objectiveId,
		puzzleId = contextState.puzzleId,
		nearbyPlayerCount = contextState.nearbyPlayerCount,
		nearbyMonsterCount = contextState.nearbyMonsterCount,
		timeSinceLastScare = contextState.timeSinceLastScare,
		tensionState = contextState.tensionState,
		areaTags = copyArray(contextState.areaTags),
		roomTags = copyArray(contextState.roomTags),
	}
end

local function readString(metadata: { [string]: any }, key: string): string?
	local value = metadata[key]

	if type(value) == "string" and value ~= "" then
		return value
	end

	return nil
end

local function readNumber(metadata: { [string]: any }, key: string): number?
	local value = metadata[key]

	if type(value) == "number" and value == value then
		return value
	end

	return nil
end

local function readTags(metadata: { [string]: any }, key: string): { string }?
	local value = metadata[key]

	if type(value) ~= "table" then
		return nil
	end

	local tags = {}

	for _, tag in ipairs(value) do
		if type(tag) == "string" and tag ~= "" then
			table.insert(tags, tag)
		end
	end

	return tags
end

function ObservationContext.update(partial: { [string]: any })
	if type(partial.chapterId) == "string" then
		contextState.chapterId = partial.chapterId
	end

	if type(partial.chapterPhase) == "string" then
		contextState.chapterPhase = partial.chapterPhase
	end

	if type(partial.weather) == "string" then
		contextState.weather = partial.weather
	end

	if type(partial.lighting) == "string" then
		contextState.lighting = partial.lighting
	end

	if type(partial.objectiveId) == "string" then
		contextState.objectiveId = partial.objectiveId
	end

	if type(partial.puzzleId) == "string" then
		contextState.puzzleId = partial.puzzleId
	end
end

function ObservationContext.build(metadata: { [string]: any }): Context
	local context = copyContext()

	context.roomId = readString(metadata, "roomId") or context.roomId
	context.areaId = readString(metadata, "areaId") or context.areaId
	context.buildingZone = readString(metadata, "buildingZone") or context.buildingZone
	context.weather = readString(metadata, "weather") or context.weather
	context.lighting = readString(metadata, "lighting") or context.lighting
	context.objectiveId = readString(metadata, "objectiveId") or context.objectiveId
	context.puzzleId = readString(metadata, "puzzleId") or context.puzzleId
	context.nearbyPlayerCount = readNumber(metadata, "nearbyPlayerCount")
		or context.nearbyPlayerCount
	context.nearbyMonsterCount = readNumber(metadata, "nearbyMonsterCount")
		or context.nearbyMonsterCount
	context.timeSinceLastScare = readNumber(metadata, "timeSinceLastScare")
		or context.timeSinceLastScare
	context.tensionState = readString(metadata, "tensionState") or context.tensionState
	context.areaTags = readTags(metadata, "areaTags") or context.areaTags
	context.roomTags = readTags(metadata, "roomTags") or context.roomTags

	return context
end

function ObservationContext.inspect(): Context
	return copyContext()
end

function ObservationContext.validate(): (boolean, string?)
	if contextState.nearbyPlayerCount < 0 or contextState.nearbyMonsterCount < 0 then
		return false, "ObservationContext nearby counts cannot be negative"
	end

	return true, nil
end

return ObservationContext
