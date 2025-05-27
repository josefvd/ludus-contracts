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
        bytes32 pseudoUid = keccak256(abi.encodePacked(request.schema, request.data.recipient, request.data.expirationTime, block.timestamp, msg.sender));
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
        });
        mockAttestations[pseudoUid] = newAtt; 
        return pseudoUid;
    }

    function attestByDelegation(DelegatedAttestationRequest calldata) external payable returns (bytes32) {
        return keccak256(abi.encodePacked("delegated"));
    }

    function multiAttest(MultiAttestationRequest[] calldata requests) external payable returns (bytes32[] memory) {
        bytes32[] memory uids = new bytes32[](requests.length);
        return uids;
    }

    function multiAttestByDelegation(MultiDelegatedAttestationRequest[] calldata requests) external payable returns (bytes32[] memory) {
        bytes32[] memory uids = new bytes32[](requests.length);
        return uids;
    }

    function revoke(RevocationRequest calldata) external payable {}
    function revokeByDelegation(DelegatedRevocationRequest calldata) external payable {}
    function multiRevoke(MultiRevocationRequest[] calldata) external payable {}
    function multiRevokeByDelegation(MultiDelegatedRevocationRequest[] calldata) external payable {}

    function timestamp(bytes32) external returns (uint64) { return uint64(block.timestamp); }
    function multiTimestamp(bytes32[] calldata) external returns (uint64) { return uint64(block.timestamp); }
    function revokeOffchain(bytes32) external returns (uint64) { return uint64(block.timestamp); }
    function multiRevokeOffchain(bytes32[] calldata) external returns (uint64) { return uint64(block.timestamp); }

    function getAttestation(bytes32 uid) external view returns (Attestation memory) {
        if (mockAttestations[uid].uid == uid) {
            Attestation memory storedAtt = mockAttestations[uid];
            storedAtt.attester = attesterAddress;
            return storedAtt;
        }
        return Attestation({
            uid: uid,
            schema: bytes32(0),
            refUID: bytes32(0),
            time: uint64(block.timestamp > 1 days ? block.timestamp - 1 days : 0),
            expirationTime: uint64(block.timestamp + 30 days),
            revocationTime: 0,
            recipient: address(this),
            attester: attesterAddress,
            revocable: true,
            data: bytes("")
        });
    }

    function isAttestationValid(bytes32) external view returns (bool) { return true; }
    function getTimestamp(bytes32) external view returns (uint64) { return uint64(block.timestamp); }
    function getRevokeOffchain(address, bytes32) external view returns (uint64) { return uint64(block.timestamp); }
    function getSchemaRegistry() external view returns (ISchemaRegistry) { return ISchemaRegistry(address(0)); }

    // ISemver requirement
    function version() external pure returns (string memory) {
        return "1.0.0";
    }

    // Helper to configure the attester address for getAttestation fallback
    function setAttesterAddress(address _attester) public {
        attesterAddress = _attester;
    }

    // Helper to directly add a mock attestation for testing precise scenarios
    function mockSetAttestation(Attestation calldata att) public {
        mockAttestations[att.uid] = att;
    }
} 