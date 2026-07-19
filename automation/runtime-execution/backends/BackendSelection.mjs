export function selectBackend(registry, requestedBackend = null) {
  if (requestedBackend !== null) {
    const exact = registry.entries.find(
      (entry) => entry.contract.backendKind === requestedBackend || entry.contract.backendId === requestedBackend
    );
    if (exact) {
      return {
        backend: exact.module,
        contract: exact.contract,
        selected: true,
        reason: `Selected requested backend ${requestedBackend}.`,
        fallbackUsed: false
      };
    }
    return {
      backend: null,
      contract: null,
      selected: false,
      reason: `Requested backend ${requestedBackend} is not registered.`,
      fallbackUsed: false
    };
  }

  const firstAvailable = registry.entries.find((entry) => entry.contract.availability === "available");
  return {
    backend: firstAvailable?.module ?? null,
    contract: firstAvailable?.contract ?? null,
    selected: firstAvailable !== undefined,
    reason: firstAvailable ? `Selected highest-priority available backend ${firstAvailable.contract.backendId}.` : "No available backend.",
    fallbackUsed: false
  };
}
