--!strict

local Types = require(script.Parent.Chapter196Types)

local State = {}
local runtimeState = Types.State.Dormant
local objectiveIndex = 1
local completed = {}
local inventoryByUserId = {}
local checkpointByUserId = {}
local audit = {}
local failures = {}
local sequence = 0

local function append(target: { any }, value: any, limit: number)
	if #target >= limit then table.remove(target, 1) end
	target[#target + 1] = value
end

function State.setRuntimeState(value: string) runtimeState = value end
function State.getRuntimeState(): string return runtimeState end
function State.getObjectiveIndex(): number return objectiveIndex end
function State.advanceObjective(interactionId: string)
	completed[interactionId] = true
	objectiveIndex += 1
	sequence += 1
	append(audit, table.freeze({ sequence = sequence, kind = "ObjectiveAdvanced", interactionId = interactionId, objectiveIndex = objectiveIndex, at = os.clock() }), Types.Limits.MaxAudit)
end
function State.isCompleted(interactionId: string): boolean return completed[interactionId] == true end
function State.addItem(userId: number, itemId: string)
	local inventory = inventoryByUserId[userId] or {}; inventory[itemId] = true; inventoryByUserId[userId] = inventory
end
function State.hasItem(userId: number, itemId: string): boolean return inventoryByUserId[userId] ~= nil and inventoryByUserId[userId][itemId] == true end
function State.setCheckpoint(userId: number, checkpointId: string) checkpointByUserId[userId] = checkpointId end
function State.getCheckpoint(userId: number): string? return checkpointByUserId[userId] end
function State.recordFailure(code: string, detail: any?) sequence += 1; append(failures, table.freeze({ sequence = sequence, code = code, detail = detail, at = os.clock() }), Types.Limits.MaxFailures) end
function State.inspect()
	local inventoryCount = 0; for _, inventory in pairs(inventoryByUserId) do for _ in pairs(inventory) do inventoryCount += 1 end end
	local completedCount = 0; for _ in pairs(completed) do completedCount += 1 end
	return { runtimeState = runtimeState, objectiveIndex = objectiveIndex, completedCount = completedCount, inventoryItemCount = inventoryCount, playerCheckpointCount = (function() local count = 0; for _ in pairs(checkpointByUserId) do count += 1 end; return count end)(), audit = table.clone(audit), failures = table.clone(failures) }
end
function State.clear() runtimeState = Types.State.Dormant; objectiveIndex = 1; completed = {}; inventoryByUserId = {}; checkpointByUserId = {}; audit = {}; failures = {}; sequence = 0 end

return State
