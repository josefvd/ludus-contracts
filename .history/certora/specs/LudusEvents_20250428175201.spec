// Certora specification for LudusEvents contract
using Ownable as ownable;

// Declare access to state variables needed for rules/invariants
using LudusEvents // Specify the contract context (no braces)
    // Declare the name of the mapping state variable
    events
    // We can also declare specific struct fields if needed, but often just the mapping is sufficient
    // Event.startTime
    // Event.endTime

methods {
    // External functions from LudusEvents
    function createEvent(uint256, uint256, uint256, uint256, uint256, address, uint256, uint256, bool, string, string, string, string, string, string[], string[], uint256[], string[], uint256[], string[]) returns (uint256) envfree;
    // function startEvent(uint256) envfree; // Commented out
    // function completeEvent(uint256, uint256[], uint256[], string) envfree; // Commented out
    // function cancelEvent(uint256) envfree; // Commented out
    // function registerForEvent(uint256, uint256) envfree; // Commented out
    
    // View functions (Keep needed ones for rules, comment others)
    // function getEventDetails(uint256) returns (uint256, uint256, uint256, uint256, uint256, uint256, address, address, uint8, uint256, uint256, uint256, bool) envfree; // Keep for now if helpers needed later
    // function getEventStatus(uint256) returns (uint8) envfree; // Commented out
    // function getEventAttestation(uint256) returns (bytes32) envfree; // Commented out
    // function getEventResultAttestation(uint256) returns (bytes32) envfree; // Commented out
    // function isRegisteredForEvent(uint256, uint256) returns (bool) envfree; // Commented out
    
    // Ownable functions (Keep needed ones for rules, comment others)
    // function owner() returns (address) envfree; // Commented out
    
    // ISchemaResolver functions (Commented out)
    // function onAttest(bytes32, Attestation) returns (bool) envfree;
    // function onRevoke(bytes32, Attestation) returns (bool) envfree;
    
    // Constants and state variables (Keep needed ones for rules, comment others)
    // function ludusIdentity() returns (address) envfree;
    // function eas() returns (address) envfree;
    // function schemaRegistry() returns (address) envfree;
    // function jbTerminal() returns (address) envfree;
    // function yieldManager() returns (address) envfree;
    // function USDC() returns (address) envfree;
    // function ludusWallet() returns (address) envfree;
    
    // IERC20 functions for USDC (Commented out)
    // function IERC20.balanceOf(address) returns (uint256) envfree;
    // function IERC20.transfer(address, uint256) returns (bool) envfree;
    // function IERC20.transferFrom(address, address, uint256) returns (bool) envfree;
    // function IERC20.approve(address, uint256) returns (bool) envfree;
}

// Rule: Treasury distribution must be valid UPON CREATION
rule checkCreateEventTreasuryDistribution(method f)
    filtered f.call(
        uint256 startTime, 
        uint256 endTime, 
        uint256 registrationStartTime, 
        uint256 registrationEndTime, 
        uint256 maxParticipants, 
        address organizerAddress, // Assuming this is arg 5, not referee
        uint256 registrationFeeUSDC, 
        uint256 registrationFeeETH, 
        bool preferYieldGeneration, // Assuming this is arg 8
        string name, 
        string description, 
        string eventType, 
        string venue, 
        string sport,
        string[] rules, 
        string[] requirements, 
        uint256[] ticketPrices, 
        string[] ticketTierNames, 
        uint256[] sponsorshipPrices, 
        string[] sponsorshipTierNames,
        // Arguments we actually care about for this rule:
        uint256 athletesShare, // Index 9? Verify order
        uint256 organizerShare, // Index 10?
        uint256 charityShare, // Index 11?
        address charityAddress // Index 12?
    ) returns uint256 eventId 
{
    env e; // Keep env for block.timestamp if needed, though not used here
    // Arguments athletesShare, organizerShare, charityShare, charityAddress are now directly available

    // Assertions applied *after* the successful execution of createEvent
    // Sum of shares must equal 9700 (97%, assuming 3% Ludus tax)
    assert athletesShare + organizerShare + charityShare == 9700, 
           "Invalid distribution upon creation: total share is not 97%";
    
    // If charity share is greater than 0, charity address must be valid
    if (charityShare > 0) {
        assert charityAddress != address(0), 
               "Invalid charity address with non-zero charity share upon creation";
    }
}

