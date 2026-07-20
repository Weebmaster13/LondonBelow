--!strict

local Types = require(script.Parent.Chapter0EnvironmentalTypes)

local Catalog = {}

local function binary(
	id: string,
	targetId: string,
	initialState: string,
	actions: { string },
	roomId: string,
	required: boolean
)
	return {
		id = id,
		version = 1,
		chapterId = Types.ChapterId,
		family = Types.FixtureFamily.BinaryMechanism,
		displayName = id,
		interactionTargetId = targetId,
		supportedActions = actions,
		initialState = initialState,
		allowedStates = {
			Types.EnvironmentalState.Closed,
			Types.EnvironmentalState.Open,
			Types.EnvironmentalState.Off,
			Types.EnvironmentalState.On,
		},
		presentationMetadata = {
			promptKey = id .. ".prompt",
			actionDisplayKeys = {
				open = "Open",
				close = "Close",
				toggle = "Toggle",
				activate = "Activate",
			},
			visualStateKey = string.lower(initialState),
		},
		observationPolicy = { requiresFocus = true },
		distancePolicy = { maxDistance = 12 },
		lineOfSightPolicy = { required = true },
		contentionPolicy = "Exclusive",
		cooldownPolicy = { seconds = 0 },
		repeatPolicy = "Repeatable",
		resetPolicy = { state = initialState },
		authoringMetadata = {
			roomId = roomId,
			authoredInstanceId = id .. ".instance",
			authoredInstanceRequired = required,
			bindingMode = "AuthoredInstanceReference",
		},
		diagnosticMetadata = { phase = 158, chapterId = Types.ChapterId },
	}
end

local function inspectable(id: string, targetId: string, roomId: string, required: boolean)
	return {
		id = id,
		version = 1,
		chapterId = Types.ChapterId,
		family = Types.FixtureFamily.InspectableObject,
		displayName = id,
		interactionTargetId = targetId,
		supportedActions = { Types.EnvironmentalAction.Inspect },
		initialState = Types.EnvironmentalState.Available,
		allowedStates = { Types.EnvironmentalState.Available, Types.EnvironmentalState.Inspected },
		presentationMetadata = {
			promptKey = id .. ".prompt",
			inspectionId = id .. ".inspection",
			titleKey = id .. ".title",
			bodyKey = id .. ".body",
		},
		observationPolicy = { requiresFocus = true },
		distancePolicy = { maxDistance = 10 },
		lineOfSightPolicy = { required = true },
		contentionPolicy = "Exclusive",
		cooldownPolicy = { seconds = 0 },
		repeatPolicy = "OneShot",
		resetPolicy = { state = Types.EnvironmentalState.Available },
		authoringMetadata = {
			roomId = roomId,
			authoredInstanceId = id .. ".instance",
			authoredInstanceRequired = required,
			bindingMode = "AuthoredInstanceReference",
		},
		diagnosticMetadata = { phase = 158, chapterId = Types.ChapterId },
	}
end

local function actuator(id: string, targetId: string, roomId: string, dependencyTarget: string?)
	return {
		id = id,
		version = 1,
		chapterId = Types.ChapterId,
		family = Types.FixtureFamily.MomentaryActuator,
		displayName = id,
		interactionTargetId = targetId,
		supportedActions = { Types.EnvironmentalAction.Activate },
		initialState = Types.EnvironmentalState.Ready,
		allowedStates = {
			Types.EnvironmentalState.Ready,
			Types.EnvironmentalState.Cooldown,
			Types.EnvironmentalState.Disabled,
		},
		presentationMetadata = {
			promptKey = id .. ".prompt",
			visualStateKey = "ready",
		},
		observationPolicy = { requiresFocus = true },
		distancePolicy = { maxDistance = 10 },
		lineOfSightPolicy = { required = true },
		contentionPolicy = "Exclusive",
		cooldownPolicy = { seconds = 0 },
		repeatPolicy = "ResetRequired",
		resetPolicy = { state = Types.EnvironmentalState.Ready },
		dependency = if dependencyTarget ~= nil
			then { bindingId = id .. ".dependency", targetObjectId = dependencyTarget }
			else nil,
		authoringMetadata = {
			roomId = roomId,
			authoredInstanceId = id .. ".instance",
			authoredInstanceRequired = false,
			bindingMode = "AuthoredInstanceReference",
		},
		diagnosticMetadata = { phase = 158, chapterId = Types.ChapterId },
	}
end

Catalog.Fixtures = {
	binary(
		"chapter0.home.entry.frontDoor",
		"chapter0.home.entry.frontDoor.target",
		Types.EnvironmentalState.Closed,
		{
			Types.EnvironmentalAction.Open,
			Types.EnvironmentalAction.Close,
		},
		"chapter0_home_sitting_room",
		true
	),
	binary(
		"chapter0.home.hallway.bedroomDoor",
		"chapter0.home.hallway.bedroomDoor.target",
		Types.EnvironmentalState.Closed,
		{
			Types.EnvironmentalAction.Open,
			Types.EnvironmentalAction.Close,
		},
		"chapter0_home_bedroom",
		true
	),
	binary(
		"chapter0.home.sittingRoom.gasLamp",
		"chapter0.home.sittingRoom.gasLamp.target",
		Types.EnvironmentalState.Off,
		{
			Types.EnvironmentalAction.Activate,
			Types.EnvironmentalAction.Toggle,
		},
		"chapter0_home_sitting_room",
		true
	),
	binary(
		"chapter0.home.kitchen.breaker",
		"chapter0.home.kitchen.breaker.target",
		Types.EnvironmentalState.Off,
		{
			Types.EnvironmentalAction.Activate,
			Types.EnvironmentalAction.Toggle,
		},
		"chapter0_home_sitting_room",
		false
	),
	binary(
		"chapter0.home.bedroom.deskDrawer",
		"chapter0.home.bedroom.deskDrawer.target",
		Types.EnvironmentalState.Closed,
		{
			Types.EnvironmentalAction.Open,
			Types.EnvironmentalAction.Close,
		},
		"chapter0_home_bedroom",
		false
	),
	binary(
		"chapter0.home.entry.windowLatch",
		"chapter0.home.entry.windowLatch.target",
		Types.EnvironmentalState.Closed,
		{
			Types.EnvironmentalAction.Open,
			Types.EnvironmentalAction.Close,
		},
		"chapter0_home_sitting_room",
		false
	),
	inspectable(
		"chapter0.home.sittingRoom.mumsNote",
		"chapter0.home.sittingRoom.mumsNote.target",
		"chapter0_home_sitting_room",
		true
	),
	actuator(
		"chapter0.home.hallway.resetPanel",
		"chapter0.home.hallway.resetPanel.target",
		"chapter0_home_hall",
		"chapter0.home.sittingRoom.gasLamp"
	),
}

function Catalog.getFixtures(): { any }
	local fixtures = {}
	for _, fixture in ipairs(Catalog.Fixtures) do
		table.insert(fixtures, fixture)
	end
	return fixtures
end

return Catalog
