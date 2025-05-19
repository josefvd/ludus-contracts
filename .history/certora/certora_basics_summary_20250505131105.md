# Certora Basics Summary (from Tutorials)

This document summarizes key concepts from the initial Certora tutorials found at [https://docs.certora.com/projects/tutorials/en/latest/lesson2_started/](https://docs.certora.com/projects/tutorials/en/latest/lesson2_started/).

## 1. ERC20 Example - Basics (`erc20_example.html`)

*   **Rules**: Define properties to be verified using Certora Verification Language (CVL).
*   **`env` Type**: Represents the blockchain execution environment (e.g., `e.msg.sender`, `e.block.timestamp`). It must be passed as the first argument to contract functions called within rules.
*   **`mathint` Type**: An arbitrary-precision integer type used in rules to avoid overflows/underflows during property checks.
*   **`assert`**: Used within rules to state conditions that must hold true. If an assertion fails, the prover reports a violation.
*   **Running the Prover**:
    *   Command: `certoraRun <ContractFile> --verify <ContractName>:<SpecFile> --solc <CompilerVersion>`
    *   The Prover checks the rule against all possible inputs and execution contexts.
*   **Violations & Counter-examples**:
    *   If a rule is violated, the Prover provides a specific counter-example (inputs, variable values, call trace) showing *how* the property failed.
    *   Debugging often involves refining the rule to handle edge cases (e.g., `transfer` to self) using conditional assertions: `condition => assertion`.

## 2. ERC20 Example - Preconditions (`preconditions.html`)

*   **Over-approximation**: The Prover might explore theoretically possible states that are not actually reachable by the contract's logic. This can lead to false violation reports.
*   **`require`**: Used to add *preconditions* to a rule. It constrains the initial state considered by the Prover, filtering out unreachable or irrelevant scenarios.
    *   Example: `require totalBefore >= userBalanceBefore;` ensures the prover only checks scenarios where the total supply was valid *before* the tested function call.
*   **CVL Variables**: Basic variables declared in rules are immutable. Their initial values can be anything allowed by their type, unless constrained by `require` statements.

*(Summary based on provided web search results for the first two links. Content for `parametric.html`, `config_files.html`, and `vacuity.html` was not available.)* 