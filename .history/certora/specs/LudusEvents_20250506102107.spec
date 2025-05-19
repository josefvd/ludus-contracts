// Certora specification for LudusEvents contract invariants

// Assuming LudusTypes.EventStatus is accessible

// --- Top-Level Helper CVL Functions ---

/// Checks if the treasury distribution property holds for a specific eventId.
/// Returns true if the event doesn't exist (property holds vacuously) or if the property holds.
function checkTreasuryDistributionProperty(uint256 eventId) returns bool {
    // Declare local variables for all return values of events()
    uint256 id_ev; uint256 startTime_ev; uint256 endTime_ev; uint256 regStartTime_ev; uint256 regEndTime_ev;
    uint256 maxParticipants_ev; address creator_ev; address organizerAddress_ev; LudusTypes.EventStatus status_ev;
    uint256 regFeeETH_ev; uint256 regFeeUSDC_ev; uint256 totalPrize_ev; bool prefYield_ev;

    (id_ev, startTime_ev, endTime_ev, regStartTime_ev, regEndTime_ev,
     maxParticipants_ev, creator_ev, organizerAddress_ev, status_ev,
     regFeeETH_ev, regFeeUSDC_ev, totalPrize_ev, prefYield_ev) = events(eventId);

    // Filter: If event doesn't exist, property holds vacuously.
    if (!(id_ev == eventId && id_ev > 0)) {
        return true;
    }

    // Declare local variables for all return values of eventDistributions()
    uint256 athletesShare_dist; uint256 organizerShare_dist; uint256 charityShare_dist; address charityAddress_dist;
    (athletesShare_dist, organizerShare_dist, charityShare_dist, charityAddress_dist) = eventDistributions(eventId);

    // Assertions for existing events
    bool distributionSumCorrect = (athletesShare_dist + organizerShare_dist + charityShare_dist == 9700);
    bool charityAddressValid = ((charityShare_dist == 0) || (charityAddress_dist != 0));

    return distributionSumCorrect && charityAddressValid;
}

/// Checks if the timeline property holds for a specific eventId.
/// Returns true if the event doesn't exist (property holds vacuously) or if the property holds.
function checkTimelineProperty(uint256 eventId) returns bool {
    // Declare local variables for all return values of events()
    uint256 id_ev; uint256 startTime_ev; uint256 endTime_ev; uint256 regStartTime_ev; uint256 regEndTime_ev;
    uint256 maxParticipants_ev; address creator_ev; address organizerAddress_ev; LudusTypes.EventStatus status_ev;
    uint256 regFeeETH_ev; uint256 regFeeUSDC_ev; uint256 totalPrize_ev; bool prefYield_ev;

    (id_ev, startTime_ev, endTime_ev, regStartTime_ev, regEndTime_ev,
     maxParticipants_ev, creator_ev, organizerAddress_ev, status_ev,
     regFeeETH_ev, regFeeUSDC_ev, totalPrize_ev, prefYield_ev) = events(eventId);

    // Filter: If event doesn't exist, property holds vacuously.
    if (!(id_ev == eventId && id_ev > 0)) {
        return true;
    }

    // Assertions for existing events
    bool regTimeValid = regEndTime_ev <= startTime_ev;
    bool eventDurationValid = startTime_ev < endTime_ev;

    return regTimeValid && eventDurationValid;
}

methods {
    // --- Contract Functions (Type-only returns) ---
    function events(uint256 eventId) external returns (
        uint256, // 0: id
        uint256, // 1: startTime
        uint256, // 2: endTime
        uint256, // 3: regStartTime
        uint256, // 4: regEndTime
        uint256, // 5: maxParticipants
        address, // 6: creator
        address, // 7: organizerAddress
        LudusTypes.EventStatus, // 8: status
        uint256, // 9: regFeeETH
        uint256, // 10: regFeeUSDC
        uint256, // 11: totalPrize
        bool     // 12: prefYield
    ) envfree;

    function eventDistributions(uint256 eventId) external returns (
        uint256, // 0: athletesShare
        uint256, // 1: organizerShare
        uint256, // 2: charityShare
        address  // 3: charityAddress
    ) envfree;

    // --- State-changing functions from LudusEventsImpl ---
    function createEvent(bytes, bytes, bytes, bytes) external returns (uint256);
    function startEvent(uint256) external;
    function completeEvent(uint256, address[], uint256[]) external;
    function cancelEvent(uint256) external;

    // --- Declarations for external contract addresses (assuming public state vars in LudusEventsImpl) ---
    function jbTerminal() external returns (address) envfree;
    function yieldManager() external returns (address) envfree;

    // --- Summaries for external calls ---
    // These summaries assume jbTerminal and yieldManager are the *types* of the contracts being called.
    // If they are just addresses, Certora might link by sighash, or specific linking might be needed in the conf file.
    // For now, this tells the prover that these specific function signatures on these (potentially abstract) contract types
    // have no side effects relevant to these invariants.
    function jbTerminal.addToBalanceOf(uint256, address, uint256, string) external {}

    function yieldManager.setDistributionCurrentEventId(uint256) external {}
}

/**
 * Invariant: Checks valid treasury distribution for all (relevant) eventIds.
 */
invariant validTreasuryDistribution(uint256 eventId) // eventId is symbolic, prover picks values
    checkTreasuryDistributionProperty(eventId); // Asserts this function returns true

/**
 * Invariant: Checks valid timeline for all (relevant) eventIds.
 */
invariant validTimeline(uint256 eventId) // eventId is symbolic, prover picks values
    checkTimelineProperty(eventId); // Asserts this function returns true

// Future: Add invariant for valid status transitions
// invariant validStatusTransitions(uint256 eventId) ... ;