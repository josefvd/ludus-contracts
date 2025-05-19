// Certora specification for LudusEvents contract invariants

// Assuming LudusTypes.EventStatus is accessible

// --- Top-Level Helper CVL Functions ---

/// Checks if the treasury distribution property holds for a specific eventId.
/// Returns true if the event doesn't exist (property holds vacuously) or if the property holds.
function checkTreasuryDistributionProperty(uint256 eventId) returns bool {
    uint256 id_ev; uint256 startTime_ev; uint256 endTime_ev; uint256 regStartTime_ev; uint256 regEndTime_ev;
    uint256 maxParticipants_ev; address creator_ev; address organizerAddress_ev; LudusTypes.EventStatus status_ev;
    uint256 regFeeETH_ev; uint256 regFeeUSDC_ev; uint256 totalPrize_ev; bool prefYield_ev;

    (id_ev, startTime_ev, endTime_ev, regStartTime_ev, regEndTime_ev,
     maxParticipants_ev, creator_ev, organizerAddress_ev, status_ev,
     regFeeETH_ev, regFeeUSDC_ev, totalPrize_ev, prefYield_ev) = events(eventId);

    if (!(id_ev == eventId && id_ev > 0)) {
        return true;
    }
    uint256 athletesShare_dist; uint256 organizerShare_dist; uint256 charityShare_dist; address charityAddress_dist;
    (athletesShare_dist, organizerShare_dist, charityShare_dist, charityAddress_dist) = eventDistributions(eventId);
    bool distributionSumCorrect = (athletesShare_dist + organizerShare_dist + charityShare_dist == 9700);
    bool charityAddressValid = ((charityShare_dist == 0) || (charityAddress_dist != 0));
    return distributionSumCorrect && charityAddressValid;
}

// function checkTimelineProperty(uint256 eventId) returns bool { ... } // Temporarily removed

methods {
    // --- LudusEventsImpl Functions ---
    function events(uint256 eventId) external returns (uint256, uint256, uint256, uint256, uint256, uint256, address, address, LudusTypes.EventStatus, uint256, uint256, uint256, bool) envfree;
    function eventDistributions(uint256 eventId) external returns (uint256, uint256, uint256, address) envfree;
    function createEvent(bytes, bytes, bytes, bytes) external returns (uint256);
    function startEvent(uint256) external;
    function completeEvent(uint256, address[], uint256[]) external;
    function cancelEvent(uint256) external;

    // --- Accessors for External Contract Addresses (from LudusEventsImpl) ---
    function jbTerminal() external returns (address) envfree;
    function yieldManager() external returns (address) envfree;

    // --- Declarations of External Signatures (minimalist approach) ---
    // Declaring the signature tells the Prover these functions exist externally.
    // Without a body or specific type, it will likely havoc their behavior regarding state changes.
    function addToBalanceOf(uint256, address, uint256, string) external;
    function setDistributionCurrentEventId(uint256) external;
}

/**
 * Invariant: Checks valid treasury distribution.
 */
invariant validTreasuryDistribution(uint256 eventId)
    checkTreasuryDistributionProperty(eventId);

// invariant validTimeline(uint256 eventId) // Temporarily removed
//     checkTimelineProperty(eventId);

// Future: Add invariant for valid status transitions
// invariant validStatusTransitions(uint256 eventId) ... ;