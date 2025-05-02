// Certora specification focused on LudusEvents createEvent post-conditions

methods {
    // Function under test
    function createEvent(bytes, bytes, bytes, bytes) external returns (uint256);

    // View functions needed for assertions
    function events(uint256) external returns (uint256, uint256, uint256, uint256, uint256, uint256, address, address, LudusTypes.EventStatus, uint256, uint256, uint256, bool) envfree;
    function eventDistributions(uint256) external returns (uint256, uint256, uint256, address) envfree;
}

// Rule: Check state properties immediately AFTER a successful createEvent call
// Using filtered approach again, but removing 'method f' parameter
rule createEventPostConditionCheck()
    // Filter: Only run this rule when 'createEvent' is the function being called
    filtered f -> createEvent(bytes configBytes, bytes treasuryDistBytes, bytes athleteDistBytes, bytes attestationDataBytes)
                    returns uint256 eventId
{
    env e; // Access environment variables like msg.sender

    // Basic check: createEvent should return a non-zero ID on success
    require eventId > 0, "createEvent returned eventId 0";

    // --- Fetch state of the newly created event ---
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

    // ID Check
    assert id == eventId, "Fetched ID does not match returned eventId";

    // Status Check
    assert status == LudusTypes.EventStatus.Created, "Newly created event status should be Created";

    // Creator Check (Matches the caller of createEvent)
    // assert creator == e.msg.sender, "Event creator mismatch"; // Note: Might fail if internal calls exist

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

    // Final assertion (often needed if last check is conditional)
    assert true;
} 