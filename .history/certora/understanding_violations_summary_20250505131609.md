# Certora Understanding Violations Summary (from Tutorials)

This document summarizes key concepts from Certora Tutorial Lesson 3 on understanding and fixing violations, based on the content found at:
*   [https://docs.certora.com/projects/tutorials/en/latest/lesson3_violations/erc20_bugs.html](https://docs.certora.com/projects/tutorials/en/latest/lesson3_violations/erc20_bugs.html)
*   [https://docs.certora.com/projects/tutorials/en/latest/lesson3_violations/borda_bugs.html](https://docs.certora.com/projects/tutorials/en/latest/lesson3_violations/borda_bugs.html)
*   [https://docs.certora.com/projects/tutorials/en/latest/lesson3_violations/reward_challenge.html](https://docs.certora.com/projects/tutorials/en/latest/lesson3_violations/reward_challenge.html)

## 1. Fixing ERC20 Spec (`erc20_bugs.html`)

*   **Core Idea**: Specifications (CVL files) can contain errors just like Solidity code. The Certora Prover's violation reports are essential for debugging *both* the contract and the specification itself.
*   **Debugging Specs**:
    *   Run `certoraRun` on the contract and spec (`certoraRun ERC20.conf` in the example).
    *   Analyze the violation reports to understand *why* a rule failed.
    *   Fix the rule in the `.spec` file by:
        *   Adding `require` statements to exclude irrelevant cases (like in `preconditions.html`).
        *   Strengthening or weakening `assert` statements to correctly capture the intended property under all conditions (including edge cases).
        *   Considering specific function behaviors or argument combinations (e.g., `transferFrom` where `sender == spender` or `recipient == sender`).
*   **`optimistic_loop` Flag**:
    *   Necessary when dealing with functions returning strings or dynamic arrays (like `name()` or `symbol()` in ERC20).
    *   Loops require special handling (covered later). Use `--optimistic_loop` or `"optimistic_loop": true` in the config to avoid spurious violations related to loops for now.
*   **Common Pitfalls (Hints from example)**:
    *   **`integrityOfTransferFrom`**: Ensure the spec covers *all* possible argument combinations, including non-typical ones (e.g., `from == spender`). Add requirements or adjust asserts.
    *   **`balanceChangesFromCertainFunctions`**: If a rule fails for only one function, check if the `assert` is missing a condition specific to that function.
    *   **`onlyOwnersMayChangeTotalSupply`**: When a rule fails for multiple functions, debug the simplest case first. Remember how logical implication (`=>`) works – the assertion only needs to hold if the premise is true.
    *   **`doesNotAffectAThirdPartyBalance`**: Be mindful of variable aliasing. A `thirdParty` could potentially be the same address as `from` or `recipient` unless explicitly constrained.

## 2. Borda Count Election - Finding Code Bugs (`borda_bugs.html`)

*   **Core Idea**: Use the counter-examples provided in violation reports to locate and understand bugs within the Solidity *code*.
*   **Debugging Code**:
    *   Run the Prover on potentially faulty implementations (`BordaBug1.conf`, `BordaBug2.conf`, etc.).
    *   When a rule fails, examine the **counter-example**:
        *   **Initial State**: Look at the "Global State" or return values from setup calls (`points()` in the example) to see the state *before* the violating function call (`vote()`).
        *   **Variable Values**: Use the variable value view to check specific inputs (`s`, `f`) or state variables.
        *   **Call Trace**: Drill down into the execution trace of the function (`vote()`). Look at storage `load`/`store` operations and internal function calls for unexpected behavior.
        *   **Reverting Conditions**: Analyze the reason for unexpected reverts, which might indicate issues like arithmetic overflow/underflow or assertion failures within the Solidity code.
*   **Parametric Rules & Invariants**:
    *   These rules are automatically checked against *all* external functions of the contract.
    *   This is powerful for ensuring properties hold universally and for catching bugs introduced by newly added functions without modifying the spec.

## 3. Reward Challenge - Spec Coverage (`reward_challenge.html`)

*   **Core Idea**: Even with a set of passing rules, the specification might not be *complete*. There could still be bugs in the contract that aren't caught because no existing rule covers that specific scenario.
*   **Challenge Example (Borda)**:
    *   The goal was to find a high-severity bug in a `Borda.sol` implementation that *passed* the provided `Borda.spec`.
    *   Required submitting the buggy code (`BordaNewBug.sol`) and a *new* rule (`BordaMissingRule.spec`) that could catch this previously missed bug.
    *   Demonstrates the iterative nature of specification writing and the importance of considering edge cases and potential attack vectors not covered by initial rules.
*   **(Note: This specific challenge finished in Oct 2023).** 