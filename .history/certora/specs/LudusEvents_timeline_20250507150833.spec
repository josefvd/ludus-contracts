// Certora specification for LudusEvents - Timeline Invariant

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
        return true;
    }

    bool registrationOrderCorrect = regEndTime_ev > regStartTime_ev;
    bool eventStartAfterRegistration = startTime_ev > regEndTime_ev;
    bool eventDurationPositive = endTime_ev > startTime_ev;

    return registrationOrderCorrect && eventStartAfterRegistration && eventDurationPositive;
}

// Define methods for the LudusIdentity contract type
// Only include methods that LudusEventsImpl *actually calls* and *exist* on the simplified LudusIdentity
methods LudusIdentityContract {
    function ownerOf(uint256 tokenId) external returns (address) envfree;
    // NOTE: canEnterTournament, hasAchievement, etc., are REMOVED from LudusIdentity
    // If LudusEventsImpl or LudusEvents still call them, it's a Solidity error.
}

methods { // This is for LudusEventsImpl (the contract under verification)
    // --- LudusEventsImpl's own functions ---
    function events(uint256 eventId) external returns (
        uint256, uint256, uint256, uint256, uint256, uint256, address, address,
        LudusTypes.EventStatus, uint256, uint256, uint256, bool
    ) envfree;
    function eventDistributions(uint256 eventId) external returns (uint256, uint256, uint256, address) envfree;
    
    // Functions called by LudusEventsImpl that modify state or are complex
    // These should NOT be envfree if their behavior is important.
    // For now, marking them to be summarized to avoid "no effect" warning.
    // A proper summary or havoc might be needed depending on the invariant.
    function createEvent(bytes, bytes, bytes, bytes) external returns (uint256) summary;
    function startEvent(uint256) external summary;
    function completeEvent(uint256, address[], uint256[]) external summary;
    function cancelEvent(uint256) external summary;

    // --- Accessors for External Contract Instances (from LudusEventsImpl) ---
    function jbTerminal() external returns (address) envfree;
    function yieldManager() external returns (address) envfree; // Assuming IYieldManager methods are handled or havoced elsewhere if needed
    function ludusIdentity() external returns (LudusIdentityContract) envfree; // Corrected return type

    // --- Declarations of External Function Signatures Called by LudusEventsImpl ---
    // These are calls made *by* LudusEventsImpl to other contracts.
    // If their effect on LudusEventsImpl's state is relevant, they need summaries or havoc.
    function addToBalanceOf(uint256, address, uint256, string) external summary;
    function setDistributionCurrentEventId(uint256) external summary;

    // Methods from ILudusIdentity are now part of LudusIdentityContract methods block above.
    // The calls like ludusIdentity().ownerOf(tokenId) will use that definition.
    // Removed old declarations for canEnterTournament, hasAchievement, recordTournamentEntry, unlockAchievement
    // as they are no longer on the simplified LudusIdentity.
    // If LudusEvents/Impl still *tries* to call them, that's a Solidity error to be fixed in .sol files.

    // TODO: Add other external functions called by LudusEventsImpl as they are identified,
    //       and decide if they need to be envfree, optional, summarized, or havoced.
}

/**
 * Invariant: Checks that event timestamps are logically ordered for all relevant eventIds.
 */
invariant validTimeline(uint256 eventId)
    checkTimelineProperty(eventId); 