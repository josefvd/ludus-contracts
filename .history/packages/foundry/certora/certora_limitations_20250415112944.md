# Certora Verification Findings and Limitations

This document tracks findings and limitations encountered during the Certora verification process for the Ludus contracts.

## Initial State Assumption (Certora Prover)

- **Issue:** The Certora Prover starts its analysis from an arbitrary state. It does not inherently know about constraints or properties established by previous transactions or the history of the contract state unless explicitly defined within the rule or through mechanisms like invariants.
- **Impact:** Rules assuming certain state properties (e.g., relationships between existing events) might fail because the prover considers scenarios where those properties don't hold in the initial arbitrary state.
- **Example:** The initial `validEventTimeline` rule failed because it assumed existing events followed certain timeline rules, which the prover couldn't guarantee from an arbitrary starting point.

## Recommended Verification Strategies

Based on feedback from the Certora team:

1.  **Function-Scoped Rules:** Verify properties directly within the context of the function that establishes them. For instance, check event creation rules within a rule filtered for the `createEvent` function. This ensures the property holds *at the time of creation*. These proven properties might potentially be used as assumptions (`require`) in other rules.
2.  **Invariants:** Use invariants for properties that must hold true across the contract's lifetime, *before and after* every external function call. This is suitable for maintaining consistent state guarantees.

## Complex Data Structures (`envfree`)

- Certora's `envfree` functions (which don't interact with the environment/state directly) currently have limitations when dealing with complex data structures like nested arrays or structs passed as arguments or return values. This requires careful consideration when defining function signatures and rules. We are using simpler rules for now to avoid these complexities where possible.

## Induction Approach for Event Creation

Based on Certora team feedback regarding induction, the verification approach for `LudusEvents` has been updated:

1.  **`createEvent` Assertions:** New rules `checkCreateEventTimeline` and `checkCreateEventTreasuryDistribution` were added to `LudusEvents.spec`. These rules use `filtered` blocks to run *after* a successful `createEvent` call. They assert that:
    *   The event timeline is valid (`startTime > block.timestamp`, `endTime > startTime`, `registrationStartTime < registrationEndTime`, `registrationEndTime <= startTime`, `registrationStartTime >= block.timestamp`).
    *   The treasury distribution sums correctly (e.g., `athletesShare + organizerShare + charityShare == 9700`) and the `charityAddress` is valid if `charityShare > 0`.

2.  **Assumptions in Other Rules:** Rules governing other event lifecycle functions (`startEvent`, `cancelEvent`, `completeEvent`, `registerForEvent`, etc.) and the `validEventStatusTransitions` invariant now include `require` statements at the beginning (e.g., `require isValidTimeline(eventId, e.block.timestamp); require isValidTreasuryDistribution(eventId);`). These `require` statements assume that any event being processed already satisfies the timeline and distribution properties, based on the guarantees proven by the `createEvent` rules. This avoids redundant checks and focuses verification on the specific logic of each function, assuming a valid initial state established during creation.

3.  **Helper Predicates:** Ghost functions `isValidTimeline` and `isValidTreasuryDistribution` were added to encapsulate the state checks used in the `require` assumptions.

## Execution Issues & Resolution

During the implementation and verification run, several technical issues were encountered:

*   **`ModuleNotFoundError: No module named certora.run`:** The command `python -m certora.run` used in the original run script failed despite `certora-cli` being installed. Investigation revealed that the package structure places binaries and libraries under `certora_cli`, etc., but not a top-level `certora` module.
*   **`certoraRun` Compatibility:** The alternative command `certoraRun` was found but required significant adjustments to the `certora_events.conf` file, as it does not recognize fields like `settings`, `rule_flags`, `spec_files`, etc. Numeric values like `loop_iter` also needed to be strings.
*   **Path Issues:** `certoraRun` exhibited issues resolving relative paths when executed from the run script, requiring manual execution or careful path handling.
*   **Prerequisites:** Execution requires `node_modules` to be installed (`npm install` in `packages/foundry`) and the specific Solidity compiler version (`solc8.19`) to be available.

The final working command structure used was manual execution via:
```bash
source certora-venv/bin/activate 
export CERTORAKEY="YOUR_KEY_HERE" 
# Ensure solc 0.8.19 is active (e.g., using solc-select)
solc-select use 0.8.19 
certoraRun packages/foundry/certora/certora_events.conf --rule checkCreateEventTimeline --rule checkCreateEventTreasuryDistribution --wait_for_results
```

## Outstanding Verification Runs

*(Add Certora run links here once available)* 