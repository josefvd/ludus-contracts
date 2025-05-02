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