--!strict

local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)
local KeyDiagnostics = require(script.Parent.KeyDiagnostics)
local KeyRegistry = require(script.Parent.KeyRegistry)
local KeyValidator = require(script.Parent.KeyValidator)

local KeyService = {}

function KeyService.initialize() end

function KeyService.registerKey(definition: any): (boolean, string?)
	return KeyRegistry.register(definition)
end

function KeyService.collectKey(userId: number, keyId: string): (boolean, string?)
	local definition = KeyRegistry.get(keyId)
	if definition == nil then
		return false, "unknown key"
	end
	local ok, reason = InventoryService.addItem(userId, {
		itemId = keyId,
		kind = "Key",
		count = 1,
		metadata = { partyShared = definition.partyShared == true },
	})
	if ok then
		KeyRegistry.recordCollected()
	end
	return ok, reason
end

function KeyService.canUnlock(userId: number, keyId: string, targetId: string): boolean
	local definition = KeyRegistry.get(keyId)
	if definition == nil then
		return false
	end
	if definition.masterKey == true then
		return InventoryService.hasItem(userId, keyId)
	end
	local unlocksTarget = false
	for _, id in ipairs(definition.unlocks) do
		if id == targetId then
			unlocksTarget = true
			break
		end
	end
	return unlocksTarget and InventoryService.hasItem(userId, keyId)
end

function KeyService.useKey(userId: number, keyId: string, targetId: string): (boolean, string?)
	local definition = KeyRegistry.get(keyId)
	if definition == nil then
		return false, "unknown key"
	end
	if not KeyService.canUnlock(userId, keyId, targetId) then
		return false, "key cannot unlock target"
	end
	if definition.singleUse == true then
		InventoryService.removeItem(userId, keyId, 1)
	end
	KeyRegistry.recordUsed()
	return true, nil
end

function KeyService.inspect()
	return KeyDiagnostics.capture({ KeyRegistry = KeyRegistry })
end

function KeyService.validate(): (boolean, string?)
	return KeyValidator.validate()
end

function KeyService.runSelfChecks()
	KeyService.shutdown()
	InventoryService.shutdown()
	KeyService.registerKey({
		id = "selfcheck.key",
		displayName = "Self Check Key",
		singleUse = true,
		reusable = false,
		masterKey = false,
		partyShared = false,
		rewardSource = "SelfCheck",
		unlocks = { "selfcheck.door" },
		metadata = {},
	})
	local collectOk = KeyService.collectKey(-13002, "selfcheck.key")
	local useOk = KeyService.useKey(-13002, "selfcheck.key", "selfcheck.door")
	local hasAfter = InventoryService.hasItem(-13002, "selfcheck.key")
	KeyService.shutdown()
	InventoryService.shutdown()
	return {
		ok = collectOk == true and useOk == true and hasAfter == false,
		keyUnlockFlowWorks = collectOk == true and useOk == true and hasAfter == false,
	}
end

function KeyService.shutdown()
	KeyRegistry.clear()
end

return KeyService
