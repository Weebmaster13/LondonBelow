# Dispatch and Delivery

`EventDispatcher.lua` dispatches routed events at most once to each matched subscription.

Subscriber failures are normalized and recorded. The default failure posture is `ContinueAfterSubscriberFailure`, so one failing subscriber does not silently corrupt or prevent independent deliveries.
