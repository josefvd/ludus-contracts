# Certora CVL Syntax Learnings (LudusEvents)

This document summarizes key syntax points and lessons learned while writing the `LudusEvents.spec` file for the `LudusEventsImpl` contract.

1.  **`using` vs. Fully Qualified Names:**
    *   Using an alias like `using LudusTypes as types;` is convenient but sometimes caused resolution issues for the prover.
    *   Using the fully qualified name (e.g., `LudusTypes.EventStatus`) proved more reliable in our case, although it makes the spec more verbose. This resolved errors like `type types.EventStatus could not be resolved`.

2.  **Method Declarations:**
    *   Functions intended only for reading state within the spec (view functions called from rules/invariants) should be marked `envfree`.
    *   Functions that modify state (`createEvent`, `startEvent`, etc.) should *not* be `envfree`. If they are declared in `methods` without `envfree` or a summary, they are essentially ignored by the prover (produces warnings like "neither `envfree`, `optional`, nor summarized, so it has no effect"). To reason about their effects, they need to be targeted by rules or invariants.

3.  **Return Values in `methods`:**
    *   CVL had issues parsing named return variables in the `methods` block (e.g., `returns (uint256 id, ...)`).
    *   Declaring only the types (e.g., `returns (uint256, uint256, ...)`) resolved syntax errors like "unexpected token near `id`".
    *   When calling these functions in rules, results must be assigned positionally: `(var1, var2, _) = func(arg);`.

4.  **`rule` vs. `invariant`:**
    *   A `rule` checks properties typically related to a specific function call or a specific state condition, often parameterized (e.g., `rule myRule(uint256 eventId)`). It doesn't automatically imply induction.
    *   An `invariant` is intended to prove a property holds across *all* reachable states by checking the inductive step (assuming it holds before, does it hold after *any* transaction?).
    *   Simple rules acting like invariants often fail because they lack inductive strength; the prover finds states satisfying `require` but violating `assert`.

5.  **`forall` Loops:**
    *   Syntax for `forall` within invariants seemed problematic in our attempts. The exact structure (`forall uint256 eventId { ... }`) caused errors like "unexpected token near `{`".
    *   The `preserved` block also had strict syntax requirements that weren't immediately obvious.
    *   Simple rules parameterized by `uint256 eventId` were easier to get syntactically correct but lacked inductive power.

6.  **Zero Address Comparison:**
    *   Use `addressVar != 0` to check if an address is not the zero address. Using `addressVar != address(0)` caused type errors.

7.  **Rule Structure & Final `assert true`:**
    *   Rules based on checking state fetched via view functions (like our final `validTreasuryDistribution` rule) often require a final `assert true;` statement if the last meaningful statement is an `if` block or other construct that doesn't guarantee an assertion is always reached. This resolved the "last statement ... is not an assertion" error.

8.  **`require` for Filtering:**
    *   `require` statements are crucial within rules/invariants to filter out irrelevant states (e.g., non-existent events `require id == eventId && id > 0;`) before checking the main property with `assert`.
    *   Strengthening `require` helps reduce false positives but doesn't automatically make a simple `rule` inductive.

9.  **Configuration (`.conf` file):**
    *   All contracts whose types/definitions are needed by the spec (including libraries like `LudusTypes.sol`) must be listed in the `"files"` array in the configuration JSON. Forgetting this leads to "could not resolve type" errors. 