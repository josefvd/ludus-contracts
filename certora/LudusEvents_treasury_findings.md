# Findings for LudusEvents_treasury.spec

## Date: [Current Date]

## Status:
The `validTreasuryDistribution` invariant in `certora/specs/LudusEvents_treasury.spec` currently fails verification.

## Key Issues Identified:

1.  **Syntax for `methods` block (CVL2):**
    *   Initial attempts to use explicit `summary;` keyword with `external` (e.g., `function foo() external summary;`) or just `summary;` (e.g., `function foo() summary;`) caused parsing errors.
    *   **Resolution:** For methods that are not `envfree` or `optional`, CVL2 defaults to `summary`. The correct syntax is to declare them with visibility (e.g., `external`) and a semicolon: `function foo() external;` or `function foo() external returns (rettype);`. This resolved the spec parsing errors.

2.  **Logical Violations due to Havoced External Calls (ERC20 Tokens):**
    *   The primary cause of the `validTreasuryDistribution` invariant failing is due to unmodeled behavior of external `IERC20` calls (`_USDC` and `_WETH` tokens) made by the `YieldManager` contract (which is called by `LudusEventsImpl`).
    *   Specifically, calls like `_USDC.allowance(address,address)` and `_USDC.approve(address,uint256)` within `YieldManager` functions (e.g., `approveAavePool`, `stakeEventFunds`) are being `AUTO havoc`'d by the Certora Prover.
    *   This means the Prover assumes these external token calls can have any behavior (e.g., `allowance` returns any value, `approve` has no effect or any arbitrary effect on allowances).
    *   This unconstrained behavior of token interactions allows the Prover to find scenarios (counterexamples) where the `validTreasuryDistribution` invariant is violated.
    *   The Certora report for the last run (`https://prover.certora.com/output/9683541/421b5ffd9f4343f6a33b2cace135fe09?anonymousKey=ab28f21efe1716f5a9908cd98c299a8d7d3d61b5`) shows this, for example, in the call trace for `YieldManager.approveAavePool`.

## Next Steps (Recommended for `LudusEvents_treasury.spec` when revisited):

1.  **Model IERC20 Interactions:**
    *   Define `IERC20` interface or ensure it's correctly picked up from linked libraries (e.g., OpenZeppelin).
    *   In `LudusEvents_treasury.spec` (or a shared spec for external contracts), add `methods` summaries for key `IERC20` functions:
        *   `allowance(address,address) returns (uint256)`
        *   `approve(address,uint256) returns (bool)`
        *   `transfer(address,uint256) returns (bool)`
        *   `transferFrom(address,address,uint256) returns (bool)`
        *   `balanceOf(address) returns (uint256)`
    *   These summaries need to accurately reflect how these functions change token state (balances, allowances) so the Prover can reason about them correctly. This typically involves using state variables within the spec (e.g., maps to model balances and allowances) that are updated by these summary functions.
2.  **Declare Token Contracts in Spec:**
    *   If `YieldManager` has state variables like `IERC20 _USDC;` and `IERC20 _WETH;`, these might need to be declared within a `contract YieldManager { ... }` block in the spec to help Certora link the calls.
3.  **Link Contracts in `events.conf`:**
    *   Ensure that if `_USDC` and `_WETH` are specific contract implementations, their source files are included in the `"files"` array in `certora/conf/events.conf`, and they are correctly linked if necessary. If they are just interface types, the summaries for `IERC20` would apply. 