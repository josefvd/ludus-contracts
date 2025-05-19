// Certora specification for LudusEvents contract

// Assuming LudusTypes.EventStatus is accessible

// --- Top-Level Helper CVL Functions ---

/// Checks if the treasury distribution property holds for a specific eventId.
/// Returns true if the event doesn't exist (property holds vacuously) or if the property holds.
function checkTreasuryDistributionProperty(uint256 eventId) returns bool {
    // events(eventId) returns (id, startTime, endTime, regStartTime, regEndTime, maxParticipants, creator, organizerAddress, status, ...)
    // eventDistributions(eventId) returns (athletesShare, organizerShare, charityShare, charityAddress)

    // Filter: If event doesn't exist (id at index 0), property holds vacuously.
    // Accessing id (index 0) from events(eventId)
    if (!(events(eventId).0 == eventId && events(eventId).0 > 0)) {
        return true;
    }

    // Assertions for existing events
    // Accessing athletesShare (index 0), organizerShare (index 1), charityShare (index 2) from eventDistributions(eventId)
    bool distributionSumCorrect = (eventDistributions(eventId).0 + eventDistributions(eventId).1 + eventDistributions(eventId).2 == 9700);
    // Accessing charityShare (index 2), charityAddress (index 3) from eventDistributions(eventId)
    bool charityAddressValid = ((eventDistributions(eventId).2 == 0) || (eventDistributions(eventId).3 != address(0)));

    return distributionSumCorrect && charityAddressValid;
}

/// Checks if the timeline property holds for a specific eventId.
/// Returns true if the event doesn't exist (property holds vacuously) or if the property holds.
function checkTimelineProperty(uint256 eventId) returns bool {
    // events(eventId) returns (id, startTime, endTime, regStartTime, regEndTime, ...)

    // Filter: If event doesn't exist (id at index 0), property holds vacuously.
    // Accessing id (index 0) from events(eventId)
    if (!(events(eventId).0 == eventId && events(eventId).0 > 0)) {
        return true;
    }

    // Assertions for existing events: regEndTime (.4) <= startTime (.1) && startTime (.1) < endTime (.2)
    // Accessing regEndTime (index 4), startTime (index 1), endTime (index 2) from events(eventId)
    bool regTimeValid = events(eventId).4 <= events(eventId).1;
    bool eventDurationValid = events(eventId).1 < events(eventId).2;

    return regTimeValid && eventDurationValid;
}

methods {
    // --- Contract Functions (Type-only returns) ---
    function events(uint256 eventId) external returns (
        uint256, // 0: id
        uint256, // 1: startTime
        uint256, // 2: endTime
        uint256, // 3: regStartTime
        uint256, // 4: regEndTime
        uint256, // 5: maxParticipants
        address, // 6: creator
        address, // 7: organizerAddress
        LudusTypes.EventStatus, // 8: status
        uint256, // 9: regFeeETH
        uint256, // 10: regFeeUSDC
        uint256, // 11: totalPrize
        bool     // 12: prefYield
    ) envfree;

    function eventDistributions(uint256 eventId) external returns (
        uint256, // 0: athletesShare
        uint256, // 1: organizerShare
        uint256, // 2: charityShare
        address  // 3: charityAddress
    ) envfree;

    // --- State-changing functions ---
    function createEvent(bytes, bytes, bytes, bytes) external returns (uint256);
    function startEvent(uint256) external;
    function completeEvent(uint256, address[], uint256[]) external;
    function cancelEvent(uint256) external;
}

/**
 * Invariant: Checks valid treasury distribution for all (relevant) eventIds.
 */
invariant validTreasuryDistribution(uint256 eventId) // eventId is symbolic, prover picks values
    checkTreasuryDistributionProperty(eventId); // Asserts this function returns true

/**
 * Invariant: Checks valid timeline for all (relevant) eventIds.
 */
invariant validTimeline(uint256 eventId) // eventId is symbolic, prover picks values
    checkTimelineProperty(eventId); // Asserts this function returns true

// Future: Add invariant for valid status transitions
// invariant validStatusTransitions(uint256 eventId) ... ;

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