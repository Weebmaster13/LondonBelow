--!strict
--[[
	EventBus signal names for Engine Governance.

	Owns internal server-process integration points for contract registration,
	validation, scorecard generation, and issue reporting.

	Does not own remotes. Governance is a Core server concern and should not be
	controlled by clients.
]]

local GovernanceSignals = {}

GovernanceSignals.ContractRegistered = "Governance.ContractRegistered"
GovernanceSignals.ContractReplaced = "Governance.ContractReplaced"
GovernanceSignals.ContractValidated = "Governance.ContractValidated"
GovernanceSignals.ContractIssueFound = "Governance.ContractIssueFound"
GovernanceSignals.ScorecardUpdated = "Governance.ScorecardUpdated"
GovernanceSignals.GovernanceReady = "Governance.Ready"

return GovernanceSignals
