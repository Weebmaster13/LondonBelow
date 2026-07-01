--!strict

local InventoryValidator = {}

local allowedKinds = {
	Key = true,
	QuestItem = true,
	Artifact = true,
	PuzzlePiece = true,
	Tool = true,
	Document = true,
	LanternFuel = true,
	Custom = true,
}

function InventoryValidator.validateItem(item: any): (boolean, string?)
	if type(item) ~= "table" then
		return false, "item must be a table"
	end
	if type(item.itemId) ~= "string" or item.itemId == "" then
		return false, "item id is required"
	end
	if not allowedKinds[item.kind] then
		return false, "item kind is unsupported"
	end
	if item.count ~= nil and (type(item.count) ~= "number" or item.count <= 0) then
		return false, "item count must be positive"
	end
	return true, nil
end

function InventoryValidator.validate(): (boolean, string?)
	return true, nil
end

return InventoryValidator
