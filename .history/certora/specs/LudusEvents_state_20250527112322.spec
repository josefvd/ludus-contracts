// Certora specification for LudusEvents - Event State Invariant and Rules

/// Checks if the status of an event is a valid member of the EventStatus enum.
/// Returns true if the event doesn't exist or if its status is valid.
function checkEventStateIsValid(uint256 eventId) returns bool {
    uint256 id_ev; uint256 startTime_ev; uint256 endTime_ev; uint256 regStartTime_ev; uint256 regEndTime_ev;
    uint256 maxParticipants_ev; uint256 minParticipantsToStart_ev; address creator_ev; address referee_ev;
    uint status_ev_uint; // Changed to uint to match getter
    uint256 regFee_ev; uint paymentCurrency_ev_uint; // Changed to uint to match getter
    uint256 totalPrize_ev; bool prefYield_ev; bool yieldActivated_ev;

    (id_ev, startTime_ev, endTime_ev, regStartTime_ev, regEndTime_ev,
     maxParticipants_ev, minParticipantsToStart_ev, creator_ev, referee_ev, 
     status_ev_uint, regFee_ev, paymentCurrency_ev_uint, totalPrize_ev, 
     prefYield_ev, yieldActivated_ev) = events(eventId); // Unpack 15 values

    if (!(id_ev == eventId && id_ev > 0)) {
        return true;
    }
    
    // Compare with LudusTypes.EventStatus enum values (0, 1, 2, 3)
    bool isValidStatus = (
           status_ev_uint == 0 // LudusTypes.EventStatus.Created
        || status_ev_uint == 1 // LudusTypes.EventStatus.Started
        || status_ev_uint == 2 // LudusTypes.EventStatus.Completed
        || status_ev_uint == 3  // LudusTypes.EventStatus.Canceled
    );

    return isValidStatus;
}

methods {
    // --- LudusEventsImpl's own functions ---
    function events(uint256 eventId) external returns (
        uint256, uint256, uint256, uint256, uint256, // id, startTime, endTime, regStartTime, regEndTime
        uint256, uint256, address, address,       // maxParticipants, minParticipantsToStart, creator, referee
        uint, uint256, uint, uint256,      // status (uint), regFee, paymentCurrency (uint), totalPrize
        bool, bool                                // prefYield, yieldActivated
    ) envfree;
    function eventDistributions(uint256 eventId) external returns (uint256, uint256, uint256, address) envfree;
    // Using bytes for complex parameters for createEvent as their internal structure is not critical for this spec
    function createEvent(bytes, bytes, bytes, bytes) external returns (uint256); // Simplified signature
    function startEvent(uint256) external;
    // Using bytes for athletes array in completeEventAndDistribute
    function completeEventAndDistribute(uint256, bytes) external; // Simplified signature
    function cancelEvent(uint256) external;
    // --- Accessors for External Contract Instances ---
    function eas() external returns (address) envfree;
    function yieldManager() external returns (address) envfree;
    function ludusIdentity() external returns (address) envfree;
    function schemaRegistry() external returns (address) envfree;
    function USDC() external returns (address) envfree;
    // --- Declarations of EAS Function Signatures ---
    function attest(bytes) external returns (bytes32) envfree;

    // --- Accessors for External Contract Instances (from LudusEventsImpl) ---
    // function jbTerminal() external returns (address) envfree; // Removed as JBX is not used
    // function addToBalanceOf(uint256, address, uint256, string) external; // Removed (JBX)
    // function setDistributionCurrentEventId(uint256) external; // Removed (YieldManager specific, handled by harness)

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

/* // Temporarily commented out to isolate parsing error
// Rule refactored into an invariant focusing on properties of created events
invariant NewlyCreatedEventHasCorrectCreatorAndState(uint256 eventId, address creator) {
    // Assuming 'creator' is the address that would have called createEvent.
    // This invariant will be true for non-existent events or events not created by 'creator'.
    // To make it more focused, we might need deeper linking or a rule with 'havoc'.

    uint256 id_ev; uint256 startTime_ev; uint256 endTime_ev; uint256 regStartTime_ev; uint256 regEndTime_ev;
    uint256 maxParticipants_ev; address creator_ev_stored; address organizerAddress_ev; LudusTypes.EventStatus status_ev;
    uint256 regFeeETH_ev; uint256 regFeeUSDC_ev; uint256 totalPrize_ev; bool prefYield_ev;

    (id_ev, startTime_ev, endTime_ev, regStartTime_ev, regEndTime_ev,
      maxParticipants_ev, creator_ev_stored, organizerAddress_ev, status_ev,
      regFeeETH_ev, regFeeUSDC_ev, totalPrize_ev, prefYield_ev) = events(eventId);

    // Only apply assertions if the event exists and was created by the 'creator' we are checking against.
    // And its status is Created (formerly Pending).
    // This requires a way to link the 'creator' argument of the invariant to the actual e.msg.sender of a createEvent call.
    // For a simple invariant, we can check properties if the event is in the Created state.
    if (id_ev == eventId && id_ev > 0 && status_ev == LudusTypes.EventStatus.Created) {
        assert creator_ev_stored == creator , "Event creator mismatch for a Created event";
        // The original rule also implicitly checked that eventId from createEvent matches id_ev.
        // Here, id_ev == eventId is part of the condition.
    }
}
*/ 