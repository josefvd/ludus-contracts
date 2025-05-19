// Certora specification for LudusEvents contract invariants

// Assuming LudusTypes.EventStatus is accessible
// Assuming IJBTerminal and IYieldManager interfaces are known to Certora (e.g., via .sol files or linking)

// --- Top-Level Helper CVL Function ---

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

/// Checks if the timeline properties hold for a specific eventId.
/// Returns true if the event doesn't exist (property holds vacuously) or if the property holds.
function checkTimelineProperty(uint256 eventId) returns bool {
    uint256 id_ev; uint256 startTime_ev; uint256 endTime_ev; uint256 regStartTime_ev; uint256 regEndTime_ev;
    uint256 maxParticipants_ev; address creator_ev; address organizerAddress_ev; LudusTypes.EventStatus status_ev;
    uint256 regFeeETH_ev; uint256 regFeeUSDC_ev; uint256 totalPrize_ev; bool prefYield_ev;

    (id_ev, startTime_ev, endTime_ev, regStartTime_ev, regEndTime_ev,
     maxParticipants_ev, creator_ev, organizerAddress_ev, status_ev,
     regFeeETH_ev, regFeeUSDC_ev, totalPrize_ev, prefYield_ev) = events(eventId);

    if (!(id_ev == eventId && id_ev > 0)) {
        // Event doesn't exist or ID mismatch, property holds vacuously.
        return true;
    }

    bool registrationOrderCorrect = regEndTime_ev > regStartTime_ev;
    bool eventStartAfterRegistration = startTime_ev > regEndTime_ev;
    bool eventDurationPositive = endTime_ev > startTime_ev;

    return registrationOrderCorrect && eventStartAfterRegistration && eventDurationPositive;
}

/// Checks if the status of an event is a valid member of the EventStatus enum.
/// Returns true if the event doesn't exist or if its status is valid.
function checkEventStateIsValid(uint256 eventId) returns bool {
    uint256 id_ev; uint256 startTime_ev; uint256 endTime_ev; uint256 regStartTime_ev; uint256 regEndTime_ev;
    uint256 maxParticipants_ev; address creator_ev; address organizerAddress_ev; LudusTypes.EventStatus status_ev;
    uint256 regFeeETH_ev; uint256 regFeeUSDC_ev; uint256 totalPrize_ev; bool prefYield_ev;

    (id_ev, startTime_ev, endTime_ev, regStartTime_ev, regEndTime_ev,
     maxParticipants_ev, creator_ev, organizerAddress_ev, status_ev,
     regFeeETH_ev, regFeeUSDC_ev, totalPrize_ev, prefYield_ev) = events(eventId);

    if (!(id_ev == eventId && id_ev > 0)) {
        // Event doesn't exist or ID mismatch, property holds vacuously.
        return true;
    }
    
    bool isValidStatus = (
           status_ev == LudusTypes.EventStatus.Created
        || status_ev == LudusTypes.EventStatus.Started
        || status_ev == LudusTypes.EventStatus.Completed
        || status_ev == LudusTypes.EventStatus.Canceled
    );

    return isValidStatus;
}

// --- Methods for LudusEventsImpl ---
methods {
    // State readers
    function events(uint256) external returns (
        uint256, uint256, uint256, uint256, uint256, uint256, address, address,
        LudusTypes.EventStatus, uint256, uint256, uint256, bool
    ) envfree;
    function eventDistributions(uint256) external returns (uint256, uint256, uint256, address) envfree;

    // State changers (Summarized)
    // function createEvent(bytes, bytes, bytes, bytes) external returns (uint256);
    function startEvent(uint256) external;
    function completeEvent(uint256, address[], uint256[]) external;
    function cancelEvent(uint256) external;

    // External Contract Accessors
    function jbTerminal() external returns (address) envfree;
    function yieldManager() external returns (address) envfree;

    // Calls to External Contracts (Summarized)
    function addToBalanceOf(uint256, address, uint256, string) external;
    function setDistributionCurrentEventId(uint256) external;
}

// --- Invariants --- 

/**
 * Invariant: Checks valid treasury distribution for all (relevant) eventIds.
 */
invariant validTreasuryDistribution(uint256 eventId)
    checkTreasuryDistributionProperty(eventId);

/**
 * Invariant: Checks that event timestamps are logically ordered for all relevant eventIds.
 */
invariant validTimeline(uint256 eventId)
    checkTimelineProperty(eventId);

/**
 * Invariant: Checks that any existing event has a valid status from the EventStatus enum.
 */
invariant validEventState(uint256 eventId)
    checkEventStateIsValid(eventId);

// Removed rule for createEvent state as it was just for testing/example