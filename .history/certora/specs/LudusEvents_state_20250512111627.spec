// Certora specification for LudusEvents - Event State Invariant and Rules

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
    function addToBalanceOf(uint256, address, uint256, string) external;
    function setDistributionCurrentEventId(uint256) external;

    /* // Temporarily commented out as they are likely not on LudusEventsImpl directly
    // Methods from ILudusIdentity (called on address from ludusIdentity())
    function ownerOf(uint256 tokenId) external returns (address) envfree;
    function canEnterTournament(uint256 profileId, uint256 tournamentId, uint256 requiredWins) external returns (bool) envfree;
    function recordTournamentEntry(uint256 profileId, uint256 tournamentId) external;
    function hasAchievement(uint256 profileId, uint8 achievementType) external returns (bool) envfree;
    function unlockAchievement(uint256 profileId, uint8 achievementType) external;
    */

    // TODO: Add other external functions called by LudusEventsImpl as they are identified.
}

/**
 * Invariant: Checks that any existing event has a valid status from the EventStatus enum.
 */
invariant validEventState(uint256 eventId)
    checkEventStateIsValid(eventId);

// Rule to check post-conditions of createEvent
rule FreshlyCreatedEventIsPendingAndCorrectlyInitialized(env e, bytes paramsBytes, bytes attesterSignature, bytes extraData, bytes identityProof) {
    address creator = e.msg.sender; 
    uint256 eventId;

    eventId = currentContract.createEvent(paramsBytes, attesterSignature, extraData, identityProof);

    require eventId > 0; // Focus the rule on successful creations that return a valid ID.

    uint256 id_ev; uint256 startTime_ev; uint256 endTime_ev; uint256 regStartTime_ev; uint256 regEndTime_ev;
    uint256 maxParticipants_ev; address creator_ev_stored; address organizerAddress_ev; LudusTypes.EventStatus status_ev;
    uint256 regFeeETH_ev; uint256 regFeeUSDC_ev; uint256 totalPrize_ev; bool prefYield_ev;

    (id_ev, startTime_ev, endTime_ev, regStartTime_ev, regEndTime_ev,
      maxParticipants_ev, creator_ev_stored, organizerAddress_ev, status_ev,
      regFeeETH_ev, regFeeUSDC_ev, totalPrize_ev, prefYield_ev) = events(eventId);

    assert id_ev == eventId                                , "Event ID mismatch post-creation";
    assert status_ev == LudusTypes.EventStatus.Created     , "Newly created event not in Created state";
    assert creator_ev_stored == creator                    , "Event creator mismatch";
} 