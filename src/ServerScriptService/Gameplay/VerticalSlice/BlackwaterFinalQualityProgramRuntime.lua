--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FinalConfig = require(ReplicatedStorage.Config.BlackwaterFinalQualityProgramConfig)

local Runtime = {}
local initialized = false
local root: Instance? = nil
local folder: Folder? = nil
local promptConnections: { RBXScriptConnection } = {}
local discoveries: { [string]: boolean } = {}
local triggeredBeats: { [string]: boolean } = {}
local counters = {
	environmentLayers = 0,
	secretPrompts = 0,
	audioCaptions = 0,
	narrativeBeats = 0,
	puzzleHints = 0,
	replayVariations = 0,
}

local function createPart(parent: Instance, name: string, position: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(3, 2, 0.35)
	part.CFrame = CFrame.new(position)
	part.Color = color
	part.Material = Enum.Material.Slate
	part.Anchored = true
	part.CanCollide = false
	part:SetAttribute("BlackwaterFinalQualityProgram", true)
	part:SetAttribute("ProxyArtStatus", "sourceImplementationProxy")
	part.Parent = parent
	return part
end

local function appendCaseFile(line: string)
	if root == nil then
		return
	end
	local current = root:GetAttribute("DiscoveryLog")
	root:SetAttribute(
		"DiscoveryLog",
		(if type(current) == "string" then current else "") .. "\n- " .. line
	)
end

local function recordSecret(secretId: string, reward: string)
	if discoveries[secretId] then
		return
	end
	discoveries[secretId] = true
	counters.replayVariations += 1
	appendCaseFile(reward)
	if root then
		root:SetAttribute("Phase220LastSecret", secretId)
		root:SetAttribute("Phase220DiscoveryCount", counters.replayVariations)
		root:SetAttribute("Phase220QualityGate", "sourceIntegratedRuntimeBlocked")
	end
end

local function createSecretPrompt(parent: Instance, secret: { [string]: any }, index: number)
	local marker = createPart(
		parent,
		secret.id,
		Vector3.new(-22 + index * 8, 2, 34 - index * 10),
		Color3.fromRGB(84, 68, 44)
	)
	marker:SetAttribute("DiscoveryMethod", secret.method)
	marker:SetAttribute("RequiredKnowledge", secret.requiredKnowledge)
	marker:SetAttribute("Reward", secret.reward)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "FinalQualitySecret"
	prompt.ActionText = "Inspect"
	prompt.ObjectText = secret.method
	prompt.HoldDuration = 0.6
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = true
	prompt.Parent = marker
	promptConnections[#promptConnections + 1] = prompt.Triggered:Connect(function()
		recordSecret(secret.id, secret.reward)
	end)
	counters.secretPrompts += 1
end

function Runtime.initialize(worldRoot: Instance?)
	Runtime.shutdown()
	initialized = true
	root = worldRoot
	if worldRoot == nil then
		return
	end
	local qualityFolder = Instance.new("Folder")
	qualityFolder.Name = "Phase209To220FinalQualityProgram"
	qualityFolder:SetAttribute("OwnerRuntime", "BlackwaterFinalQualityProgramRuntime")
	qualityFolder:SetAttribute("SchemaVersion", FinalConfig.SchemaVersion)
	qualityFolder:SetAttribute("CertificationState", FinalConfig.CertificationState)
	qualityFolder.Parent = worldRoot
	folder = qualityFolder

	local layers = Instance.new("Folder")
	layers.Name = "EnvironmentMemoryLayers"
	layers.Parent = qualityFolder
	for _, layer in ipairs(FinalConfig.EnvironmentLayers) do
		local marker = createPart(layers, layer.id, layer.position, layer.color)
		marker:SetAttribute("Room", layer.room)
		marker:SetAttribute("Layer", layer.layer)
		marker:SetAttribute("Response", layer.response)
		counters.environmentLayers += 1
	end

	local secrets = Instance.new("Folder")
	secrets.Name = "ExplorationSecrets"
	secrets.Parent = qualityFolder
	for index, secret in ipairs(FinalConfig.ExplorationSecrets) do
		createSecretPrompt(secrets, secret, index)
	end

	counters.audioCaptions = #FinalConfig.AudibleWorld
	counters.narrativeBeats = #FinalConfig.NarrativeBeats
	counters.puzzleHints = #FinalConfig.PuzzleProduction
	worldRoot:SetAttribute("Phase220ProgramVersion", FinalConfig.SchemaVersion)
	worldRoot:SetAttribute("Phase220QualityGate", "sourceIntegratedRuntimeBlocked")
	worldRoot:SetAttribute("FinalAudioEvidence", "assetUploadBlocked")
	worldRoot:SetAttribute("FinalStudioEvidence", "studioBlocked")
	worldRoot:SetAttribute("FinalHumanEvidence", "humanPlaytestRequired")
	worldRoot:SetAttribute("FinalPerformanceEvidence", "performanceUnknown")
	worldRoot:SetAttribute("ReleaseCandidateGate", "blockedByExternalEvidence")
	worldRoot:SetAttribute("AccessibilityEquivalenceCount", #FinalConfig.AccessibilityEquivalents)
	worldRoot:SetAttribute("QualityPillarCount", #FinalConfig.QualityPillars)
end

function Runtime.applyObjective(objectiveId: string, pressure: number)
	if root == nil then
		return
	end
	if objectiveId == "ignite_lantern" then
		root:SetAttribute("StreetListensState", "first_wrong_answer")
		root:SetAttribute("StreetAudioCaption", FinalConfig.AudibleWorld[1].caption)
	elseif objectiveId == "read_ledger" then
		root:SetAttribute("NarrativeText", FinalConfig.NarrativeBeats[2].text)
		root:SetAttribute("PuzzleHintLevel", "environmental")
	elseif string.sub(objectiveId, 1, 5) == "ward_" then
		root:SetAttribute("NarrativeText", FinalConfig.NarrativeBeats[3].text)
		root:SetAttribute("PuzzleHintLevel", "contextual")
	elseif objectiveId == "take_heart" then
		root:SetAttribute("NarrativeText", FinalConfig.NarrativeBeats[4].text)
		root:SetAttribute("StreetAudioCaption", FinalConfig.AudibleWorld[12].caption)
		root:SetAttribute("ReleaseCandidateGate", "glassHeartRouteRuntimeBlocked")
	elseif objectiveId == "escape_gate" then
		root:SetAttribute("NarrativeText", FinalConfig.NarrativeBeats[5].text)
		root:SetAttribute("StreetAudioCaption", FinalConfig.AudibleWorld[15].caption)
		root:SetAttribute("DawnIsNotSafety", true)
	end
	root:SetAttribute(
		"Phase220PressureSegment",
		if pressure >= 0.85 then "climax" elseif pressure >= 0.55 then "pressure" else "build"
	)
	triggeredBeats[objectiveId] = true
end

function Runtime.inspect()
	local discoveryCount = 0
	for _ in pairs(discoveries) do
		discoveryCount += 1
	end
	local triggeredCount = 0
	for _ in pairs(triggeredBeats) do
		triggeredCount += 1
	end
	return {
		initialized = initialized,
		schemaVersion = FinalConfig.SchemaVersion,
		phaseCount = #FinalConfig.Phases,
		pillarCount = #FinalConfig.QualityPillars,
		audioCueCount = #FinalConfig.AudibleWorld,
		environmentLayerCount = counters.environmentLayers,
		secretPromptCount = counters.secretPrompts,
		puzzleProductionCount = counters.puzzleHints,
		narrativeBeatCount = counters.narrativeBeats,
		horrorSegmentCount = #FinalConfig.HorrorPacing,
		multiplayerRuleCount = #FinalConfig.MultiplayerRules,
		accessibilityEquivalentCount = #FinalConfig.AccessibilityEquivalents,
		replayVariationCount = #FinalConfig.ReplayVariations,
		discoveryCount = discoveryCount,
		triggeredBeatCount = triggeredCount,
		releaseCandidateGates = table.clone(FinalConfig.ReleaseCandidateGates),
		studioEvidence = "studioBlocked",
		humanEvidence = "humanPlaytestRequired",
		performanceEvidence = "performanceUnknown",
		finalAssetEvidence = "finalAssetBlocked",
	}
end

function Runtime.runSelfChecks()
	Runtime.initialize(nil)
	Runtime.applyObjective("ignite_lantern", 0.2)
	Runtime.applyObjective("take_heart", 0.92)
	local snapshot = Runtime.inspect()
	return {
		ok = snapshot.phaseCount == 12
			and snapshot.pillarCount == 5
			and snapshot.audioCueCount >= 16
			and #FinalConfig.EnvironmentLayers >= 7
			and #FinalConfig.ExplorationSecrets >= 4
			and #FinalConfig.PuzzleProduction >= 3
			and #FinalConfig.NarrativeBeats >= 5
			and #FinalConfig.HorrorPacing >= 5
			and #FinalConfig.MultiplayerRules >= 5
			and #FinalConfig.AccessibilityEquivalents >= 5
			and #FinalConfig.PlaytestProtocol >= 7
			and snapshot.triggeredBeatCount == 2
			and snapshot.releaseCandidateGates.studioRoute == false,
		snapshot = snapshot,
	}
end

function Runtime.shutdown()
	for _, connection in ipairs(promptConnections) do
		connection:Disconnect()
	end
	table.clear(promptConnections)
	if folder then
		folder:Destroy()
	end
	folder = nil
	root = nil
	initialized = false
	discoveries = {}
	triggeredBeats = {}
	counters.environmentLayers = 0
	counters.secretPrompts = 0
	counters.audioCaptions = 0
	counters.narrativeBeats = 0
	counters.puzzleHints = 0
	counters.replayVariations = 0
end

return Runtime
