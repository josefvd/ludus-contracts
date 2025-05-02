// Certora specification focused on LudusEvents createEvent post-conditions

methods {
    // Function under test
    function createEvent(bytes, bytes, bytes, bytes) external returns (uint256);

    // View functions needed for assertions
    function events(uint256) external returns (uint256, uint256, uint256, uint256, uint256, uint256, address, address, LudusTypes.EventStatus, uint256, uint256, uint256, bool) envfree;
    function eventDistributions(uint256) external returns (uint256, uint256, uint256, address) envfree;
}

// Rule: Check state properties for an event that is in the 'Created' state,
// assuming this means it was just created by createEvent.
rule createEventPostConditionCheck(uint256 eventId) {
    // env e; // Not strictly needed for this version

    // --- Fetch state of the event ---
    uint256 id;
    uint256 startTime;
    uint256 endTime;
    uint256 regStartTime;
    uint256 regEndTime;
    uint256 maxParticipants;
    address creator;
    address organizerAddress;
    LudusTypes.EventStatus status;
    uint256 regFeeETH;
    uint256 regFeeUSDC;
    uint256 totalPrize;
    bool prefYield;
    (id, startTime, endTime, regStartTime, regEndTime, maxParticipants, creator, organizerAddress, status, regFeeETH, regFeeUSDC, totalPrize, prefYield) = events(eventId);

    uint256 athletesShare;
    uint256 organizerShare;
    uint256 charityShare;
    address charityAddress;
    (athletesShare, organizerShare, charityShare, charityAddress) = eventDistributions(eventId);

    // --- Assumption: Only check events that exist and are in the Created state ---
    require id == eventId && id > 0 && status == LudusTypes.EventStatus.Created;

    // --- Assert expected post-conditions for a newly created event ---

    // Timeline Check (Already implicitly checked by require status == Created if status is set correctly)
    // No, status check doesn't guarantee timeline, check explicitly.
    assert regEndTime <= startTime, "Stored regEndTime should be <= stored startTime";
    assert endTime > startTime, "Stored endTime should be > stored startTime";

    // Distribution Check
    assert athletesShare + organizerShare + charityShare == 9700,
           "Stored distribution percentages must sum to 9700 (97%)";
    if (charityShare > 0) {
        assert charityAddress != 0,
               "Stored charity address is zero with non-zero charity share";
    }

    // Final assertion
    assert true;
} 