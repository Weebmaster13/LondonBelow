--!strict
--[[
	Reusable server-side object interaction behavior.

	Owns small, generic state transitions for common object categories. It does
	not animate final art, solve puzzles, grant inventory, or author scares.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.PlayerExperienceTypes)

local ObjectInteractionHandlers = {}

type InteractionDescriptor = Types.InteractionDescriptor
type FeedbackInstruction = Types.FeedbackInstruction

local function feedback(
	kind: Types.FeedbackKind,
	id: string,
	intensity: number,
	duration: number?
): FeedbackInstruction
	return {
		kind = kind,
		id = id,
		intensity = intensity,
		duration = duration,
		metadata = {},
	}
end

local function setBooleanState(instance: Instance?, attribute: string): boolean
	if instance == nil then
		return false
	end

	local nextValue = not (instance:GetAttribute(attribute) == true)
	instance:SetAttribute(attribute, nextValue)

	return nextValue
end

local function markConsumed(instance: Instance?)
	if instance ~= nil then
		instance:SetAttribute("InteractionEnabled", false)
		instance:SetAttribute("Consumed", true)
	end
end

function ObjectInteractionHandlers.execute(
	player: Player,
	descriptor: InteractionDescriptor
): (boolean, string?, { FeedbackInstruction })
	local object = descriptor.instance
	local feedbackInstructions = {}

	if descriptor.kind == "Door" then
		local opened = setBooleanState(object, "Open")
		table.insert(
			feedbackInstructions,
			feedback("Audio", if opened then "door_open" else "door_close", 0.65, 1.2)
		)
		table.insert(feedbackInstructions, feedback("Visual", "door_state_changed", 0.45, 0.5))
	elseif descriptor.kind == "Drawer" then
		local opened = setBooleanState(object, "Open")
		table.insert(
			feedbackInstructions,
			feedback("Audio", if opened then "drawer_open" else "drawer_close", 0.55, 0.9)
		)
	elseif descriptor.kind == "Cabinet" then
		local opened = setBooleanState(object, "Open")
		table.insert(
			feedbackInstructions,
			feedback("Audio", if opened then "cabinet_open" else "cabinet_close", 0.55, 0.9)
		)
	elseif descriptor.kind == "Switch" then
		local on = setBooleanState(object, "On")
		table.insert(
			feedbackInstructions,
			feedback("Audio", if on then "switch_on" else "switch_off", 0.45, 0.5)
		)
		table.insert(feedbackInstructions, feedback("Visual", "switch_state_changed", 0.35, 0.3))
	elseif descriptor.kind == "Lever" then
		setBooleanState(object, "Pulled")
		table.insert(feedbackInstructions, feedback("Audio", "lever_pull", 0.65, 1.0))
	elseif descriptor.kind == "Collectible" or descriptor.kind == "Key" then
		markConsumed(object)
		table.insert(feedbackInstructions, feedback("Audio", "collect", 0.55, 0.8))
		table.insert(feedbackInstructions, feedback("Prompt", "collected", 0.5, 1.0))
	elseif descriptor.kind == "Note" then
		table.insert(feedbackInstructions, feedback("Prompt", "note_open", 0.5, nil))
	else
		table.insert(feedbackInstructions, feedback("Prompt", "interacted", 0.4, 0.5))
	end

	if object ~= nil then
		object:SetAttribute("LastInteractedByUserId", player.UserId)
		object:SetAttribute("LastInteractedAt", os.clock())
	end

	return true, nil, feedbackInstructions
end

function ObjectInteractionHandlers.validate(): (boolean, string?)
	return true, nil
end

return ObjectInteractionHandlers
