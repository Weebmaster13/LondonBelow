--!strict
--[[
	Scheduler centralizes asynchronous work for London Engine.

	It supports delays, intervals, RunService phases, deferred queues,
	cancellation, groups, tags, profiling, and cleanup. Gameplay systems should
	use Scheduler instead of scattering task.delay/task.spawn loops everywhere.
]]

local RunService = game:GetService("RunService")

local Logger = require(script.Parent.Logger)

local Scheduler = {}

export type TaskHandle = {
	id: number,
	name: string,
	group: string?,
	tags: { [string]: boolean },
	cancelled: boolean,
	startedAt: number,
	runCount: number,
	totalDuration: number,
	cancel: (self: TaskHandle) -> (),
}

local log = Logger.scope("Scheduler")
local nextTaskId = 0
local handles: { [number]: TaskHandle } = {}
local connections: { [number]: RBXScriptConnection } = {}
local frameBudgetMs = 4
local deferredQueue: { () -> () } = {}
local profilingEnabled = true

local function createHandle(name: string, group: string?, tags: { string }?): TaskHandle
	nextTaskId += 1

	local tagMap = {}

	for _, tag in ipairs(tags or {}) do
		tagMap[tag] = true
	end

	local handle = {
		id = nextTaskId,
		name = name,
		group = group,
		tags = tagMap,
		cancelled = false,
		startedAt = os.clock(),
		runCount = 0,
		totalDuration = 0,
	} :: TaskHandle

	function handle:cancel()
		Scheduler.cancel(self)
	end

	handles[handle.id] = handle

	return handle
end

local function profile(handle: TaskHandle, callback: (...any) -> (), ...: any)
	if handle.cancelled then
		return
	end

	local startedAt = os.clock()
	local ok, err = pcall(callback, ...)
	local duration = os.clock() - startedAt

	handle.runCount += 1
	handle.totalDuration += duration

	if profilingEnabled and duration * 1000 > frameBudgetMs then
		log.withContext("WARN", "Scheduled task exceeded frame budget", {
			taskId = handle.id,
			name = handle.name,
			durationMs = math.floor(duration * 1000),
			frameBudgetMs = frameBudgetMs,
		})
	end

	if not ok then
		log.withContext("ERROR", "Scheduled task failed", {
			taskId = handle.id,
			name = handle.name,
			error = tostring(err),
		})
	end
end

function Scheduler.delay(
	seconds: number,
	callback: () -> (),
	name: string?,
	group: string?,
	tags: { string }?
): TaskHandle
	assert(type(seconds) == "number" and seconds >= 0, "seconds must be a non-negative number")
	assert(type(callback) == "function", "callback must be a function")

	local handle = createHandle(name or "Delay", group, tags)

	task.delay(seconds, function()
		if handle.cancelled then
			return
		end

		profile(handle, callback)
		handles[handle.id] = nil
	end)

	return handle
end

function Scheduler.defer(
	callback: () -> (),
	name: string?,
	group: string?,
	tags: { string }?
): TaskHandle
	assert(type(callback) == "function", "callback must be a function")

	local handle = createHandle(name or "Deferred", group, tags)

	table.insert(deferredQueue, function()
		if handle.cancelled then
			return
		end

		profile(handle, callback)
		handles[handle.id] = nil
	end)

	task.defer(function()
		Scheduler.flushDeferred()
	end)

	return handle
end

function Scheduler.interval(
	seconds: number,
	callback: () -> (),
	name: string?,
	group: string?,
	tags: { string }?
): TaskHandle
	assert(type(seconds) == "number" and seconds > 0, "seconds must be a positive number")
	assert(type(callback) == "function", "callback must be a function")

	local handle = createHandle(name or "Interval", group, tags)

	task.spawn(function()
		while not handle.cancelled do
			task.wait(seconds)

			if not handle.cancelled then
				profile(handle, callback)
			end
		end
	end)

	return handle
end

local function connectRunService(
	signalName: string,
	signal: RBXScriptSignal,
	callback: (number) -> (),
	name: string?,
	group: string?,
	tags: { string }?
): TaskHandle
	local handle = createHandle(name or signalName, group, tags)

	local connection = signal:Connect(function(deltaTime)
		profile(handle, callback, deltaTime)
	end)

	connections[handle.id] = connection

	return handle
end

function Scheduler.heartbeat(
	callback: (number) -> (),
	name: string?,
	group: string?,
	tags: { string }?
): TaskHandle
	return connectRunService("Heartbeat", RunService.Heartbeat, callback, name, group, tags)
end

function Scheduler.stepped(
	callback: (number) -> (),
	name: string?,
	group: string?,
	tags: { string }?
): TaskHandle
	return connectRunService("Stepped", RunService.Stepped, callback, name, group, tags)
end

function Scheduler.render(
	callback: (number) -> (),
	name: string?,
	group: string?,
	tags: { string }?
): TaskHandle?
	if not RunService:IsClient() then
		log.warn("Render scheduling requested on server; request ignored")
		return nil
	end

	return connectRunService("Render", RunService.RenderStepped, callback, name, group, tags)
end

function Scheduler.flushDeferred(limit: number?)
	local budget = limit or #deferredQueue
	local processed = 0

	while processed < budget and #deferredQueue > 0 do
		processed += 1
		local callback = table.remove(deferredQueue, 1)
		callback()
	end
end

function Scheduler.cancel(handleOrId: TaskHandle | number): boolean
	local id = if type(handleOrId) == "number" then handleOrId else handleOrId.id
	local handle = handles[id]

	if handle == nil then
		return false
	end

	handle.cancelled = true
	handles[id] = nil

	local connection = connections[id]

	if connection ~= nil then
		connection:Disconnect()
		connections[id] = nil
	end

	return true
end

function Scheduler.cancelGroup(groupName: string): number
	local cancelled = 0

	for id, handle in pairs(table.clone(handles)) do
		if handle.group == groupName and Scheduler.cancel(id) then
			cancelled += 1
		end
	end

	return cancelled
end

function Scheduler.cancelTag(tagName: string): number
	local cancelled = 0

	for id, handle in pairs(table.clone(handles)) do
		if handle.tags[tagName] and Scheduler.cancel(id) then
			cancelled += 1
		end
	end

	return cancelled
end

function Scheduler.setFrameBudget(milliseconds: number)
	assert(type(milliseconds) == "number" and milliseconds > 0, "milliseconds must be positive")

	frameBudgetMs = milliseconds
end

function Scheduler.setProfilingEnabled(enabled: boolean)
	profilingEnabled = enabled
end

function Scheduler.inspect()
	local tasks = {}

	for id, handle in pairs(handles) do
		tasks[id] = {
			name = handle.name,
			group = handle.group,
			runCount = handle.runCount,
			totalDuration = handle.totalDuration,
			averageDuration = if handle.runCount > 0
				then handle.totalDuration / handle.runCount
				else 0,
			age = os.clock() - handle.startedAt,
		}
	end

	return {
		frameBudgetMs = frameBudgetMs,
		deferredQueue = #deferredQueue,
		activeTasks = Scheduler.count(),
		tasks = tasks,
	}
end

function Scheduler.count(): number
	local count = 0

	for _ in pairs(handles) do
		count += 1
	end

	return count
end

function Scheduler.cleanup()
	for id in pairs(table.clone(handles)) do
		Scheduler.cancel(id)
	end

	table.clear(deferredQueue)
end

function Scheduler.validate(): (boolean, string?)
	if frameBudgetMs <= 0 then
		return false, "Scheduler frame budget must be positive"
	end

	return true, nil
end

return Scheduler
