--!strict
--[[
	Authoritative registry for reusable world interactables.

	Owns descriptor construction from attributes, explicit registration, lookup,
	and priority sorting. It does not execute interactions or trust client focus.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlayerExperienceConfig = require(ReplicatedStorage.Config.PlayerExperienceConfig)
local Types = require(ReplicatedStorage.Shared.PlayerExperienceTypes)

local InteractionRegistry = {}

type InteractionDescriptor = Types.InteractionDescriptor
type InteractionKind = Types.InteractionKind

local TAG = "LondonInteractable"
local descriptorsById: { [string]: InteractionDescriptor } = {}
local idsByInstance: { [Instance]: string } = {}

local function asString(value: any, fallback: string): string
	return if type(value) == "string" and value ~= "" then value else fallback
end

local function asNumber(value: any, fallback: number): number
	return if type(value) == "number" and value == value then value else fallback
end

local function asBoolean(value: any, fallback: boolean): boolean
	return if type(value) == "boolean" then value else fallback
end

local function asKind(value: any): InteractionKind
	local text = asString(value, "Generic")

	if
		text == "Door"
		or text == "Drawer"
		or text == "Cabinet"
		or text == "Switch"
		or text == "Lever"
		or text == "Collectible"
		or text == "Note"
		or text == "Key"
	then
		return text
	end

	return "Generic"
end

local function observationForKind(kind: InteractionKind): string?
	if kind == "Door" then
		return "Interaction.OpenDoor"
	elseif kind == "Drawer" then
		return "Interaction.OpenDrawer"
	elseif kind == "Cabinet" then
		return "Interaction.OpenCabinet"
	elseif kind == "Switch" then
		return "Interaction.ToggleSwitch"
	elseif kind == "Lever" then
		return "Interaction.PullLever"
	elseif kind == "Collectible" then
		return "Interaction.CollectibleFound"
	elseif kind == "Note" then
		return "Interaction.ReadNote"
	elseif kind == "Key" then
		return "Interaction.PickupKey"
	end

	return nil
end

local function metadataFromInstance(instance: Instance): { [string]: any }
	local metadata = {}

	for name, value in pairs(instance:GetAttributes()) do
		if string.sub(name, 1, 5) == "Meta_" then
			metadata[string.sub(name, 6)] = value
		end
	end

	metadata.instanceName = instance.Name

	return metadata
end

local function descriptorFromInstance(instance: Instance): InteractionDescriptor
	local kind = asKind(instance:GetAttribute("InteractionKind"))
	local id = asString(instance:GetAttribute("InteractionId"), instance:GetFullName())

	return {
		id = id,
		kind = kind,
		instance = instance,
		prompt = asString(
			instance:GetAttribute("Prompt"),
			PlayerExperienceConfig.Interaction.defaultPrompt
		),
		priority = asNumber(instance:GetAttribute("Priority"), 0),
		maxDistance = asNumber(
			instance:GetAttribute("MaxDistance"),
			PlayerExperienceConfig.Interaction.defaultMaxDistance
		),
		requiresLineOfSight = asBoolean(instance:GetAttribute("RequiresLineOfSight"), true),
		cooperative = asBoolean(instance:GetAttribute("Cooperative"), false),
		replayable = asBoolean(
			instance:GetAttribute("Replayable"),
			kind ~= "Collectible" and kind ~= "Key"
		),
		enabled = asBoolean(instance:GetAttribute("InteractionEnabled"), true),
		observationId = asString(
			instance:GetAttribute("ObservationId"),
			observationForKind(kind) or ""
		),
		metadata = metadataFromInstance(instance),
	}
end

local function sanitizeDescriptor(descriptor: InteractionDescriptor): InteractionDescriptor
	return {
		id = descriptor.id,
		kind = descriptor.kind,
		instance = descriptor.instance,
		prompt = descriptor.prompt,
		priority = descriptor.priority,
		maxDistance = descriptor.maxDistance,
		requiresLineOfSight = descriptor.requiresLineOfSight,
		cooperative = descriptor.cooperative,
		replayable = descriptor.replayable,
		enabled = descriptor.enabled,
		observationId = descriptor.observationId,
		metadata = table.clone(descriptor.metadata),
	}
end

local function findTaggedAncestor(instance: Instance): Instance?
	local current: Instance? = instance

	while current ~= nil and current ~= Workspace do
		if CollectionService:HasTag(current, TAG) then
			return current
		end

		current = current.Parent
	end

	return nil
end

function InteractionRegistry.registerInstance(instance: Instance): InteractionDescriptor
	local descriptor = descriptorFromInstance(instance)

	descriptorsById[descriptor.id] = descriptor
	idsByInstance[instance] = descriptor.id

	return sanitizeDescriptor(descriptor)
end

function InteractionRegistry.unregisterInstance(instance: Instance)
	local id = idsByInstance[instance]

	if id ~= nil then
		descriptorsById[id] = nil
		idsByInstance[instance] = nil
	end
end

function InteractionRegistry.get(id: string): InteractionDescriptor?
	local descriptor = descriptorsById[id]

	if descriptor == nil then
		return nil
	end

	if descriptor.instance ~= nil then
		local refreshed = descriptorFromInstance(descriptor.instance)

		if refreshed.id ~= id then
			descriptorsById[id] = nil
		end

		descriptor = refreshed
		descriptorsById[refreshed.id] = refreshed
		idsByInstance[descriptor.instance] = descriptor.id
	end

	return sanitizeDescriptor(descriptor)
end

function InteractionRegistry.getForInstance(instance: Instance): InteractionDescriptor?
	local id = idsByInstance[instance]

	if id == nil and CollectionService:HasTag(instance, TAG) then
		return InteractionRegistry.registerInstance(instance)
	elseif id == nil then
		local taggedAncestor = findTaggedAncestor(instance)

		if taggedAncestor == nil then
			return nil
		end

		return InteractionRegistry.getForInstance(taggedAncestor)
	end

	return InteractionRegistry.get(id)
end

function InteractionRegistry.refreshTagged()
	for _, instance in ipairs(CollectionService:GetTagged(TAG)) do
		InteractionRegistry.registerInstance(instance)
	end
end

function InteractionRegistry.getCandidates(): { InteractionDescriptor }
	local descriptors = {}

	for _, descriptor in pairs(descriptorsById) do
		table.insert(descriptors, sanitizeDescriptor(descriptor))
	end

	table.sort(descriptors, function(left, right)
		if left.priority == right.priority then
			return left.id < right.id
		end

		return left.priority > right.priority
	end)

	return descriptors
end

function InteractionRegistry.clear()
	table.clear(descriptorsById)
	table.clear(idsByInstance)
end

function InteractionRegistry.inspect()
	return {
		count = #InteractionRegistry.getCandidates(),
		interactions = InteractionRegistry.getCandidates(),
	}
end

function InteractionRegistry.validate(): (boolean, string?)
	for id, descriptor in pairs(descriptorsById) do
		if id == "" or #id > PlayerExperienceConfig.Interaction.maxInteractionIdLength then
			return false, "Interaction id is invalid: " .. id
		end

		if descriptor.maxDistance <= 0 then
			return false, "Interaction maxDistance must be positive: " .. id
		end
	end

	return true, nil
end

return InteractionRegistry
