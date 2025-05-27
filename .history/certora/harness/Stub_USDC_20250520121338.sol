// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Stub_USDC is IERC20 {
    string public constant name = "Stub USDC";
    string public constant symbol = "sUSDC";
    uint8 public constant decimals = 6;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal _totalSupply;

    constructor() {
        // Mint some to a known address if needed for specific test setups, or leave as is
        // _mint(msg.sender, 1_000_000 * 10**uint256(decimals())); // Example
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        // For isolated verification of LudusEvents, we often don't need full balance logic
        // unless an invariant specifically checks USDC balances changing.
        // Defaulting to success is common for harnessing.
        // _balances[msg.sender] -= amount;
        // _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true; 
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        // Similar to transfer, often simplified to always return true for harnessing.
        // uint256 currentAllowance = _allowances[sender][msg.sender];
        // require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        // _allowances[sender][msg.sender] = currentAllowance - amount;
        // _balances[sender] -= amount;
        // _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Internal mint function if needed for setup (e.g., in constructor or a test setup function)
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
} 