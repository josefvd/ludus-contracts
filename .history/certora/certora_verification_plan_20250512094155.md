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
    - **Current Focus:** Verify the `validTimeline` property.
    - **Target Spec File:** `certora/specs/LudusEvents_timeline.spec`.
    - **Action Plan:**
        1.  **Modify Configuration:** Update `certora/conf/events.conf` to point to `LudusEvents_timeline.spec`. (DONE)
        2.  **Refine `LudusEvents_timeline.spec` Syntax:** 
            - Commented out `contract LudusIdentityContract {}` block.
            - Changed `ludusIdentity()` accessor to return `address`.
            - Applied correct CVL2 default summary syntax (`external ... ;`) to methods. (DONE)
        3.  **Run Verification:** Execute `sh certora/scripts/run_events.sh`. (DONE)
        4.  **Analyze Results:** 
            - Prover run **successful** (parsed spec without syntax errors).
            - Prover **found violations** for the `validTimeline` invariant.
        5.  **Next Step:** Examine the detailed Certora Prover report for counterexamples to understand why the `validTimeline` invariant is failing.
            - Report URL: `https://prover.certora.com/output/9683541/3e3ccce2a9914c37b300339af4e72bcf?anonymousKey=86babcf94e3429008eb23a359aa00a4b5f96c257`

## General Log
- **[Previous Date/Time]**: Multiple attempts to fix syntax in `LudusEvents.spec` (main combined spec) and `LudusEvents_treasury.spec`.
- **[Current Date/Time]**: 
    - Successfully ran `LudusEvents_treasury.spec` (syntax clear, logical violations found related to ERC20 havocing).
    - Switched to `LudusEvents_timeline.spec`, corrected its syntax based on previous learnings.
    - Certora run for `LudusEvents_timeline.spec` completed without spec syntax errors but **found logical violations** for the `validTimeline` invariant.
    - Next step is to analyze the `validTimeline` prover report. 