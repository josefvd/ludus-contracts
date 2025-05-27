// Certora specification for LudusEvents - Timeline Invariant

// --- Helper Functions (CVL) ---
function checkTimelineProperty(uint256 eventId) returns bool {
    uint256 id_ev; uint256 startTime_ev; uint256 endTime_ev; uint256 regStartTime_ev; uint256 regEndTime_ev;
    uint256 maxParticipants_ev; uint256 minParticipantsToStart_ev; address creator_ev; address referee_ev;
    LudusTypes.EventStatus status_ev; uint256 regFee_ev; LudusTypes.PaymentCurrency paymentCurrency_ev; uint256 totalPrize_ev; 
    bool prefYield_ev; bool yieldActivated_ev;

    (id_ev, startTime_ev, endTime_ev, regStartTime_ev, regEndTime_ev,
     maxParticipants_ev, minParticipantsToStart_ev, creator_ev, referee_ev, status_ev,
     regFee_ev, paymentCurrency_ev, totalPrize_ev, prefYield_ev, yieldActivated_ev) = events(eventId);

    if (!(id_ev == eventId && id_ev > 0)) {
        return true;
    }

    bool registrationOrderCorrect = regEndTime_ev > regStartTime_ev;
    bool eventStartAfterRegistration = startTime_ev > regEndTime_ev;
    bool eventDurationPositive = endTime_ev > startTime_ev;

    return registrationOrderCorrect && eventStartAfterRegistration && eventDurationPositive;
}

/* // Temporarily commented out to resolve parsing error
// --- Definition for LudusIdentity External Contract ---
contract LudusIdentityContract { // Note: No 'type' keyword, based on Prover feedback trial
    function ownerOf(uint256) external returns (address) envfree; // Semicolon added
}
*/

// --- Methods for the Contract Under Verification (LudusEventsImpl) ---
methods {
    // State-reading functions
    function events(uint256) external returns (
        uint256, uint256, uint256, uint256, uint256, // id, startTime, endTime, regStartTime, regEndTime
        uint256, uint256, address, address,       // maxParticipants, minParticipantsToStart, creator, referee
        LudusTypes.EventStatus, uint256, LudusTypes.PaymentCurrency, uint256,      // status, regFee, paymentCurrency, totalPrize
        bool, bool                                // prefYield, yieldActivated
    ) envfree;
    function eventDistributions(uint256) external returns (uint256, uint256, uint256, address) envfree;

    // State-changing functions
    function createEvent(LudusTypes.EventCreationParams, uint256[], uint256[], LudusTypes.EventAttestationData) external returns (uint256) optional;
    function startEvent(uint256) external optional;
    function completeEventAndDistribute(uint256, bytes) external optional; // Simplified signature for athletes array
    function cancelEvent(uint256) external optional;

    // Accessors for linked contracts
    function eas() external returns (address) envfree;
    function yieldManager() external returns (address) envfree;
    function ludusIdentity() external returns (address) envfree;
    function schemaRegistry() external returns (address) envfree;
    function USDC() external returns (address) envfree;

    // Calls to external contracts (default summary)
    // function attest(bytes) external returns (bytes32) envfree;
}

function eventExists(uint256 eventId) returns bool {
    uint256 id_ev;
    (id_ev,,,,,,,,,,,,,,) = events(eventId);
    return id_ev == eventId && id_ev > 0;
}

// --- Invariants ---
invariant validTimeline(uint256 eventId)
    eventExists(eventId) ? checkTimelineProperty(eventId) : true;