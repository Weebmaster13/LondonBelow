--!strict

local Serialization = require(script.Parent.SaveSessionSerialization)

local Snapshots = {}

function Snapshots.capture(runtime: any)
	local inspected = runtime.inspect()
	return Serialization.deepCopy({
		sessionSnapshot = inspected.registry.sessions,
		lifecycleSnapshot = inspected.lifecycle.lifecycleSnapshot,
		transactionSnapshot = inspected.transactions.transactionSnapshot,
		lockSnapshot = inspected.locks.lockSnapshot,
		recoverySnapshot = inspected.recovery.recoverySnapshot,
		evidence = inspected.evidence,
	})
end

return Snapshots
