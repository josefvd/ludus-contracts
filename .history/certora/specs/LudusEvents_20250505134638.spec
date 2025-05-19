// Certora specification for LudusEvents contract invariants

// Assuming LudusTypes.EventStatus is accessible (e.g., via linking in conf or if defined in a base contract)

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
invariant validTreasuryDistributionInvariant()
    forall uint256 eventId . (
        // Premise: Fetch state and check existence
        let (id_check,,,,,,,,status_check,,,,) = events(eventId) in
        let (athletesShare, organizerShare, charityShare, charityAddress) = eventDistributions(eventId) in
        (id_check == eventId && id_check > 0) // Filter condition
    ) => (
        // Consequence: Assert properties
        (athletesShare + organizerShare + charityShare == 9700) &&
        ((charityShare == 0) || (charityAddress != address(0)))
    );

/**
 * Invariant: Checks valid timeline for all events.
 */
invariant validTimelineInvariant()
    forall uint256 eventId . (
        // Premise: Fetch state and check existence
        let (id_check, startTime, endTime, , regEndTime, , , , status_check, , , , ) = events(eventId) in
        (id_check == eventId && id_check > 0) // Filter condition
    ) => (
        // Consequence: Assert properties
        (regEndTime <= startTime) && (startTime < endTime)
    );

// Future: Add invariant for valid status transitions
// invariant validStatusTransitionsInvariant() { ... }