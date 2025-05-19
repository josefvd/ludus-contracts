// Certora specification for LudusEvents - Treasury Invariant

/// Checks if the treasury distribution property holds for a specific eventId.
/// Returns true if the event doesn't exist (property holds vacuously) or if the property holds.
function checkTreasuryDistributionProperty(uint256 eventId) returns bool {
    uint256 id_ev; uint256 startTime_ev; uint256 endTime_ev; uint256 regStartTime_ev; uint256 regEndTime_ev;
    uint256 maxParticipants_ev; address creator_ev; address organizerAddress_ev; LudusTypes.EventStatus status_ev;
    uint256 regFeeETH_ev; uint256 regFeeUSDC_ev; uint256 totalPrize_ev; bool prefYield_ev;

    (id_ev, startTime_ev, endTime_ev, regStartTime_ev, regEndTime_ev,
     maxParticipants_ev, creator_ev, organizerAddress_ev, status_ev,
     regFeeETH_ev, regFeeUSDC_ev, totalPrize_ev, prefYield_ev) = events(eventId);

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
    // --- LudusEventsImpl's own functions ---
    function events(uint256 eventId) external returns (
        uint256, uint256, uint256, uint256, uint256, uint256, address, address,
        LudusTypes.EventStatus, uint256, uint256, uint256, bool
    ) envfree;
    function eventDistributions(uint256 eventId) external returns (uint256, uint256, uint256, address) envfree;
    function createEvent(bytes, bytes, bytes, bytes) returns (uint256) summary;
    function startEvent(uint256) summary;
    function completeEvent(uint256, address[], uint256[]) summary;
    function cancelEvent(uint256) summary;

    // --- Accessors for External Contract Instances (from LudusEventsImpl) ---
    function jbTerminal() external returns (address) envfree;
    function yieldManager() external returns (address) envfree;

    // --- Declarations of External Function Signatures Called by LudusEventsImpl ---
    function addToBalanceOf(uint256, address, uint256, string) summary;
    function setDistributionCurrentEventId(uint256) summary;

    // TODO: Add other external functions called by LudusEventsImpl as they are identified.
}

/**
 * Invariant: Checks valid treasury distribution for all (relevant) eventIds.
 */
invariant validTreasuryDistribution(uint256 eventId)
    checkTreasuryDistributionProperty(eventId); 