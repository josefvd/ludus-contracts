// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../src/interfaces/IYieldManager.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Stub_YieldManager is IYieldManager {
    address public usdcTokenAddress;
    address public wethTokenAddress;
    address public owner;

    event DistributionSet(uint256 indexed eventId, uint256 athletesShare, uint256 organizerShare, uint256 charityShare, address charityAddress);
    event YieldGenerationEnabled(uint256 indexed eventId, bool isETH);
    event FundsStakedETH(uint256 indexed eventId, uint256 amount);
    event FundsStakedUSDC(uint256 indexed eventId, uint256 amount);
    event FundsWithdrawnETH(uint256 indexed eventId, uint256 principal, uint256 yield);
    event FundsWithdrawnUSDC(uint256 indexed eventId, uint256 principal, uint256 yield);

    constructor(address _usdcTokenAddress, address _wethTokenAddress) {
        usdcTokenAddress = _usdcTokenAddress;
        wethTokenAddress = _wethTokenAddress;
        owner = msg.sender;
    }

    function usdc() external view returns (address) {
        return usdcTokenAddress;
    }

    function weth() external view returns (address) {
        return wethTokenAddress;
    }

    function setDistribution(
        uint256 eventId,
        uint256 athletesShare,
        uint256 organizerShare,
        uint256 charityShare,
        address charityAddress
    ) external {
        emit DistributionSet(eventId, athletesShare, organizerShare, charityShare, charityAddress);
    }

    function stakeEventFundsETH(uint256 eventId) external payable {
        emit FundsStakedETH(eventId, msg.value);
    }

    function stakeEventFundsUSDC(uint256 eventId, uint256 amount) external {
        emit FundsStakedUSDC(eventId, amount);
    }

    function enableYieldGeneration(uint256 eventId) external {
        emit YieldGenerationEnabled(eventId, true);
    }

    function withdrawEventFundsETH(uint256 eventId) external returns (uint256) {
        emit FundsWithdrawnETH(eventId, 0, 0);
        return 0;
    }

    function withdrawEventFundsUSDC(uint256 eventId) external returns (uint256) {
        emit FundsWithdrawnUSDC(eventId, 0, 0);
        return 0;
    }

    function getEventYield(uint256 eventId) external view returns (uint256) {
        return 0;
    }

    function getEventYieldETH(uint256 eventId) external view returns (uint256) {
        return 0;
    }

    function isYieldGenerationEnabled(uint256 eventId) external view returns (bool) {
        return false;
    }

    function isYieldGenerationEnabledETH(uint256 eventId) external view returns (bool) {
        return false;
    }

    function getEventStake(uint256 eventId) external view returns (uint256) {
        return 0;
    }

    function getEventStakeETH(uint256 eventId) external view returns (uint256) {
        return 0;
    }

    function getEventBalance(uint256 eventId) external view returns (uint256) {
        return 0;
    }

    function getEventBalanceETH(uint256 eventId) external view returns (uint256) {
        return 0;
    }

    function getEventTotalFunds(uint256 eventId) external view returns (uint256) {
        return 0;
    }

    function getEventTotalFundsETH(uint256 eventId) external view returns (uint256) {
        return 0;
    }

    function updateEventYield(uint256 eventId) external returns (uint256) {
        return 0;
    }

    function updateEventYieldETH(uint256 eventId) external returns (uint256) {
        return 0;
    }

    receive() external payable {}
} 