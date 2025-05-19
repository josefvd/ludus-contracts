// Certora specification for LudusEvents - Timeline Invariant

// --- Helper Functions (CVL) ---
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

// --- Definition for LudusIdentity External Contract ---
contract LudusIdentityContract { // Note: No 'type' keyword, based on Prover feedback trial
    function ownerOf(uint256) external returns (address) envfree; // Semicolon added
}

// --- Methods for the Contract Under Verification (LudusEventsImpl) ---
methods {
    // State-reading functions
    function events(uint256) external returns (
        uint256, uint256, uint256, uint256, uint256, uint256, address, address,
        LudusTypes.EventStatus, uint256, uint256, uint256, bool
    ) envfree; // Semicolon added
    function eventDistributions(uint256) external returns (uint256, uint256, uint256, address) envfree; // Semicolon added

    // State-changing functions (summarized)
    function createEvent(bytes memory, bytes memory, bytes memory, bytes memory) returns (uint256) summary; // Semicolon added
    function startEvent(uint256) summary; // Semicolon added
    function completeEvent(uint256, address[] memory, uint256[] memory) summary; // Semicolon added
    function cancelEvent(uint256) summary; // Semicolon added

    // Accessors for linked contracts
    function jbTerminal() external returns (address) envfree; // Semicolon added
    function yieldManager() external returns (address) envfree; // Semicolon added
    function ludusIdentity() external returns (LudusIdentityContract) envfree; // Semicolon added

    // Calls to external contracts (summarized)
    function addToBalanceOf(uint256, address, uint256, string memory) summary; // Semicolon added
    function setDistributionCurrentEventId(uint256) summary; // Semicolon added
}

// --- Invariants ---
invariant validTimeline(uint256 eventId)
    checkTimelineProperty(eventId);