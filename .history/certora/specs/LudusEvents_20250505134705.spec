// Certora specification for LudusEvents contract invariants

// Assuming LudusTypes.EventStatus is accessible (e.g., via linking in conf or if defined in a base contract)

// --- Top-Level Helper Functions for Invariants ---
/**
 * Checks if the treasury distribution is valid for a given eventId.
 * Returns true if the event doesn't exist or if the distribution is valid.
 */
function checkTreasuryDistribution(uint256 eventId) returns bool {
    uint256 id_check;
    LudusTypes.EventStatus status_check;
    // We need access to the 'events' method, how to call it from here?
    // This syntax likely needs adjustment based on how methods are accessed from CVL funcs
    (id_check, , , , , , , , status_check, , , , ) = /*???*/ events(eventId);

    if (!(id_check == eventId && id_check > 0)) {
        return true;
    }

    uint256 athletesShare;
    uint256 organizerShare;
    uint256 charityShare;
    address charityAddress;
    // Need access to 'eventDistributions' method
    (athletesShare, organizerShare, charityShare, charityAddress) = /*???*/ eventDistributions(eventId);

    bool distributionSumCorrect = athletesShare + organizerShare + charityShare == 9700;
    bool charityAddressValid = (charityShare == 0) || (charityAddress != address(0));

    return distributionSumCorrect && charityAddressValid;
}

/**
 * Checks if the timeline is valid for a given eventId.
 * Returns true if the event doesn't exist or if the timeline is valid.
 */
function checkTimeline(uint256 eventId) returns bool {
    uint256 id_check;
    uint256 startTime;
    uint256 endTime;
    uint256 regEndTime;
    LudusTypes.EventStatus status_check;
    // Need access to 'events' method
    (id_check, startTime, endTime, , regEndTime, , , , status_check, , , , ) = /*???*/ events(eventId);

    if (!(id_check == eventId && id_check > 0)) {
        return true;
    }

    bool regTimeValid = regEndTime <= startTime;
    bool eventDurationValid = startTime < endTime;

    return regTimeValid && eventDurationValid;
}

methods {
    // --- Contract Functions ---
    function events(uint256 eventId) external returns (
        uint256, uint256, uint256, uint256, uint256, uint256, address, address,
        LudusTypes.EventStatus, uint256, uint256, uint256, bool
    ) envfree;
    function eventDistributions(uint256 eventId) external returns (
        uint256, uint256, uint256, address
    ) envfree;
    function createEvent(bytes, bytes, bytes, bytes) external returns (uint256);
    function startEvent(uint256) external;
    function completeEvent(uint256, address[], uint256[]) external;
    function cancelEvent(uint256) external;
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