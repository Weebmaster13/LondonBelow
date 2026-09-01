--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QualityConfig = require(ReplicatedStorage.Config.BlackwaterQualityStrikeConfig)

local Runtime = {}
local initialized = false
local root: Instance? = nil
local folder: Folder? = nil
local promptConnections: { RBXScriptConnection } = {}
local discovered: { [string]: boolean } = {}
local transformed: { [string]: boolean } = {}
local counters = {
	arrangements = 0,
	inspectables = 0,
	reactiveProps = 0,
	sideBranches = 0,
	shortcuts = 0,
	returnTransforms = 0,
	falseSafeLocations = 0,
	safeRecoverySpaces = 0,
	discoveries = 0,
	resourceEvents = 0,
}
local lanternStability = QualityConfig.ResourceLoop.startingValue

local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	material: Enum.Material,
	color: Color3
): Part
	local instance = Instance.new("Part")
	instance.Name = name
	instance.Size = size
	instance.CFrame = CFrame.new(position)
	instance.Material = material
	instance.Color = color
	instance.Anchored = true
	instance.CanCollide = true
	instance:SetAttribute("Phase207QualityStrike", true)
	instance.Parent = parent
	return instance
end

local function appendDiscovery(discoveryId: string, reward: string)
	if discovered[discoveryId] then
		return
	end
	discovered[discoveryId] = true
	counters.discoveries += 1
	if root then
		local existing = root:GetAttribute("DiscoveryLog")
		root:SetAttribute(
			"DiscoveryLog",
			(
				if type(existing) == "string" and existing ~= ""
					then existing
					else "• No discoveries recorded."
			)
				.. "\n• "
				.. reward
		)
		root:SetAttribute("Phase207LastDiscovery", discoveryId)
		root:SetAttribute("Phase207DiscoveryCount", counters.discoveries)
	end
end

local function spendLantern(amount: number, reason: string)
	lanternStability = math.clamp(lanternStability - amount, 0, QualityConfig.ResourceLoop.capacity)
	counters.resourceEvents += 1
	if root then
		root:SetAttribute("LanternStability", lanternStability)
		root:SetAttribute("LanternDecision", reason)
	end
end

local function restoreLantern(amount: number, reason: string)
	lanternStability = math.clamp(lanternStability + amount, 0, QualityConfig.ResourceLoop.capacity)
	counters.resourceEvents += 1
	if root then
		root:SetAttribute("LanternStability", lanternStability)
		root:SetAttribute("LanternDecision", reason)
	end
end

local function createInspectable(parent: Instance, discovery: { [string]: any })
	local target = part(
		parent,
		discovery.id,
		Vector3.new(2.2, 2.2, 2.2),
		discovery.position,
		Enum.Material.Wood,
		Color3.fromRGB(92, 70, 48)
	)
	target:SetAttribute("OptionalDiscoveryId", discovery.id)
	target:SetAttribute("OptionalReward", discovery.reward)
	target:SetAttribute("DiscoveryMethod", discovery.method)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Phase207OptionalInspect"
	prompt.ActionText = discovery.label
	prompt.ObjectText = "Blackwater detail"
	prompt.HoldDuration = 0.45
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = true
	prompt.Parent = target
	promptConnections[#promptConnections + 1] = prompt.Triggered:Connect(function()
		appendDiscovery(discovery.id, discovery.reward)
		if discovery.id == "secret_dawn_reflection" then
			restoreLantern(QualityConfig.ResourceLoop.recoveries.watchBox, "secret_reflection")
		elseif discovery.id == "microstory_bailiff_watch" then
			spendLantern(QualityConfig.ResourceLoop.costs.revealSecret, "bailiff_observation")
		end
	end)
end

