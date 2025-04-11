// Certora specification for LudusEvents contract registration rules
using LudusTypes as types;

methods {
    // View functions
    function events(uint256) external returns (uint256, uint256, uint256, uint256, uint256, uint256, address, address, types.EventStatus, uint256, uint256, uint256, bool) envfree;
    function isParticipantRegistered(uint256, uint256) external returns (bool) envfree;
    function getParticipantCount(uint256) external returns (uint256) envfree;
    function getEventStatus(uint256) external returns (types.EventStatus) envfree;
    
    // State-changing functions
    function registerParticipant(uint256, uint256) external;
    
    // External contract calls (Linked LudusIdentity)
    function ownerOf(uint256) external returns (address) => DISPATCHER(true);
}

// Helper function to check if a status is Created
function isCreated(types.EventStatus status) returns bool {
    return status == types.EventStatus.Created;
}

// Helper function to check if registration time is valid
function isValidRegistrationTime(uint256 currentTime, uint256 regStartTime, uint256 regEndTime, uint256 startTime) returns bool {
    return currentTime >= regStartTime && currentTime <= regEndTime && currentTime < startTime;
}

// Helper function to check if registration is allowed
function canRegister(types.EventStatus status, uint256 currentTime, uint256 regStartTime, uint256 regEndTime, uint256 startTime) returns bool {
    return isCreated(status) && isValidRegistrationTime(currentTime, regStartTime, regEndTime, startTime);
}

// Rule 1: Registration is only allowed for events in Created state
rule registrationOnlyInCreatedState(uint256 eventId, uint256 profileId) {
    env e;
    
    // Get event details before registration
    types.EventStatus statusBefore = getEventStatus(eventId);
    
    // Try to register
    registerParticipant@withrevert(e, eventId, profileId);
    
    // If registration succeeds, event must have been in Created state
    assert !lastReverted => isCreated(statusBefore),
        "Registration allowed in non-Created state";
}

// Rule 2: Registration updates participant state correctly
rule registrationUpdatesState(uint256 eventId, uint256 profileId) {
    env e;
    
    // Store initial state
    bool wasRegistered = isParticipantRegistered(eventId, profileId);
    uint256 initialCount = getParticipantCount(eventId);
    
    // Perform registration
    registerParticipant@withrevert(e, eventId, profileId);
    
    // If registration succeeds
    if (!lastReverted) {
        // Participant should be marked as registered
        assert isParticipantRegistered(eventId, profileId),
            "Participant not marked as registered after successful registration";
            
        // Participant count should increase by 1 if not previously registered
        if (!wasRegistered) {
            assert getParticipantCount(eventId) == initialCount + 1,
                "Participant count not incremented correctly";
        }
    }
}

// Rule 3: No double registration
rule noDoubleRegistration(uint256 eventId, uint256 profileId) {
    env e;
    
    // First registration
    registerParticipant@withrevert(e, eventId, profileId);
    
    // If first registration succeeds, second should fail
    if (!lastReverted) {
        registerParticipant@withrevert(e, eventId, profileId);
        assert lastReverted, "Double registration not prevented";
    }
}

// Rule 4: Registration timing constraints
rule registrationTimingConstraints(uint256 eventId, uint256 profileId) {
    env e;
    
    // Get event details
    uint256 id;
    uint256 startTime;
    uint256 endTime;
    uint256 regStartTime;
    uint256 regEndTime;
    uint256 maxParticipants;
    address creator;
    address referee;
    types.EventStatus status;
    uint256 regFeeETH;
    uint256 regFeeUSDC;
    uint256 totalPrize;
    bool prefYield;
    
    id, startTime, endTime, regStartTime, regEndTime, maxParticipants, creator, referee, status, regFeeETH, regFeeUSDC, totalPrize, prefYield = events(eventId);
    
    // Try to register
    registerParticipant@withrevert(e, eventId, profileId);
    
    // If registration succeeds, verify timing constraints
    if (!lastReverted) {
        assert isValidRegistrationTime(e.block.timestamp, regStartTime, regEndTime, startTime),
            "Registration allowed outside registration phase";
    }
}

// Rule 5: Profile ownership verification
rule profileOwnershipVerification(uint256 eventId, uint256 profileId) {
    env e;
    
    // Skip if profileId is 0 (allowed for non-profile registrations)
    if (profileId > 0) {
        // Get the owner of the profile via linked LudusIdentity
        address profileOwner = ownerOf(profileId);
        
        // Try to register with non-owner sender
        require profileOwner != e.msg.sender;

        registerParticipant@withrevert(e, eventId, profileId);
        assert lastReverted,
            "Non-owner allowed to register with profile";
    }
} 