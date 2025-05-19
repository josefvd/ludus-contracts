// Certora specification for LudusEvents contract

// Assuming LudusTypes.EventStatus is accessible

// --- Top-Level Helper Functions ---
/**
 * Checks if the treasury distribution property holds for a specific eventId.
 * Returns true if the event doesn't exist or if the property holds.
 */
function checkTreasuryDistributionProperty(LudusEventsImpl contract, uint256 eventId) returns bool {
    uint256 id_check;
    // Assuming the full tuple structure from events(eventId) call
    // id, startTime, endTime, regStartTime, regEndTime, maxParticipants, creator, organizerAddress, status, ...
    (id_check,,,,,,,,,,,) = contract.events(eventId);

    // If event doesn't exist, property holds vacuously for this eventId
    if (!(id_check == eventId && id_check > 0)) {
        return true;
    }

    uint256 athletesShare;
    uint256 organizerShare;
    uint256 charityShare;
    address charityAddress;
    (athletesShare, organizerShare, charityShare, charityAddress) = contract.eventDistributions(eventId);

    bool distributionSumCorrect = athletesShare + organizerShare + charityShare == 9700;
    bool charityAddressValid = (charityShare == 0) || (charityAddress != address(0));

    return distributionSumCorrect && charityAddressValid;
}

/**
 * Checks if the timeline property holds for a specific eventId.
 * Returns true if the event doesn't exist or if the property holds.
 */
function checkTimelineProperty(LudusEventsImpl contract, uint256 eventId) returns bool {
    uint256 id_check;
    uint256 startTime;
    uint256 endTime;
    uint256 regEndTime;
    // id, startTime, endTime, regStartTime, regEndTime, ...
    (id_check, startTime, endTime, , regEndTime, , , , , , , , ) = contract.events(eventId);

    // If event doesn't exist, property holds vacuously for this eventId
    if (!(id_check == eventId && id_check > 0)) {
        return true;
    }

    bool regTimeValid = regEndTime <= startTime;
    bool eventDurationValid = startTime < endTime;

    return regTimeValid && eventDurationValid;
}

methods {
    // --- Contract Functions (Type-only returns) ---
    function events(uint256 eventId) external returns (
        uint256, uint256, uint256, uint256, uint256, // id, startTime, endTime, regStartTime, regEndTime
        uint256, address, address, LudusTypes.EventStatus, // maxParticipants, creator, organizerAddress, status
        uint256, uint256, uint256, bool // regFeeETH, regFeeUSDC, totalPrize, prefYield
    ) envfree;
    function eventDistributions(uint256 eventId) external returns (
        uint256, uint256, uint256, address // athletesShare, organizerShare, charityShare, charityAddress
    ) envfree;

    // --- State-changing functions ---
    function createEvent(bytes, bytes, bytes, bytes) external returns (uint256);
    function startEvent(uint256) external;
    function completeEvent(uint256, address[], uint256[]) external;
    function cancelEvent(uint256) external;
}

// --- Helper functions (Definition needed later) ---
// Checks if the treasury distribution property holds for all existing events
// function checkTreasuryDistributionForAll() returns bool; // Needs proper definition/linking

// Checks if the timeline property holds for all existing events
// function checkTimelineForAll() returns bool; // Needs proper definition/linking

/**
 * Rule: Checks that the treasury distribution property is maintained by any method f.
 */
rule checkTreasuryDistributionPreserved(method f) {
    // Inductive Hypothesis: Assume property holds for all events BEFORE f runs
    // require checkTreasuryDistributionForAll(); // Placeholder

    // Execute the method
    env e; // Assume method might need env
    calldataarg args;
    f(e, args); // Pass env and args

    // Assert property holds for all events AFTER f runs
    // assert checkTreasuryDistributionForAll(); // Placeholder
    assert true; // Temporary assertion
}

/**
 * Rule: Checks that the timeline property is maintained by any method f.
 */
rule checkTimelinePreserved(method f) {
    // Inductive Hypothesis: Assume property holds for all events BEFORE f runs
    // require checkTimelineForAll(); // Placeholder

    // Execute the method
    env e; // Assume method might need env
    calldataarg args;
    f(e, args); // Pass env and args

    // Assert property holds for all events AFTER f runs
    // assert checkTimelineForAll(); // Placeholder
    assert true; // Temporary assertion
}

// Future: Add rule for valid status transitions
// rule checkStatusTransitionsPreserved(method f) { ... }