--!strict

local Guard = {}

function Guard.verify(record: any, mountTarget: Instance): (boolean, string?)
	if not record or not record.root then
		return true
	end
	if record.root.Parent ~= mountTarget then
		return false, "root-parent-changed"
	end
	if record.root:GetAttribute("LondonEngineContractId") ~= record.contractId then
		return false, "contract-id-changed"
	end
	if record.root:GetAttribute("LondonEngineRevision") ~= record.revision then
		return false, "revision-changed"
	end
	local count = 1 + #record.root:GetDescendants()
	if count ~= record.nodeCount then
		return false, "owned-tree-cardinality-changed"
	end
	for nodeId, instance in pairs(record.instances) do
		if instance:GetAttribute("LondonEngineNodeId") ~= nodeId then
			return false, "node-id-changed"
		end
		if instance ~= record.root and not instance:IsDescendantOf(record.root) then
			return false, "node-detached"
		end
	end
	return true
end

return table.freeze(Guard)
