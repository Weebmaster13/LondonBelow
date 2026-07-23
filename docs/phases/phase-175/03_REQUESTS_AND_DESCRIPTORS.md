# Requests And Descriptors

Presentation requests declare that Dialogue content is ready for future presentation.

Required request fields include presentation id, execution id, conversation id, dialogue id, node id, speaker id, presentation kind, descriptor, synchronization policy, localization references, accessibility metadata, and runtime metadata.

Descriptors are serializable metadata only. Functions, threads, userdata, cyclic payloads, oversized strings, deep payloads, and oversized descriptors reject before mutation.
