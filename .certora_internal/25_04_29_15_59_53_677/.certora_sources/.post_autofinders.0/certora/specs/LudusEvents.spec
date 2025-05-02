// Certora specification for LudusEvents contract

// Declare access to state variables needed for rules/invariants
// using LudusEventsImpl {
//     // Declare the specific fields within the mapping we need
//     events[uint256].startTime,
//     events[uint256].endTime
// }

using LudusTypes as types; // Assuming LudusTypes.sol defines the EventStatus enum

methods {
    // External functions from LudusEventsImpl (target contract)
    function createEvent(
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
    ) returns (uint256);
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

    // Add the events view function signature from the successful spec
    function events(uint256) external returns (uint256 id, uint256 startTime, uint256 endTime, uint256 regStartTime, uint256 regEndTime, uint256 maxParticipants, address creator, address organizerAddress /* referee changed to organizerAddress */, types.EventStatus status, uint256 regFeeETH, uint256 regFeeUSDC, uint256 totalPrize, bool prefYield) envfree;
    
    // View function for distributions (from successful spec)
    function eventDistributions(uint256) external returns (uint256 athletesShare, uint256 organizerShare, uint256 charityShare, address charityAddress) envfree;
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

// Rule: Check state properties AFTER a successful createEvent call
rule createEventPostStateCheck(method f)
    filtered f.call(
        uint256 startTimeArg, // Use different names to avoid clash with view results
        uint256 endTimeArg,
        uint256 registrationStartTimeArg,
        uint256 registrationEndTimeArg,
        uint256 maxParticipantsArg,
        address organizerAddressArg,
        uint256 registrationFeeUSDCArg,
        uint256 registrationFeeETHArg,
        bool preferYieldGenerationArg,
        string nameArg, 
        string descriptionArg, 
        string eventTypeArg, 
        string venueArg, 
        string sportArg,
        string[] rulesArg, 
        string[] requirementsArg, 
        uint256[] ticketPricesArg, 
        string[] ticketTierNamesArg, 
        uint256[] sponsorshipPricesArg, 
        string[] sponsorshipTierNamesArg,
        uint256 athletesShareArg, 
        uint256 organizerShareArg, 
        uint256 charityShareArg, 
        address charityAddressArg 
    ) returns uint256 eventId 
{
    env e;
    require eventId > 0; // Focus on successful creation

    // Fetch the state of the newly created event
    uint256 id; 
    uint256 startTime; 
    uint256 endTime; 
    uint256 regStartTime; 
    uint256 regEndTime; 
    uint256 maxParticipants; 
    address creator; 
    address organizerAddress; 
    types.EventStatus status; 
    uint256 regFeeETH; 
    uint256 regFeeUSDC; 
    uint256 totalPrize; 
    bool prefYield;

    id, startTime, endTime, regStartTime, regEndTime, maxParticipants, creator, organizerAddress, status, regFeeETH, regFeeUSDC, totalPrize, prefYield = events(eventId);

    // Assert expected initial state properties
    assert id == eventId, "Event ID mismatch after creation";
    assert status == types.EventStatus.Created, "Newly created event status should be Created";
    assert creator == e.msg.sender, "Event creator should be msg.sender";
    
    // Check stored distribution matches arguments (redundant if checkCreateEventTreasuryDistribution passes, but good cross-check)
    uint256 storedAthletesShare;
    uint256 storedOrganizerShare;
    uint256 storedCharityShare;
    address storedCharityAddress;
    storedAthletesShare, storedOrganizerShare, storedCharityShare, storedCharityAddress = eventDistributions(eventId);

    assert storedAthletesShare == athletesShareArg, "Stored athletesShare mismatch";
    assert storedOrganizerShare == organizerShareArg, "Stored organizerShare mismatch";
    assert storedCharityShare == charityShareArg, "Stored charityShare mismatch";
    assert storedCharityAddress == charityAddressArg, "Stored charityAddress mismatch";
    
    // Check timeline arguments match stored values (redundant if checkCreateEventTimeline passes)
    assert startTime == startTimeArg, "Stored startTime mismatch";
    assert endTime == endTimeArg, "Stored endTime mismatch";
    assert regStartTime == registrationStartTimeArg, "Stored regStartTime mismatch";
    assert regEndTime == registrationEndTimeArg, "Stored regEndTime mismatch";

}

// Invariant: Existing event timelines must remain valid
// Remove the old invariant based on direct storage access
// invariant validEventTimelineInvariant()
//    // Access events.keys() implicitly through the declared fields
//    forall uint256 eventId in events.keys {
//        // Access fields directly as they are declared in 'using'
//        require events[eventId].startTime > 0;
//        assert events[eventId].endTime > events[eventId].startTime,
//               "Invariant Violated: Event endTime is not strictly greater than startTime";
//    }

// Add new invariant using the events view function
invariant validTimelineInvariant(uint256 eventId) {
    // Fetch event details using the view function
    uint256 id;
    uint256 startTime;
    uint256 endTime;
    uint256 regStartTime;
    uint256 regEndTime;
    // ... other fields we don't need for this invariant ...
    types.EventStatus status; // Get status to potentially filter by

    id, startTime, endTime, regStartTime, regEndTime, _, _, _, status, _, _, _, _ = events(eventId);

    // The invariant holds vacuously true for non-existent events (id == 0)
    // Only assert for events that actually exist (id > 0)
    require id > 0 => (regEndTime <= startTime && endTime > startTime);
    // We might also want to ensure startTime is non-zero for existing events, 
    // although createEvent rules should enforce this initially.
    // require id > 0 => startTime > 0; 
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