// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IYieldManager} from "../../src/interfaces/IYieldManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Stub_YieldManager is IYieldManager {
    address public usdcTokenAddress;
    address public owner;

    event DistributionSet(uint256 indexed eventId, uint256 athletesShare, uint256 organizerShare, uint256 charityShare, address charityAddress);
    event YieldGenerationEnabled(uint256 indexed eventId, bool isETH);
    event FundsStakedETH(uint256 indexed eventId, uint256 amount);
    event FundsStakedUSDC(uint256 indexed eventId, uint256 amount);
    event FundsWithdrawnETH(uint256 indexed eventId, uint256 principal, uint256 yield);
    event FundsWithdrawnUSDC(uint256 indexed eventId, uint256 principal, uint256 yield);

    constructor(address _usdcTokenAddress) {
        usdcTokenAddress = _usdcTokenAddress;
        owner = msg.sender; // Or a fixed address for tests
    }

    function usdc() external view override returns (address) {
        return usdcTokenAddress;
    }

    function setDistribution(
        uint256 eventId,
        uint256 athletesShare,
        uint256 organizerShare,
        uint256 charityShare,
        address charityAddress
    ) external override {
        // No-op for harness, or emit an event if useful for spec
        emit DistributionSet(eventId, athletesShare, organizerShare, charityShare, charityAddress);
    }

    function stakeEventFundsETH(uint256 eventId) external payable override {
        // No-op for harness, or emit an event
        emit FundsStakedETH(eventId, msg.value);
    }

    function stakeEventFundsUSDC(uint256 eventId, uint256 amount) external override {
        // No-op for harness, or emit an event
        // IERC20(usdcTokenAddress).transferFrom(msg.sender, address(this), amount); // Not needed if LudusEvents approves YieldManager
        emit FundsStakedUSDC(eventId, amount);
    }

    function enableYieldGeneration(uint256 eventId) external override {
        // No-op for harness, or emit an event
        emit YieldGenerationEnabled(eventId, true); // Assuming ETH for simplicity or make it configurable
    }

    function withdrawEventFundsETH(uint256 eventId) external override returns (uint256) {
        // Return 0 or a symbolic value if needed by the spec.
        // For LudusEvents, it expects some ETH back, so we might need to send some if it tries to use the return value.
        // However, LudusEvents.sol adds the result to eventPrizesETH[eventId], so returning 0 yield is simplest.
        emit FundsWithdrawnETH(eventId, 0, 0); // principal, yield
        return 0; 
    }

    function withdrawEventFundsUSDC(uint256 eventId) external override returns (uint256) {
        // Return 0 or a symbolic value.
        emit FundsWithdrawnUSDC(eventId, 0, 0); // principal, yield
        return 0;
    }

    // Add a receive function if the harness itself needs to receive ETH for some reason
    // (though stakeEventFundsETH is payable)
    receive() external payable {}
} 