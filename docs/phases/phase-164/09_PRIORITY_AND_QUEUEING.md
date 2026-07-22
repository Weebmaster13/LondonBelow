# Priority and Queueing

`EventQueue.lua` provides bounded priority queues.

Priority order is `Critical`, `High`, `Normal`, then `Low`. Equal-priority events preserve FIFO order through server-owned sequence and queue insertion order.

Queue overflow returns a normalized `QueueFull` failure and records evidence. There is no polling loop.
