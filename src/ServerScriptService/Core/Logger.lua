--!strict
--[[
	Logger is the London Engine observability layer.

	It provides scoped logs, filtering, context payloads, timers, startup timing,
	memory samples, buffering, and panic mode. It intentionally keeps output
	human-readable in Roblox Studio while preserving structured entries for
	future export.
]]

local Logger = {}

export type Level = "DEBUG" | "INFO" | "SUCCESS" | "WARN" | "ERROR" | "FATAL"
export type Context = { [string]: any }
export type LogEntry = {
	timestamp: string,
	elapsed: number,
	level: Level,
	system: string,
	category: string,
	message: string,
	context: Context?,
	memoryKb: number?,
}

local LEVEL_WEIGHT: { [Level]: number } = {
	DEBUG = 10,
	INFO = 20,
	SUCCESS = 25,
	WARN = 30,
	ERROR = 40,
	FATAL = 50,
}

local LEVEL_PREFIX: { [Level]: string } = {
	DEBUG = "[DEBUG]",
	INFO = "[INFO]",
	SUCCESS = "[SUCCESS]",
	WARN = "[WARN]",
	ERROR = "[ERROR]",
	FATAL = "[FATAL]",
}

local DEFAULT_CATEGORY = "General"
local MAX_BUFFER_SIZE = 500

local engineStartedAt = os.clock()
local debugEnabled = false
local minimumLevel: Level = "DEBUG"
local panicMode = false
local buffer: { LogEntry } = {}
local disabledCategories: { [string]: boolean } = {}
local disabledSystems: { [string]: boolean } = {}
local activeTimers: { [string]: { system: string, category: string, startedAt: number } } = {}

local function nowIso(): string
	return DateTime.now():ToIsoDate()
end

local function normalizeLevel(level: string): Level
	local upper = string.upper(level)

	if LEVEL_WEIGHT[upper :: Level] == nil then
		return "INFO"
	end

	return upper :: Level
end

local function safeFormat(message: string, ...: any): string
	local args = { ... }

	if #args == 0 then
		return tostring(message)
	end

	local ok, formatted = pcall(string.format, tostring(message), table.unpack(args))

	if ok then
		return formatted
	end

	return tostring(message)
end

local function serializeValue(value: any, depth: number): string
	if depth > 2 then
		return "<max-depth>"
	end

	local valueType = typeof(value)

	if valueType ~= "table" then
		return tostring(value)
	end

	local parts = {}

	for key, child in pairs(value :: Context) do
		table.insert(parts, string.format("%s=%s", tostring(key), serializeValue(child, depth + 1)))
	end

	table.sort(parts)

	return "{" .. table.concat(parts, ", ") .. "}"
end

local function contextToString(context: Context?): string
	if context == nil then
		return ""
	end

	return " " .. serializeValue(context, 0)
end

local function shouldWrite(level: Level, systemName: string, category: string): boolean
	if panicMode and level ~= "FATAL" then
		return false
	end

	if level == "DEBUG" and not debugEnabled then
		return false
	end

	if LEVEL_WEIGHT[level] < LEVEL_WEIGHT[minimumLevel] then
		return false
	end

	if disabledSystems[systemName] then
		return false
	end

	if disabledCategories[category] then
		return false
	end

	return true
end

local function appendBuffer(entry: LogEntry)
	table.insert(buffer, entry)

	if #buffer > MAX_BUFFER_SIZE then
		table.remove(buffer, 1)
	end
end

local function write(
	level: Level,
	systemName: string,
	category: string,
	message: string,
	context: Context?
)
	local entry: LogEntry = {
		timestamp = nowIso(),
		elapsed = os.clock() - engineStartedAt,
		level = level,
		system = systemName,
		category = category,
		message = message,
		context = context,
		memoryKb = collectgarbage("count"),
	}

	appendBuffer(entry)

	if not shouldWrite(level, systemName, category) then
		return
	end

	local output = string.format(
		"%s [LondonBelow][%.3fs][%s][%s] %s%s",
		LEVEL_PREFIX[level],
		entry.elapsed,
		systemName,
		category,
		message,
		contextToString(context)
	)

	if level == "WARN" or level == "ERROR" or level == "FATAL" then
		warn(output)
	else
		print(output)
	end
end

