# Certora Invariants, Preserved Blocks, and Ghosts Summary (from Tutorials)

This document summarizes key concepts from Certora Tutorial Lesson 4 on invariants, preserved blocks, ghosts, and hooks. These features allow for verifying deeper properties of smart contracts by defining expected state conditions and tracking abstract properties not directly present in the Solidity code.

Based on the content found at:
*   [https://docs.certora.com/projects/tutorials/en/latest/lesson4_invariants/invariants/simple.html](https://docs.certora.com/projects/tutorials/en/latest/lesson4_invariants/invariants/simple.html)
*   [https://docs.certora.com/projects/tutorials/en/latest/lesson4_invariants/invariants/auction.html](https://docs.certora.com/projects/tutorials/en/latest/lesson4_invariants/invariants/auction.html)
*   [https://docs.certora.com/projects/tutorials/en/latest/lesson4_invariants/invariants/preserved.html](https://docs.certora.com/projects/tutorials/en/latest/lesson4_invariants/invariants/preserved.html)
*   [https://docs.certora.com/projects/tutorials/en/latest/lesson4_invariants/ghosts/basics.html](https://docs.certora.com/projects/tutorials/en/latest/lesson4_invariants/ghosts/basics.html)
*   (Exercises implicitly referenced for context, e.g., ghosts/exercises.html)

## 1. Invariants (`simple.html`, `auction.html`)

*   **Core Idea**: An invariant is a property expressed in CVL that is expected to hold true *at all times* during the contract's lifecycle. The Certora Prover checks if the invariant holds after the constructor finishes and remains true after every possible external/public function call.
*   **Syntax**:
    ```cvl
    invariant invariantName(arg_declarations...)
        boolean_condition;
    ```
*   **Verification Principle (Induction)**:
    1.  **Base Case**: The Prover checks if the invariant holds true immediately after the contract's deployment (after the constructor executes).
    2.  **Inductive Step**: For every possible external/public function `f`, the Prover *assumes* the invariant holds *before* `f` is called and checks if it *still holds* *after* `f` completes execution.
*   **vs. Rules**:
    *   Invariants automatically cover the base case (constructor) and the inductive step for all functions.
    *   A *parametric rule* can mimic the *inductive step* of an invariant but requires manually adding a precondition assuming the property held before the call. It does *not* automatically check the base case (constructor).
    *   A naive rule without the precondition (`require invariant_holds_before;`) will likely fail, as it doesn't establish the assumption needed for the inductive step.
*   **Examples**:
    *   `votesInFavor + votesAgainst == totalVotes` (Simple Voting).
    *   `balanceOf(address(0)) == 0` (ERC20 - might reveal bugs!).
    *   `highestBid >= bids[bidder]` for all bidders (English Auction).
    *   `bids[highestBidder] == highestBid` (English Auction - requires handling initial state where `highestBidder` might be `address(0)`).
*   **`optimistic_loop`**: May be needed if the invariant relies on functions returning dynamic types (like `string` in ERC20 `name()`/`symbol()`) until loop handling is properly configured.

## 2. Preserved Blocks (`preserved.html`)

*   **Core Idea**: Sometimes, proving the *inductive step* of an invariant for a specific function call requires assuming that the *same invariant* (or another related invariant) holds true for *other* relevant parts of the contract state *before* the call. Preserved blocks provide a sound way to introduce these necessary assumptions.
*   **Use Case**: When a function modifies state based on multiple objects or addresses (e.g., a transfer involving `sender` and `recipient`), proving the invariant holds for `recipient` after the call might require assuming it held for `sender` before the call.
*   **Syntax**:
    ```cvl
    invariant invariantName(address account)
        condition(account)
    {
        // Optional: Default block applied if no specific function block matches
        preserved {
           // requireInvariant someOtherInvariant(...);
        }

        // Specific block for a function
        preserved functionSignature(arg_declarations...) [with (env e)]
        {
            // Assumption needed for this function
            requireInvariant invariantName(e.msg.sender); // Example: Assume invariant holds for the caller
            // requireInvariant otherInvariant(...);
        }
    }
    ```
*   **`requireInvariant`**: This is the *key* statement within a preserved block. It allows you to assume another invariant holds. This is **sound** because the Prover must *also* successfully verify the invariant being assumed (`invariantName` or `otherInvariant` in the example). Using a simple `require` here can be unsound and lead to missed violations.
*   **`with (env e)`**: If the function signature in the `preserved` block is not `envfree`, you need `with (env e)` to access environment variables like `e.msg.sender` within the block.
*   **Example**: To prove `collateralOf(account) >= balanceOf(account)` holds after `transferDebt(account)` (where `msg.sender` sends debt *to* `account`), we need to assume `collateralOf(msg.sender) >= balanceOf(msg.sender)` held *before* the transfer. This assumption is added using `requireInvariant collateralCoversBalance(e.msg.sender);` inside a `preserved transferDebt(...)` block.

## 3. Ghosts and Hooks (`basics.html`)

*   **Core Idea**: Ghost variables are state variables defined *only* in the CVL specification, not in the Solidity contract. They are used to track abstract properties or aggregate information needed for verification but not explicitly stored by the contract. Hooks are used to automatically update these ghost variables based on the contract's execution (like storage changes or function calls).
*   **Ghost Variables**:
    *   Track state that's implied but not explicit (e.g., total supply derived from balances, whether a user has interacted before).
    *   Syntax:
        ```cvl
        // Simple ghost
        ghost uint256 ghostTotalSupply;

        // Ghost mapping
        ghost mapping(address => bool) hasInteracted;

        // Initialized ghost
        ghost uint256 counter {
            init_state axiom counter == 0;
        }
        ```
    *   Initialization: Can be done via `init_state` rules or sometimes directly in the ghost definition.
*   **Hooks**:
    *   Trigger updates to ghost variables based on low-level operations.
    *   Common Hooks: `Sload` (storage load), `Sstore` (storage store), `Call`, `Staticcall`, `Delegatecall`, `Create`, `Create2`, `Return`, `Revert`, `Selfdestruct`.
    *   Syntax:
        ```cvl
        // Hook on storage writes to a specific variable (_balances mapping)
        hook Sstore _balances[KEY address user] uint newBalance (uint oldBalance) {
           ghostTotalSupply = ghostTotalSupply - oldBalance + newBalance;
           hasInteracted[user] = true;
        }

        // Hook on external calls to a specific function
        hook Call FuncSig functionName(arg_declarations...) {
            // Update ghosts based on call arguments or env
        }
        ```
    *   Filtering: Hooks can be filtered by contract address, function signature (`FuncSig`), storage variable (`-> _variableName` or specific slots), etc.
*   **Use Cases**:
    *   Calculating aggregate values (e.g., total supply from balance changes).
    *   Tracking interaction patterns (e.g., marking addresses that have called certain functions).
    *   Implementing reference models or state machines within the spec.
    *   Checking complex properties like reentrancy guards by tracking execution depth or state.
*   **Example**: Using `Sstore` hooks on the `_balances` mapping in an ERC20 contract to maintain a `ghostTotalSupply` variable, which can then be used in invariants or rules. Tracking `nonces` or states in a reentrancy guard using ghost mappings updated by `Call` hooks.

---

In summary, invariants provide a powerful way to state universal properties. Preserved blocks handle the interdependencies often needed to prove invariants in complex contracts. Ghosts and hooks extend verification capabilities further by allowing the tracking and reasoning about abstract state and behavior not directly encoded in the contract's storage, enabling the formal verification of more sophisticated properties. 