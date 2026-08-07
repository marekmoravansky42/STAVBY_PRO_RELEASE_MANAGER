# Build 235 – Plugin Event Bus Foundation

Version: 6.3.8+235

- Added an isolated in-process event bus for compile-time plugins.
- Added typed platform event categories and immutable event messages.
- Added filtered subscriptions, cancellation, and deterministic delivery order.
- Subscriber exceptions are captured without interrupting other subscribers.
- Added delivery reports and automated tests.
