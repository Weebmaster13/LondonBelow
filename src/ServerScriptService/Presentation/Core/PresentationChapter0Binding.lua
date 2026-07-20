--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local FixtureCatalog = require(ServerScriptService.Chapter0Home.Environment.Chapter0FixtureCatalog)
local EnvironmentalTypes = require(ServerScriptService.Interaction.Environmental.EnvironmentalTypes)

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Binding = {}

local FIXTURE_PRESENTATION = {
	["chapter0.home.entry.frontDoor"] = {
		actionKeyByState = {
			CLOSED = "chapter0.home.prompt.frontDoor.open",
			OPEN = "chapter0.home.prompt.frontDoor.close",
		},
		audioKeyByAction = { OPEN = "door.open", CLOSE = "door.close" },
		animationKeyByAction = { OPEN = "door.open", CLOSE = "door.close" },
		messageKey = "chapter0.home.message.frontDoor",
	},
	["chapter0.home.hallway.bedroomDoor"] = {
		actionKeyByState = {
			CLOSED = "chapter0.home.prompt.bedroomDoor.open",
			OPEN = "chapter0.home.prompt.bedroomDoor.close",
		},
		audioKeyByAction = { OPEN = "door.open", CLOSE = "door.close" },
		animationKeyByAction = { OPEN = "door.open", CLOSE = "door.close" },
		messageKey = "chapter0.home.message.bedroomDoor",
	},
	["chapter0.home.sittingRoom.gasLamp"] = {
		actionKeyByState = {
			OFF = "chapter0.home.prompt.gasLamp.light",
			ON = "chapter0.home.prompt.gasLamp.lower",
		},
		audioKeyByAction = { ACTIVATE = "switch.toggle", TOGGLE = "switch.toggle" },
		animationKeyByAction = { ACTIVATE = "switch.toggle", TOGGLE = "switch.toggle" },
		messageKey = "chapter0.home.message.gasLamp",
	},
	["chapter0.home.kitchen.breaker"] = {
		actionKeyByState = {
			OFF = "chapter0.home.prompt.breaker.switchOn",
			ON = "chapter0.home.prompt.breaker.switchOff",
		},
		audioKeyByAction = { ACTIVATE = "switch.toggle", TOGGLE = "switch.toggle" },
		animationKeyByAction = { ACTIVATE = "switch.toggle", TOGGLE = "switch.toggle" },
		messageKey = "chapter0.home.message.breaker",
	},
	["chapter0.home.bedroom.deskDrawer"] = {
		actionKeyByState = {
			CLOSED = "chapter0.home.prompt.drawer.open",
			OPEN = "chapter0.home.prompt.drawer.close",
		},
		audioKeyByAction = { OPEN = "drawer.open", CLOSE = "drawer.close" },
		animationKeyByAction = { OPEN = "drawer.open", CLOSE = "drawer.close" },
		messageKey = "chapter0.home.message.drawer",
	},
	["chapter0.home.entry.windowLatch"] = {
		actionKeyByState = {
			CLOSED = "chapter0.home.prompt.windowLatch.open",
			OPEN = "chapter0.home.prompt.windowLatch.close",
		},
		audioKeyByAction = { OPEN = "windowLatch.open", CLOSE = "windowLatch.close" },
		animationKeyByAction = { OPEN = "windowLatch.open", CLOSE = "windowLatch.close" },
		messageKey = "chapter0.home.message.windowLatch",
	},
	["chapter0.home.sittingRoom.mumsNote"] = {
		actionKeyByState = {
			AVAILABLE = "chapter0.home.prompt.mumsNote.inspect",
			INSPECTED = "chapter0.home.prompt.mumsNote.readAgain",
		},
		audioKeyByAction = { INSPECT = "inspection.success" },
		animationKeyByAction = { INSPECT = "inspect.note" },
		messageKey = "chapter0.home.message.mumsNote",
	},
	["chapter0.home.hallway.resetPanel"] = {
		actionKeyByState = {
			READY = "chapter0.home.prompt.resetPanel.activate",
			COOLDOWN = "chapter0.home.prompt.resetPanel.busy",
		},
		audioKeyByAction = { ACTIVATE = "interaction.busy" },
		animationKeyByAction = { ACTIVATE = "switch.toggle" },
		messageKey = "chapter0.home.message.resetPanel",
	},
}

