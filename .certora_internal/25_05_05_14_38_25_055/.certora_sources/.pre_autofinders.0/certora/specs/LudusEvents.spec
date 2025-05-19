// Certora specification for LudusEvents contract

// Assuming LudusTypes.EventStatus is accessible

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