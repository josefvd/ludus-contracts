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
1.  **Modify Configuration:** The `certora/scripts/run_events.sh` script uses `certora/conf/events.conf`. This config file needs to be updated to point to `certora/specs/LudusEvents_treasury.spec`.
2.  **Refine `LudusEvents_treasury.spec` Methods Block Syntax:**
    - Identified that for CVL2, non-`envfree`/`optional` methods are `summary` by default. Correct syntax is `function name(args) external [returns (ret)] ;` (i.e., explicit `summary` keyword was causing issues).
    - Applied this corrected syntax to `LudusEvents_treasury.spec`.
3.  **Run Verification:** Execute `sh certora/scripts/run_events.sh`.
4.  **Analyze Results:** 
    - Prover run **successful** (parsed spec without syntax errors).
    - Prover **found violations** for the `validTreasuryDistribution` invariant, as before. This indicates the spec is now syntactically correct but the underlying logic (or modeling of externals) leads to the invariant failing.
5.  **Next Step:** Examine the detailed Certora Prover report for counterexamples to understand why the invariant is failing. Focus on how external calls (e.g., to `_USDC` via `YieldManager`) are havoced and contribute to violations.
    - Report URL: `https://prover.certora.com/output/9683541/421b5ffd9f4343f6a33b2cace135fe09?anonymousKey=ab28f21efe1716f5a9908cd98c299a8d7d3d61b5`
6.  **Future Action (based on report analysis):** Add summaries for `IERC20` methods (`approve`, `allowance`, `transfer`, `transferFrom`, `balanceOf`) to `LudusEvents_treasury.spec` to accurately model interactions with `_USDC` and `_WETH` tokens via `YieldManager`.

## Log
- **[Previous Date/Time]**: Multiple attempts to fix syntax in `LudusEvents.spec` (main combined spec) and `LudusEvents_treasury.spec`.
- **[Current Date/Time]**: 
    - Switched to using `certora/specs/LudusEvents_treasury.spec` and updated `events.conf`.
    - Resolved persistent syntax errors in `LudusEvents_treasury.spec`'s `methods` block by removing explicit `summary` keyword and using `function name(...) external;` for default summary methods.
    - Certora run completed without spec syntax errors but **found logical violations** for the `validTreasuryDistribution` invariant.
    - Next step is to analyze the prover report to understand counterexamples, likely related to havocing of ERC20 token calls made by `YieldManager`. 