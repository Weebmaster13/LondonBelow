--!strict

local InventoryTypes = {}

export type ItemKind =
	"Key"
	| "QuestItem"
	| "Artifact"
	| "PuzzlePiece"
	| "Tool"
	| "Document"
	| "LanternFuel"
	| "Custom"

export type ItemStack = {
	itemId: string,
	kind: ItemKind,
	count: number,
	metadata: { [string]: any },
}

return InventoryTypes
