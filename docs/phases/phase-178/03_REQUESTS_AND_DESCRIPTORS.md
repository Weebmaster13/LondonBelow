# Requests And Descriptors

`RenderingRequestBuilder` constructs normalized rendering requests and `RenderingRequestRegistry` stores immutable registered copies.

Requests preserve execution session, presentation session, presentation id, consumer id, rendering kind, descriptor, synchronization policy, references, priority, creation ordinal, runtime metadata, contract version, and status.

`RenderingDescriptorValidator` rejects unsafe values, invalid kinds, oversized descriptors, non-table descriptors, cyclic data, functions, coroutines, userdata, Roblox Instances, and unbounded payloads before mutation.
