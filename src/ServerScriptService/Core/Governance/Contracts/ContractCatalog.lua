--!strict
-- Deterministic aggregation point for built-in London Engine governance contracts.

local ContractCatalog = {}

local groups = {
	{ name = "CoreContracts", contracts = require(script.Parent.CoreContracts) },
	{ name = "ObservationContracts", contracts = require(script.Parent.ObservationContracts) },
	{ name = "NarrativeContracts", contracts = require(script.Parent.NarrativeContracts) },
	{ name = "GameplayContracts", contracts = require(script.Parent.GameplayContracts) },
	{ name = "PresentationContracts", contracts = require(script.Parent.PresentationContracts) },
	{ name = "CertificationContracts", contracts = require(script.Parent.CertificationContracts) },
	{
		name = "AssetExecutionContracts",
		contracts = require(script.Parent.AssetExecutionContracts),
	},
	{
		name = "StudioExecutionContracts",
		contracts = require(script.Parent.StudioExecutionContracts),
	},
	{ name = "ChapterContracts", contracts = require(script.Parent.ChapterContracts) },
	{
		name = "InfrastructureContracts",
		contracts = require(script.Parent.InfrastructureContracts),
	},
}

local function isValidContract(contract: any): boolean
	return type(contract) == "table"
		and type(contract.systemName) == "string"
		and contract.systemName ~= ""
		and type(contract.ownerLayer) == "string"
		and contract.ownerLayer ~= ""
		and type(contract.status) == "string"
		and contract.status ~= ""
		and type(contract.responsibilities) == "table"
		and type(contract.doesNotOwn) == "table"
		and type(contract.dependencies) == "table"
		and type(contract.diagnosticsExposed) == "table"
		and type(contract.snapshotProviders) == "table"
		and type(contract.cleanupBehavior) == "table"
		and type(contract.documentation) == "table"
		and type(contract.tags) == "table"
end

function ContractCatalog.getBuiltInContracts(): { any }
	local all = {}
	local seen = {}

	for _, group in ipairs(groups) do
		for index, contract in ipairs(group.contracts) do
			if not isValidContract(contract) then
				error(
					string.format(
						"Malformed governance contract in %s at index %d",
						group.name,
						index
					)
				)
			end

			if seen[contract.systemName] then
				error("Duplicate governance contract: " .. contract.systemName)
			end

			seen[contract.systemName] = true
			table.insert(all, contract)
		end
	end

	return all
end

function ContractCatalog.inspectGroups()
	local summary = {}

	for _, group in ipairs(groups) do
		table.insert(summary, {
			name = group.name,
			count = #group.contracts,
		})
	end

	return summary
end

return ContractCatalog
