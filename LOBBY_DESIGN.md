# London Below Lobby Design

The lobby is the multiplayer gateway into London Below.

## Goals

- Let players gather safely.
- Support party creation and party membership.
- Support ready states.
- Support chapter selection or voting.
- Launch parties into chapters together.
- Provide clear feedback for join, leave, ready, unready, launch, and failure states.
- Maintain London Below atmosphere without starting full chapter pressure.

## Server Responsibilities

- Party truth.
- Party leader.
- Ready state.
- Chapter selection.
- Queue state.
- Launch validation.
- Teleport handling.
- Failure recovery.

## Client Responsibilities

- Party UI.
- Ready buttons.
- Chapter selection UI.
- Launch feedback.
- Error messages.
- Lobby ambience and presentation.

## Party Rules

- The server decides party membership.
- The server validates ready state changes.
- The server validates chapter launch.
- Disconnected players are removed safely.
- Party ownership transfers or disbands by explicit rules.

## Teleporting Rules

Teleporting must handle:

- Reserved servers.
- Party size validation.
- Failed teleport retries.
- Partial party failure.
- Return-to-lobby paths.
- Logging for every failure.

## Atmosphere

The lobby should feel like a threshold into Victorian London: safe enough for organization, but still cold, foggy, and wrong.
