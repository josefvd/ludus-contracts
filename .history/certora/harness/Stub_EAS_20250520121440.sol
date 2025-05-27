// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IEAS, Attestation} from "@eas/IEAS.sol"; // Assuming IEAS.sol is available in this path or via remappings

contract Stub_EAS is IEAS {
    // Mapping to store mock attestations if needed for more complex scenarios
    mapping(bytes32 => Attestation) private mockAttestations;
    address public attesterAddress; // Configurable attester for returned attestations

    constructor(address _defaultAttester) {
        attesterAddress = _defaultAttester;
    }

    function attest(AttestationRequest calldata request) external payable override returns (bytes32 uid) {
        // To be called by LudusEvents.LudusAttestations library (which itself is called by LudusEvents)
        // For harness purposes, we can generate a pseudo-UID and store a mock attestation.
        bytes32 pseudoUid = keccak256(abi.encodePacked(request.schema, request.data.recipient, request.data.expirationTime, block.timestamp));
        
        // Store a mock attestation based on the request if LudusEvents.sol tries to read it back via getAttestation
        // The attester in the stored Attestation struct should be the msg.sender of this attest call
        // which in the context of LudusEvents calling its internal library which then calls IEAS.attest(),
        // will be the LudusEvents contract itself. The check in LudusEvents is:
        // require(attestation.attester == msg.sender, "Invalid attester"); where msg.sender is the original caller of createEvent.
        // So, the mockAttestations attester field should be controllable or set to the expected attester (original createEvent caller)

        // For simplicity, if LudusEvents only creates and does not immediately getAttestation for its *own* attestations
        // within the same transaction in a way that affects core logic being verified by these invariants,
        // this attest function can be simpler.
        // The _handleYieldAndAttestation function does call eas.getAttestation(attestationUid).
        // The attestation.attester is checked against msg.sender (original caller of createEvent).

        mockAttestations[pseudoUid] = Attestation({
            uid: pseudoUid,
            schema: request.schema,
            refUID: request.data.refUID,
            time: uint64(block.timestamp),
            expirationTime: uint64(request.data.expirationTime),
            revocationTime: 0, // Not revoked
            recipient: request.data.recipient,
            attester: msg.sender, // This will be LudusEvents contract. The check needs to be handled carefully.
                                  // Or, use the pre-configured attesterAddress for simplicity if LudusEvents compares against a known party.
            revocable: request.data.revocable,
            data: request.data.data
        });

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
        // LudusEvents._handleYieldAndAttestation calls this.
        // It checks: attestation.schema == eventSchemaId
        // It checks: attestation.attester == msg.sender (caller of createEvent)
        // The attesterAddress field in this harness should be set to the expected msg.sender for createEvent when testing.
        // Or, the attest function needs to correctly store the attester.
        
        // If a mock is stored for this UID, return it.
        if (mockAttestations[uid].uid == uid) { // Check if uid exists
            return mockAttestations[uid];
        }

        // Fallback: return a default attestation that satisfies the checks in LudusEvents
        // This requires eventSchemaId to be known or passed to this harness, or use a symbolic one.
        return Attestation({
            uid: uid,
            schema: bytes32(0), // Should be a known schemaId for successful check, or made symbolic by Prover
            refUID: bytes32(0),
            time: uint64(block.timestamp - 1 days), // Some past time
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