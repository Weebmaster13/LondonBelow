# Architecture

Presentation Runtime owns presentation execution. Presentation Rendering Contract owns rendering intent metadata. Future rendering runtimes may consume this contract but cannot own or mutate it.

The provider identity is `presentationRuntimeRenderingContract`; the contract identity is `presentationRenderingContract`; the snapshot provider is `presentationRuntimeRenderingContract`.

The contract remains server-authoritative and data-only. It does not create GUI, render content, load assets, resolve localization, implement accessibility, network, persist, mutate Workspace, execute gameplay, execute dialogue, or grant client authority.
