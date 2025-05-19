// Certora specification for LudusEvents contract

// using LudusTypes as types; // Keep commented out, use fully qualified names

methods {
    // External functions from LudusEventsImpl (target contract)
    function createEvent(bytes, bytes, bytes, bytes) external returns (uint256);
    function startEvent(uint256) external;
    function completeEvent(uint256, address[], uint256[]) external;
    function cancelEvent(uint256) external;
    // Add other relevant state-changing functions if needed for invariant checks
    // function registerParticipant(uint256, uint256) external; // Example
    
    // View functions needed for invariants
    function events(uint256 eventId) external returns (
        uint256, uint256, uint256, uint256, uint256,
        uint256, address, address, LudusTypes.EventStatus,
        uint256, uint256, uint256, bool
    ) envfree;
    function eventDistributions(uint256 eventId) external returns (
        uint256, uint256, uint256, address
    ) envfree;
    
    // Hypothetical boolean check functions (need proper definition later)
    // function checkTreasuryDistributionForAll() returns bool envfree;
    // function checkTimelineForAll() returns bool envfree;
}

/**
 * Invariant: Checks valid treasury distribution for any given eventId IF that event exists.
 */
invariant validTreasuryDistributionInvariant(uint256 eventId) // eventId is symbolic
    // Use 'let' to bind results, naming all return values
    let (uint256 id_check, uint256 startTime_unused, uint256 endTime_unused, uint256 regStartTime_unused, uint256 regEndTime_unused,
         uint256 maxParticipants_unused, address creator_unused, address organizerAddress_unused, LudusTypes.EventStatus status_check,
         uint256 regFeeETH_unused, uint256 regFeeUSDC_unused, uint256 totalPrize_unused, bool prefYield_unused) = events(eventId) in
    let (uint256 athletesShare, uint256 organizerShare, uint256 charityShare, address charityAddress) = eventDistributions(eventId) in
    ( // Filter condition: Event must exist
      id_check == eventId && id_check > 0
    ) => ( // Assertion condition: Properties must hold
        (athletesShare + organizerShare + charityShare == 9700) &&
        ((charityShare == 0) || (charityAddress != address(0)))
    ); // End of invariant with semicolon

/**
 * Invariant: Checks valid timeline for any given eventId IF that event exists.
 */
invariant validTimelineInvariant(uint256 eventId) // eventId is symbolic
    // Use 'let' to bind results, naming all return values
    let (uint256 id_check, uint256 startTime, uint256 endTime, uint256 regStartTime_unused, uint256 regEndTime,
         uint256 maxParticipants_unused, address creator_unused, address organizerAddress_unused, LudusTypes.EventStatus status_check,
         uint256 regFeeETH_unused, uint256 regFeeUSDC_unused, uint256 totalPrize_unused, bool prefYield_unused) = events(eventId) in
    ( // Filter condition: Event must exist
      id_check == eventId && id_check > 0
    ) => ( // Assertion condition: Properties must hold
      (regEndTime <= startTime) && (startTime < endTime)
    ); // End of invariant with semicolon

// Future: Add invariant for valid status transitions
// invariant validStatusTransitionsInvariant() { ... }