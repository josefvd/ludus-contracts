// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../src/interfaces/IYieldManager.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

abstract contract Stub_YieldManager is IYieldManager {
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
        owner = msg.sender;
    }

    function usdc() public view returns (address) {
        return usdcTokenAddress;
    }

    function setDistribution(
        uint256 eventId,
        uint256 athletesShare,
        uint256 organizerShare,
        uint256 charityShare,
        address charityAddress
    ) public {
        emit DistributionSet(eventId, athletesShare, organizerShare, charityShare, charityAddress);
    }

    function stakeEventFundsETH(uint256 eventId) public payable {
        emit FundsStakedETH(eventId, msg.value);
    }

    function stakeEventFundsUSDC(uint256 eventId, uint256 amount) public {
        emit FundsStakedUSDC(eventId, amount);
    }

    function enableYieldGeneration(uint256 eventId) public {
        emit YieldGenerationEnabled(eventId, true);
    }

    function withdrawEventFundsETH(uint256 eventId) public returns (uint256) {
        emit FundsWithdrawnETH(eventId, 0, 0);
        return 0;
    }

    function withdrawEventFundsUSDC(uint256 eventId) public returns (uint256) {
        emit FundsWithdrawnUSDC(eventId, 0, 0);
        return 0;
    }

    receive() external payable {}
} 