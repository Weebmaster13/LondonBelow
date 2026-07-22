--!strict

local Types = require(script.Parent.SaveSessionTypes)

local Validation = {}

local function validId(value: any): boolean
	return type(value) == "string"
		and value ~= ""
		and #value <= Types.Limits.MaxStringLength
		and string.match(value, "^[%w%._%-:]+$") ~= nil
end

function Validation.id(value: any): boolean
	return validId(value)
end

function Validation.state(value: any): boolean
	for _, state in pairs(Types.State) do
		if value == state then
			return true
		end
	end
	return false
end

function Validation.session(record: any): (boolean, string?)
	if type(record) ~= "table" then
		return false, "session must be a table"
	end
	if not validId(record.sessionId) or not validId(record.saveId) then
		return false, "session identity is invalid"
	end
	if record.provider ~= nil and not validId(record.provider) then
		return false, "session provider is invalid"
	end
	if record.state ~= nil and not Validation.state(record.state) then
		return false, "session state is unsupported"
	end
	return true, nil
end

function Validation.transition(fromState: string, toState: string): (boolean, string?)
	if not Validation.state(fromState) or not Validation.state(toState) then
		return false, "transition state is unsupported"
	end
	local allowed = {
		New = { Opening = true, Cancelled = true },
		Opening = { Active = true, Failed = true, Cancelled = true },
		Active = { Dirty = true, Loading = true, Closing = true, Cancelled = true },
		Dirty = { Saving = true, Closing = true, Cancelled = true },
		Saving = { Active = true, Failed = true, Cancelled = true },
		Loading = { Active = true, Failed = true, Cancelled = true },
		Failed = { Recovering = true, Closing = true },
		Recovering = { Active = true, Failed = true, Closing = true },
		Closing = { Closed = true, Failed = true },
		Closed = {},
		Cancelled = {},
	}
	if allowed[fromState][toState] ~= true then
		return false, "invalid session transition"
	end
	return true, nil
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativeSaveSessionRuntime" then
		return false, "Save Session Runtime mode changed"
	end
	return true, nil
end

return Validation
