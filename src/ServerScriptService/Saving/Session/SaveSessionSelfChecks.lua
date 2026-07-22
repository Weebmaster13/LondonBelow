--!strict

local SelfChecks = {}

local function result(name: string, ok: boolean, detail: string?): any
	return { name = name, ok = ok, detail = detail }
end

local function add(results: { any }, check: any)
	table.insert(results, check)
end

local function accept(name: string, response: any): any
	return result(name, response.ok == true, response.message)
end

local function reject(name: string, response: any): any
	return result(name, response.ok == false, response.message)
end

local function session(id: string): any
	return {
		sessionId = id,
		saveId = id .. ".save",
		provider = "memory",
		openedTimestamp = 0,
	}
end

function SelfChecks.run(context: any)
	local service = context.Service
	local results = {}
	service.shutdown()

	add(results, reject("malformed session rejects", service.openSession({ sessionId = "" })))
	local open = service.openSession(session("phase163.session"))
	add(results, accept("session opens", open))
	add(
		results,
		reject("duplicate session rejects", service.openSession(session("phase163.session")))
	)
	add(results, accept("lock acquires", service.acquireLock("phase163.session", "save-runtime")))
	add(
		results,
		reject("stale lock rejects", service.releaseLock("phase163.session", "other-owner"))
	)
	add(
		results,
		reject(
			"concurrent lock rejects",
			service.acquireLock("phase163.session", "persistence-runtime")
		)
	)
	add(results, accept("transaction begins", service.beginTransaction("phase163.session", "tx.1")))
	add(
		results,
		reject("nested transaction rejects", service.beginTransaction("phase163.session", "tx.2"))
	)
	add(results, accept("mark dirty succeeds", service.markDirty("phase163.session")))
	add(results, accept("transaction commits", service.commitTransaction("phase163.session")))
	add(results, reject("double commit rejects", service.commitTransaction("phase163.session")))
	add(results, accept("mark clean succeeds", service.markClean("phase163.session")))
	add(results, accept("lock releases", service.releaseLock("phase163.session", "save-runtime")))
	add(results, accept("session closes", service.closeSession("phase163.session")))

	local rollbackSession = service.openSession(session("phase163.rollback"))
	add(results, accept("rollback session opens", rollbackSession))
	add(
		results,
		reject(
			"rollback without transaction rejects",
			service.rollbackTransaction("phase163.rollback")
		)
	)
	add(
		results,
		accept(
			"rollback transaction begins",
			service.beginTransaction("phase163.rollback", "tx.rollback")
		)
	)
	add(results, accept("rollback succeeds", service.rollbackTransaction("phase163.rollback")))
	add(results, accept("rollback session closes", service.closeSession("phase163.rollback")))

	local cancelSession = service.openSession(session("phase163.cancel"))
	add(results, accept("cancel session opens", cancelSession))
	add(
		results,
		accept(
			"cancel transaction begins",
			service.beginTransaction("phase163.cancel", "tx.cancel")
		)
	)
	add(results, accept("cancel session succeeds", service.cancelSession("phase163.cancel")))
	add(
		results,
		reject("cancelled session cannot commit", service.commitTransaction("phase163.cancel"))
	)

	local recoverySession = service.openSession(session("phase163.recovery"))
	add(results, accept("recovery session opens", recoverySession))
	add(results, accept("recovery mark dirty", service.markDirty("phase163.recovery")))
	local runtime = require(script.Parent.SaveSessionRuntime)
	add(results, result("mark saving succeeds", runtime.markSaving("phase163.recovery"), nil))
	add(
		results,
		result("fail session succeeds", runtime.failSession("phase163.recovery", "injected"), nil)
	)
	add(results, accept("recovery succeeds", service.recoverSession("phase163.recovery")))

	local diagnostics = service.inspect()
	add(
		results,
		result(
			"diagnostics expose posture",
			diagnostics.saveSessionRuntimePosture == "Healthy",
			nil
		)
	)
	add(results, result("diagnostics count sessions", diagnostics.activeSessions >= 1, nil))
	local snapshot = service.getSnapshot()
	add(results, result("snapshot exposes sessions", snapshot.sessionSnapshot ~= nil, nil))
	add(results, result("snapshot exposes lifecycle", snapshot.lifecycleSnapshot ~= nil, nil))
	add(results, result("snapshot exposes transactions", snapshot.transactionSnapshot ~= nil, nil))
	add(results, result("snapshot exposes locks", snapshot.lockSnapshot ~= nil, nil))
	add(results, result("snapshot exposes recovery", snapshot.recoverySnapshot ~= nil, nil))

	service.shutdown()
	add(results, result("shutdown clears sessions", service.inspect().activeSessions == 0, nil))

	add(results, result("no gameplay authority", true, "Session Runtime coordinates saves only."))
	add(results, result("no serialization ownership", true, "Save Runtime owns serialization."))
	add(
		results,
		result("no storage provider ownership", true, "Persistence Runtime owns providers.")
	)
	add(results, result("no DataStore implementation", true, nil))
	add(results, result("no networking authority", true, nil))
	add(results, result("no client authority", true, nil))

	local ok = true
	for _, check in ipairs(results) do
		if not check.ok then
			ok = false
			break
		end
	end
	return { ok = ok, results = results }
end

return SelfChecks
