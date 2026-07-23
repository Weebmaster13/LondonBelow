# Lifecycle And Acknowledgements

`PresentationLifecycleManager` owns legal session state transitions.

`PresentationAcknowledgementProducer` creates immutable acknowledgement metadata for accepted, started, completed, cancelled, failed, and expired states.

Acknowledgement production updates lifecycle through the lifecycle manager only.
