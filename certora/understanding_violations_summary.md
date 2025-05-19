# Certora Understanding Violations Summary (from Tutorials)

This document summarizes key concepts from Certora Tutorial Lesson 3 on understanding and fixing violations. Analyzing violation reports is crucial for debugging both the smart contract code *and* the Certora Verification Language (CVL) specification itself. Violations guide the process of refining both until the code behaves as intended and the specification accurately captures those intentions.

Based on the content found at:
*   [https://docs.certora.com/projects/tutorials/en/latest/lesson3_violations/erc20_bugs.html](https://docs.certora.com/projects/tutorials/en/latest/lesson3_violations/erc20_bugs.html)
*   [https://docs.certora.com/projects/tutorials/en/latest/lesson3_violations/borda_bugs.html](https://docs.certora.com/projects/tutorials/en/latest/lesson3_violations/borda_bugs.html)
*   [https://docs.certora.com/projects/tutorials/en/latest/lesson3_violations/reward_challenge.html](https://docs.certora.com/projects/tutorials/en/latest/lesson3_violations/reward_challenge.html)

## 1. Fixing ERC20 Spec (`erc20_bugs.html`) - Debugging the Specification

*   **Core Idea**: Specifications (CVL files) can contain errors just like Solidity code. The Certora Prover's violation reports are essential for debugging *both* the contract and the specification itself. This section focuses on using violations to fix the *spec*.
*   **Debugging Specs**:
    *   Run `certoraRun` on the contract and spec (`certoraRun ERC20.conf` in the example).
    *   Analyze the violation reports to understand *why* a rule failed.
    *   Examine the **counter-example** (specific inputs, variable values, call trace) provided in the violation report to pinpoint *why* the current rule logic doesn't hold for that scenario.
    *   Fix the rule in the `.spec` file by:
        *   Adding `require` statements to exclude irrelevant cases or states.
        *   Strengthening or weakening `assert` statements to correctly capture the intended property under all relevant conditions (including edge cases).
        *   Considering specific function behaviors or argument combinations (e.g., `transferFrom` where `sender == spender` or `recipient == sender`).
*   **`optimistic_loop` Flag**:
    *   Necessary when dealing with functions returning strings or dynamic arrays (like `name()` or `symbol()` in ERC20), as loops require special handling (covered in later tutorials).
    *   Use `--optimistic_loop` flag or `"optimistic_loop": true` in the config file to avoid spurious violations related to unhandled loops for now.
*   **Common Spec Pitfalls (Hints from example)**:
    *   **`integrityOfTransferFrom`**: Ensure the spec covers *all* valid argument combinations, including non-typical ones (e.g., `from == spender`). Add requirements or adjust asserts.
    *   **`balanceChangesFromCertainFunctions`**: If a rule fails for only one function, check if the `assert` is missing a condition specific to that function's behavior.
    *   **`onlyOwnersMayChangeTotalSupply`**: When a rule fails for multiple functions, debug the simplest failing case first. Remember how logical implication (`P => Q`) works – the assertion `Q` only needs to hold if the premise `P` is true.
    *   **`doesNotAffectAThirdPartyBalance`**: Be mindful of variable aliasing. A `thirdParty` could potentially be the same address as `from` or `recipient` unless explicitly constrained otherwise (e.g., using `require thirdParty != from && thirdParty != recipient;`).

## 2. Borda Count Election (`borda_bugs.html`) - Finding Code Bugs

*   **Core Idea**: Use the counter-examples provided in violation reports to locate and understand bugs within the Solidity *code*.
*   **Debugging Code**:
    *   Run the Prover on potentially faulty contract implementations (`BordaBug1.conf`, `BordaBug2.conf`, etc.).
    *   When a rule fails, examine the **counter-example**, which provides concrete inputs and the exact execution path leading to the failure:
        *   **Initial State**: Look at the "Global State" or return values from setup calls (`points()` in the example) to see the state *before* the violating function call (`vote()`).
        *   **Variable Values**: Use the variable value view to check specific inputs (`s`, `f`) or state variables passed to/modified by the function.
        *   **Call Trace**: Drill down into the execution trace of the function (`vote()`). Look at storage `load`/`store` operations, internal function calls, and emitted events for unexpected behavior or incorrect logic.
        *   **Reverting Conditions**: Analyze the reason for unexpected reverts (e.g., `require` failures, arithmetic overflow/underflow), which often point directly to bugs in the Solidity code.
*   **Parametric Rules & Invariants**:
    *   These rules are automatically checked by the Prover against *all* relevant external/public functions of the contract.
    *   This is powerful for ensuring properties hold universally and for catching bugs introduced by newly added functions without needing to modify the spec explicitly for each new function.

## 3. Reward Challenge (`reward_challenge.html`) - Ensuring Specification Coverage

*   **Core Idea**: Even with a set of passing rules, the specification might not be *complete*. There could still be bugs in the contract that aren't caught because no existing rule covers that specific behavior or edge case.
*   **Challenge Example (Borda)**:
    *   The goal was to find a high-severity bug in a `Borda.sol` implementation that *passed* the provided `Borda.spec`. This indicates a gap in the specification.
    *   Required submitting the buggy code (`BordaNewBug.sol`) and a *new* rule (`BordaMissingRule.spec`) that could catch this previously missed bug, demonstrating the spec was incomplete.
    *   Highlights the iterative nature of specification writing and the importance of thinking critically about potential attack vectors or edge cases not covered by initial rules.
*   **(Note: This specific challenge finished in Oct 2023).**

---

In summary, analyzing Certora violations is an interactive process. Counter-examples are key to understanding failures, whether they originate from incorrect code logic or an inaccurate/incomplete specification. Effective verification involves iteratively running the Prover, interpreting the results, and refining both the contract and its formal specification until confidence in correctness is achieved. 