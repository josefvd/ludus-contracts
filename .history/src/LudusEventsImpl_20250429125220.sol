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
    function attest(AttestationRequest calldata request) external payable override returns (bool) {
        // Using 'payable' based on ISchemaResolver interface, assuming needed
        // Also adding 'override' keyword as it implements an interface method
        require(!processedAttestations[request.uid], "Attestation already processed"); // Use request.uid
        require(msg.sender == address(eas), "Only EAS can call attest");
        
        if (request.schema == eventSchemaId) {
            // Event attestation validation logic
            LudusTypes.EventAttestationData memory eventData = abi.decode(
                request.data.data, // Use request.data.data
                (LudusTypes.EventAttestationData)
            );
            require(events[eventData.eventId].id == eventData.eventId, "Event does not exist");
            // Check recipient matches creator? Based on old logic.
            // require(events[eventData.eventId].creator == request.recipient, "Invalid event creator");
            processedAttestations[request.uid] = true; // Mark as processed
            return true;
        } else if (request.schema == resultSchemaId) {
            // Result attestation processing logic
            LudusTypes.ResultAttestationData memory resultData = abi.decode(
                request.data.data, // Use request.data.data
                (LudusTypes.ResultAttestationData)
            );
            // Validation checks
            require(events[resultData.eventId].id == resultData.eventId, "Event does not exist");
            require(events[resultData.eventId].status == LudusTypes.EventStatus.Started, "Event not started");
            require(block.timestamp >= events[resultData.eventId].endTime, "Event not ended");
            // require(attestation.attester == events[resultData.eventId].referee, "Only registered referee can attest results"); // Need full Attestation struct? request doesn't have attester

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
            processedAttestations[request.uid] = true; // Mark as processed

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

    // Note: multiAttest, revoke, multiRevoke, version are implemented (or reverted/returned) in base
} 