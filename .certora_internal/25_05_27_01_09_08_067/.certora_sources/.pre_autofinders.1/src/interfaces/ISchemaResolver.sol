// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IEAS.sol";

interface ISchemaResolver {
    /**
     * @dev Returns true if the resolver supports attestations.
     */
    function isPayable() external pure returns (bool);

    /**
     * @dev Processes an attestation and verifies its validity.
     */
    function attest(IEAS.Attestation calldata attestation) external payable returns (bool);

    /**
     * @dev Processes multiple attestations and verifies their validity.
     */
    function multiAttest(IEAS.Attestation[] calldata attestations) external payable returns (bool);

    /**
     * @dev Processes an attestation revocation and verifies its validity.
     */
    function revoke(IEAS.Attestation calldata attestation) external payable returns (bool);

    /**
     * @dev Processes multiple attestation revocations and verifies their validity.
     */
    function multiRevoke(IEAS.Attestation[] calldata attestations) external payable returns (bool);

    /**
     * @dev Returns the version of the resolver.
     */
    function version() external pure returns (string memory);
} 