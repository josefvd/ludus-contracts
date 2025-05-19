# Certora Basics Summary (from Tutorials)

This document summarizes key concepts from the initial Certora tutorials found at [https://docs.certora.com/projects/tutorials/en/latest/lesson2_started/](https://docs.certora.com/projects/tutorials/en/latest/lesson2_started/).

## 1. ERC20 Example - Basics (`erc20_example.html`)

*   **Core Idea**: Verify properties of smart contract functions (like `transfer`, `mint`, `burn`, `approve` in the ERC20 example) using Certora Verification Language (CVL) rules.
*   **CVL Rules**: Define expected behaviors. Assertions check if these behaviors hold.
    *   Example: `transferSpec` verifies that `transfer` correctly updates sender and recipient balances.
*   **Execution Environment (`env`)**:
    *   Represents the *entire* blockchain execution context (e.g., `e.msg.sender`, `e.block.number`, `e.block.timestamp`).
    *   Must be passed as the first argument to non-`envfree` contract functions called within rules (e.g., `transfer(e, recipient, amount)`).
*   **Arbitrary Precision Integers (`mathint`)**:
    *   A CVL type representing integers of any size. Used to store results from contract calls (like `balanceOf`) to prevent specification checks from failing due to integer overflow/underflow.
    *   Operations (`+`, `-`) on `mathint` *never* overflow or underflow.
*   **`assert` Statement**:
    *   States a condition that *must* be true at that point in the rule's execution path.
    *   If the condition can be false for *any* possible input or state allowed by the rule, the Prover reports a violation.
*   **Running the Prover (`certoraRun`)**:
    *   Command: `certoraRun <ContractFile> --verify <ContractName>:<SpecFile> --solc <CompilerVersion>`
    *   Can use `solc-select` to manage compiler versions.
    *   Process: 1. Local check (Solidity compilation, CVL syntax). 2. Cloud verification (heavy analysis).
    *   Use `certoraRun --help` for options. MacOS users might need Rosetta (`softwareupdate --install-rosetta`).
*   **Violations & Counter-examples**:
    *   When an `assert` fails, the Prover provides a *counter-example*: specific inputs (e.g., `recipient`, `amount`) and a call trace showing *how* the rule was violated.
    *   Crucial for debugging the contract *or the rule itself*.
*   **Handling Edge Cases (Rule Debugging)**:
    *   Rules must be precise. The initial `transferSpec` failed because it didn't handle the `recipient == msg.sender` case correctly.
    *   Use conditional assertions: `condition => assertion` (read as "if `condition` is true, then `assertion` must also be true").
    *   Example Fix for `transferSpec`:
        ```cvl
        address sender = e.msg.sender;
        assert recipient != sender => balance_sender_after == balance_sender_before - amount;
        assert recipient != sender => balance_recip_after == balance_recip_before + amount;
        assert recipient == sender => balance_sender_after == balance_sender_before; // Balance shouldn't change
        ```

## 2. ERC20 Example - Preconditions (`preconditions.html`)

*   **Over-approximation**: A core technique where the Prover explores a *superset* of possible states to avoid missing bugs (false positives). However, this means it might analyze states that are not actually reachable in the contract, potentially leading to violation reports for impossible scenarios (false negatives).
*   **`require` Statement**:
    *   Adds *preconditions* to a rule.
    *   Tells the Prover: "Only consider execution paths where this condition holds true *before* executing the subsequent code in the rule."
    *   Filters out unreachable states stemming from over-approximation, focusing verification on relevant scenarios.
    *   Example: `require totalBefore >= userBalanceBefore;` before a `mint` call prevents the Prover from considering (invalid) initial states where a user's balance already exceeded the total supply.
*   **CVL Variables (in rules)**:
    *   Standard variables declared within a rule (e.g., `mathint balance_sender_before = ...`) are *immutable* – their value is fixed once assigned based on the state at that point.
    *   Their initial value can be *any* value consistent with their type *unless constrained* by `require` statements earlier in the rule. (Mutable *ghost* variables are different and introduced later).
*   **Useful `certoraRun` Flags**:
    *   `--rule <RuleName>`: Verifies only the specified rule.
    *   `--msg "description"`: Adds a custom message to the verification job report.

*(Summary based on provided web search results for `erc20_example.html` and `preconditions.html`.)*

*(Summary based on provided web search results for the first two links. Content for `parametric.html`, `config_files.html`, and `vacuity.html` was not available.)* 