local function createShortcut(parent: Instance, shortcut: { [string]: any }, index: number)
	local marker = part(
		parent,
		shortcut.id,
		Vector3.new(4, 5, 1),
		Vector3.new(-16 + index * 12, 2.5, -92),
		Enum.Material.Metal,
		if shortcut.risk == "high" then Color3.fromRGB(112, 34, 32) else Color3.fromRGB(88, 86, 72)
	)
	marker:SetAttribute("ShortcutFrom", shortcut.from)
	marker:SetAttribute("ShortcutTo", shortcut.to)
	marker:SetAttribute("ShortcutRisk", shortcut.risk)
	marker:SetAttribute("RequiresDiscovery", shortcut.requiresDiscovery)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Phase207Shortcut"
	prompt.ActionText = shortcut.label
	prompt.ObjectText = "Route"
	prompt.HoldDuration = if shortcut.risk == "high" then 1.4 else 0.7
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = true
	prompt.Parent = marker
	promptConnections[#promptConnections + 1] = prompt.Triggered:Connect(function()
		if discovered[shortcut.requiresDiscovery] then
			if shortcut.risk == "high" then
				spendLantern(QualityConfig.ResourceLoop.costs.dangerousFastRoute, shortcut.id)
			else
				spendLantern(QualityConfig.ResourceLoop.costs.safeRoute, shortcut.id)
			end
			transformed[shortcut.id] = true
			counters.returnTransforms += 1
			if root then
				root:SetAttribute("Phase207ShortcutOpened", shortcut.id)
			end
		elseif root then
			root:SetAttribute("Phase207ShortcutBlocked", shortcut.id)
			root:SetAttribute(
				"Phase207ShortcutBlockedReason",
				"Requires " .. shortcut.requiresDiscovery
			)
		end
	end)
end

