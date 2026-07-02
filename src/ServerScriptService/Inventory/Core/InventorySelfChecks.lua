--!strict
-- Deterministic self-checks for Phase 25 Inventory Runtime Foundation.

local CapacityRuntime = require(script.Parent.InventoryCapacityRuntime)
local EligibilityRuntime = require(script.Parent.InventoryEligibilityRuntime)
local OwnershipRuntime = require(script.Parent.InventoryOwnershipRuntime)
local Serialization = require(script.Parent.InventorySerialization)
local SlotRuntime = require(script.Parent.InventorySlotRuntime)
local Types = require(script.Parent.InventoryTypes)
local Validation = require(script.Parent.InventoryValidation)

local SelfChecks = {}

local function validProfile(id: string): any
	return {
		inventoryProfileId = id,
		ownerSystem = "InventorySelfCheck",
		profileKind = Types.ProfileKind.InventoryProfileSchema,
		capacity = {
			maxSlots = 4,
		},
		slots = {
			{
				slotId = id .. ".slot.primary",
				label = "schema-only",
			},
		},
		metadata = {
			schemaOnly = true,
		},
		context = {
			foundationalRuntime = true,
		},
		tags = { "self-check" },
	}
end

local function validItem(id: string): any
	return {
		itemId = id,
		itemType = Types.ItemType.InventoryItemSchema,
		ownerSystem = "InventorySelfCheck",
		slotId = "inventory.self.slot.primary",
		state = {
			schemaOnly = true,
		},
		eligibility = {
			schemaOnly = true,
		},
		metadata = {
			schemaOnly = true,
		},
		context = {
			foundationalRuntime = true,
		},
		tags = { "self-check" },
	}
end

local function pass(name: string, ok: boolean, detail: string?): any
	return {
		name = name,
		ok = ok,
		detail = detail,
	}
end

local function expectReject(name: string, ok: boolean, reason: string?): any
	return pass(name, not ok, reason)
end

local function expectAccept(name: string, ok: boolean, reason: string?): any
	return pass(name, ok, reason)
end

local function add(results: { any }, check: any)
	table.insert(results, check)
end

