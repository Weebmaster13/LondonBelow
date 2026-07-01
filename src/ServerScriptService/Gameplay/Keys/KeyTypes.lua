--!strict

local KeyTypes = {}

export type KeyDefinition = {
	id: string,
	displayName: string,
	singleUse: boolean,
	reusable: boolean,
	masterKey: boolean,
	partyShared: boolean,
	rewardSource: string?,
	unlocks: { string },
	metadata: { [string]: any },
}

return KeyTypes