local function commandId(objectId: string, suffix: string, revision: number): string
	return objectId .. "." .. suffix .. "." .. tostring(revision)
end

local function configFor(objectId: string)
	return FIXTURE_PRESENTATION[objectId]
end

function Binding.commandsForFixture(fixture: any, state: string, revision: number): { any }
	local config = configFor(fixture.id)
	if config == nil then
		return {}
	end
	local firstAction = fixture.supportedActions[1]
	local commands = {
		{
			commandId = commandId(fixture.id, "prompt", revision),
			sourceRuntime = "Chapter0EnvironmentalBinding",
			objectId = fixture.id,
			presentationType = Types.PresentationType.ShowPrompt,
			priority = if fixture.family == EnvironmentalTypes.Family.InspectableObject
				then "Inspection"
				else "Interaction",
			revision = revision,
			payload = {
				promptId = fixture.id .. ".prompt",
				objectId = fixture.id,
				titleKey = fixture.presentationMetadata.promptKey,
				subtitleKey = config.messageKey,
				actionKey = config.actionKeyByState[state]
					or config.actionKeyByState.CLOSED
					or config.messageKey,
				enabled = true,
				busy = false,
				distance = fixture.distancePolicy.maxDistance,
				priority = "Interaction",
				accessibilityMetadata = {
					screenReaderKey = config.messageKey,
					subtitleKey = config.messageKey,
					colorIndependentState = state,
					inputGlyphKey = "input.interact",
				},
			},
		},
		{
			commandId = commandId(fixture.id, "cursor", revision),
			sourceRuntime = "Chapter0EnvironmentalBinding",
			objectId = fixture.id,
			presentationType = Types.PresentationType.UpdateCursor,
			priority = "Context",
			revision = revision,
			payload = { cursorState = Types.CursorState.Interactable },
		},
		{
			commandId = commandId(fixture.id, "highlight", revision),
			sourceRuntime = "Chapter0EnvironmentalBinding",
			objectId = fixture.id,
			presentationType = Types.PresentationType.HighlightObject,
			priority = "Context",
			revision = revision,
			payload = { highlightKey = fixture.id .. ".highlight", colorIndependentState = state },
		},
		{
			commandId = commandId(fixture.id, "audio", revision),
			sourceRuntime = "Chapter0EnvironmentalBinding",
			objectId = fixture.id,
			presentationType = Types.PresentationType.PlayAudio,
			priority = "Context",
			revision = revision,
			payload = { audioKey = config.audioKeyByAction[firstAction] or "interaction.denied" },
		},
		{
			commandId = commandId(fixture.id, "animation", revision),
			sourceRuntime = "Chapter0EnvironmentalBinding",
			objectId = fixture.id,
			presentationType = Types.PresentationType.PlayAnimation,
			priority = "Context",
			revision = revision,
			payload = {
				animationKey = config.animationKeyByAction[firstAction] or "interaction.busy",
			},
		},
		{
			commandId = commandId(fixture.id, "message", revision),
			sourceRuntime = "Chapter0EnvironmentalBinding",
			objectId = fixture.id,
			presentationType = Types.PresentationType.ShowMessage,
			priority = "Ambient",
			revision = revision,
			payload = {
				messageId = fixture.id .. ".message",
				messageKey = config.messageKey,
				accessibilityMetadata = {
					screenReaderKey = config.messageKey,
					subtitleKey = config.messageKey,
				},
			},
		},
	}
	return Serialization.deepCopy(commands)
end

function Binding.commandsForCatalog(): { any }
	local commands = {}
	local revision = 1
	for _, fixture in ipairs(FixtureCatalog.getFixtures()) do
		for _, command in
			ipairs(Binding.commandsForFixture(fixture, fixture.initialState, revision))
		do
			table.insert(commands, command)
			revision += 1
		end
	end
	return commands
end

return Binding
