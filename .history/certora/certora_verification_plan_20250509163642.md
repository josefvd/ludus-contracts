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
2.  **Refine `LudusEvents_treasury.spec`:** 
    - Simplify the `methods` block to only include `envfree` functions absolutely necessary for `checkTreasuryDistributionProperty`.
3.  **Run Verification:** Execute `sh certora/scripts/run_events.sh` after updating the configuration and spec.
4.  **Analyze Results:** Review the output for success or new errors specific to the treasury spec.
5.  **Next Step:** Examine the detailed Certora Prover report for counterexamples to understand why the invariant is failing.
    - Report URL: `https://prover.certora.com/output/9683541/8c118012494e4306bb6a9cbc07ab43b4?anonymousKey=41573279b9cd1f27926dcd837e6f4bb6726f5041`

## Log
- **[Previous Date/Time]**: Multiple attempts to fix syntax in `LudusEvents.spec` (main combined spec).
- **[Current Date/Time]**: 
    - Switched to using `certora/specs/LudusEvents_treasury.spec` and updated `events.conf`.
    - Simplified `methods` block in `LudusEvents_treasury.spec` to only essential `envfree` functions (`events`, `eventDistributions`, `jbTerminal`, `yieldManager`).
    - Certora run completed without syntax errors for the spec but **found violations** for the `validTreasuryDistribution` invariant. 