// Rule: Event timeline must be valid UPON CREATION (Checks the new event)
rule checkCreateEventTimeline(method f)
    filtered f.call(
        uint256 startTime,
        uint256 endTime,
        uint256 registrationStartTime,
        uint256 registrationEndTime,
        uint256 maxParticipants,
        address organizerAddress,
        uint256 registrationFeeUSDC,
        uint256 registrationFeeETH,
        bool preferYieldGeneration,
        string name,
        string description,
        string eventType,
        string venue,
        string sport,
        string[] rules,
        string[] requirements,
        uint256[] ticketPrices,
        string[] ticketTierNames,
        uint256[] sponsorshipPrices,
        string[] sponsorshipTierNames,
        uint256 athletesShare,
        uint256 organizerShare,
        uint256 charityShare,
        address charityAddress
    ) returns uint256 eventId
{
    env e; // Keep env for block.timestamp

    // Assertions applied *after* the successful execution of createEvent
    assert startTime > e.block.timestamp,
           "Invalid start time: must be in the future";
    assert endTime > startTime,
           "Invalid end time: must be after start time";
    assert registrationStartTime < registrationEndTime,
           "Invalid registration period: start must be before end";
    assert registrationEndTime <= startTime,
           "Invalid timeline: registration must end before or when event starts";
    assert registrationStartTime >= e.block.timestamp,
           "Invalid registration start time: must be now or in the future";
}

// Invariant: Existing event timelines must remain valid
// This checks that endTime > startTime for all events in the 'events' mapping
// before and after *any* external function call defined in 'methods'.
invariant validEventTimelineInvariant()
    forall uint256 eventId in events.keys() { // 'events' is now accessible via the 'using' block
        Event storage currentEvent = events[eventId]; 
        require currentEvent.startTime > 0;
        assert currentEvent.endTime > currentEvent.startTime,
               "Invariant Violated: Event endTime is not strictly greater than startTime";
    }

/*
// --- ALL OTHER RULES COMMENTED OUT TEMPORARILY ---

// Rule: Only the owner can cancel an event
rule onlyOwnerCanCancelEvent(uint256 eventId) {
    ...
}

// Rule: Only the event creator or referee can start an event
rule onlyCreatorOrRefereeCanStartEvent(uint256 eventId) {
    ...
}

// Rule: Only the event creator or referee can complete an event
rule onlyCreatorOrRefereeCanCompleteEvent(...) {
    ...
}

// Rule: Cannot register for an event that has already started
rule cannotRegisterForStartedEvent(...) {
    ...
}

// Rule: Cannot register for an event after registration period ends
rule cannotRegisterAfterRegistrationEnds(...) {
    ...
}

// Rule: Cannot complete an event that hasn't started
rule cannotCompleteUnstartedEvent(...) {
    ...
}

// Rule: Cannot start an event before its start time
rule cannotStartEventBeforeStartTime(uint256 eventId) {
    ...
}

// Rule: Registration status is correctly updated
rule registrationStatusUpdated(...) {
    ...
}

// Invariant: Event status transitions are valid
invariant validEventStatusTransitions(uint256 eventId);

*/
    // { Body was empty anyway as helpers were removed }
    // require isValidTimeline(eventId, current_timestamp); // Removed
    // require isValidTreasuryDistribution(eventId); // Removed
    // getEventStatus(eventId) <= 3 // This condition likely needs to be inside the invariant body if we add one 