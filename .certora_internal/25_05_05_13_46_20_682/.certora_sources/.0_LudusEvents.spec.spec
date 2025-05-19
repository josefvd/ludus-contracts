// Certora specification for LudusEvents contract invariants

// Assuming LudusTypes.EventStatus is accessible (e.g., via linking in conf or if defined in a base contract)

methods {
    // --- Functions needed by invariants ---

    // View functions to access state per eventId
    function events(uint256 eventId) external returns (
        uint256, // id
        uint256, // startTime
        uint256, // endTime
        uint256, // regStartTime
        uint256, // regEndTime
        uint256, // maxParticipants
        address, // creator
        address, // organizerAddress
        LudusTypes.EventStatus, // status
        uint256, // regFeeETH
        uint256, // regFeeUSDC
        uint256, // totalPrize
        bool // prefYield
    ) envfree;

    function eventDistributions(uint256 eventId) external returns (
        uint256, // athletesShare
        uint256, // organizerShare
        uint256, // charityShare
        address // charityAddress
    ) envfree;

    // --- State-changing functions (optional but good practice for context) ---
    // List any external functions that can change the state checked by invariants
    function createEvent(bytes, bytes, bytes, bytes) external returns (uint256);
    function startEvent(uint256) external;
    function completeEvent(uint256, address[], uint256[]) external;
    function cancelEvent(uint256) external;
    // Add others like registerParticipant if they modify event state relevant to invariants

    // --- Helper Functions for Invariants ---
    /**
     * Checks if the treasury distribution is valid for a given eventId.
     * Returns true if the event doesn't exist or if the distribution is valid.
     */
    function checkTreasuryDistribution(uint256 eventId) returns bool envfree {
        uint256 id_check;
        LudusTypes.EventStatus status_check;
        (id_check, , , , , , , , status_check, , , , ) = events(eventId);

        // If event doesn't exist, the property trivially holds for this ID
        if (!(id_check == eventId && id_check > 0)) {
            return true;
        }

        uint256 athletesShare;
        uint256 organizerShare;
        uint256 charityShare;
        address charityAddress;
        (athletesShare, organizerShare, charityShare, charityAddress) = eventDistributions(eventId);

        bool distributionSumCorrect = athletesShare + organizerShare + charityShare == 9700;
        bool charityAddressValid = (charityShare == 0) || (charityAddress != address(0));

        return distributionSumCorrect && charityAddressValid;
    }

    /**
     * Checks if the timeline is valid for a given eventId.
     * Returns true if the event doesn't exist or if the timeline is valid.
     */
    function checkTimeline(uint256 eventId) returns bool envfree {
        uint256 id_check;
        uint256 startTime;
        uint256 endTime;
        uint256 regEndTime;
        LudusTypes.EventStatus status_check;
        (id_check, startTime, endTime, , regEndTime, , , , status_check, , , , ) = events(eventId);

        // If event doesn't exist, the property trivially holds for this ID
        if (!(id_check == eventId && id_check > 0)) {
            return true;
        }

        bool regTimeValid = regEndTime <= startTime;
        bool eventDurationValid = startTime < endTime;

        return regTimeValid && eventDurationValid;
    }
}

/**
 * Invariant: Checks valid treasury distribution for all events.
 */
invariant validTreasuryDistributionInvariant() {
    uint256 eventId; // Symbolic ID
    checkTreasuryDistribution(eventId);
}

/**
 * Invariant: Checks valid timeline for all events.
 */
invariant validTimelineInvariant() {
    uint256 eventId; // Symbolic ID
    checkTimeline(eventId);
}

// Future: Add invariant for valid status transitions
// invariant validStatusTransitionsInvariant() { ... }