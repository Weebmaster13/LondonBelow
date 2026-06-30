local Logger = {}

local LEVELS = {
	debug = "DEBUG",
	info = "INFO",
	warn = "WARN",
	error = "ERROR",
}

local function formatMessage(scopeName, level, message, ...)
	local ok, formatted = pcall(string.format, tostring(message), ...)

	if not ok then
		formatted = tostring(message)
	end

	return string.format("[LondonBelow][%s][%s] %s", scopeName, level, formatted)
end

local function write(scopeName, level, message, ...)
	local output = formatMessage(scopeName, level, message, ...)

	if level == LEVELS.warn or level == LEVELS.error then
		warn(output)
	else
		print(output)
	end
end

function Logger.scope(scopeName)
	local resolvedScope = tostring(scopeName or "Global")

	return {
		debug = function(message, ...)
			write(resolvedScope, LEVELS.debug, message, ...)
		end,
		info = function(message, ...)
			write(resolvedScope, LEVELS.info, message, ...)
		end,
		warn = function(message, ...)
			write(resolvedScope, LEVELS.warn, message, ...)
		end,
		error = function(message, ...)
			write(resolvedScope, LEVELS.error, message, ...)
		end,
	}
end

return Logger
