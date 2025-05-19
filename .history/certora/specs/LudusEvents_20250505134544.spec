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
    (id_check, , , , , , , , status_check, , , , ) = events(eventId);

    uint256 athletesShare;
    uint256 organizerShare;
    uint256 charityShare;
    address charityAddress;
    (athletesShare, organizerShare, charityShare, charityAddress) = eventDistributions(eventId);

    // Filter condition
    bool exists = id_check == eventId && id_check > 0;

    // Assertion conditions
    bool distributionSumCorrect = athletesShare + organizerShare + charityShare == 9700;
    bool charityAddressValid = (charityShare == 0) || (charityAddress != address(0));

    // Combine using implication: exists => (distributionSumCorrect && charityAddressValid)
    exists => (distributionSumCorrect && charityAddressValid);
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
    (id_check, startTime, endTime, , regEndTime, , , , status_check, , , , ) = events(eventId);

    // Filter condition
    bool exists = id_check == eventId && id_check > 0;

    // Assertion conditions
    bool regTimeValid = regEndTime <= startTime;
    bool eventDurationValid = startTime < endTime;

    // Combine using implication: exists => (regTimeValid && eventDurationValid)
    exists => (regTimeValid && eventDurationValid);
}

// Future: Add invariant for valid status transitions
// invariant validStatusTransitionsInvariant() { ... }