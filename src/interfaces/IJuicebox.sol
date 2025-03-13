// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IJBController {
    function projects() external view returns (uint256);
    function fundingCycleStore() external view returns (address);
    function distributionLimitOf(
        uint256 projectId,
        uint256 configuration,
        address terminal,
        address token
    ) external view returns (uint256 distributionLimit, uint256 distributionLimitCurrency);
}

interface IJBMultiTerminal {
    function transferTo(
        uint256 projectId, 
        address payable recipient, 
        uint256 amount, 
        address token
    ) external;
    
    function currentEthOverflow(uint256 projectId) external view returns (uint256);
    function currentOverflowOf(uint256 projectId, address token) external view returns (uint256);
}

interface IJBTokens {
    function totalSupplyOf(uint256 projectId) external view returns (uint256);
    function balanceOf(address account, uint256 projectId) external view returns (uint256);
} 