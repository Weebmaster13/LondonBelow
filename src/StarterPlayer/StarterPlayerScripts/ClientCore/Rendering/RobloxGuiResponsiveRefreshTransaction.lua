--!strict

local Transaction = {}

local function restore(applied: { any }): boolean
	local rollbackOk = true
	for index = #applied, 1, -1 do
		local change = applied[index]
		local ok = pcall(function()
			if change.kind == "attribute" then
				change.instance:SetAttribute(change.name, change.previous)
			else
				(change.instance :: any)[change.name] = change.previous
			end
		end)
		rollbackOk = rollbackOk and ok
	end
	return rollbackOk
end

function Transaction.apply(plans: { any }, shouldFail: ((string, number) -> boolean)?)
	local applied = {}
	local sequence = 0
	for _, plan in ipairs(plans) do
		local attributeNames = {}
		for name in pairs(plan.attributes) do
			attributeNames[#attributeNames + 1] = name
		end
		table.sort(attributeNames)
		for _, name in ipairs(attributeNames) do
			sequence += 1
			local previous = plan.instance:GetAttribute(name)
			local ok = not (shouldFail and shouldFail("attribute", sequence))
				and pcall(function()
					plan.instance:SetAttribute(name, plan.attributes[name])
				end)
			if not ok then
				return false, restore(applied)
			end
			applied[#applied + 1] =
				{ kind = "attribute", instance = plan.instance, name = name, previous = previous }
		end
		local propertyNames = {}
		for name in pairs(plan.properties) do
			propertyNames[#propertyNames + 1] = name
		end
		table.sort(propertyNames)
		for _, name in ipairs(propertyNames) do
			sequence += 1
			local readOk, previous = pcall(function()
				return (plan.instance :: any)[name]
			end)
			local writeOk = readOk
				and not (shouldFail and shouldFail("property", sequence))
				and pcall(function()
					(plan.instance :: any)[name] = plan.properties[name]
				end)
			if not writeOk then
				return false, restore(applied)
			end
			applied[#applied + 1] =
				{ kind = "property", instance = plan.instance, name = name, previous = previous }
		end
	end
	return true, true
end

return table.freeze(Transaction)
