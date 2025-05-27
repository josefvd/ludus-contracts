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

    function revoke(bytes32, bytes32) external returns (bool) {
        return true;
    }

    function getSchema(bytes32 uid) external view returns (SchemaRecord memory) {
        return SchemaRecord({uid: uid, resolver: ISchemaResolver(address(0)), revocable: false, schema: ""});
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