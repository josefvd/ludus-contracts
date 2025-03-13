// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IWETH
 * @dev Interface for the Wrapped Ether (WETH) contract
 */
interface IWETH {
    /**
     * @dev Deposit ether to get wrapped ether
     */
    function deposit() external payable;

    /**
     * @dev Withdraw wrapped ether to get ether
     */
    function withdraw(uint256) external;

    /**
     * @dev Transfer wrapped ether
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Approve wrapped ether for spending
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Get the balance of an account
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Get the allowance of a spender for an owner
     */
    function allowance(address owner, address spender) external view returns (uint256);
} 