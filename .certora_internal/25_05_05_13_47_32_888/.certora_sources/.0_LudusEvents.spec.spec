// Certora specification for LudusEvents contract invariants

// Assuming LudusTypes.EventStatus is accessible (e.g., via linking in conf or if defined in a base contract)
// Assuming the contract being verified is LudusEventsImpl

// --- Top-Level Helper Functions for Invariants ---
/**
 * Checks if the treasury distribution is valid for a given eventId on a contract instance.
 * Returns true if the event doesn't exist or if the distribution is valid.
 */
function checkTreasuryDistribution(LudusEventsImpl contract, uint256 eventId) returns bool {
    uint256 id_check;
    LudusTypes.EventStatus status_check;
    // Call method on the contract instance
    (id_check, , , , , , , , status_check, , , , ) = contract.events(eventId);

    if (!(id_check == eventId && id_check > 0)) {
        return true;
    }

    uint256 athletesShare;
    uint256 organizerShare;
    uint256 charityShare;
    address charityAddress;
    // Call method on the contract instance
    (athletesShare, organizerShare, charityShare, charityAddress) = contract.eventDistributions(eventId);

    bool distributionSumCorrect = athletesShare + organizerShare + charityShare == 9700;
    bool charityAddressValid = (charityShare == 0) || (charityAddress != address(0));

    return distributionSumCorrect && charityAddressValid;
}

/**
 * Checks if the timeline is valid for a given eventId on a contract instance.
 * Returns true if the event doesn't exist or if the timeline is valid.
 */
function checkTimeline(LudusEventsImpl contract, uint256 eventId) returns bool {
    uint256 id_check;
    uint256 startTime;
    uint256 endTime;
    uint256 regEndTime;
    LudusTypes.EventStatus status_check;
    // Call method on the contract instance
    (id_check, startTime, endTime, , regEndTime, , , , status_check, , , , ) = contract.events(eventId);

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
invariant validTreasuryDistributionInvariant(LudusEventsImpl currentContract) {
    uint256 eventId; // Symbolic ID
    checkTreasuryDistribution(currentContract, eventId);
}

/**
 * Invariant: Checks valid timeline for all events.
 */
invariant validTimelineInvariant(LudusEventsImpl currentContract) {
    uint256 eventId; // Symbolic ID
    checkTimeline(currentContract, eventId);
}

// Future: Add invariant for valid status transitions
// invariant validStatusTransitionsInvariant() { ... }