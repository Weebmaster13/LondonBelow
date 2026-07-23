--!strict

local Types = {}

Types.ProviderName = "dialogueRuntimePresentationContract"
Types.ContractId = "dialoguePresentationContract"

Types.PresentationKind = {
	DialogueLine = "DialogueLine",
	ChoiceList = "ChoiceList",
	Narration = "Narration",
	SpeakerIntroduction = "SpeakerIntroduction",
	SystemMessage = "SystemMessage",
	ConversationTransition = "ConversationTransition",
	ConversationCompletion = "ConversationCompletion",
	PresentationCue = "PresentationCue",
}

Types.SynchronizationPolicy = {
	NoWait = "NoWait",
	WaitForAccepted = "WaitForAccepted",
	WaitForStarted = "WaitForStarted",
	WaitForCompleted = "WaitForCompleted",
	WaitForCancelled = "WaitForCancelled",
	WaitForTerminalState = "WaitForTerminalState",
}

Types.RequestStatus = {
	Created = "Created",
	Registered = "Registered",
	PendingAcknowledgement = "PendingAcknowledgement",
	Accepted = "Accepted",
	Started = "Started",
	Completed = "Completed",
	Closed = "Closed",
	Rejected = "Rejected",
	Cancelled = "Cancelled",
	Expired = "Expired",
	Failed = "Failed",
}

Types.AcknowledgementKind = {
	Accepted = "Accepted",
	Rejected = "Rejected",
	Started = "Started",
	Completed = "Completed",
	Cancelled = "Cancelled",
	Failed = "Failed",
	Expired = "Expired",
}

Types.FailureType = {
	RuntimeShutdown = "RuntimeShutdown",
	ValidationFailure = "ValidationFailure",
	DuplicateContract = "DuplicateContract",
	UnknownContract = "UnknownContract",
	DuplicatePresentation = "DuplicatePresentation",
	UnknownPresentation = "UnknownPresentation",
	InvalidPresentationKind = "InvalidPresentationKind",
	InvalidDescriptor = "InvalidDescriptor",
	InvalidSynchronizationPolicy = "InvalidSynchronizationPolicy",
	DuplicateAcknowledgement = "DuplicateAcknowledgement",
	InvalidAcknowledgement = "InvalidAcknowledgement",
	InvalidLifecycleTransition = "InvalidLifecycleTransition",
	OwnershipMismatch = "OwnershipMismatch",
	ExecutionMismatch = "ExecutionMismatch",
	LimitExceeded = "LimitExceeded",
	RequestCancelled = "RequestCancelled",
	RequestExpired = "RequestExpired",
	RequestCompleted = "RequestCompleted",
	SynchronizationNotSatisfied = "SynchronizationNotSatisfied",
}

Types.Limits = {
	MaxContracts = 16,
	MaxPresentationRequests = 320,
	MaxAcknowledgements = 520,
	MaxLocalizationReferences = 640,
	MaxAccessibilityEntries = 320,
	MaxDescriptorFields = 96,
	MaxSynchronizationRecords = 520,
	MaxEvidence = 900,
	MaxProfilerRecords = 240,
	MaxStringLength = 2048,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 420,
}

local function contains(values: { [string]: string }, value: string): boolean
	for _, item in pairs(values) do
		if item == value then
			return true
		end
	end
	return false
end

function Types.isPresentationKind(value: string): boolean
	return contains(Types.PresentationKind, value)
end

function Types.isSynchronizationPolicy(value: string): boolean
	return contains(Types.SynchronizationPolicy, value)
end

function Types.isAcknowledgementKind(value: string): boolean
	return contains(Types.AcknowledgementKind, value)
end

return Types
