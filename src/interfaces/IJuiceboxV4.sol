// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IJBPaymentTerminal {
    function pay(
        uint256 amount,
        address beneficiary,
        address token,
        bool preferClaimedTokens,
        string memory memo,
        bytes memory metadata
    ) external returns (uint256);
}

interface IJBSplitsPayerDeployer {
    function deploySplitsPayer(
        bool defaultSplitsDomain,
        bool defaultSplitsProjectId,
        bool defaultSplitsGroup,
        bool defaultSplitsPreferClaimed,
        bool defaultSplitsPreferAddToBalance,
        bool defaultSplitsPercentage,
        bool defaultSplitsBeneficiary,
        bool defaultSplitsLockedUntil,
        bool defaultSplitsMemo
    ) external returns (address splitsPayer);
} 