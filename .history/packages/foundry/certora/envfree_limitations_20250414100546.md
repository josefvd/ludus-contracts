# Limitations of envfree with Complex Data Structures in Certora

## Overview

This document outlines the limitations encountered when using `envfree` with complex data structures during formal verification of the LudusEvents contract. The Certora Prover faces challenges when handling certain complex data types in envfree contexts, which can impact verification effectiveness.

## Identified Limitations

### 1. Nested Structures and Arrays

The LudusEvents contract uses nested structures and arrays extensively, such as:

- `LudusTypes.EventDetails` containing multiple fields
- `LudusTypes.Distribution` for treasury distribution
- `LudusTypes.AthleteDistribution` with arrays of positions and percentages
- `LudusTypes.EventAttestationData` with multiple string arrays

**Limitation**: In envfree context, Certora has difficulty tracking state changes in nested structures, especially when arrays are involved. This makes it challenging to verify properties about the integrity of these structures after state modifications.

### 2. Complex Method Parameters

Methods like `createEvent()` accept numerous parameters, including arrays and struct types:

```solidity
function createEvent(
    uint256 startTime,
    uint256 endTime,
    // ... more parameters ...
    uint256[] memory positions,
    uint256[] memory percentages,
    LudusTypes.EventAttestationData memory attestationData
) external returns (uint256)
```

**Limitation**: With envfree, passing complex structures as parameters can lead to over-abstraction, where the prover cannot precisely model the relationship between input parameters and resulting state changes.

### 3. External Contract Interactions

The LudusEvents contract interacts with multiple external contracts:

- LudusIdentity contract
- EAS attestation system
- JBTerminal for treasury management
- YieldManager for yield generation

**Limitation**: Envfree cannot capture the environmental context of these external calls, making it difficult to reason about cross-contract invariants without extensive harness specifications.

### 4. String Arrays and Dynamic Data

The contract uses string arrays for various event metadata:

```solidity
string[] rules;
string[] requirements;
string[] ticketTierNames;
```

**Limitation**: Certora has limited support for string manipulation and dynamic data structures in envfree context, requiring simplifications or abstractions that may weaken the verification model.

## Workarounds Implemented

1. **Simplified Property Checking**: Rules like `validTreasuryDistribution` and `validEventTimeline` focus on numerical relationships rather than complex structural properties.

2. **Function-Level Verification**: Rather than verifying properties across all contract functions, we've focused on critical safety properties within specific function boundaries.

3. **State Inspection**: Using post-condition checks on accessible state variables rather than trying to reason about the complete state transformation.

4. **Bounded Verification**: Using small, concrete bounds for array sizes and loop iterations to make verification tractable.

## Recommendations for Future Verification

1. **Decomposed Properties**: Break complex properties into smaller, more focused properties that can be verified independently.

2. **Custom Abstractions**: Create special-purpose abstraction functions for complex data structures to simplify reasoning.

3. **Environment Simulation**: For properties requiring environmental context, create explicit harness contracts that simulate the required environment.

4. **Parametric Rules**: Use parametric verification to cover different scenarios without requiring full environmental context.

5. **Combined Approach**: Use envfree for core safety properties, and combine with unit tests and traditional auditing for more complex behavioral properties.

## Conclusion

While envfree provides valuable capability for formally verifying critical safety properties, complex data structures in the LudusEvents contract expose the limitations of this approach. A comprehensive verification strategy should combine formal verification with other validation techniques to ensure complete coverage of the contract's behavior.

By understanding these limitations, we can better target our formal verification efforts toward properties that can be meaningfully verified within the constraints of the envfree model. 