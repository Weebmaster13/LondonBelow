--!strict

local Runtime = require(script.Parent.RuntimeRobloxGuiInstanceContract)
local Types = require(script.Parent.RobloxGuiInstanceContractTypes)

local SelfChecks = {}

local function validContract(id: string)
	return { contractId = id, schemaVersion = Types.SchemaVersion, sourcePatchId = "visual.patch.185", targetRevision = 185, rootNodeId = "root", nodes = {
		{ nodeId = "root", className = "ScreenGui", parentNodeId = "PlayerGui", properties = { Enabled = true, DisplayOrder = 10 }, references = {}, tags = { "game-ui" }, accessibility = { role = "application", label = "London Below" }, responsive = { policy = "SafeArea" } },
		{ nodeId = "panel", className = "Frame", parentNodeId = "root", properties = { Visible = true, Size = { xScale = 1, xOffset = 0, yScale = 1, yOffset = 0 } }, references = {}, tags = { "panel" }, accessibility = {}, responsive = { policy = "Scale" } },
	}, metadata = { phase = 185, authority = "server", immutableAfterPublication = true } }
end

function SelfChecks.run()
	Runtime.reset(); local checks = {}
	local function check(name, ok, detail) checks[#checks + 1] = { name = name, ok = ok, detail = detail } end
	local registered = Runtime.register(validContract("contract.success")); check("valid contract registers", registered.ok, registered)
	local validated = Runtime.validateContract("contract.success"); check("valid contract validates", validated.ok, validated)
	local published = Runtime.publish("contract.success"); check("validated contract publishes", published.ok, published)
	local duplicate = Runtime.register(validContract("contract.success")); check("duplicate contract rejects", not duplicate.ok and duplicate.code == Types.FailureType.DuplicateContract, duplicate)
	local mutation = Runtime.validateContract("contract.success"); check("published contract rejects mutation", not mutation.ok, mutation)
	local retired = Runtime.retire("contract.success"); check("published contract retires", retired.ok, retired)
	local backwards = Runtime.publish("contract.success"); check("retired contract is terminal", not backwards.ok, backwards)
	local forbidden = validContract("contract.forbidden"); forbidden.nodes[2].className = "LocalScript"; Runtime.register(forbidden)
	local forbiddenResult = Runtime.validateContract("contract.forbidden"); check("forbidden class rejects", not forbiddenResult.ok, forbiddenResult)
	local unknown = validContract("contract.unknown"); unknown.nodes[2].properties.NotAProperty = true; Runtime.register(unknown)
	local unknownResult = Runtime.validateContract("contract.unknown"); check("unknown property rejects", not unknownResult.ok, unknownResult)
	local cycle = validContract("contract.cycle"); cycle.nodes[2].parentNodeId = "panel"; Runtime.register(cycle)
	local cycleResult = Runtime.validateContract("contract.cycle"); check("hierarchy cycle rejects", not cycleResult.ok, cycleResult)
	local exact = validContract("contract.extra"); exact.extra = true; Runtime.register(exact)
	local exactResult = Runtime.validateContract("contract.extra"); check("unknown root field rejects", not exactResult.ok, exactResult)
	local snapshotA = Runtime.getSnapshot(); snapshotA.contractIds[1] = "tampered"; local snapshotB = Runtime.getSnapshot(); check("snapshot is isolated", snapshotB.contractIds[1] ~= "tampered", snapshotB.contractIds)
	local diagnostics = Runtime.inspect(); check("posture denies Instance creation", diagnostics.posture.noInstanceCreation == true, diagnostics.posture)
	check("posture denies GUI mutation", diagnostics.posture.noGuiMutation == true, diagnostics.posture)
	check("posture denies networking", diagnostics.posture.noNetworking == true, diagnostics.posture)
	Runtime.shutdown(); local afterShutdown = Runtime.register(validContract("contract.shutdown")); check("shutdown rejects work", not afterShutdown.ok and afterShutdown.code == Types.FailureType.RuntimeShutdown, afterShutdown)
	local failed = 0; for _, item in ipairs(checks) do if not item.ok then failed += 1 end end
	return { ok = failed == 0, total = #checks, passed = #checks - failed, failed = failed, checks = checks }
end

return table.freeze(SelfChecks)
