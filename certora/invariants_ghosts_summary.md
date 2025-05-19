# Certora Invariants, Preserved Blocks, and Ghosts Summary (from Tutorials)

This document summarizes key concepts from Certora Tutorial Lesson 4 on invariants, preserved blocks, ghosts, and hooks. These features allow for verifying deeper properties of smart contracts by defining expected state conditions and tracking abstract properties not directly present in the Solidity code.

Based on the content found at:
*   [https://docs.certora.com/projects/tutorials/en/latest/lesson4_invariants/invariants/simple.html](https://docs.certora.com/projects/tutorials/en/latest/lesson4_invariants/invariants/simple.html)
*   [https://docs.certora.com/projects/tutorials/en/latest/lesson4_invariants/invariants/auction.html](https://docs.certora.com/projects/tutorials/en/latest/lesson4_invariants/invariants/auction.html)
*   [https://docs.certora.com/projects/tutorials/en/latest/lesson4_invariants/invariants/preserved.html](https://docs.certora.com/projects/tutorials/en/latest/lesson4_invariants/invariants/preserved.html)
*   [https://docs.certora.com/projects/tutorials/en/latest/lesson4_invariants/ghosts/basics.html](https://docs.certora.com/projects/tutorials/en/latest/lesson4_invariants/ghosts/basics.html)
*   (Exercises implicitly referenced for context, e.g., ghosts/exercises.html)

## 1. Invariants (`simple.html`, `auction.html`)

*   **Core Idea**: An invariant is a property expressed in CVL that must hold true *at all observable states* of the contract. This means it must be true after the constructor completes and must remain true after every subsequent external/public function call successfully finishes.
*   **Syntax**:
    ```cvl
    invariant invariantName(arg_declarations...) // Optional arguments
        boolean_condition; // The property that must always hold
    ```
*   **Verification Principle (Proof by Induction)**:
    1.  **Base Case**: The Prover checks if the invariant holds true immediately after the contract's deployment (after the constructor executes).
    2.  **Inductive Step**: For *every* possible external/public function `f`, the Prover *assumes* the invariant holds *before* `f` is called (the inductive hypothesis), then checks if the invariant *still holds* *after* `f` completes its execution. If this holds for all functions, the invariant is proven.
*   **vs. Rules**:
    *   Invariants are powerful because they automatically cover the base case (constructor) and the inductive step for *all* current and future public/external functions without needing explicit function calls in the spec.
    *   A *parametric rule* (e.g., `rule check(method f) {...}`) can mimic the *inductive step* of an invariant but requires manually adding a precondition: `require invariant_condition_holds_before;`. Crucially, parametric rules *do not* automatically check the base case (constructor state).
    *   A naive rule asserting the condition without the precondition (`require`) will likely fail, as it lacks the inductive hypothesis assumption needed for the proof.
*   **Examples**:
    *   `votesInFavor + votesAgainst == totalVotes` (Simple Voting: Ensures vote counts are consistent).
    *   `balanceOf(address(0)) == 0` (ERC20: `address(0)` should never hold tokens; finding violations often points to bugs in `transfer`/`mint`/`burn`).
    *   `highestBid >= bids[bidder]` for all bidders (English Auction: No bid should exceed the recorded highest bid).
    *   `bids[highestBidder] == highestBid` (English Auction: The highest bidder's recorded bid must match the highest bid amount. Requires careful handling of the initial state where `highestBidder` might be `address(0)`).
*   **`optimistic_loop` Flag**: Often necessary (`--optimistic_loop` or `"optimistic_loop": true` in config) when invariants involve contract functions returning dynamic types (like `string`, `bytes`, or dynamic arrays), as loop summarization is needed.
*   **Summary**: Invariants define universal properties that must *always* be maintained by the contract, providing strong guarantees about its state integrity.

## 2. Preserved Blocks (`preserved.html`)

*   **Core Idea**: Proving the inductive step of an invariant (`invariant P holds after f`) sometimes requires assuming that `P` (or another invariant `Q`) *also held true* for *other relevant state components* just before `f` was called. Preserved blocks provide a mechanism to state these necessary assumptions *soundly*.
*   **Use Case Motivation**: Consider proving `collateral[x] >= debt[x]` for an account `x`. If a function `transferDebt(from, to, amount)` exists, proving the invariant still holds for `to` after the transfer might require knowing it held for `from` *before* the transfer.
*   **Syntax**:
    ```cvl
    invariant invariantName(address account)
        condition(account)
    {
        // Optional: Default preserved block applied if no specific function block matches
        preserved {
           // Assumptions for functions not explicitly listed below
           // requireInvariant someOtherInvariant(...);
        }

        // Specific preserved block for a particular function signature
        preserved functionSignature(arg_declarations...) [with (env e)] // `with (env e)` needed if func uses env vars
        {
            // State assumptions specific to this function's execution
            requireInvariant invariantName(e.msg.sender); // Common: Assume invariant holds for the caller
            requireInvariant someOtherInvariant(relevant_arg); // Assume another invariant holds
        }
        // ... other specific preserved blocks ...
    }
    ```
*   **`requireInvariant` vs. `require`**:
    *   `requireInvariant invariantName(...)`: This is the **sound** way to introduce assumptions within preserved blocks. It tells the Prover: "You can assume `invariantName` holds here, *provided you also prove `invariantName` globally*". It leverages the invariant's own inductive proof.
    *   `require condition`: Using a regular `require` inside a preserved block is generally **unsound**. It introduces an assumption without proof obligation, potentially hiding violations and leading to false positives (incorrectly verified rules/invariants). Avoid it unless you have a very specific, justifiable reason.
*   **`with (env e)`**: Necessary if the function signature being matched in the `preserved` block uses environment variables (like `msg.sender`, `block.timestamp`, etc.) and you need to refer to them within the block (e.g., `requireInvariant invariantName(e.msg.sender)`).
*   **Example (DebtToken)**: To prove `collateralOf(account) >= balanceOf(account)` is maintained by `transferDebt(recipient)`, where `msg.sender` transfers *their* debt to `recipient`, the preserved block for `transferDebt` needs: `requireInvariant collateralCoversBalance(e.msg.sender);`. This assumes the sender's collateral covered their balance *before* the transfer, which is necessary for the recipient's state to be valid *after*.
*   **Summary**: Preserved blocks allow stating necessary preconditions for the inductive step of an invariant proof, ensuring soundness by linking these assumptions back to the global proof of the required invariants themselves.

## 3. Ghosts and Hooks (`basics.html`)

*   **Core Idea**: Ghost variables are abstract state variables existing *only* in the CVL specification, not in the Solidity code. They track information needed for verification (e.g., aggregate sums, interaction states) that isn't explicitly stored on-chain. Hooks automatically update these ghost variables based on observing low-level EVM execution details (like storage changes or function calls).
*   **Ghost Variables**:
    *   Purpose: Track implicit properties, simulate reference models, maintain aggregates.
    *   Syntax:
        ```cvl
        // Simple ghost variable
        ghost uint256 ghostTotalSupply;

        // Ghost mapping
        ghost mapping(address => uint) ghostInteractionCount;

        // Ghost with initial state axiom
        ghost uint256 counter {
            // `init_state` defines the value right after constructor
            init_state axiom counter == 0;
        }
        ```
    *   Initialization: Defined using `init_state` rules (checked after constructor) or directly within the ghost definition block using `init_state axiom`.
*   **Hooks**:
    *   Purpose: Observe EVM execution and update ghost state accordingly. They bridge the spec's abstract view with the contract's concrete operations.
    *   Common Hooks: `Sload` (storage read), `Sstore` (storage write), `Call`, `Staticcall`, `Delegatecall`, `Create`, `Create2`, `Return` (successful function return), `Revert` (function revert), `Selfdestruct`.
    *   Syntax & Filtering:
        ```cvl
        // Hook Sstore on the '_balances' mapping variable
        // Updates ghostTotalSupply whenever any balance changes
        hook Sstore _balances[KEY address user] uint newBalance (uint oldBalance) {
           ghostTotalSupply = ghostTotalSupply - oldBalance + newBalance;
        }

        // Hook Sstore on a specific storage slot (advanced)
        hook Sstore 0x0 { ... } // Hook writes to slot 0

        // Hook Call to a specific function by signature
        hook Call FuncSig "transfer(address,uint256)" (address to, uint256 amount) {
            ghostInteractionCount[e.msg.sender] = ghostInteractionCount[e.msg.sender] + 1;
        }

        // Hook any external Call made by the primary contract
        hook Call { // Can filter further by contract address, etc.
            // ... update ghosts ...
        }
        ```
    *   Filtering: Hooks can be precisely targeted based on:
        *   Storage Variable Name: `hook Sstore _variableName ...`
        *   Storage Slot: `hook Sstore 0x... ...`
        *   Function Signature: `hook Call FuncSig "name(types...)" ...`
        *   Target Contract Address: (e.g., only hooks calls *to* a specific external contract)
*   **Use Cases & Examples**:
    *   **Aggregate Calculation**: Maintaining `ghostTotalSupply` in ERC20 via `Sstore` hooks on `_balances`.
    *   **Interaction Tracking**: Using `ghost mapping(address => bool) hasVoted;` updated by a `Call` hook on the `vote` function.
    *   **Reference Model**: Implementing a simplified state machine as ghosts to check against the contract's logic.
    *   **Reentrancy Guard Check**: A common pattern uses `ghost uint entryCounter;` incremented on `Call` hooks (entering the contract) and decremented on `Return`/`Revert` hooks (exiting). Invariants then check `entryCounter <= 1`.
*   **Summary**: Ghosts and hooks provide powerful abstraction capabilities, allowing specifications to track and reason about complex behaviors, state aggregations, and interaction patterns that go beyond the explicitly stored contract state.

---

In summary, invariants establish universal contract properties. Preserved blocks provide the necessary sound assumptions for proving complex invariants. Ghosts and hooks enable tracking and verifying abstract states and behaviors by observing low-level execution, allowing for comprehensive formal verification. 