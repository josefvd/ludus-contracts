// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../src/interfaces/IEAS.sol";

contract Stub_EAS is IEAS {
    // Mapping to store mock attestations if needed for more complex scenarios
    mapping(bytes32 => Attestation) private mockAttestations;
    address public attesterAddress; // Configurable attester for returned attestations

    constructor(address _defaultAttester) {
        attesterAddress = _defaultAttester;
    }

    function attest(AttestationRequest calldata request) external payable returns (bytes32 uid) {
        bytes32 pseudoUid = keccak256(abi.encodePacked(request.schema, request.data.recipient, request.data.expirationTime, block.timestamp, msg.sender));assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000001,pseudoUid)}
        Attestation memory newAtt = Attestation({
            uid: pseudoUid,
            schema: request.schema,
            refUID: request.data.refUID,
            time: uint64(block.timestamp),
            expirationTime: uint64(request.data.expirationTime),
            revocationTime: 0,
            recipient: request.data.recipient,
            attester: attesterAddress,
            revocable: request.data.revocable,
            data: request.data.data
        });assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010002,0)}
        mockAttestations[pseudoUid] = newAtt; 
        return pseudoUid;
    }

    function revoke(bytes32, bytes32) external returns (bool) {
        return true;
    }

    function getSchema(bytes32 uid) external view returns (SchemaRecord memory) {
        return SchemaRecord({uid: uid, resolver: ISchemaResolver(address(0)), revocable: false, schema: ""});
    }

    function getAttestation(bytes32 uid) external view returns (Attestation memory) {
        // Return a valid Attestation with expected schema and attester
        // For simplicity, use fixed values or echo the uid as schema
        return Attestation({
            uid: uid,
            schema: uid, // Use uid as schema for determinism
            time: uint64(block.timestamp),
            expirationTime: uint64(block.timestamp + 1 days),
            revocationTime: 0,
            refUID: bytes32(0),
            recipient: address(0x1234),
            attester: attesterAddress,
            revocable: false,
            data: ""
        });
    }

    // Helper to configure the attester address for getAttestation fallback
    function setAttesterAddress(address _attester) public {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00000000, 1037618708480) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00000001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00001000, _attester) }
        attesterAddress = _attester;
    }

    // Helper to directly add a mock attestation for testing precise scenarios
    function mockSetAttestation(Attestation calldata att) public {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00010000, 1037618708481) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00010001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00017000, att)}
        mockAttestations[att.uid] = att;
    }
} 