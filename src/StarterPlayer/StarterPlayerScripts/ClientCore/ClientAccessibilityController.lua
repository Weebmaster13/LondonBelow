--!strict
--[[
	Client accessibility settings facade.

	Owns local presentation preferences that may later be backed by settings
	persistence. It does not override server authority or gameplay validation.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerExperienceConfig = require(ReplicatedStorage.Config.PlayerExperienceConfig)

local ClientAccessibilityController = {}

local settings = table.clone(PlayerExperienceConfig.Accessibility)

function ClientAccessibilityController.apply(payload: any)
	if type(payload) ~= "table" then
		return
	end

	for key, value in pairs(payload) do
		settings[key] = value
	end
end

function ClientAccessibilityController.get()
	return table.clone(settings)
end

return ClientAccessibilityController
