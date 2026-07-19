--!strict

local Serialization = require(script.Parent.Serialization)
local State = require(script.Parent.State)
local Types = require(script.Parent.Types)
local Validation = require(script.Parent.Validation)

local RuntimeSession = {}

local function merge(defaults: any, overrides: any): any
	local session = Serialization.deepCopy(defaults)
	if type(overrides) == "table" then
		for key, value in pairs(overrides) do
			session[key] = Serialization.deepCopy(value)
		end
	end
	return session
end

function RuntimeSession.import(sessionOverride: any?): (boolean, string?, any?)
	local session = merge(Types.DefaultSession, sessionOverride)
	local ok, reason = Validation.session(session)
	if not ok then
		return false, reason, nil
	end
	State.setSession(session)
	State.recordEvent("Session Imported", "VERIFIED", session.sessionId)
	return true, nil, session
end

return RuntimeSession
