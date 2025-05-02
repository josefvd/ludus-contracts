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

// Invariant: Event status transitions are valid
// Created (0) -> Started (1) -> Completed (2) or Created (0) -> Canceled (3)
invariant validEventStatusTransitions(uint256 eventId)
    getEventStatus(eventId) <= 3 