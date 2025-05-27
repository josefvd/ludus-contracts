# Certora Inductiveness Process

## Steps for Proving Inductive Invariants

1. **Define the Invariant:**
   - Write the property you want to prove as an invariant in the CVL spec file.

2. **Stub External Dependencies:**
   - Replace all external contract calls with stubs that match the interface but have deterministic, simple behavior.

3. **Align Specs with Contract:**
   - Ensure all function signatures, types, and tuple unpacking in the spec match the contract exactly.

4. **Run Certora Prover:**
   - Use a config file that links the contract under verification to the stubs.
   - Run the prover and check for violations or warnings.

5. **Interpret Results:**
   - If the invariant holds after the constructor and is preserved by all external (non-view) methods, Certora will show the property as inductive.
   - Warnings about unrelated or unimplemented functions do not affect the proof for the current property.
   - If violations are found, refine the stubs/specs and rerun.

6. **Document and Clean Up:**
   - Record the process, results, and any stub/spec changes for future reference.

## Interpreting Certora Output

- **Green Checkmarks:** Indicate the property is inductive for the isolated contract.
- **Warnings:** Usually relate to unimplemented or irrelevant functions; safe to ignore if not part of the property logic.
- **Violations:** Address these by refining stubs or fixing spec/contract mismatches.

---

*This process ensures that the property is inductive for the isolated, stubbed contract as verified by Certora.* 