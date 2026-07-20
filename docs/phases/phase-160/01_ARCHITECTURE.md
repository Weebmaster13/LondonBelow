# Phase 160 Architecture

The runtime path is:

Observation -> Interaction -> Environmental -> Presentation -> Gameplay Flow -> Future Save Runtime.

Gameplay Flow consumes accepted runtime events and owns only progression state:

- active objective
- completed objectives
- failed objectives
- skipped objectives
- prerequisite graph
- condition evaluations
- checkpoint eligibility metadata
- objective evidence

It does not validate interaction requests, mutate environmental state, execute presentation, create remotes, write saves, own inventory, own dialogue, own Monster AI, or create Chapter 1 content.
