# Certora Verification Learnings

## Key Learnings from the Certora Verification Process

- **Stub Harnessing:**
  - Use stub contracts for all external dependencies to isolate the contract under verification.
  - Stubs should match the interface signatures and types exactly.
  - For problematic functions (e.g., dynamic hashing), return constant values in the stub to avoid prover limitations.

- **Spec Alignment:**
  - Ensure all CVL spec function signatures match the contract exactly, including custom types (enums, structs).
  - Unpack all return values from tuple-returning functions, even if some are unused.
  - Use the correct types for enums and custom types in both the `methods` block and helper functions.

- **Error Resolution:**
  - Type mismatches and tuple unpacking errors are common; always check the number and type of variables.
  - Certora warnings about unresolved calls or unbounded hashing can be fixed by simplifying stubs.
  - Use Certora's static analysis feedback to iteratively refine both specs and stubs.

- **Inductive Invariants:**
  - Certora proves an invariant inductively if it holds after the constructor and is preserved by all external (non-view) methods.
  - Warnings about unrelated or unimplemented functions do not invalidate the proof for the property being checked, as long as the relevant logic is covered.

- **General Advice:**
  - Keep a checklist for each verification run to track progress and issues.
  - Document stub and spec changes for future maintainers. 