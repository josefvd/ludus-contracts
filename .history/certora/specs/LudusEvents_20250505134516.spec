// Certora specification for LudusEvents contract invariants

// Assuming LudusTypes.EventStatus is accessible (e.g., via linking in conf or if defined in a base contract)

methods {
    // --- Functions needed by invariants ---

    // View functions to access state per eventId
    function events(uint256 eventId) external returns (
        uint256, // id
        uint256, // startTime
        uint256, // endTime
        uint256, // regStartTime
        uint256, // regEndTime
        uint256, // maxParticipants
        address, // creator
        address, // organizerAddress
        LudusTypes.EventStatus, // status
        uint256, // regFeeETH
        uint256, // regFeeUSDC
        uint256, // totalPrize
        bool // prefYield
    ) envfree;

    function eventDistributions(uint256 eventId) external returns (
        uint256, // athletesShare
        uint256, // organizerShare
        uint256, // charityShare
        address // charityAddress
    ) envfree;

    // --- State-changing functions (optional but good practice for context) ---
    // List any external functions that can change the state checked by invariants
    function createEvent(bytes, bytes, bytes, bytes) external returns (uint256);
    function startEvent(uint256) external;
    function completeEvent(uint256, address[], uint256[]) external;
    function cancelEvent(uint256) external;
    // Add others like registerParticipant if they modify event state relevant to invariants
}

/**
 * Invariant: Checks that the treasury distribution percentages are valid for all existing events.
 * - Sum of shares must be 9700 (97%).
 * - If charityShare > 0, charityAddress must not be the zero address.
 */
invariant validTreasuryDistributionInvariant() {
    // Declare a symbolic eventId - the prover will check this for all possible values
    uint256 eventId;

    // Fetch the state associated with the symbolic eventId
    uint256 id_check; // Use a distinct name to avoid shadowing eventId
    LudusTypes.EventStatus status_check; // Capture status if needed for filtering
    // ... other event fields are unused here ...
    (id_check, , , , , , , , status_check, , , , ) = events(eventId);

    uint256 athletesShare;
    uint256 organizerShare;
    uint256 charityShare;
    address charityAddress;
    (athletesShare, organizerShare, charityShare, charityAddress) = eventDistributions(eventId);

    // --- Filter: Only apply checks to existing events ---
    // Assumes events(0) returns default/zero values or reverts.
    // We check if the returned ID matches the queried ID and is non-zero.
    // Optional: Add status checks if invariants don't apply to certain states (e.g., Cancelled).
    require id_check == eventId && id_check > 0; // && status_check != LudusTypes.EventStatus.Cancelled;

    // --- Assertions for existing events ---
    assert athletesShare + organizerShare + charityShare == 9700,
           "Treasury distribution percentages must sum to 9700 for existing events";

    if (charityShare > 0) {
        assert charityAddress != address(0),
               "Charity address must be non-zero if charity share is non-zero for existing events";
    }
}

/**
 * Invariant: Checks that the event timeline is valid for all existing events.
 * - regEndTime <= startTime
 * - startTime < endTime
 */
invariant validTimelineInvariant() {
    // Declare a symbolic eventId
    uint256 eventId;

    // Fetch the state associated with the symbolic eventId
    uint256 id_check;
    uint256 startTime;
    uint256 endTime;
    uint256 regEndTime;
    LudusTypes.EventStatus status_check;
     // ... other event fields are unused here ...
    (id_check, startTime, endTime, , regEndTime, , , , status_check, , , , ) = events(eventId);

    // --- Filter: Only apply checks to existing events ---
    // Optional: Add status checks if needed.
    require id_check == eventId && id_check > 0; // && status_check != LudusTypes.EventStatus.Cancelled;

    // --- Assertions for existing events ---
    assert regEndTime <= startTime,
           "Registration end time must be less than or equal to start time for existing events";

    assert startTime < endTime, // Note: Using strict inequality based on previous message
           "Start time must be strictly less than end time for existing events";
}

// Future: Add invariant for valid status transitions
// invariant validStatusTransitionsInvariant() { ... }