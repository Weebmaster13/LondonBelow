--!strict

local Signals = {
	RuntimeInitialized = "AssetGovernanceCertificationInspection.RuntimeInitialized",
	RuntimeStarted = "AssetGovernanceCertificationInspection.RuntimeStarted",
	RuntimeShutdown = "AssetGovernanceCertificationInspection.RuntimeShutdown",
	InspectionRegistered = "AssetGovernanceCertificationInspection.InspectionRegistered",
	ObservationRegistered = "AssetGovernanceCertificationInspection.ObservationRegistered",
	FindingRegistered = "AssetGovernanceCertificationInspection.FindingRegistered",
	AuditRegistered = "AssetGovernanceCertificationInspection.AuditRegistered",
	ValidationRejected = "AssetGovernanceCertificationInspection.ValidationRejected",
}

return Signals
