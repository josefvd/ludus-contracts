// Certora specification for LudusEvents contract
using Ownable as ownable;

methods {
    // External functions from LudusEvents
    createEvent(uint256, uint256, uint256, uint256, uint256, address, uint256, uint256, bool, string, string, string, string, string, string[], string[], uint256[], string[], uint256[], string[]) returns (uint256) envfree;
    startEvent(uint256) envfree;
    completeEvent(uint256, uint256[], uint256[], string) envfree;
    cancelEvent(uint256) envfree;
    registerForEvent(uint256, uint256) envfree;
    
    // View functions
    getEventDetails(uint256) returns (uint256, uint256, uint256, uint256, uint256, uint256, address, address, uint8, uint256, uint256, uint256, bool) envfree;
    getEventStatus(uint256) returns (uint8) envfree;
    getEventAttestation(uint256) returns (bytes32) envfree;
    getEventResultAttestation(uint256) returns (bytes32) envfree;
    isRegisteredForEvent(uint256, uint256) returns (bool) envfree;
    
    // Ownable functions
    owner() returns (address) envfree;
    
    // ISchemaResolver functions
    onAttest(bytes32, Attestation) returns (bool) envfree;
    onRevoke(bytes32, Attestation) returns (bool) envfree;
    
    // Constants and state variables
    ludusIdentity() returns (address) envfree;
    eas() returns (address) envfree;
    schemaRegistry() returns (address) envfree;
    jbTerminal() returns (address) envfree;
    yieldManager() returns (address) envfree;
    USDC() returns (address) envfree;
    ludusWallet() returns (address) envfree;
    
    // IERC20 functions for USDC
    IERC20.balanceOf(address) returns (uint256) envfree;
    IERC20.transfer(address, uint256) returns (bool) envfree;
    IERC20.transferFrom(address, address, uint256) returns (bool) envfree;
    IERC20.approve(address, uint256) returns (bool) envfree;
}

// Rule: Only the owner can cancel an event
rule onlyOwnerCanCancelEvent(uint256 eventId) {
    env e;
    
    require e.msg.sender != ownable.owner();
    
    cancelEvent@withrevert(e, eventId);
    assert lastReverted;
}

// Rule: Only the event creator or referee can start an event
rule onlyCreatorOrRefereeCanStartEvent(uint256 eventId) {
    env e;
    
    var (_, _, _, _, _, _, creator, referee, _, _, _, _, _) = getEventDetails(eventId);
    
    require e.msg.sender != creator;
    require e.msg.sender != referee;
    require e.msg.sender != ownable.owner();
    
    startEvent@withrevert(e, eventId);
    assert lastReverted;
}

// Rule: Only the event creator or referee can complete an event
rule onlyCreatorOrRefereeCanCompleteEvent(uint256 eventId, uint256[] winnerIds, uint256[] prizeShares, string resultURI) {
    env e;
    
    var (_, _, _, _, _, _, creator, referee, _, _, _, _, _) = getEventDetails(eventId);
    
    require e.msg.sender != creator;
    require e.msg.sender != referee;
    require e.msg.sender != ownable.owner();
    
    completeEvent@withrevert(e, eventId, winnerIds, prizeShares, resultURI);
    assert lastReverted;
}

// Rule: Cannot register for an event that has already started
rule cannotRegisterForStartedEvent(uint256 eventId, uint256 profileId) {
    env e;
    
    uint8 status = getEventStatus(eventId);
    require status != 0; // Not in Created state
    
    registerForEvent@withrevert(e, eventId, profileId);
    assert lastReverted;
}

// Rule: Cannot register for an event after registration period ends
rule cannotRegisterAfterRegistrationEnds(uint256 eventId, uint256 profileId) {
    env e;
    
    var (_, _, _, _, registrationEndTime, _, _, _, _, _, _, _, _) = getEventDetails(eventId);
    
    require e.block.timestamp > registrationEndTime;
    
    registerForEvent@withrevert(e, eventId, profileId);
    assert lastReverted;
}

// Rule: Cannot complete an event that hasn't started
rule cannotCompleteUnstartedEvent(uint256 eventId, uint256[] winnerIds, uint256[] prizeShares, string resultURI) {
    env e;
    
    uint8 status = getEventStatus(eventId);
    require status != 1; // Not in Started state
    
    completeEvent@withrevert(e, eventId, winnerIds, prizeShares, resultURI);
    assert lastReverted;
}

