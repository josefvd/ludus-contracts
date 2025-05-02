// Certora specification focused on LudusEvents createEvent post-conditions

// Define the EventCreated event signature matching the contract
event EventCreated(uint256 eventId, string name, uint256 startTime, uint256 endTime);

methods {
    // Function under test (Needed for context, though rule triggers on event)
    function createEvent(bytes, bytes, bytes, bytes) external returns (uint256);

    // View functions needed for assertions
    function events(uint256) external returns (uint256, uint256, uint256, uint256, uint256, uint256, address, address, LudusTypes.EventStatus, uint256, uint256, uint256, bool) envfree;
    function eventDistributions(uint256) external returns (uint256, uint256, uint256, address) envfree;
}

// Rule: Check state properties immediately AFTER the EventCreated event is emitted
rule checkPropertiesAfterEventCreated() {
    // Capture the last emitted EventCreated event
    require last_event.EventCreated(?eventId, ?name, ?eventStartTime, ?eventEndTime);

    // --- Fetch state using the eventId from the event ---
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

    // --- Assert expected post-conditions ---

    // Basic Checks based on event args and fetched state
    assert id == eventId, "Fetched ID does not match eventId from EventCreated";
    assert startTime == eventStartTime, "Fetched startTime does not match startTime from EventCreated";
    assert endTime == eventEndTime, "Fetched endTime does not match endTime from EventCreated";
    assert status == LudusTypes.EventStatus.Created, "Event status should be Created after EventCreated emission";

    // Timeline Check
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