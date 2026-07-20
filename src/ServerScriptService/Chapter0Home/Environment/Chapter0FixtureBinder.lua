--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local EnvironmentalSerialization =
	require(ServerScriptService.Interaction.Environmental.EnvironmentalSerialization)

local Types = require(script.Parent.Chapter0EnvironmentalTypes)

local Binder = {}

local function defaultResolver()
	return nil
end

function Binder.plan(fixtures: { any }, resolver: ((string) -> any?)?)
	local instanceResolver = resolver or defaultResolver
	local bindings = {}
	local warnings = {}
	local failures = {}

	for _, fixture in ipairs(fixtures) do
		local metadata = fixture.authoringMetadata or {}
		local instanceId = metadata.authoredInstanceId
		local required = metadata.authoredInstanceRequired == true
		local resolved = instanceResolver(instanceId)

		if required and resolved == nil then
			table.insert(failures, {
				fixtureId = fixture.id,
				code = Types.ResultCode.MissingAuthoredInstance,
				message = "required authored instance is unavailable",
			})
		elseif resolved == nil then
			table.insert(warnings, {
				fixtureId = fixture.id,
				code = Types.ResultCode.MissingAuthoredInstance,
				message = "optional authored instance is unavailable",
			})
		end

		table.insert(bindings, {
			fixtureId = fixture.id,
			authoredInstanceId = instanceId,
			required = required,
			resolved = resolved ~= nil,
			status = if resolved ~= nil
				then Types.BindingStatus.Bound
				elseif required then Types.BindingStatus.Blocked
				else Types.BindingStatus.Unbound,
		})
	end

	return EnvironmentalSerialization.deepCopy({
		ok = #failures == 0,
		bindings = bindings,
		warnings = warnings,
		failures = failures,
	})
end

return Binder
