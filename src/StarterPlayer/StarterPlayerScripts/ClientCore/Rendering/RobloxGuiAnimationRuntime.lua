--!strict

local TweenService = game:GetService("TweenService")

local MotionPreferences = require(script.Parent.RobloxGuiMotionPreferences)
local Registry = require(script.Parent.RobloxGuiInstanceRegistry)
local Types = require(script.Parent.RobloxGuiAnimationTypes)
local Validator = require(script.Parent.RobloxGuiAnimationValidator)

local Runtime = {}
local shutdown = false
local generation = 0
local sequence = 0
local active = {}
local propertyOwners = {}
local audit = {}
local failures = {}
local counters = { requests = 0, started = 0, completed = 0, cancelled = 0, superseded = 0, immediate = 0, validationFailures = 0, staleRejected = 0, restored = 0, reconcileCancels = 0 }

local function append(target: { any }, value: any, limit: number)
	if #target >= limit then table.remove(target, 1) end
	target[#target + 1] = value
end

local function record(kind: string, detail: any?)
	sequence += 1
	append(audit, table.freeze({ sequence = sequence, generation = generation, kind = kind, detail = detail }), Types.Limits.maxAudit)
end

local function fail(code: string, detail: any?)
	local result = table.freeze({ ok = false, code = code, detail = detail })
	append(failures, result, Types.Limits.maxFailures)
	record("Failure", result)
	return result
end

local function release(recordData: any)
	if recordData.connection then recordData.connection:Disconnect() recordData.connection = nil end
	for _, propertyName in ipairs(recordData.properties) do
		local key = recordData.nodeId .. ":" .. propertyName
		if propertyOwners[key] == recordData.animationId then propertyOwners[key] = nil end
	end
	active[recordData.animationId] = nil
end

local function restore(recordData: any)
	if not recordData.restoreOnCancel then return end
	for propertyName, value in pairs(recordData.original) do
		pcall(function() (recordData.instance :: any)[propertyName] = value end)
	end
	counters.restored += 1
end

local function cancelRecord(recordData: any, reason: string, shouldRestore: boolean)
	if recordData.connection then recordData.connection:Disconnect() recordData.connection = nil end
	pcall(function() recordData.tween:Cancel() end)
	if shouldRestore then restore(recordData) end
	release(recordData)
	counters.cancelled += 1
	recordData.state = Types.State.Cancelled
	record("Cancelled", { animationId = recordData.animationId, reason = reason })
end

local function countActive(): number
	local count = 0
	for _ in pairs(active) do count += 1 end
	return count
end

function Runtime.play(contract: any)
	counters.requests += 1
	if shutdown then return fail(Types.FailureType.RuntimeShutdown) end
	local tree = Registry.get()
	if not tree or type(contract) ~= "table" then return fail(Types.FailureType.InvalidTarget) end
	if contract.targetRevision ~= tree.revision then counters.staleRejected += 1 return fail(Types.FailureType.InvalidRevision, { active = tree.revision, requested = contract.targetRevision }) end
	local instance = tree.instances and tree.instances[contract.targetNodeId]
	if not instance or instance:GetAttribute("LondonEngineContractId") ~= tree.contractId then return fail(Types.FailureType.InvalidTarget) end
	local valid, reason, goals = Validator.validate(contract, instance)
	if not valid or not goals then counters.validationFailures += 1 return fail(reason or Types.FailureType.InvalidContract) end
	if active[contract.animationId] then return fail(Types.FailureType.DuplicateAnimation) end
	if countActive() >= Types.Limits.maxActiveAnimations then return fail(Types.FailureType.BudgetExceeded) end
	local properties = {}
	local original = {}
	local supersededOwners = {}
	for propertyName in pairs(goals) do
		properties[#properties + 1] = propertyName
		local key = contract.targetNodeId .. ":" .. propertyName
		local owner = propertyOwners[key]
		if owner and active[owner] then supersededOwners[owner] = true end
		local ok, value = pcall(function() return (instance :: any)[propertyName] end)
		if not ok then return fail(Types.FailureType.InvalidGoal, propertyName) end
		original[propertyName] = value
	end
	table.sort(properties)
	local ownerIds = {}
	for owner in pairs(supersededOwners) do ownerIds[#ownerIds + 1] = owner end
	table.sort(ownerIds)
	for _, owner in ipairs(ownerIds) do
		if active[owner] then counters.superseded += 1 cancelRecord(active[owner], "Superseded", false) end
	end
	local preference = MotionPreferences.get()
	local duration = contract.duration
	local delayTime = contract.delay
	local repeatCount = contract.repeatCount
	local reverses = contract.reverses
	if preference == Types.MotionPreference.Reduce then
		duration = math.min(duration, Types.Limits.reducedDurationSeconds)
		delayTime = 0
		repeatCount = 0
		reverses = false
	elseif preference == Types.MotionPreference.Remove then
		if contract.motionEssential then
			duration = math.min(duration, Types.Limits.essentialRemovedDurationSeconds)
			delayTime = 0
			repeatCount = 0
			reverses = false
		else
			local applied = {}
			for _, propertyName in ipairs(properties) do
				local ok = pcall(function()
					(instance :: any)[propertyName] = goals[propertyName]
				end)
				if not ok then
					for index = #applied, 1, -1 do
						local appliedProperty = applied[index]
						pcall(function()
							(instance :: any)[appliedProperty] = original[appliedProperty]
						end)
					end
					return fail(Types.FailureType.ImmediateApplyFailed, propertyName)
				end
				applied[#applied + 1] = propertyName
			end
			counters.immediate += 1
			counters.completed += 1
			record("CompletedImmediately", { animationId = contract.animationId })
			return { ok = true, animationId = contract.animationId, immediate = true }
		end
	end
	local tweenInfo = TweenInfo.new(duration, (Enum.EasingStyle :: any)[contract.easingStyle], (Enum.EasingDirection :: any)[contract.easingDirection], repeatCount, reverses, delayTime)
	local okTween, tweenOrError = pcall(function() return TweenService:Create(instance, tweenInfo, goals) end)
	if not okTween then return fail(Types.FailureType.TweenCreationFailed, tostring(tweenOrError)) end
	local recordData = { animationId = contract.animationId, nodeId = contract.targetNodeId, revision = contract.targetRevision, generation = generation, instance = instance, tween = tweenOrError, properties = properties, original = original, restoreOnCancel = contract.restoreOnCancel, state = Types.State.Playing, connection = nil }
	for _, propertyName in ipairs(properties) do propertyOwners[contract.targetNodeId .. ":" .. propertyName] = contract.animationId end
	active[contract.animationId] = recordData
	recordData.connection = tweenOrError.Completed:Connect(function(playbackState)
		if active[contract.animationId] ~= recordData or recordData.generation ~= generation then return end
		release(recordData)
		recordData.state = playbackState == Enum.PlaybackState.Completed and Types.State.Completed or Types.State.Cancelled
		if recordData.state == Types.State.Completed then counters.completed += 1 else counters.cancelled += 1 end
		record(recordData.state, { animationId = contract.animationId })
	end)
	counters.started += 1
	record("Started", { animationId = contract.animationId, nodeId = contract.targetNodeId, duration = duration, preference = preference })
	tweenOrError:Play()
	return { ok = true, animationId = contract.animationId, immediate = false, duration = duration, generation = generation }
end

function Runtime.cancel(animationId: any, restoreValues: boolean?)
	if shutdown then return fail(Types.FailureType.RuntimeShutdown) end
	if type(animationId) ~= "string" or not active[animationId] then return fail(Types.FailureType.UnknownAnimation) end
	cancelRecord(active[animationId], "Requested", restoreValues ~= false)
	return { ok = true, animationId = animationId }
end

function Runtime.cancelAll(reason: string)
	local records = {}
	for _, recordData in pairs(active) do records[#records + 1] = recordData end
	table.sort(records, function(a, b) return a.animationId < b.animationId end)
	for _, recordData in ipairs(records) do cancelRecord(recordData, reason, false) end
end

function Runtime.reconcile()
	Runtime.cancelAll("VisualReconciliation")
	generation += 1
	counters.reconcileCancels += 1
	record("Reconciled")
	return { ok = true, generation = generation }
end

function Runtime.setMotionPreference(value: any)
	local ok, reason = MotionPreferences.set(value)
	if not ok then return fail(reason or Types.FailureType.InvalidMotionPreference) end
	record("MotionPreferenceChanged", { preference = value })
	return { ok = true, preference = value }
end

function Runtime.inspect()
	local ids = {}
	for animationId in pairs(active) do ids[#ids + 1] = animationId end
	table.sort(ids)
	return { runtimeVersion = Types.RuntimeVersion, generation = generation, state = shutdown and Types.State.Shutdown or (#ids > 0 and Types.State.Playing or Types.State.Idle), motionPreference = MotionPreferences.get(), activeAnimationIds = ids, activeCount = #ids, counters = table.clone(counters), failures = table.clone(failures), posture = { clientPresentationOnly = true, runtimeOwnedGuiOnly = true, noGameplayAuthority = true, noNetworking = true, noPersistence = true, noWorkspaceMutation = true, noAnalytics = true, noTelemetry = true } }
end

function Runtime.getSnapshot() return { diagnostics = Runtime.inspect(), audit = table.clone(audit) } end

function Runtime.shutdown()
	if shutdown then return end
	Runtime.cancelAll("Shutdown")
	MotionPreferences.reset()
	shutdown = true
	generation += 1
	record("Shutdown")
end

return Runtime
