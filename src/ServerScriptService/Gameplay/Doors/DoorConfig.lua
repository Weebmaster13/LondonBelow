--!strict

local DoorConfig = {
	RecentTransitionLimit = 120,
	LockedStates = {
		Locked = true,
		Bolted = true,
		Barred = true,
		Jammed = true,
		PowerLocked = true,
		PuzzleLocked = true,
		DirectorLocked = true,
		NarrativeLocked = true,
		Sealed = true,
		Disabled = true,
	},
}

return DoorConfig
