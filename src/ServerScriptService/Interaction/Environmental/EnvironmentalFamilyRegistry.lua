--!strict

local BinaryMechanismFamily = require(script.Parent.Families.BinaryMechanismFamily)
local InspectableObjectFamily = require(script.Parent.Families.InspectableObjectFamily)
local MomentaryActuatorFamily = require(script.Parent.Families.MomentaryActuatorFamily)
local Types = require(script.Parent.EnvironmentalTypes)

local Registry = {}

local families = {
	[Types.Family.BinaryMechanism] = BinaryMechanismFamily,
	[Types.Family.InspectableObject] = InspectableObjectFamily,
	[Types.Family.MomentaryActuator] = MomentaryActuatorFamily,
}

function Registry.get(familyId: string): any?
	return families[familyId]
end

function Registry.inspect()
	local names = {}
	for name in pairs(families) do
		table.insert(names, name)
	end
	table.sort(names)
	return {
		count = #names,
		families = names,
	}
end

return Registry