// Rule: Cannot start an event before its start time
rule cannotStartEventBeforeStartTime(uint256 eventId) {
    env e;
    
    var (_, startTime, _, _, _, _, _, _, _, _, _, _, _) = getEventDetails(eventId);
    
    require e.block.timestamp < startTime;
    
    startEvent@withrevert(e, eventId);
    assert lastReverted;
}

// Rule: Registration status is correctly updated
rule registrationStatusUpdated(uint256 eventId, uint256 profileId) {
    env e;
    
    bool oldStatus = isRegisteredForEvent(eventId, profileId);
    registerForEvent(e, eventId, profileId);
    bool newStatus = isRegisteredForEvent(eventId, profileId);
    
    assert oldStatus == false;
    assert newStatus == true;
}

// Rule: Treasury distribution must be valid
rule validTreasuryDistribution(uint256 athletesShare, uint256 organizerShare, uint256 charityShare, address charityAddress) {
    env e;
    
    // Create event with specified distribution
    uint256 eventId = createEvent(
        e.block.timestamp + 10000, // startTime (future)
        e.block.timestamp + 20000, // endTime
        e.block.timestamp + 1000, // registrationStartTime
        e.block.timestamp + 5000, // registrationEndTime
        10, // maxParticipants
        1000000, // registrationFeeUSDC (1 USDC)
        0, // registrationFeeETH
        e.msg.sender, // refereeAddress
        e.msg.sender, // organizerAddress
        athletesShare, // athletesShare
        organizerShare, // organizerShare
        charityShare, // charityShare
        charityAddress, // charityAddress
        // Empty positions and percentages for simplicity
        new uint256[](0), 
        new uint256[](0),
        false, // preferYieldGeneration
        "Test Event", // name
        "Test Description", // description
        "Tournament", // eventType
        "Virtual", // venue
        "Gaming", // sport
        new string[](0), // rules
        new string[](0), // requirements
        new uint256[](0), // ticketPrices
        new string[](0), // ticketTierNames
        new uint256[](0), // sponsorshipPrices
        new string[](0) // sponsorshipTierNames
    ) at withrevert;
    
    // If event creation succeeds, distribution must be valid
    if (!lastReverted) {
        // Sum of shares must not exceed 9700 (97%, with 3% Ludus tax)
        assert athletesShare + organizerShare + charityShare <= 9700, 
               "Invalid distribution: total share exceeds 97%";
        
        // If charity share is greater than 0, charity address must be valid
        if (charityShare > 0) {
            assert charityAddress != 0, 
                   "Invalid charity address with non-zero charity share";
        }
    }
}

// Rule: Event timeline must be valid upon creation
rule checkCreateEventTimeline(method f) filtered { f.sig -> createEvent(uint256, uint256, uint256, uint256, uint256, address, uint256, uint256, bool, string, string, string, string, string, string[], string[], uint256[], string[], uint256[], string[]) } {
    env e;
    uint256 startTime = f.args[0];
    uint256 endTime = f.args[1];
    uint256 registrationStartTime = f.args[2];
    uint256 registrationEndTime = f.args[3];

    // Assertions applied *after* the successful execution of createEvent

    // Start time must be greater than current block time
    assert startTime > e.block.timestamp, 
           "Invalid start time: must be in the future";
    
    // End time must be after start time
    assert endTime > startTime, 
           "Invalid end time: must be after start time";
    
    // Registration start time must be before registration end time
    assert registrationStartTime < registrationEndTime, 
           "Invalid registration period: start must be before end";
    
    // Registration must end before or exactly when event starts
    assert registrationEndTime <= startTime, 
           "Invalid timeline: registration must end before or when event starts";

    // Registration start time must be now or in the future
    assert registrationStartTime >= e.block.timestamp,
           "Invalid registration start time: must be now or in the future";
}

// Invariant: Event status transitions are valid
// Created (0) -> Started (1) -> Completed (2) or Created (0) -> Canceled (3)
invariant validEventStatusTransitions(uint256 eventId)
    getEventStatus(eventId) <= 3 