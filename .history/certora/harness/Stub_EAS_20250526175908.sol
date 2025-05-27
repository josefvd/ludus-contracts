// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IEAS, Attestation} from "lib/eas-contracts/contracts/IEAS.sol";

contract Stub_EAS is IEAS {
    // Mapping to store mock attestations if needed for more complex scenarios
    mapping(bytes32 => Attestation) private mockAttestations;
    address public attesterAddress; // Configurable attester for returned attestations

    constructor(address _defaultAttester) {
        attesterAddress = _defaultAttester;
    }

    function attest(AttestationRequest calldata request) external payable override returns (bytes32 uid) {
        bytes32 pseudoUid = keccak256(abi.encodePacked(request.schema, request.data.recipient, request.data.expirationTime, block.timestamp, msg.sender)); // Ensure some uniqueness
        // We don't strictly need to store it if getAttestation fabricates it based on attesterAddress.
        // However, storing it allows for more complex mock scenarios if needed later.
        Attestation memory newAtt = Attestation({
            uid: pseudoUid,
            schema: request.schema,
            refUID: request.data.refUID,
            time: uint64(block.timestamp),
            expirationTime: uint64(request.data.expirationTime),
            revocationTime: 0,
            recipient: request.data.recipient,
            attester: attesterAddress, //  <<<< IMPORTANT: Use configured attesterAddress for consistency with getAttestation check
            revocable: request.data.revocable,
            data: request.data.data
        });
        mockAttestations[pseudoUid] = newAtt; 
        return pseudoUid;
    }

    function attestByDelegation(AttestationRequest calldata request, address /*delegator*/) external payable override returns (bytes32) {
        // Similar to attest, generate a UID and potentially store.
        // Not directly used by LudusEvents.sol as per current code.
        return keccak256(abi.encodePacked("delegated", request.schema, request.data.recipient, request.data.expirationTime));
    }

    function multiAttest(AttestationRequest[] calldata requests) external payable override returns (bytes32[] memory) {
        bytes32[] memory uids = new bytes32[](requests.length);
        // Not used by LudusEvents.sol
        return uids;
    }

    function multiAttestByDelegation(AttestationRequest[] calldata requests, address /*delegator*/) external payable override returns (bytes32[] memory) {
        bytes32[] memory uids = new bytes32[](requests.length);
        // Not used by LudusEvents.sol
        return uids;
    }

    function revoke(RevocationRequest calldata request) external payable override {
        // No-op for harness
    }

    function revokeByDelegation(RevocationRequest calldata request, address /*delegator*/) external payable override {
        // No-op
    }

    function multiRevoke(RevocationRequest[] calldata requests) external payable override {
        // No-op
    }

    function multiRevokeByDelegation(RevocationRequest[] calldata requests, address /*delegator*/) external payable override {
        // No-op
    }

    function timestamp(bytes32 data) external payable override returns (uint64) {
        return uint64(block.timestamp);
    }

    function multiTimestamp(bytes32[] calldata data) external payable override returns (uint64) {
        return uint64(block.timestamp);
    }

    function getAttestation(bytes32 uid) external view override returns (Attestation memory) {
        if (mockAttestations[uid].uid == uid) { // Check if uid exists via a mockSetAttestation call or prior attest
            Attestation memory storedAtt = mockAttestations[uid];
            // Ensure the attester field matches the configurable attesterAddress for the check in LudusEvents
            storedAtt.attester = attesterAddress; 
            return storedAtt;
        }

        // Fallback: return a default attestation that satisfies the checks in LudusEvents
        return Attestation({
            uid: uid,
            schema: bytes32(0), // Symbolic, or set via mockSetAttestationSchema(bytes32)
            refUID: bytes32(0),
            time: uint64(block.timestamp > 1 days ? block.timestamp - 1 days : 0), // Some past time
            expirationTime: uint64(block.timestamp + 30 days), // Some future time
            revocationTime: 0,
            recipient: address(this), // Or some other address
            attester: attesterAddress, // This is CRITICAL for the check in LudusEvents
            revocable: true,
            data: bytes("")
        });
    }

    function isAttestationValid(bytes32 uid) external view override returns (bool) {
        return true; // Simplification for harness
    }

    function getRevokeOffchain(address revoker, bytes32 uid) external view override returns (bytes memory) {
        return bytes("");
    }

    function getAttestOffchain(address attester, AttestationRequest calldata request) external view override returns (bytes memory) {
        return bytes("");
    }

    function getSchemaRegistry() external view override returns (ISchemaRegistry) {
        // Return address(0) or a mock schema registry address if needed.
        // LudusEvents directly stores schemaRegistry address, so this might not be called on the EAS harness.
        return ISchemaRegistry(address(0)); 
    }

    // Helper to configure the attester address for getAttestation fallback
    function setAttesterAddress(address _attester) external {
        // require(msg.sender == owner); // Add ownership if this should be restricted
        attesterAddress = _attester;
    }

    // Helper to directly add a mock attestation for testing precise scenarios
    function mockSetAttestation(Attestation calldata att) external {
        mockAttestations[att.uid] = att;
    }
} 