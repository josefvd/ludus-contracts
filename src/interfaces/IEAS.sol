// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ISchemaResolver.sol";

interface IEAS {
    struct Attestation {
        bytes32 uid;        // Unique identifier of the attestation
        bytes32 schema;     // Schema identifier of the attestation
        uint64 time;       // Time when the attestation was created
        uint64 expirationTime; // Time when the attestation expires
        uint64 revocationTime; // Time when the attestation was revoked
        bytes32 refUID;    // Reference to another attestation
        address recipient;  // Address of the recipient
        address attester;   // Address of the attester
        bool revocable;    // Whether the attestation is revocable
        bytes data;        // Custom attestation data
    }

    struct AttestationRequestData {
        address recipient;      // Address of the recipient
        uint64 expirationTime; // Time when the attestation expires
        bool revocable;        // Whether the attestation is revocable
        bytes32 refUID;       // Reference to another attestation
        bytes data;           // Custom attestation data
        uint256 value;        // Value attached to the attestation
    }

    struct AttestationRequest {
        bytes32 schema;    // Schema identifier
        AttestationRequestData data; // Attestation data
    }

    /**
     * @dev Creates a new attestation.
     */
    function attest(AttestationRequest calldata request) external payable returns (bytes32);

    /**
     * @dev Revokes an attestation.
     */
    function revoke(bytes32 schema, bytes32 uid) external returns (bool);

    /**
     * @dev Returns the schema record for a given schema UID.
     */
    function getSchema(bytes32 uid) external view returns (SchemaRecord memory);
}

struct SchemaRecord {
    bytes32 uid;
    ISchemaResolver resolver;
    bool revocable;
    string schema;
} 