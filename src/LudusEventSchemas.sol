// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title LudusEventSchemas
 * @notice This contract defines the schemas for Ludus event attestations.
 * These schemas should be registered with EAS before being used.
 * The actual registration is done through the EAS website/interface, not through this contract.
 */
contract LudusEventSchemas {
    // Schema name for event creation attestation
    string public constant EVENT_CREATION_SCHEMA_NAME = "LudusEventCreation";
    
    // Schema name for event results attestation
    string public constant EVENT_RESULT_SCHEMA_NAME = "LudusEventResult";

    /**
     * @notice The schema string for event creation
     * This defines the structure of data that will be attested when an event is created
     * Format follows EAS schema format: see https://docs.attest.sh/docs/tutorials/schemas
     */
    function getEventCreationSchema() external pure returns (string memory) {
        return "uint256 eventId,string name,string description,string eventType,string venue,string sport,string[] rules,string[] requirements,bytes32[] ticketPrices,string[] ticketTierNames,bytes32[] sponsorshipPrices,string[] sponsorshipTierNames,string eventURI";
    }

    /**
     * @notice The schema string for event results
     * This defines the structure of data that will be attested when event results are submitted
     */
    function getEventResultSchema() external pure returns (string memory) {
        return "uint256 eventId,bytes32 eventAttestationUID,uint256[] winnerIds,uint256[] scores,string resultDetails,address[] referees,uint64 timestamp,string[] evidenceURIs,string[] refereeComments";
    }
} 