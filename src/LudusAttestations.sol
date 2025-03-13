// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@eas/IEAS.sol";
import "./LudusIdentity.sol";

contract LudusAttestations is Ownable {
    IEAS public immutable eas;

    // Schema IDs for different attestation types
    bytes32 public constant TOURNAMENT_DETAILS_SCHEMA = keccak256("TournamentDetails");
    bytes32 public constant TOURNAMENT_RESULT_SCHEMA = keccak256("TournamentResult");
    bytes32 public constant VENUE_SCHEMA = keccak256("VenueDetails");

    // Tournament contract address that can create attestations
    address public tournamentContract;

    // Track which schema was used for each attestation
    mapping(bytes32 => bytes32) public attestationSchemas;

    event AttestationCreated(bytes32 indexed schemaId, address indexed attester, bytes32 indexed attestationId);

    constructor(address _eas) Ownable() {
        eas = IEAS(_eas);
    }

    function setTournamentContract(address _tournamentContract) external onlyOwner {
        tournamentContract = _tournamentContract;
    }

    function attestTournamentDetails(
        uint256 eventId,
        string memory venue,
        string memory sportsType,
        string memory eventType,
        uint256 startDate,
        uint256 endDate
    ) external returns (bytes32) {
        require(msg.sender == tournamentContract, "Only tournament contract can attest");

        bytes memory data = abi.encode(
            eventId,
            venue,
            sportsType,
            eventType,
            startDate,
            endDate
        );

        AttestationRequest memory request = AttestationRequest({
            schema: TOURNAMENT_DETAILS_SCHEMA,
            data: AttestationRequestData({
                recipient: address(0),
                expirationTime: 0,
                revocable: true,
                refUID: 0,
                data: data,
                value: 0
            })
        });

        bytes32 attestationId = eas.attest(request);
        attestationSchemas[attestationId] = TOURNAMENT_DETAILS_SCHEMA;
        emit AttestationCreated(TOURNAMENT_DETAILS_SCHEMA, msg.sender, attestationId);
        return attestationId;
    }

    function attestTournamentResult(
        uint256 eventId,
        address[] memory winners,
        uint256[] memory rankings,
        uint256 completionTime
    ) external returns (bytes32) {
        require(msg.sender == tournamentContract, "Only tournament contract can attest");

        bytes memory data = abi.encode(
            eventId,
            winners,
            rankings,
            completionTime
        );

        AttestationRequest memory request = AttestationRequest({
            schema: TOURNAMENT_RESULT_SCHEMA,
            data: AttestationRequestData({
                recipient: address(0),
                expirationTime: 0,
                revocable: true,
                refUID: 0,
                data: data,
                value: 0
            })
        });

        bytes32 attestationId = eas.attest(request);
        emit AttestationCreated(TOURNAMENT_RESULT_SCHEMA, msg.sender, attestationId);
        return attestationId;
    }

    function attestVenue(
        string memory venueName,
        string memory location,
        uint256 capacity,
        string memory facilities
    ) external returns (bytes32) {
        require(msg.sender == tournamentContract || msg.sender == owner(), "Not authorized");

        bytes memory data = abi.encode(
            venueName,
            location,
            capacity,
            facilities
        );

        AttestationRequest memory request = AttestationRequest({
            schema: VENUE_SCHEMA,
            data: AttestationRequestData({
                recipient: address(0),
                expirationTime: 0,
                revocable: true,
                refUID: 0,
                data: data,
                value: 0
            })
        });

        bytes32 attestationId = eas.attest(request);
        emit AttestationCreated(VENUE_SCHEMA, msg.sender, attestationId);
        return attestationId;
    }

    function revokeAttestation(bytes32 attestationId) external {
        require(msg.sender == tournamentContract || msg.sender == owner(), "Not authorized");
        require(attestationSchemas[attestationId] != bytes32(0), "Attestation not found");
        
        RevocationRequest memory request = RevocationRequest({
            schema: attestationSchemas[attestationId],
            data: RevocationRequestData({
                uid: attestationId,
                value: 0
            })
        });
        
        eas.revoke(request);
    }
} 