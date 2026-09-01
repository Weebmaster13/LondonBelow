--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AudioManifest = require(ReplicatedStorage.Config.BlackwaterAudioManifest)

local Runtime = {}
local initialized = false
local root: Instance? = nil
local triggered: { [string]: boolean } = {}
local eventLog = {}
local activeLayerState = {
	worldBed = "ordinaryLondon",
	localObjects = "streetPhysical",
	livingWorld = "present",
	playerPhysicality = "wetStone",
	psychological = "subtle",
}

local openingSegments = table.freeze({
	{
		id = "ordinary_london",
		startSeconds = 0,
		endSeconds = 30,
		layers = {
			"rain",
			"wind",
			"distantCarriage",
			"distantDog",
			"playerFootsteps",
			"coatAndLantern",
		},
		caption = "Rain, distant traffic, and wet steps establish the street.",
	},
	{
		id = "house_reveal",
		startSeconds = 30,
		endSeconds = 60,
		layers = {
			"distantBell",
			"singleRaven",
			"cityRetreat",
			"pressureTone",
			"upperStructureStrain",
		},
		caption = "The street grows quieter as Blackwater House notices the party.",
	},
	{
		id = "gate_approach",
		startSeconds = 60,
		endSeconds = 120,
		layers = {
			"detailedFootsteps",
			"clearLantern",
			"sourceLessCarriage",
			"dogSilence",
			"gateWeight",
		},
		caption = "A carriage passes without appearing.",
	},
	{
		id = "boundary_crossing",
		startSeconds = 120,
		endSeconds = 180,
		layers = {
			"filteredRain",
			"houseBreath",
			"impossibleFootsteps",
			"gaslightInstability",
			"controlledSilence",
		},
		caption = "The house inhales and the rain seems to wait.",
	},
})

local authoredEvents = table.freeze({
	impossible_footsteps = {
		caption = "Two wet footsteps continue after you stop.",
		visualEquivalent = "upper-window pressure pulse",
		rateLimitSeconds = 9999,
		layer = "psychological",
	},
	wrong_bell = {
		caption = "The bell strikes once too many.",
		visualEquivalent = "ward glyph pulse",
		rateLimitSeconds = 9999,
		layer = "psychological",
	},
	source_less_carriage = {
		caption = "Hooves and wheels pass, but no carriage appears.",
		visualEquivalent = "street shadow without source",
		rateLimitSeconds = 9999,
		layer = "livingWorld",
	},
	breathing_architecture = {
		caption = "Blackwater House breathes through the timber.",
		visualEquivalent = "house silhouette constricts",
		rateLimitSeconds = 9999,
		layer = "localObjects",
	},
	constable_vale_presence = {
		caption = "A notebook shifts somewhere ahead.",
		visualEquivalent = "case-file edge glows",
		rateLimitSeconds = 45,
		layer = "psychological",
	},
})

local function append(value: { [string]: any })
	if #eventLog >= 128 then
		table.remove(eventLog, 1)
	end
	eventLog[#eventLog + 1] = table.freeze(value)
end

local function publishAttributes(eventId: string, caption: string, visualEquivalent: string)
	if root == nil then
		return
	end
	root:SetAttribute("StreetAudioEvent", eventId)
	root:SetAttribute("StreetAudioCaption", caption)
	root:SetAttribute("StreetAudioVisualEquivalent", visualEquivalent)
	root:SetAttribute("StreetAudioIdentity", AudioManifest.AudioIdentity)
	root:SetAttribute("StreetAudioAssetsReady", false)
end

function Runtime.initialize(worldRoot: Instance?)
	initialized = true
	root = worldRoot
	triggered = {}
	eventLog = {}
	activeLayerState = {
		worldBed = "ordinaryLondon",
		localObjects = "streetPhysical",
		livingWorld = "present",
		playerPhysicality = "wetStone",
		psychological = "subtle",
	}
	publishAttributes("ordinary_london", openingSegments[1].caption, "none")
end

function Runtime.segmentForProgress(progress: number): { [string]: any }
	if progress < 0.25 then
		return openingSegments[1]
	elseif progress < 0.5 then
		return openingSegments[2]
	elseif progress < 0.78 then
		return openingSegments[3]
	end
	return openingSegments[4]
end

function Runtime.trigger(eventId: string, reason: string): (boolean, string?)
	local event = authoredEvents[eventId]
	if not event then
		return false, "UnknownStreetAudioEvent"
	end
	if triggered[eventId] then
		return false, "StreetAudioEventAlreadyTriggered"
	end
	triggered[eventId] = true
	activeLayerState[event.layer] = eventId
	publishAttributes(eventId, event.caption, event.visualEquivalent)
	append({
		eventId = eventId,
		reason = reason,
		caption = event.caption,
		visualEquivalent = event.visualEquivalent,
		assetStatus = "assetUploadBlocked",
		at = os.clock(),
	})
	return true, nil
end

function Runtime.applyProgress(progress: number)
	local segment = Runtime.segmentForProgress(progress)
	if root then
		root:SetAttribute("StreetAudioSegment", segment.id)
		root:SetAttribute("StreetAudioSegmentCaption", segment.caption)
	end
end

function Runtime.inspect()
	local triggeredCount = 0
	for _ in pairs(triggered) do
		triggeredCount += 1
	end
	return {
		initialized = initialized,
		audioIdentity = AudioManifest.AudioIdentity,
		candidateCount = #AudioManifest.Candidates,
		triggeredCount = triggeredCount,
		openingSegmentCount = #openingSegments,
		layerState = table.clone(activeLayerState),
		eventLog = table.clone(eventLog),
		runtimeEvidence = "executionBlocked",
		robloxAssetUploadStatus = "assetUploadBlocked",
	}
end

function Runtime.runSelfChecks()
	Runtime.initialize(nil)
	local first = Runtime.trigger("impossible_footsteps", "self_check")
	local duplicate = Runtime.trigger("impossible_footsteps", "self_check")
	local segment = Runtime.segmentForProgress(0.8)
	return {
		ok = first == true
			and duplicate == false
			and segment.id == "boundary_crossing"
			and #AudioManifest.Candidates == 10,
		candidates = #AudioManifest.Candidates,
		segments = #openingSegments,
	}
end

function Runtime.shutdown()
	initialized = false
	root = nil
	triggered = {}
	eventLog = {}
end

return Runtime
