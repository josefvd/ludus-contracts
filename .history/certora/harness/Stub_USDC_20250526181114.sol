// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

abstract contract Stub_USDC is IERC20 {
    string public constant name = "Stub USDC";
    string public constant symbol = "sUSDC";
    uint8 public constant decimals = 6;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    constructor() {
        // Mint some to a known address if needed for specific test setups, or leave as is
        // _mint(msg.sender, 1_000_000 * 10**uint256(decimals())); // Example
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _allowances[sender][msg.sender] -= amount;
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        return true;
    }

    // Harness helpers
    function mockMint(address to, uint256 amount) public {
        _balances[to] += amount;
        _totalSupply += amount;
    }

    function mockSetBalance(address account, uint256 amount) public {
        _totalSupply = _totalSupply - _balances[account] + amount;
        _balances[account] = amount;
    }

    // Internal mint function if needed for setup (e.g., in constructor or a test setup function)
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
} 