# Phase 164 Baseline

Phase 164 starts from Phase 163 state commit `d7c9a28b8107a46f1ae227324c6e8a956599a319`.

The repository already contained `src/ServerScriptService/Core/EventBus.lua` as a legacy process-local signal bus used by many coordinators through the `EventBus` bootstrap dependency. That bus was not an authoritative typed runtime event bus: it accepted raw event names, had no typed event definitions, no publisher registry, no subscriber registry, no bounded priority queue, no immutable event envelope model, and no normalized delivery evidence.

Phase 164 hardens the existing Core EventBus ownership instead of creating duplicate domain messaging ownership.
