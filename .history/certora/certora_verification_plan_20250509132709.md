# Certora Verification Plan & Debugging Log

## Goal
Successfully run Certora verification for the LudusEvents contract, focusing on individual invariants.

## Current Status & Plan

### Previous Approach (Debugging `LudusEvents.spec`)
- Attempted to debug semicolon and syntax issues in the main `certora/specs/LudusEvents.spec` file.
- Tried commenting out various invariants and helper functions within `LudusEvents.spec`.
- Encountered persistent errors, including native crashes, suggesting issues beyond simple spec syntax on the modified lines.

### New Approach (Using Individual Spec Files)
- **User Clarification:** The project uses separate `.spec` files for each major invariant/property (e.g., `LudusEvents_treasury.spec`, `LudusEvents_timeline.spec`). This allows for focused verification.
- **Current Focus:** Verify the `validTreasuryDistribution` property.
- **Target Spec File:** `certora/specs/LudusEvents_treasury.spec`.

### Action Plan:
1.  **Modify Configuration:** The `certora/scripts/run_events.sh` script uses `certora/conf/events.conf`. This config file needs to be updated to point to `certora/specs/LudusEvents_treasury.spec` instead of the general `certora/specs/LudusEvents.spec`.
    - The line to change in `events.conf` is `"verify": "LudusEventsImpl:certora/specs/LudusEvents.spec"` to `"verify": "LudusEventsImpl:certora/specs/LudusEvents_treasury.spec"`.
2.  **Run Verification:** Execute `sh certora/scripts/run_events.sh` after updating the configuration.
3.  **Analyze Results:** Review the output for success or new errors specific to the treasury spec.

## Log
*(This section will be updated as we try different steps)* 