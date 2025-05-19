// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILudusEventsOracle {
    function getCompletedEventCount() external view returns (uint256);
} 