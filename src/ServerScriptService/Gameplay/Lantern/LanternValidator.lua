--!strict

local Config = require(script.Parent.LanternConfig)
local Types = require(script.Parent.LanternTypes)

local LanternValidator = {}

type ToggleRequest = Types.ToggleRequest
type LanternStatus = Types.LanternStatus

function LanternValidator.sanitizeToggle(payload: any): ToggleRequest?
	if type(payload) ~= "table" then
		return nil
	end

	local request: ToggleRequest = {
		requestId = if type(payload.requestId) == "string" then payload.requestId else nil,
		on = if type(payload.on) == "boolean" then payload.on else nil,
		equipped = if type(payload.equipped) == "boolean" then payload.equipped else nil,
		zoneId = nil,
		zoneKind = nil,
		metadata = {},
	}

	if request.on == nil and request.equipped == nil then
		return nil
	end

	return request
end

function LanternValidator.canToggle(status: LanternStatus, now: number): (boolean, string)
	if now - status.lastToggleAt < Config.MinToggleIntervalSeconds then
		return false, Types.ResultCode.RateLimited
	end

	if status.battery <= 0 then
		return false, Types.ResultCode.NotEquipped
	end

	return true, Types.ResultCode.Ok
end

function LanternValidator.validate(): (boolean, string?)
	if Config.LowBatteryThreshold <= 0 or Config.LowBatteryThreshold >= 1 then
		return false, "LowBatteryThreshold must be between 0 and 1"
	end

	if Config.OveruseThreshold <= 0 or Config.OveruseThreshold > 1 then
		return false, "OveruseThreshold must be between 0 and 1"
	end

	return true, nil
end

return LanternValidator
