# Certora Support Query: Issues with validTreasuryDistribution and validEventTimeline Rules

## Background
We're working on formal verification for our LudusEvents.sol contract. We've successfully verified some rules (startEventTransition, cancelEventTransition) but are encountering issues with the following rules:

1. `validTreasuryDistribution` - Fails, likely due to `envfree` state reading issues
2. `validEventTimeline` - Also fails, likely for similar reasons

## Problem Description
Both rules are related to data consistency validations. We believe the failures are linked to how Certora reads state via `envfree` declarations. 

The rules attempt to verify:
- `validTreasuryDistribution`: That the distribution percentages for an event's treasury always sum to 100%
- `validEventTimeline`: That event timestamps maintain proper chronological order

## Questions
1. Are there known limitations with `envfree` rules when reading complex state structures?
2. Can you recommend alternative approaches for modeling these validations, perhaps using summaries?
3. Is there a way to structure these rules differently to avoid the state reading issues?

## Files Provided
We've included:
- LudusEvents.sol contract
- Supporting interfaces and libraries
- Certora specification files (LudusEvents.spec and LudusEvents_registration.spec)
- Configuration files

Thank you for your assistance in resolving these verification challenges.