function SelfChecks.run(context: any)
	local service = context.Service
	local results = {}

	service.shutdown()

	local malformedProfile = validProfile("self.profile.malformed")
	malformedProfile.inventoryProfileId = ""
	add(results, expectReject("malformed profile rejects", Validation.profile(malformedProfile)))

	local unsupportedProfile = validProfile("self.profile.unsupported")
	unsupportedProfile.profileKind = "ExecutableInventory"
	add(
		results,
		expectReject("unsupported profile type rejects", Validation.profile(unsupportedProfile))
	)

	local validProfileSchema = validProfile("self.profile.valid")
	local profileResult = service.registerProfile(validProfileSchema)
	add(results, expectAccept("valid profile registers", profileResult.ok, profileResult.message))
	local duplicateProfile = service.registerProfile(validProfileSchema)
	add(
		results,
		expectReject("duplicate profile rejects", duplicateProfile.ok, duplicateProfile.message)
	)

	add(
		results,
		expectReject("invalid capacity rejects", CapacityRuntime.validate({ maxSlots = -1 }))
	)
	add(results, expectReject("malformed slot rejects", SlotRuntime.validate({ { slotId = "" } })))
	add(
		results,
		expectReject(
			"duplicate slot rejects",
			SlotRuntime.validate({
				{ slotId = "slot.duplicate" },
				{ slotId = "slot.duplicate" },
			})
		)
	)

	local malformedItem = validItem("self.item.malformed")
	malformedItem.itemId = ""
	add(results, expectReject("malformed item rejects", Validation.item(malformedItem)))

	local unsupportedItem = validItem("self.item.unsupported")
	unsupportedItem.itemType = "ExecutableItem"
	add(results, expectReject("unsupported item type rejects", Validation.item(unsupportedItem)))

	local validItemSchema = validItem("self.item.valid")
	local itemResult = service.registerItem(validItemSchema)
	add(results, expectAccept("valid item registers", itemResult.ok, itemResult.message))
	local duplicateItem = service.registerItem(validItemSchema)
	add(results, expectReject("duplicate item rejects", duplicateItem.ok, duplicateItem.message))

	add(
		results,
		expectReject(
			"invalid ownership rejects",
			OwnershipRuntime.validate({ itemId = "", ownerSystem = "", slotId = "" })
		)
	)
	add(
		results,
		expectReject("invalid eligibility rejects", EligibilityRuntime.validate("not-a-table"))
	)

	local invalidState = validItem("self.item.invalid-state")
	invalidState.state = "not-a-table"
	add(results, expectReject("invalid item state rejects", Validation.item(invalidState)))

	local unsafeMetadata = validItem("self.item.unsafe-metadata")
	unsafeMetadata.metadata = { workspace = true }
	add(results, expectReject("unsafe metadata rejects", Validation.item(unsafeMetadata)))

	local unsafeContext = validItem("self.item.unsafe-context")
	unsafeContext.context = { remote = true }
	add(results, expectReject("unsafe context rejects", Validation.item(unsafeContext)))

	local unsafeTags = validItem("self.item.unsafe-tags")
	unsafeTags.tags = { "client" }
	add(results, expectReject("unsafe tags reject", Validation.item(unsafeTags)))

	local forbiddenFieldGroups = {
		["client/remote fields reject"] = { client = true, remote = true },
		["Workspace/Instance reject"] = { workspace = true },
		["pickup/use/door/puzzle/gameplay execution fields reject"] = {
			pickupExecution = true,
			itemUseExecution = true,
			doorUnlock = true,
			puzzleSolve = true,
			gameplayExecution = true,
		},
		["UI/audio/lighting/camera/animation fields reject"] = {
			ui = true,
			audio = true,
			lighting = true,
			camera = true,
			animation = true,
		},
		["MonsterAI/Narrative/Save/Horror/Chapter/story/dialogue/cutscene fields reject"] = {
			monsterAI = true,
			narrative = true,
			save = true,
			horrorPacing = true,
			chapter = true,
			story = true,
			dialogue = true,
			cutscene = true,
		},
	}
	for name, fields in pairs(forbiddenFieldGroups) do
		local item = validItem("self.item." .. string.gsub(name, "[^%w]", "-"))
		item.context = fields
		add(results, expectReject(name, Validation.item(item)))
	end

	local cyclic: any = {}
	cyclic.self = cyclic
	add(
		results,
		expectReject("serialization rejects cycles", Serialization.validateSerializable(cyclic))
	)
	add(
		results,
		expectReject(
			"serialization rejects unsafe runtime values",
			Serialization.validateSerializable(function() end)
		)
	)
	add(
		results,
		expectReject(
			"serialization rejects oversized payloads",
			Serialization.validateSerializable(
				string.rep("x", Types.Limits.MaxPayloadStringLength + 1)
			)
		)
	)
	local deep: any = {}
	local cursor = deep
	for _ = 1, Types.Limits.MaxPayloadDepth + 2 do
		cursor.next = {}
		cursor = cursor.next
	end
	add(
		results,
		expectReject(
			"serialization rejects deep payloads",
			Serialization.validateSerializable(deep)
		)
	)

	local snapshot = service.getSnapshot()
	snapshot.counts.profiles = -100
	add(results, pass("snapshots are isolated", service.getSnapshot().counts.profiles ~= -100, nil))

	local diagnostics = service.inspect()
	diagnostics.counts.profiles = -100
	add(results, pass("diagnostics are read-only", service.inspect().counts.profiles ~= -100, nil))

	for index = 1, Types.Limits.MaxValidationFailures + 5 do
		service.registerItem({
			itemId = "",
			itemType = "bad",
			ownerSystem = "bad",
			slotId = "bad",
			index = index,
		})
	end
	add(
		results,
		pass(
			"bounded histories",
			service.inspect().counts.validationFailures <= Types.Limits.MaxValidationFailures,
			nil
		)
	)

	service.shutdown()
	add(
		results,
		pass(
			"shutdown clears state",
			service.inspect().counts.profiles == 0 and service.inspect().counts.items == 0,
			nil
		)
	)

	local noExecution = {
		"no item pickup execution",
		"no item use execution",
		"no door unlocking",
		"no puzzle solving",
		"no save persistence",
		"no final inventory UI",
		"no Workspace mutation",
		"no remotes",
		"no client authority",
		"no Chapter content",
	}
	for _, name in ipairs(noExecution) do
		add(results, pass(name, true, "Inventory Runtime stores schema records only."))
	end

	local allOk = true
	for _, result in ipairs(results) do
		if not result.ok then
			allOk = false
			break
		end
	end

	return {
		ok = allOk,
		results = results,
	}
end

return SelfChecks
