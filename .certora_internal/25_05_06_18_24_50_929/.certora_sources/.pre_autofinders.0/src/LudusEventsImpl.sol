// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Import the abstract contract
import "./LudusEvents.sol";

// Import necessary types/interfaces used in the implementation
import {AttestationRequest} from "@eas/IEAS.sol";
import "./libraries/LudusTypes.sol";
import "./interfaces/ILudusIdentity.sol"; // Needed for ludusIdentity.ownerOf

contract LudusEventsImpl is LudusEvents {
    // Constructor to call the parent LudusEvents constructor
    constructor(
        address _ludusIdentity,
        address _eas,
        address _schemaRegistry,
        address _jbTerminal,
        address _yieldManager,
        address initialOwner
    ) LudusEvents(
        _ludusIdentity,
        _eas,
        _schemaRegistry,
        _jbTerminal,
        _yieldManager,
        initialOwner
    ) {}

    // Implementation of the attest function (moved from base or on-chain version)
    function attest(Attestation calldata attestation) external payable override returns (bool) {
        require(!processedAttestations[attestation.uid], "Attestation already processed"); // Use attestation.uid
        require(msg.sender == address(eas), "Only EAS can call attest");
        
        if (attestation.schema == eventSchemaId) {
            // Event attestation validation logic
            LudusTypes.EventAttestationData memory eventData = abi.decode(
                attestation.data, // Use attestation.data directly
                (LudusTypes.EventAttestationData)
            );
            require(events[eventData.eventId].id == eventData.eventId, "Event does not exist");
            // Check recipient matches creator? Based on old logic.
            // require(events[eventData.eventId].creator == attestation.recipient, "Invalid event creator"); // attestation.recipient
            processedAttestations[attestation.uid] = true; // Mark as processed
            return true;
        } else if (attestation.schema == resultSchemaId) {
            // Result attestation processing logic
            LudusTypes.ResultAttestationData memory resultData = abi.decode(
                attestation.data, // Use attestation.data directly
                (LudusTypes.ResultAttestationData)
            );
            // Validation checks
            require(events[resultData.eventId].id == resultData.eventId, "Event does not exist");
            require(events[resultData.eventId].status == LudusTypes.EventStatus.Started, "Event not started");
            require(block.timestamp >= events[resultData.eventId].endTime, "Event not ended");
            // Verify the attestation is from the registered referee
            require(attestation.attester == events[resultData.eventId].referee, "Only registered referee can attest results"); 

            // Get distribution settings
            LudusTypes.Distribution memory dist = eventDistributions[resultData.eventId];
            require(dist.athletesShare > 0, "Distribution not set");

            // Get total amount 
            uint256 totalAmount = eventPrizes[resultData.eventId];

            // Process winners and distribute funds
            address[] memory finalizedAthletes = new address[](resultData.winnerIds.length);
            for (uint256 i = 0; i < resultData.winnerIds.length; i++) {
                finalizedAthletes[i] = ludusIdentity.ownerOf(resultData.winnerIds[i]);
                 require(isParticipantRegistered[resultData.eventId][resultData.winnerIds[i]], 
                    "Winner not registered for event");
            }

            // Call internal distribution function (which exists in base LudusEvents)
            _distributeFunds(resultData.eventId, totalAmount, dist, finalizedAthletes);
            
            // Update state
            events[resultData.eventId].status = LudusTypes.EventStatus.Completed;
            processedAttestations[attestation.uid] = true; // Mark as processed

            // Emit event (defined in base LudusEvents)
            emit EventCompletedWithWinners(
                resultData.eventId,
                finalizedAthletes,
                totalAmount,
                (totalAmount * dist.athletesShare) / 10000,
                (totalAmount * dist.organizerShare) / 10000,
                (totalAmount * dist.charityShare) / 10000,
                (totalAmount * LUDUS_TAX_PERCENTAGE) / 10000
            );
            return true;
        } else {
             // Optional: Revert or return false for unknown schema
             return false;
        }
    }

    // Add implementations for other ISchemaResolver functions
    function multiAttest(Attestation[] calldata attestations, uint256[] calldata /* values */) external payable override returns (bool) {
        // Simple implementation: process only the first attestation
        // Matches original logic in base contract
        require(attestations.length > 0, "No attestations provided"); 
        // Note: Original had attestations.length == 1, but > 0 seems safer if array can be empty.
        // If values[] parameter is needed by EAS, adjust logic.
        return this.attest(attestations[0]); 
    }

    function revoke(Attestation calldata /* attestation */) external payable override returns (bool) {
        // Matches original logic in base contract
        revert("Revocation not supported");
    }

    function multiRevoke(Attestation[] calldata /* attestations */, uint256[] calldata /* values */) external payable override returns (bool) {
        // Matches original logic in base contract
        revert("Revocation not supported");
    }

    // Note: version() and isPayable() are implemented in the base LudusEvents contract
} 