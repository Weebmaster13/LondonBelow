--!strict
-- Budget schema registration boundary. Defines future CPU, memory, network, render, and category budgets only.

local PerformanceBudgetRuntime = {}

function PerformanceBudgetRuntime.register(state: any, schema: any): (boolean, string?)
	return state.registerBudget(schema)
end

return PerformanceBudgetRuntime
