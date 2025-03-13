// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IYieldManager {
    function usdc() external view returns (address);
    function weth() external view returns (address);
    function stakeEventFunds(uint256 eventId, uint256 amount) external;
    function stakeEventFundsETH(uint256 eventId) external payable;
    function withdrawEventFunds(uint256 eventId) external returns (uint256);
    function withdrawEventFundsETH(uint256 eventId) external returns (uint256);
    function setDistribution(
        uint256 eventId,
        uint256 athletesShare,
        uint256 organizerShare,
        uint256 charityShare,
        address charityAddress
    ) external;
    function getEventYield(uint256 eventId) external view returns (uint256);
    function getEventYieldETH(uint256 eventId) external view returns (uint256);
    function isYieldGenerationEnabled(uint256 eventId) external view returns (bool);
    function isYieldGenerationEnabledETH(uint256 eventId) external view returns (bool);
    function getEventStake(uint256 eventId) external view returns (uint256);
    function getEventStakeETH(uint256 eventId) external view returns (uint256);
    function getEventBalance(uint256 eventId) external view returns (uint256);
    function getEventBalanceETH(uint256 eventId) external view returns (uint256);
    function getEventTotalFunds(uint256 eventId) external view returns (uint256);
    function getEventTotalFundsETH(uint256 eventId) external view returns (uint256);
    function updateEventYield(uint256 eventId) external returns (uint256);
    function updateEventYieldETH(uint256 eventId) external returns (uint256);
    function enableYieldGeneration(uint256 eventId) external;
} 