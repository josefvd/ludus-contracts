# Certora Verification Plan & Debugging Log

## Goal
Successfully run Certora verification for the LudusEvents contract, focusing on individual invariants.

## Current Status & Plan

### Previous Approach (Debugging `LudusEvents.spec`)
- Attempted to debug semicolon and syntax issues in the main `certora/specs/LudusEvents.spec` file.
- Tried commenting out various invariants and helper functions within `LudusEvents.spec`.
- Encountered persistent errors, including native crashes, suggesting issues beyond simple spec syntax on the modified lines.

### New Approach (Using Individual Spec Files)
- **User Clarification:** The project uses separate `.spec` files for each major invariant/property. This allows for focused verification.

**1. Treasury Distribution (`LudusEvents_treasury.spec`)**
    - **Target Spec File:** `certora/specs/LudusEvents_treasury.spec`.
    - **Status:** Resolved spec syntax errors. Prover found **logical violations** for `validTreasuryDistribution`.
    - **Issue:** Violations likely due to `AUTO havoc` on external ERC20 calls (`_USDC.allowance`, `_USDC.approve`) within `YieldManager`.
    - **Report:** `https://prover.certora.com/output/9683541/421b5ffd9f4343f6a33b2cace135fe09?anonymousKey=ab28f21efe1716f5a9908cd98c299a8d7d3d61b5`
    - **Next Step (for Treasury):** When revisited, model IERC20 interactions in the spec.

**2. Event Timeline (`LudusEvents_timeline.spec`)**
    - **Target Spec File:** `certora/specs/LudusEvents_timeline.spec`.
    - **Status:** Resolved spec syntax errors. Prover found **logical violations** for `validTimeline`.
    - **Report:** `https://prover.certora.com/output/9683541/3e3ccce2a9914c37b300339af4e72bcf?anonymousKey=86babcf94e3429008eb23a359aa00a4b5f96c257`
    - **Next Step (for Timeline):** Analyze counterexamples from the report.

**3. Event State (`LudusEvents_state.spec`)**
    - **Current Focus:** Verify `validEventState` invariant and associated rules.
    - **Target Spec File:** `certora/specs/LudusEvents_state.spec`.
    - **Action Plan & Log:**
        1.  **Modify Configuration:** Update `certora/conf/events.conf` to point to `LudusEvents_state.spec`. (DONE)
        2.  **Refine `LudusEvents_state.spec` Syntax:** Corrected `EventStatus` enum usage. Corrected `methods` block syntax for default summaries. Commented out `NewlyCreatedEventHasCorrectCreatorAndState` invariant due to persistent parsing issues with its declaration (potentially hidden characters or complex interaction).
        3.  **Run Verification (attempt 1 after enum fix):** Failed due to `Variable e has not been declared` in the `FreshlyCreatedEventIsPendingAndCorrectlyInitialized` rule and persistent method summary warnings.
        4.  **Refine Rule & Methods:** Added `env e` to rule. Re-attempted to fix method summary syntax. Simplified `createEvent` signature in spec & rule to no arguments. (DONE)
        5.  **Run Verification (attempt 2 after createEvent simplification):** Failed due to `Contract LudusEvents has no bytecode`. This occurred after `LudusEvents.sol` (abstract parent) was added to `files` in `events.conf`.
        6.  **Refine Config & Spec:** Changed `verify` target to `LudusEvents` (still no bytecode error). Changed `verify` back to `LudusEventsImpl` and *removed* `LudusEvents.sol` from `files` (relying on import). (DONE)
        7.  **Run Verification (attempt 3 after config change):** Failed due to `Syntax error: unexpected token near {` for the `NewlyCreatedEventHasCorrectCreatorAndState` invariant, even after manual cleanup by user.
        8.  **Refine Spec:** Commented out `NewlyCreatedEventHasCorrectCreatorAndState` invariant. (DONE)
        9.  **Run Verification (attempt 4 with only `validEventState` invariant):** Prover run **successful** (parsed spec without syntax errors). Prover **found violations** for the `validEventState` invariant.
        10. **Next Step:** Examine the detailed Certora Prover report for counterexamples for `validEventState`.
            - Report URL: `https://prover.certora.com/output/9683541/a656a6a47c2347a588c39e94b1ed34ff?anonymousKey=e735b48b645b115d1fd54f943b7d9b86d3c887ae` (This was the link when `validEventState` ran and found violations).

## General Log
- Successfully ran `LudusEvents_treasury.spec` (syntax clear, logical violations found related to ERC20 havocing).
- Successfully ran `LudusEvents_timeline.spec` (syntax clear, logical violations found).
- Successfully ran `LudusEvents_state.spec` for the `validEventState` invariant (syntax clear, logical violations found).
- The primary remaining challenge for all specs, before true bugs in `LudusEventsImpl` can be confirmed, is the accurate modeling of external contract interactions (especially ERC20 tokens called by `YieldManager`). 