function Runtime.initialize(worldRoot: Instance?)
	Runtime.shutdown()
	initialized = true
	root = worldRoot
	lanternStability = QualityConfig.ResourceLoop.startingValue
	if worldRoot == nil then
		return
	end
	local qualityFolder = Instance.new("Folder")
	qualityFolder.Name = "Phase207QualityStrike"
	qualityFolder:SetAttribute("OwnerRuntime", "BlackwaterQualityStrikeRuntime")
	qualityFolder:SetAttribute("ProxyArtStatus", "sourceImplementationProxy")
	qualityFolder.Parent = worldRoot
	folder = qualityFolder

	local arrangements = Instance.new("Folder")
	arrangements.Name = "EnvironmentalStorytelling"
	arrangements.Parent = qualityFolder
	for _, arrangement in ipairs(QualityConfig.EnvironmentArrangements) do
		local item = part(
			arrangements,
			arrangement.id,
			arrangement.size,
			arrangement.position,
			arrangement.material,
			arrangement.color
		)
		item:SetAttribute("Area", arrangement.area)
		item:SetAttribute("PrimaryLandmark", arrangement.landmark)
		item:SetAttribute("OptionalStoryClue", arrangement.clue)
		item:SetAttribute("AudioIdentity", "The Street That Listens")
		item:SetAttribute("ProxyArtStatus", "sourceImplementationProxy")
		counters.arrangements += 1
	end

	local branches = Instance.new("Folder")
	branches.Name = "ExplorationBranches"
	branches.Parent = qualityFolder
	for _, branch in ipairs(QualityConfig.SideBranches) do
		local zone = part(
			branches,
			branch.id,
			branch.size,
			branch.position,
			Enum.Material.Slate,
			if branch.route == "dangerous fast route"
				then Color3.fromRGB(64, 31, 34)
				else Color3.fromRGB(38, 45, 48)
		)
		zone:SetAttribute("BranchKind", branch.kind)
		zone:SetAttribute("RouteRole", branch.route)
		zone:SetAttribute("Reward", branch.reward)
		zone.Transparency = 0.18
		counters.sideBranches += 1
	end

	local inspectables = Instance.new("Folder")
	inspectables.Name = "InspectableDetails"
	inspectables.Parent = qualityFolder
	for _, discovery in ipairs(QualityConfig.OptionalDiscoveries) do
		createInspectable(inspectables, discovery)
		counters.inspectables += 1
	end

	local shortcuts = Instance.new("Folder")
	shortcuts.Name = "OptionalShortcuts"
	shortcuts.Parent = qualityFolder
	for index, shortcut in ipairs(QualityConfig.ShortcutRules) do
		createShortcut(shortcuts, shortcut, index)
		counters.shortcuts += 1
	end

	counters.reactiveProps = #QualityConfig.ReactiveProps
	counters.falseSafeLocations = 2
	counters.safeRecoverySpaces = 1
	worldRoot:SetAttribute(
		"Phase207OpeningBudgetControlSeconds",
		QualityConfig.OpeningBudgets.controlSeconds
	)
	worldRoot:SetAttribute("Phase207SignatureMomentCount", #QualityConfig.SignatureMoments)
	worldRoot:SetAttribute("LanternStability", lanternStability)
	worldRoot:SetAttribute("Phase207QualityState", "implementedUnverified")
end

function Runtime.applyObjective(objectiveId: string)
	for _, prop in ipairs(QualityConfig.ReactiveProps) do
		if prop.trigger == objectiveId then
			transformed[prop.id] = true
			if root then
				root:SetAttribute(prop.attribute, true)
				root:SetAttribute("Phase207LastReactiveProp", prop.id)
			end
		end
	end
	if objectiveId == "ignite_lantern" then
		appendDiscovery(
			"opening_dramatic_question",
			"Why did every witness vanish before reaching Blackwater House?"
		)
	elseif objectiveId == "ward_crypt" then
		spendLantern(QualityConfig.ResourceLoop.costs.hidingRecovery, "ward_pressure")
	elseif objectiveId == "escape_gate" then
		restoreLantern(QualityConfig.ResourceLoop.recoveries.dawn, "dawn_escape")
	end
end

function Runtime.inspect()
	local discoveryCount = 0
	for _ in pairs(discovered) do
		discoveryCount += 1
	end
	local transformedCount = 0
	for _ in pairs(transformed) do
		transformedCount += 1
	end
	return {
		initialized = initialized,
		schemaVersion = QualityConfig.SchemaVersion,
		arrangements = counters.arrangements,
		inspectables = counters.inspectables,
		reactiveProps = counters.reactiveProps,
		sideBranches = counters.sideBranches,
		shortcuts = counters.shortcuts,
		returnTransforms = counters.returnTransforms,
		falseSafeLocations = counters.falseSafeLocations,
		safeRecoverySpaces = counters.safeRecoverySpaces,
		discoveries = discoveryCount,
		transformed = transformedCount,
		lanternStability = lanternStability,
		signatureMoments = #QualityConfig.SignatureMoments,
		evidenceState = "implementedUnverified",
		studioEvidence = "studioBlocked",
	}
end

function Runtime.runSelfChecks()
	Runtime.initialize(nil)
	Runtime.applyObjective("ignite_lantern")
	Runtime.applyObjective("ward_crypt")
	local snapshot = Runtime.inspect()
	return {
		ok = snapshot.arrangements == 0
			and #QualityConfig.EnvironmentArrangements >= 12
			and #QualityConfig.OptionalDiscoveries >= 5
			and #QualityConfig.SideBranches >= 3
			and #QualityConfig.ShortcutRules >= 2
			and #QualityConfig.ReactiveProps >= 5
			and #QualityConfig.SignatureMoments == 10
			and snapshot.lanternStability < QualityConfig.ResourceLoop.startingValue,
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
	discovered = {}
	transformed = {}
	lanternStability = QualityConfig.ResourceLoop.startingValue
	counters.arrangements = 0
	counters.inspectables = 0
	counters.reactiveProps = 0
	counters.sideBranches = 0
	counters.shortcuts = 0
	counters.returnTransforms = 0
	counters.falseSafeLocations = 0
	counters.safeRecoverySpaces = 0
	counters.discoveries = 0
	counters.resourceEvents = 0
end

return Runtime
