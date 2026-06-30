# Room Profiles

Room personality profiles let future systems interpret a room's emotional identity without hard-coding story content.

## Personality Types

`Neutral` rooms carry minimal bias. They are good for traversal, setup, or low-pressure exploration.

`Watching` rooms make the building feel attentive. They suit subtle sounds, light hesitation, distant presence, and observation-heavy tension.

`Hostile` rooms tolerate stronger pressure, but still require Director approval for major events.

`Protective` rooms lower pressure and are appropriate for safe rooms, regrouping, or checkpoint-adjacent spaces.

`Mourning` rooms support grief, memory, quiet movement, distant voices, and environmental storytelling.

`Deceptive` rooms support fake sounds, misleading ambience, and uncertainty, but must avoid confusing objective-critical information unfairly.

`PuzzleFocused` rooms protect player thinking and cooperative communication.

`Transit` rooms support movement between important states: lobby to chapter, street to building, floor to wing, or safe space to danger.

## Profile Fields

- `tensionBias`: how much the room naturally leans into or away from pressure.
- `repetitionTolerance`: how often similar reactions can be tolerated before they become predictable.
- `preferredAffordances`: reactions that fit the room's identity.
- `suppressedAffordances`: reactions that should be avoided unless explicitly overridden.
- `tags`: developer-facing search and debugging labels.

## Fairness Rules

Room personality must never override server authority, Director approval, puzzle protection, safe-room rules, or multiplayer state.

Personality is context, not command. A hostile room does not automatically create a scare. A deceptive room does not automatically lie to the player. A protective room does not make the player invincible.