local function scoped(systemName: string, defaultCategory: string?)
	local resolvedSystem = tostring(systemName)
	local resolvedCategory = defaultCategory or DEFAULT_CATEGORY

	return {
		debug = function(message: string, ...: any)
			write("DEBUG", resolvedSystem, resolvedCategory, safeFormat(message, ...), nil)
		end,
		info = function(message: string, ...: any)
			write("INFO", resolvedSystem, resolvedCategory, safeFormat(message, ...), nil)
		end,
		success = function(message: string, ...: any)
			write("SUCCESS", resolvedSystem, resolvedCategory, safeFormat(message, ...), nil)
		end,
		warn = function(message: string, ...: any)
			write("WARN", resolvedSystem, resolvedCategory, safeFormat(message, ...), nil)
		end,
		error = function(message: string, ...: any)
			write("ERROR", resolvedSystem, resolvedCategory, safeFormat(message, ...), nil)
		end,
		fatal = function(message: string, ...: any)
			write("FATAL", resolvedSystem, resolvedCategory, safeFormat(message, ...), nil)
		end,
		withContext = function(level: Level, message: string, context: Context?)
			write(
				normalizeLevel(level),
				resolvedSystem,
				resolvedCategory,
				tostring(message),
				context
			)
		end,
		category = function(category: string)
			return scoped(resolvedSystem, category)
		end,
		startTimer = function(name: string)
			Logger.startTimer(resolvedSystem .. ":" .. name, resolvedSystem, resolvedCategory)
		end,
		endTimer = function(name: string, context: Context?)
			return Logger.endTimer(resolvedSystem .. ":" .. name, context)
		end,
	}
end

function Logger.scope(systemName: string, defaultCategory: string?)
	assert(type(systemName) == "string", "systemName must be a string")

	return scoped(systemName, defaultCategory)
end

function Logger.write(
	level: Level,
	systemName: string,
	category: string,
	message: string,
	context: Context?
)
	write(normalizeLevel(level), systemName, category, message, context)
end

function Logger.setDebugEnabled(enabled: boolean)
	debugEnabled = enabled
end

function Logger.isDebugEnabled(): boolean
	return debugEnabled
end

function Logger.setMinimumLevel(level: Level)
	minimumLevel = normalizeLevel(level)
end

function Logger.disableCategory(category: string)
	disabledCategories[category] = true
end

function Logger.enableCategory(category: string)
	disabledCategories[category] = nil
end

function Logger.disableSystem(systemName: string)
	disabledSystems[systemName] = true
end

function Logger.enableSystem(systemName: string)
	disabledSystems[systemName] = nil
end

function Logger.startTimer(timerName: string, systemName: string?, category: string?)
	assert(type(timerName) == "string", "timerName must be a string")

	activeTimers[timerName] = {
		system = systemName or "Timer",
		category = category or "Performance",
		startedAt = os.clock(),
	}
end

function Logger.endTimer(timerName: string, context: Context?): number?
	local timer = activeTimers[timerName]

	if timer == nil then
		write(
			"WARN",
			"Logger",
			"Performance",
			"Timer '%s' was not started",
			{ timerName = timerName }
		)
		return nil
	end

	activeTimers[timerName] = nil

	local duration = os.clock() - timer.startedAt
	local timerContext: Context = context or {}
	timerContext.durationMs = math.floor(duration * 1000)

	write(
		"DEBUG",
		timer.system,
		timer.category,
		string.format("Timer '%s' completed", timerName),
		timerContext
	)

	return duration
end

function Logger.captureMemory(systemName: string, category: string?): number
	local memoryKb = collectgarbage("count")

	write("DEBUG", systemName, category or "Memory", "Memory snapshot captured", {
		memoryKb = math.floor(memoryKb),
	})

	return memoryKb
end

function Logger.getBuffer(): { LogEntry }
	return table.clone(buffer)
end

function Logger.clearBuffer()
	table.clear(buffer)
end

function Logger.enterPanicMode(reason: string?)
	panicMode = true
	write("FATAL", "Logger", "Panic", reason or "Global panic mode enabled", nil)
end

function Logger.exitPanicMode()
	panicMode = false
	write("WARN", "Logger", "Panic", "Global panic mode disabled", nil)
end

function Logger.isInPanicMode(): boolean
	return panicMode
end

function Logger.getStartupDuration(): number
	return os.clock() - engineStartedAt
end

function Logger.validate(): (boolean, string?)
	if LEVEL_WEIGHT[minimumLevel] == nil then
		return false, "Logger minimum level is invalid"
	end

	return true, nil
end

return Logger
