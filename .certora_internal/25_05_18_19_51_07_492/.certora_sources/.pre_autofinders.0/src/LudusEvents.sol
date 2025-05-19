// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// OpenZeppelin Imports
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// EAS Contracts
// Import structs/types from the main IEAS interface
import {IEAS, Attestation, AttestationRequest, AttestationRequestData, RevocationRequest, RevocationRequestData} from "@eas/IEAS.sol";
import {ISchemaRegistry} from "@eas/ISchemaRegistry.sol";
// Import only the ISchemaResolver interface from its file
import {ISchemaResolver} from "@eas/resolver/ISchemaResolver.sol";

// Local Interfaces
import "./interfaces/ILudusIdentity.sol";
import "./interfaces/IYieldManager.sol";

// Local Libraries
import "./libraries/LudusTypes.sol";
import "./libraries/LudusAttestations.sol";

// Custom errors
error Unauthorized();
error InvalidAddress();
error InvalidTime();
error InvalidAmount();
error InvalidDistribution();
error EventNotInState();
error InvalidAttestation();
error InvalidPaymentCurrency();
error StakingConditionsNotMet();
error YieldAlreadyActivated();

abstract contract LudusEvents is Ownable, ReentrancyGuard, ISchemaResolver {
    using LudusTypes for LudusTypes.EventDetails;
    using LudusTypes for LudusTypes.Distribution;
    using LudusTypes for LudusTypes.EventAttestationData;
    using LudusTypes for LudusTypes.ResultAttestationData;
    using LudusAttestations for *;

    // Contract references
    ILudusIdentity public immutable ludusIdentity;
    IEAS public immutable eas;
    ISchemaRegistry public immutable schemaRegistry;
    IYieldManager public yieldManager;
    IERC20 public immutable USDC;
    address public ludusWallet;

    // Constants
    uint256 public constant MINIMUM_TREASURY_AMOUNT = 1000e6; // 1000 USDC
    uint256 public constant MINIMUM_LOCK_PERIOD = 7 days;
    uint256 public constant LUDUS_TAX_PERCENTAGE = 300; // 3% fixed Ludus tax

    // Event schema IDs
    bytes32 public eventSchemaId;
    bytes32 public resultSchemaId;

    // Event tracking
    uint256 public eventCount;
    mapping(uint256 => LudusTypes.EventDetails) public events;
    mapping(uint256 => mapping(uint256 => bool)) public isParticipantRegistered;
    mapping(uint256 => uint256) public eventPrizesETH;
    mapping(uint256 => uint256) public eventPrizesUSDC;

    // Track participant event count
    mapping(address => uint256) public participantEventCount;
    mapping(address => string) public participantUsernames;

    // Distribution settings
    mapping(uint256 => LudusTypes.Distribution) public eventDistributions;
    mapping(uint256 => LudusTypes.AthleteDistribution) internal _athleteDistributions;
    
    // Add mapping to track attestations
    mapping(bytes32 => bool) public processedAttestations;

    // Events
    event DistributionSet(
        uint256 indexed eventId,
        uint256 athletesShare,
        uint256 organizerShare,
        uint256 charityShare,
        address charityAddress
    );
    event EventCreated(uint256 indexed eventId, string name, uint256 startTime, uint256 endTime);
    event ParticipantRegistered(uint256 indexed eventId, uint256 indexed profileId);
    event EventStarted(uint256 indexed eventId);
    event EventCompletedWithWinners(
        uint256 indexed eventId,
        address[] winners,
        uint256 totalAmountDistributed,
        uint256 athletesAmount,
        uint256 organizerAmount,
        uint256 charityAmount,
        uint256 platformFee
    );
    event EventCanceled(uint256 indexed eventId);
    event YieldUpdated(uint256 indexed eventId, uint256 principal, uint256 yield, bool isEnabled);
    event YieldManagerUpdated(address indexed oldYieldManager, address indexed newYieldManager);

    // New events for ETH staking operations
    event ETHStaked(uint256 indexed eventId, uint256 amount);
    event YieldGenerationEnabled(uint256 indexed eventId, bool isETH);
    event ETHWithdrawn(uint256 indexed eventId, uint256 amount);

    // New events for USDC staking operations
    event USDCStaked(uint256 indexed eventId, uint256 amount);
    event USDCWithdrawn(uint256 indexed eventId, uint256 amount);

    // Modifier for schema management
    modifier onlyOwnerOrAdmin() {
        if (msg.sender != owner()) revert Unauthorized();
        _;
    }

    // Add receive function to accept ETH payments
    receive() external payable {}

    constructor(
        address _ludusIdentity,
        address _eas,
        address _schemaRegistry,
        address _yieldManager,
        address initialOwner
    ) Ownable(initialOwner) {
        if (_ludusIdentity == address(0) || _eas == address(0) || 
            _schemaRegistry == address(0) || 
            _yieldManager == address(0)) revert InvalidAddress();
        if (initialOwner == address(0)) revert InvalidAddress();

        ludusIdentity = ILudusIdentity(_ludusIdentity);
        eas = IEAS(_eas);
        schemaRegistry = ISchemaRegistry(_schemaRegistry);
        yieldManager = IYieldManager(_yieldManager);
        USDC = IERC20(yieldManager.usdc());
        ludusWallet = 0x44A59082F113C75EaefbD3Fe57447C00dEb41874;
    }

    function approveAchievementTerminal() external onlyOwner {
        USDC.approve(address(yieldManager), type(uint256).max);
    }

    function setLudusWallet(address _newLudusWallet) external onlyOwner {
        if (_newLudusWallet == address(0)) revert InvalidAddress();
        ludusWallet = _newLudusWallet;
    }

    function setSchemaIds(bytes32 _eventSchemaId, bytes32 _resultSchemaId) external onlyOwner {
        if (_eventSchemaId == bytes32(0) || _resultSchemaId == bytes32(0)) revert InvalidAddress();
        eventSchemaId = _eventSchemaId;
        resultSchemaId = _resultSchemaId;
    }

    function setYieldManager(address _yieldManager) external onlyOwner {
        require(_yieldManager != address(0), "Invalid yield manager address");
        address oldYieldManager = address(yieldManager);
        yieldManager = IYieldManager(_yieldManager);
        emit YieldManagerUpdated(oldYieldManager, _yieldManager);
    }

    function _canEnableYieldGeneration(uint256 eventId, uint256 amount) internal view returns (bool) {
        LudusTypes.EventDetails memory eventData = events[eventId];
        return amount >= MINIMUM_TREASURY_AMOUNT && 
               (eventData.endTime - eventData.startTime) >= MINIMUM_LOCK_PERIOD;
    }

    // --- Internal Helper Functions --- 

    // Updated to accept the params struct
    function _validateCreateEventInputs(
        LudusTypes.EventCreationParams memory params, // Use struct param
        uint256[] memory positions,
        uint256[] memory percentages,
        LudusTypes.EventAttestationData memory attestationData
    ) internal view {
        require(params.startTime > block.timestamp, "Invalid start time");
        require(params.endTime > params.startTime, "End time must be after start time");
        require(params.registrationStartTime < params.registrationEndTime, "Invalid registration period");
        require(params.registrationEndTime <= params.startTime, "Registration must end before event starts");
        require(params.registrationStartTime >= block.timestamp, "Registration start time must be in the future");
        require(params.maxParticipants > 0, "Max participants must be greater than 0");
        require(params.paymentCurrency != LudusTypes.PaymentCurrency.NONE, "Payment currency must be set");
        require(params.registrationFee > 0, "Registration fee must be greater than 0");
        require(params.minParticipantsToStart > 0, "Min participants to start must be > 0");
        require(params.minParticipantsToStart <= params.maxParticipants, "Min participants <= max participants");
        require(positions.length == percentages.length, "Invalid distribution arrays");
        require(positions.length > 0, "Must have at least one position");
        require(params.athletesShare + params.organizerShare + params.charityShare == 9700, "Total shares must sum to exactly 97% (9700)");
        require(params.refereeAddress != address(0), "Invalid referee address");
        require(params.organizerAddress != address(0), "Invalid organizer address");
        require(params.charityShare == 0 || params.charityAddress != address(0), "Invalid charity setup");
        
        uint256 totalPercentage;
        for (uint256 i = 0; i < percentages.length; i++) {
            totalPercentage += percentages[i];
        }
        require(totalPercentage == 10000, "Athlete percentages must sum to 100%");
        
        require(attestationData.ticketPrices.length == attestationData.ticketTierNames.length, "Invalid ticket tiers");
        require(attestationData.sponsorshipPrices.length == attestationData.sponsorshipTierNames.length, "Invalid sponsorship tiers");
    }

    // Updated to accept the params struct
    function _calculateTotalPrizePool(
        LudusTypes.EventCreationParams memory params, // Use struct param
        LudusTypes.EventAttestationData memory attestationData
    ) internal pure returns (uint256 totalPrizePool) {
        totalPrizePool = params.registrationFee * params.maxParticipants;
        for (uint256 i = 0; i < attestationData.ticketPrices.length; i++) {
            totalPrizePool += attestationData.ticketPrices[i];
        }
        for (uint256 i = 0; i < attestationData.sponsorshipPrices.length; i++) {
            totalPrizePool += attestationData.sponsorshipPrices[i];
        }
    }

    // Updated to accept the params struct
    function _storeEventDetails(
        uint256 currentEventId,
        LudusTypes.EventCreationParams memory params, // Use struct param
        uint256 totalPrizePool,
        uint256[] memory positions,
        uint256[] memory percentages
    ) internal {
        events[currentEventId] = LudusTypes.EventDetails({
            id: currentEventId,
            startTime: params.startTime,
            endTime: params.endTime,
            registrationStartTime: params.registrationStartTime,
            registrationEndTime: params.registrationEndTime,
            maxParticipants: params.maxParticipants,
            minParticipantsToStart: params.minParticipantsToStart,
            creator: params.organizerAddress,
            referee: params.refereeAddress,
            status: LudusTypes.EventStatus.Created,
            registrationFee: params.registrationFee,
            paymentCurrency: params.paymentCurrency,
            totalPrizePool: totalPrizePool,
            preferYieldGeneration: params.preferYieldGeneration,
            yieldActivated: false
        });
        
        eventDistributions[currentEventId] = LudusTypes.Distribution({
            athletesShare: params.athletesShare,
            organizerShare: params.organizerShare,
            charityShare: params.charityShare,
            charityAddress: params.charityAddress
        });
        
        _athleteDistributions[currentEventId] = LudusTypes.AthleteDistribution({
            positions: positions,
            percentages: percentages
        });
    }

    // Updated to accept the params struct
    function _handleYieldAndAttestation(
        uint256 currentEventId,
        LudusTypes.EventCreationParams memory params, // Use struct param
        LudusTypes.EventAttestationData memory attestationData
    ) internal {
        if (block.chainid != 31337) {
            yieldManager.setDistribution(
                currentEventId,
                params.athletesShare,
                params.organizerShare,
                params.charityShare,
                params.charityAddress
            );
            
            attestationData.eventId = currentEventId; 
            bytes32 attestationUid = LudusAttestations.createEventAttestation(
                currentEventId,
                attestationData.name, attestationData.description, attestationData.eventType,
                attestationData.venue, attestationData.sport, attestationData.rules,
                attestationData.requirements, attestationData.ticketPrices, attestationData.ticketTierNames,
                attestationData.sponsorshipPrices, attestationData.sponsorshipTierNames, attestationData.eventURI,
                msg.sender, eventSchemaId, address(eas)
            );
            
            require(attestationUid != bytes32(0), "Attestation creation failed");
            
            try eas.getAttestation(attestationUid) returns (Attestation memory attestation) {
                require(attestation.schema == eventSchemaId, "Invalid schema for attestation");
                require(attestation.attester == msg.sender, "Invalid attester"); 
            } catch {
                revert("Failed to verify attestation with EAS");
            }
        } else {
            yieldManager.setDistribution(
                currentEventId,
                params.athletesShare,
                params.organizerShare,
                params.charityShare,
                params.charityAddress
            );
        }
    }

    // --- createEvent Function (Updated Signature) ---

    function createEvent(
        LudusTypes.EventCreationParams memory params, // Use struct param
        uint256[] memory positions,
        uint256[] memory percentages,
        LudusTypes.EventAttestationData memory attestationData
    ) external returns (uint256) {
        // Step 1: Validate Inputs
        _validateCreateEventInputs(params, positions, percentages, attestationData);
        
        eventCount++; 

        // Step 2 & 3: Calculate Prize Pool and Store Core Details 
        _storeEventDetails(
            eventCount,
            params, // Pass struct 
            _calculateTotalPrizePool(params, attestationData), // Pass struct
            positions, 
            percentages
        );
        
        // Step 4: Handle Yield Manager and Attestation
        _handleYieldAndAttestation(
            eventCount,
            params, // Pass struct
            attestationData 
        );
        
        // Emit final events (access params struct for needed fields)
        emit EventCreated(eventCount, attestationData.name, params.startTime, params.endTime);
        emit DistributionSet(eventCount, params.athletesShare, params.organizerShare, params.charityShare, params.charityAddress);
        
        return eventCount;
    }

    function registerParticipant(uint256 eventId, uint256 profileId) external payable {
        LudusTypes.EventDetails storage eventData = events[eventId];
        require(eventData.status == LudusTypes.EventStatus.Created, "Event not in registration phase");
        require(block.timestamp < eventData.startTime, "Registration period ended");
        require(!isParticipantRegistered[eventId][profileId], "Already registered");
        
        // Check profileId ownership only if it's not zero
        if (profileId > 0) {
            require(ludusIdentity.ownerOf(profileId) == msg.sender, "Not profile owner");
        }
        
        // Handle registration fee payment based on event's specified currency
        if (eventData.paymentCurrency == LudusTypes.PaymentCurrency.ETH) {
            require(msg.value == eventData.registrationFee, "Incorrect ETH amount for registration");
            eventData.totalPrizePool += msg.value;
            eventPrizesETH[eventId] += msg.value; // Add to contract's ETH pool, no immediate staking
        } else if (eventData.paymentCurrency == LudusTypes.PaymentCurrency.USDC) {
            require(msg.value == 0, "ETH sent for USDC registration"); // Ensure no ETH is sent for USDC fees
            require(eventData.registrationFee > 0, "USDC registration fee not set for event");
            require(
                USDC.transferFrom(msg.sender, address(this), eventData.registrationFee),
                "USDC transfer for registration failed"
            );
            eventData.totalPrizePool += eventData.registrationFee;
            eventPrizesUSDC[eventId] += eventData.registrationFee; // Add to contract's USDC pool, no immediate staking
        } else {
            revert InvalidPaymentCurrency(); // Event not configured for ETH or USDC payment
        }
        
        isParticipantRegistered[eventId][profileId] = true;
        
        // Increment participant event count
        participantEventCount[msg.sender] += 1;
        
        emit ParticipantRegistered(eventId, profileId);
    }

    function startEvent(uint256 eventId) external {
        LudusTypes.EventDetails storage eventData = events[eventId];
        require(eventData.creator == msg.sender, "Only creator can start event");
        require(eventData.status == LudusTypes.EventStatus.Created, "Event not in created state");
        require(block.timestamp >= eventData.startTime, "Start time not reached");
        
        eventData.status = LudusTypes.EventStatus.Started;
        emit EventStarted(eventId);
    }

    function getEvent(uint256 eventId) external view returns (LudusTypes.EventDetails memory) {
        return events[eventId];
    }

    function isParticipant(uint256 eventId, uint256 profileId) external view returns (bool) {
        return isParticipantRegistered[eventId][profileId];
    }

    function getParticipantEventCount(address participant) external view returns (uint256) {
        return participantEventCount[participant];
    }

    function canCreateProfile(address participant) external view returns (bool) {
        return participantEventCount[participant] >= 3;
    }

    function getEventDistribution(uint256 eventId) external view returns (
        uint256 athletesShare,
        uint256 organizerShare,
        uint256 charityShare,
        address charityAddress
    ) {
        LudusTypes.Distribution memory dist = eventDistributions[eventId];
        return (
            dist.athletesShare,
            dist.organizerShare,
            dist.charityShare,
            dist.charityAddress
        );
    }

    function getParticipants(uint256 eventId) external view returns (uint256[] memory) {
        uint256 count = 0;
        uint256 totalSupply = ludusIdentity.totalSupply();
        uint256[] memory participants = new uint256[](totalSupply);
        
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (isParticipantRegistered[eventId][i]) {
                participants[count] = i;
                count++;
            }
        }
        
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = participants[i];
        }
        
        return result;
    }

    function getParticipantCount(uint256 eventId) external view returns (uint256) {
        uint256 count = 0;
        uint256 totalSupply = ludusIdentity.totalSupply();
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (isParticipantRegistered[eventId][i]) {
                count++;
            }
        }
        return count;
    }

    function getAthleteDistribution(uint256 eventId) external view returns (uint256[] memory positions, uint256[] memory percentages) {
        LudusTypes.AthleteDistribution storage distribution = _athleteDistributions[eventId];
        return (distribution.positions, distribution.percentages);
    }

    // ISchemaResolver implementation
    function isPayable() external pure override returns (bool) {
        return true;
    }

    function version() external pure virtual returns (string memory) {
        return "1.0.0";
    }

    function _distributeFunds(
        uint256 eventId,
        LudusTypes.Distribution memory dist,
        address[] memory finalizedAthletes
    ) internal returns (uint256 totalEthDistributed, uint256 totalUsdcDistributed) {
        require(finalizedAthletes.length > 0, "No athletes provided");
        
        LudusTypes.EventDetails storage eventDetails = events[eventId];
        address organizerAddress = eventDetails.creator;
        
        LudusTypes.AthleteDistribution storage athleteDist = _athleteDistributions[eventId];
        require(finalizedAthletes.length <= athleteDist.positions.length, "Too many athletes");

        // --- ETH Distribution ---
        if (eventPrizesETH[eventId] > 0) {
            uint256 currentPoolEth = eventPrizesETH[eventId];
            totalEthDistributed = currentPoolEth; // All of it will be distributed or attempted

            uint256 athletesAmountEth = (currentPoolEth * dist.athletesShare) / 10000;
            uint256 organizerAmountEth = (currentPoolEth * dist.organizerShare) / 10000;
            uint256 charityAmountEth = (currentPoolEth * dist.charityShare) / 10000;
            uint256 platformFeeEth = (currentPoolEth * LUDUS_TAX_PERCENTAGE) / 10000;

            uint256 distributedToAthletesEth = 0;
        for (uint256 i = 0; i < finalizedAthletes.length; i++) {
                uint256 athleteShareEth = (athletesAmountEth * athleteDist.percentages[i]) / 10000;
                if (athleteShareEth > 0) {
                    (bool sent, ) = payable(finalizedAthletes[i]).call{value: athleteShareEth}("");
                    require(sent, "ETH transfer to athlete failed");
                    distributedToAthletesEth += athleteShareEth;
                }
            }

            if (organizerAmountEth > 0) {
                (bool sent, ) = payable(organizerAddress).call{value: organizerAmountEth}("");
                require(sent, "ETH transfer to organizer failed");
            }

            if (charityAmountEth > 0 && dist.charityAddress != address(0)) {
                (bool sent, ) = payable(dist.charityAddress).call{value: charityAmountEth}("");
                require(sent, "ETH transfer to charity failed");
            }

            if (platformFeeEth > 0) {
                (bool sent, ) = payable(ludusWallet).call{value: platformFeeEth}("");
                require(sent, "ETH transfer to platform failed");
            }
            eventPrizesETH[eventId] = 0; // Clear the pool after distribution
        }

        // --- USDC Distribution ---
        if (eventPrizesUSDC[eventId] > 0) {
            uint256 currentPoolUsdc = eventPrizesUSDC[eventId];
            totalUsdcDistributed = currentPoolUsdc; // All of it will be distributed

            uint256 athletesAmountUsdc = (currentPoolUsdc * dist.athletesShare) / 10000;
            uint256 organizerAmountUsdc = (currentPoolUsdc * dist.organizerShare) / 10000;
            uint256 charityAmountUsdc = (currentPoolUsdc * dist.charityShare) / 10000;
            uint256 platformFeeUsdc = (currentPoolUsdc * LUDUS_TAX_PERCENTAGE) / 10000;
            
            uint256 distributedToAthletesUsdc = 0;
            for (uint256 i = 0; i < finalizedAthletes.length; i++) {
                uint256 athleteShareUsdc = (athletesAmountUsdc * athleteDist.percentages[i]) / 10000;
                if (athleteShareUsdc > 0) {
                    require(USDC.transfer(finalizedAthletes[i], athleteShareUsdc), "USDC transfer to athlete failed");
                    distributedToAthletesUsdc += athleteShareUsdc;
                }
            }

            if (organizerAmountUsdc > 0) {
                require(USDC.transfer(organizerAddress, organizerAmountUsdc), "USDC transfer to organizer failed");
        }

            if (charityAmountUsdc > 0 && dist.charityAddress != address(0)) {
                require(USDC.transfer(dist.charityAddress, charityAmountUsdc), "USDC transfer to charity failed");
        }

            if (platformFeeUsdc > 0) {
                require(USDC.transfer(ludusWallet, platformFeeUsdc), "USDC transfer to platform failed");
            }
            eventPrizesUSDC[eventId] = 0; // Clear the pool after distribution
        }
    }

    function completeEventAndDistribute(
        uint256 eventId,
        address[] calldata finalizedAthletes
    ) external {
        require(msg.sender == address(schemaRegistry), "Only schema resolver can call");
        require(events[eventId].status == LudusTypes.EventStatus.Started, "Event not started");
        require(block.timestamp >= events[eventId].endTime, "Event not ended");

        // Get distribution settings
        LudusTypes.Distribution memory dist = eventDistributions[eventId];
        require(dist.athletesShare > 0, "Distribution not set");

        // Get total amount (including yield if enabled)
        // uint256 totalAmount = eventPrizes[eventId]; // Old logic

        // Validate athlete distribution
        LudusTypes.AthleteDistribution storage athleteDist = _athleteDistributions[eventId];
        require(finalizedAthletes.length <= athleteDist.positions.length, "Too many winners");
        require(finalizedAthletes.length > 0, "No winners provided");

        // Calculate and distribute prizes
        (uint256 totalEthDistributed, uint256 totalUsdcDistributed) = _distributeFunds(eventId, dist, finalizedAthletes);
        
        // Update event status
        events[eventId].status = LudusTypes.EventStatus.Completed;
        
        // For event emission, sum the values. This is a simplification as ETH and USDC have different values.
        // A more accurate event would list amounts per currency or use an oracle for total value.
        uint256 combinedTotalAmount = totalEthDistributed + totalUsdcDistributed; // Note: This is a sum of potentially different units
        uint256 combinedAthletesAmount = (totalEthDistributed * dist.athletesShare / 10000) + (totalUsdcDistributed * dist.athletesShare / 10000);
        uint256 combinedOrganizerAmount = (totalEthDistributed * dist.organizerShare / 10000) + (totalUsdcDistributed * dist.organizerShare / 10000);
        uint256 combinedCharityAmount = (totalEthDistributed * dist.charityShare / 10000) + (totalUsdcDistributed * dist.charityShare / 10000);
        uint256 combinedPlatformFee = (totalEthDistributed * LUDUS_TAX_PERCENTAGE / 10000) + (totalUsdcDistributed * LUDUS_TAX_PERCENTAGE / 10000);
        
        emit EventCompletedWithWinners(
            eventId,
            finalizedAthletes,
            combinedTotalAmount,
            combinedAthletesAmount,
            combinedOrganizerAmount,
            combinedCharityAmount,
            combinedPlatformFee
        );
    }

    function cancelEvent(uint256 eventId) external nonReentrant {
        LudusTypes.EventDetails storage eventData = events[eventId];
        
        // Case 1: Emergency cancellation by organizer
        if (msg.sender == eventData.creator) {
            require(eventData.status == LudusTypes.EventStatus.Created || 
                   eventData.status == LudusTypes.EventStatus.Started, 
                   "Can only cancel active events");
            
            eventData.status = LudusTypes.EventStatus.Canceled;
            
            // Get all registered participants
            uint256[] memory participants = this.getParticipants(eventId);
            uint256 participantCount = participants.length;
            
            if (participantCount > 0) {
                // Calculate refund amount per participant (no platform fee taken)
                // uint256 refundAmount = eventPrizes[eventId] / participantCount; // Old
                uint256 refundAmountETH = 0;
                uint256 refundAmountUSDC = 0;

                if (eventPrizesETH[eventId] > 0) {
                    refundAmountETH = eventPrizesETH[eventId] / participantCount;
                }
                if (eventPrizesUSDC[eventId] > 0) {
                    refundAmountUSDC = eventPrizesUSDC[eventId] / participantCount;
                }
                
                // Refund each participant
                for (uint256 i = 0; i < participantCount; i++) {
                    address participantAddress = ludusIdentity.ownerOf(participants[i]);
                    if (refundAmountETH > 0) {
                        (bool sent, ) = payable(participantAddress).call{value: refundAmountETH}("");
                        require(sent, "ETH refund transfer failed");
                    }
                    if (refundAmountUSDC > 0) {
                        require(USDC.transfer(participantAddress, refundAmountUSDC), "USDC refund transfer failed");
                }
            }
            }
            eventPrizesETH[eventId] = 0;
            eventPrizesUSDC[eventId] = 0;
            
            emit EventCanceled(eventId);
            return;
        }
        
        // Case 2: Automatic cancellation when minimums not met
        require(block.timestamp >= eventData.registrationEndTime, "Registration period not ended");
        require(eventData.status == LudusTypes.EventStatus.Created, "Event not in created state");
        
        // Check if minimum participants requirement is met
        uint256 currentParticipants = this.getParticipantCount(eventId);
        if (currentParticipants < eventData.minParticipantsToStart) {
            eventData.status = LudusTypes.EventStatus.Canceled;
            
            // Get all registered participants for refund
            uint256[] memory participants = this.getParticipants(eventId);
            uint256 currentParticipantCount = participants.length; // Use actual number of participants for refund division

            if (currentParticipantCount > 0) {
                uint256 refundAmountETH = 0;
                uint256 refundAmountUSDC = 0;

                if (eventPrizesETH[eventId] > 0) {
                    refundAmountETH = eventPrizesETH[eventId] / currentParticipantCount;
                }
                if (eventPrizesUSDC[eventId] > 0) {
                    refundAmountUSDC = eventPrizesUSDC[eventId] / currentParticipantCount;
                }
            
            // Refund each participant
                for (uint256 i = 0; i < currentParticipantCount; i++) {
                address participantAddress = ludusIdentity.ownerOf(participants[i]);
                     if (refundAmountETH > 0) {
                        (bool sent, ) = payable(participantAddress).call{value: refundAmountETH}("");
                        require(sent, "ETH refund transfer failed");
                    }
                    if (refundAmountUSDC > 0) {
                        require(USDC.transfer(participantAddress, refundAmountUSDC), "USDC refund transfer failed");
            }
                }
            }
            eventPrizesETH[eventId] = 0;
            eventPrizesUSDC[eventId] = 0;
            
            emit EventCanceled(eventId);
        }
    }

    // Add a public function to check if event should be cancelled due to minimum requirements
    function shouldEventBeCancelled(uint256 eventId) public view returns (bool) {
        LudusTypes.EventDetails storage eventData = events[eventId];
        if (eventData.status != LudusTypes.EventStatus.Created) return false;
        if (block.timestamp < eventData.registrationEndTime) return false;
        
        uint256 currentParticipants = this.getParticipantCount(eventId);
        return currentParticipants < eventData.minParticipantsToStart;
    }

    // New function to stake ETH with the YieldManager
    function _stakeEventETH(uint256 eventId, uint256 amount) internal {
        // Forward ETH to YieldManager for staking
        yieldManager.stakeEventFundsETH{value: amount}(eventId);
        
        // Emit event for tracking
        emit ETHStaked(eventId, amount);
    }
    
    // New function to enable yield generation for an event's ETH
    function enableETHYieldGeneration(uint256 eventId) external {
        LudusTypes.EventDetails storage eventData = events[eventId];
        require(eventData.creator == msg.sender || msg.sender == owner(), "Not authorized");
        require(eventData.preferYieldGeneration, "Event does not prefer yield generation");
        
        // Call YieldManager to enable yield generation
        yieldManager.enableYieldGeneration(eventId);
        
        emit YieldGenerationEnabled(eventId, true);
    }
    
    // New function to withdraw ETH funds after event is completed
    function withdrawEventETH(uint256 eventId) external {
        LudusTypes.EventDetails storage eventData = events[eventId];
        require(eventData.creator == msg.sender || msg.sender == owner(), "Not authorized");
        require(eventData.status == LudusTypes.EventStatus.Completed || 
                eventData.status == LudusTypes.EventStatus.Canceled, "Event must be completed or canceled");
        
        // Withdraw ETH funds from YieldManager
        uint256 withdrawnAmount = yieldManager.withdrawEventFundsETH(eventId);
        
        // Update event prizes to include any yield generated
        // eventPrizes[eventId] = withdrawnAmount; // Old
        eventPrizesETH[eventId] += withdrawnAmount; // Add withdrawn ETH (principal + yield from staking)
        
        emit ETHWithdrawn(eventId, withdrawnAmount);
    }

    // New function to withdraw USDC funds after event is completed or canceled
    function withdrawEventUSDC(uint256 eventId) external {
        LudusTypes.EventDetails storage eventData = events[eventId];
        require(eventData.creator == msg.sender || msg.sender == owner(), "Not authorized");
        require(eventData.status == LudusTypes.EventStatus.Completed || 
                eventData.status == LudusTypes.EventStatus.Canceled, "Event must be completed or canceled");
        
        // Assumes YieldManager has withdrawEventFundsUSDC
        uint256 withdrawnAmount = yieldManager.withdrawEventFundsUSDC(eventId);
        
        // Update event prizes USDC to include any yield generated or principal returned
        eventPrizesUSDC[eventId] += withdrawnAmount;
        
        emit USDCWithdrawn(eventId, withdrawnAmount);
    }

    // New function to activate yield generation after registration ends and conditions are met
    function activateYieldGeneration(uint256 eventId) external nonReentrant {
        LudusTypes.EventDetails storage eventData = events[eventId];

        require(msg.sender == eventData.creator || msg.sender == owner(), "Not authorized");
        require(eventData.status == LudusTypes.EventStatus.Created, "Event not in created state");
        require(block.timestamp >= eventData.registrationEndTime, "Registration period not ended");
        require(eventData.preferYieldGeneration, "Yield generation not preferred for this event");
        require(!eventData.yieldActivated, "Yield generation already activated for this event");

        // Check if event is proceeding (not being cancelled due to min participants)
        require(!this.shouldEventBeCancelled(eventId), "Event will be cancelled, cannot activate yield");

        if (eventData.paymentCurrency == LudusTypes.PaymentCurrency.ETH) {
            if (eventPrizesETH[eventId] > 0) {
                uint256 amountToStake = eventPrizesETH[eventId];
                eventPrizesETH[eventId] = 0; // Funds moved from temp holding to YieldManager
                _stakeEventETH(eventId, amountToStake); // _stakeEventETH emits ETHStaked
            }
        } else if (eventData.paymentCurrency == LudusTypes.PaymentCurrency.USDC) {
            if (eventPrizesUSDC[eventId] > 0) {
                uint256 amountToStake = eventPrizesUSDC[eventId];
                eventPrizesUSDC[eventId] = 0; // Funds moved from temp holding to YieldManager
                // Ensure LudusEvents contract has approved YieldManager for USDC
                yieldManager.stakeEventFundsUSDC(eventId, amountToStake);
                emit USDCStaked(eventId, amountToStake);
            }
        } else {
            revert InvalidPaymentCurrency(); // Should not happen if validated at creation
        }
        
        eventData.yieldActivated = true;
    }
} 