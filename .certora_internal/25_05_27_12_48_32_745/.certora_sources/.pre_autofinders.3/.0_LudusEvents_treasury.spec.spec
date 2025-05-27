// Certora specification for LudusEvents - Treasury Invariant

/// Checks if the treasury distribution property holds for a specific eventId.
/// Returns true if the event doesn't exist (property holds vacuously) or if the property holds.
function checkTreasuryDistributionProperty(uint256 eventId) returns bool {
    uint256 id_ev; uint256 startTime_ev; uint256 endTime_ev; uint256 regStartTime_ev; uint256 regEndTime_ev;
    uint256 maxParticipants_ev; uint256 minParticipantsToStart_ev; address creator_ev; address referee_ev;
    LudusTypes.EventStatus status_ev;
    uint256 regFee_ev; LudusTypes.PaymentCurrency paymentCurrency_ev; uint256 totalPrize_ev;
    bool prefYield_ev; bool yieldActivated_ev;

    (id_ev, startTime_ev, endTime_ev, regStartTime_ev, regEndTime_ev,
     maxParticipants_ev, minParticipantsToStart_ev, creator_ev, referee_ev,
     status_ev, regFee_ev, paymentCurrency_ev, totalPrize_ev,
     prefYield_ev, yieldActivated_ev) = events(eventId);

    if (!(id_ev == eventId && id_ev > 0)) {
        return true;
    }
    uint256 athletesShare_dist; uint256 organizerShare_dist; uint256 charityShare_dist; address charityAddress_dist;
    (athletesShare_dist, organizerShare_dist, charityShare_dist, charityAddress_dist) = eventDistributions(eventId);
    bool distributionSumCorrect = (athletesShare_dist + organizerShare_dist + charityShare_dist == 9700);
    bool charityAddressValid = ((charityShare_dist == 0) || (charityAddress_dist != 0));
    return distributionSumCorrect && charityAddressValid;
}

methods {
    // State readers
    function events(uint256 eventId) external returns (
        uint256, uint256, uint256, uint256, uint256, // id, startTime, endTime, regStartTime, regEndTime
        uint256, uint256, address, address,          // maxParticipants, minParticipantsToStart, creator, referee
        LudusTypes.EventStatus, uint256, LudusTypes.PaymentCurrency, uint256, // status, regFee, paymentCurrency, totalPrize
        bool, bool                                   // prefYield, yieldActivated
    ) envfree;
    function eventDistributions(uint256 eventId) external returns (uint256, uint256, uint256, address) envfree;

    // External Contract Accessors
    function yieldManager() external returns (address) envfree;
    function ludusIdentity() external returns (address) envfree;
    function eas() external returns (address) envfree;
    function schemaRegistry() external returns (address) envfree;
    function USDC() external returns (address) envfree;

    // State changers (relevant to treasury or called by YieldManager-interacting functions)
    function createEvent(bytes, bytes, bytes, bytes) external returns (uint256);
    function startEvent(uint256) external;
    function completeEventAndDistribute(uint256, bytes) external;
    function cancelEvent(uint256) external;
    function enableETHYieldGeneration(uint256) external;
    function registerParticipant(uint256,uint256) external;
    function withdrawEventETH(uint256) external;
    // function multiRevoke((bytes32,bytes32,uint64,uint64,uint64,bytes32,address,address,bool,bytes)[],uint256[]) summary; // Complex type, handle later if needed
    // function revoke((bytes32,bytes32,uint64,uint64,uint64,bytes32,address,address,bool,bytes)) summary; // Complex type, handle later if needed

    // --- Declarations of External Function Signatures Called by LudusEventsImpl ---
    function setDistributionCurrentEventId(uint256) external;

    // TODO: Add other external functions called by LudusEventsImpl as they are identified.
}

/**
 * Invariant: Checks valid treasury distribution for all (relevant) eventIds.
 */
invariant validTreasuryDistribution(uint256 eventId)
    checkTreasuryDistributionProperty(eventId); 