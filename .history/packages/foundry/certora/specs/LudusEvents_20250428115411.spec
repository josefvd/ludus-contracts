// Certora specification for LudusEvents contract
using Ownable as ownable;

methods {
    // External functions from LudusEvents
    function createEvent(uint256, uint256, uint256, uint256, uint256, address, uint256, uint256, bool, string, string, string, string, string, string[], string[], uint256[], string[], uint256[], string[]) returns (uint256) envfree;
    function startEvent(uint256) envfree;
    function completeEvent(uint256, uint256[], uint256[], string) envfree;
    function cancelEvent(uint256) envfree;
    function registerForEvent(uint256, uint256) envfree;
    
    // View functions
    function getEventDetails(uint256) returns (uint256, uint256, uint256, uint256, uint256, uint256, address, address, uint8, uint256, uint256, uint256, bool) envfree;
    function getEventStatus(uint256) returns (uint8) envfree;
    function getEventAttestation(uint256) returns (bytes32) envfree;
    function getEventResultAttestation(uint256) returns (bytes32) envfree;
    function isRegisteredForEvent(uint256, uint256) returns (bool) envfree;
    
    // Ownable functions
    function owner() returns (address) envfree;
    
    // ISchemaResolver functions
    function onAttest(bytes32, Attestation) returns (bool) envfree;
    function onRevoke(bytes32, Attestation) returns (bool) envfree;
    
    // Constants and state variables
    function ludusIdentity() returns (address) envfree;
    function eas() returns (address) envfree;
    function schemaRegistry() returns (address) envfree;
    function jbTerminal() returns (address) envfree;
    function yieldManager() returns (address) envfree;
    function USDC() returns (address) envfree;
    function ludusWallet() returns (address) envfree;
    
    // IERC20 functions for USDC
    function IERC20.balanceOf(address) returns (uint256) envfree;
    function IERC20.transfer(address, uint256) returns (bool) envfree;
    function IERC20.transferFrom(address, address, uint256) returns (bool) envfree;
    function IERC20.approve(address, uint256) returns (bool) envfree;
}

// Rule: Treasury distribution must be valid UPON CREATION
rule checkCreateEventTreasuryDistribution(method f) {
    // Declare env and arguments
    env e;
    uint256 athletesShare;
    uint256 organizerShare;
    uint256 charityShare;
    address charityAddress;
    
    // Assign from f.args
    athletesShare = f.args[9]; 
    organizerShare = f.args[10];
    charityShare = f.args[11];
    charityAddress = f.args[12];

    // Assertions applied *after* the successful execution of createEvent
    // Sum of shares must equal 9700 (97%, assuming 3% Ludus tax)
    assert athletesShare + organizerShare + charityShare == 9700, 
           "Invalid distribution upon creation: total share is not 97%";
    
    // If charity share is greater than 0, charity address must be valid
    if (charityShare > 0) {
        assert charityAddress != address(0), 
               "Invalid charity address with non-zero charity share upon creation";
    }
} where f.selector == createEvent(uint256, uint256, uint256, uint256, uint256, address, uint256, uint256, bool, string, string, string, string, string, string[], string[], uint256[], string[], uint256[], string[]).selector

// Rule: Event timeline must be valid UPON CREATION
rule checkCreateEventTimeline(method f) {
    // Declare env and arguments
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
} where f.selector == createEvent(uint256, uint256, uint256, uint256, uint256, address, uint256, uint256, bool, string, string, string, string, string, string[], string[], uint256[], string[], uint256[], string[]).selector

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

// Invariant: Event status transitions are valid
// Created (0) -> Started (1) -> Completed (2) or Created (0) -> Canceled (3)
invariant validEventStatusTransitions(uint256 eventId)
    getEventStatus(eventId) <= 3 