--!strict

local Signals = {}

Signals.ExecutionDesignContractRegistered =
	"AssetExecutionDesignContract.ExecutionDesignContractRegistered"
Signals.ExecutionDesignResponsibilityRegistered =
	"AssetExecutionDesignContract.ExecutionDesignResponsibilityRegistered"
Signals.ExecutionDesignBoundaryRegistered =
	"AssetExecutionDesignContract.ExecutionDesignBoundaryRegistered"
Signals.ExecutionDesignAuditRegistered =
	"AssetExecutionDesignContract.ExecutionDesignAuditRegistered"
Signals.ValidationRejected = "AssetExecutionDesignContract.ValidationRejected"
Signals.SnapshotCaptured = "AssetExecutionDesignContract.SnapshotCaptured"

return Signals
