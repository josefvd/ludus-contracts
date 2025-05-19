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
           status_ev == LudusTypes.EventStatus.Pending
        || status_ev == LudusTypes.EventStatus.RegistrationOpen
        || status_ev == LudusTypes.EventStatus.RegistrationClosed
        || status_ev == LudusTypes.EventStatus.Started
        || status_ev == LudusTypes.EventStatus.Completed
        || status_ev == LudusTypes.EventStatus.Cancelled
    );

    return isValidStatus;
}

methods {
    // --- LudusEventsImpl's own functions ---
    function events(uint256 eventId) external returns (
        uint256, uint256, uint256, uint256, uint256, uint256, address, address,
        LudusTypes.EventStatus, uint256, uint256, uint256, bool
    ) envfree;
    function eventDistributions(uint256 eventId) external returns (uint256, uint256, uint256, address) envfree;
    function createEvent(bytes, bytes, bytes, bytes) external returns (uint256);
    function startEvent(uint256) external;
    function completeEvent(uint256, address[], uint256[]) external;
    function cancelEvent(uint256) external;

    // --- Accessors for External Contract Instances (from LudusEventsImpl) ---
    function jbTerminal() external returns (address) envfree;
    function yieldManager() external returns (address) envfree;
    function ludusIdentity() external returns (address) envfree;

    // --- Declarations of External Function Signatures Called by LudusEventsImpl ---
    // Removed type prefixes. Certora will attempt to link by signature.
    function addToBalanceOf(uint256, address, uint256, string) external;
    function setDistributionCurrentEventId(uint256) external;

    // Methods from ILudusIdentity (called on address from ludusIdentity())
    function ownerOf(uint256 tokenId) external returns (address) envfree;
    function canEnterTournament(uint256 profileId, uint256 tournamentId, uint256 requiredWins) external returns (bool) envfree;
    function recordTournamentEntry(uint256 profileId, uint256 tournamentId) external;
    function hasAchievement(uint256 profileId, uint8 achievementType) external returns (bool) envfree;
    function unlockAchievement(uint256 profileId, uint8 achievementType) external;

    // TODO: Add other external functions called by LudusEventsImpl as they are identified.
}

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

// Rule to check post-conditions of createEvent
rule FreshlyCreatedEventIsPendingAndCorrectlyInitialized(bytes paramsBytes, bytes attesterSignature, bytes extraData, bytes identityProof) {
    address creator = e.msg.sender; 
    uint256 eventId;

    eventId = currentContract.createEvent(paramsBytes, attesterSignature, extraData, identityProof);

    require eventId > 0; // Focus the rule on successful creations that return a valid ID.

    uint256 id_ev; uint256 startTime_ev; uint256 endTime_ev; uint256 regStartTime_ev; uint256 regEndTime_ev;
    uint256 maxParticipants_ev; address creator_ev; address organizerAddress_ev; LudusTypes.EventStatus status_ev;
    uint256 regFeeETH_ev; uint256 regFeeUSDC_ev; uint256 totalPrize_ev; bool prefYield_ev;

    (id_ev, startTime_ev, endTime_ev, regStartTime_ev, regEndTime_ev,
      maxParticipants_ev, creator_ev, organizerAddress_ev, status_ev,
      regFeeETH_ev, regFeeUSDC_ev, totalPrize_ev, prefYield_ev) = events(eventId);

    assert id_ev == eventId                                , "Event ID mismatch post-creation";
    assert status_ev == LudusTypes.EventStatus.Pending     , "Newly created event not in Pending state";
    assert creator_ev == creator                           , "Event creator mismatch";
}

// Future: Add validTimeline invariant and its helper function back later.