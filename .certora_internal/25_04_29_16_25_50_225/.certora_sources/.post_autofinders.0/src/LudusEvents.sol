// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// OpenZeppelin Imports
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Juicebox V4 Interfaces
import {IJBTerminal} from "@juicebox/interfaces/IJBTerminal.sol";

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
    IJBTerminal public immutable jbTerminal;
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
    mapping(uint256 => uint256) public eventPrizes;

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
        uint256 totalAmount,
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
        address _jbTerminal,
        address _yieldManager,
        address initialOwner
    ) Ownable(initialOwner) {
        if (_ludusIdentity == address(0) || _eas == address(0) || 
            _schemaRegistry == address(0) || _jbTerminal == address(0) || 
            _yieldManager == address(0)) revert InvalidAddress();
        if (initialOwner == address(0)) revert InvalidAddress();

        ludusIdentity = ILudusIdentity(_ludusIdentity);
        eas = IEAS(_eas);
        schemaRegistry = ISchemaRegistry(_schemaRegistry);
        jbTerminal = IJBTerminal(_jbTerminal);
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
        address oldYieldManager = address(yieldManager);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000001,oldYieldManager)}
        yieldManager = IYieldManager(_yieldManager);
        emit YieldManagerUpdated(oldYieldManager, _yieldManager);
    }

    function _canEnableYieldGeneration(uint256 eventId, uint256 amount) internal view returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00000000, 1037618708480) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00000001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00001000, eventId) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00001001, amount) }
        LudusTypes.EventDetails memory eventData = events[eventId];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010002,0)}
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
    ) internal view {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00020000, 1037618708482) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00020001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00021000, params) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00021001, positions) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00021002, percentages) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00021003, attestationData) }
        require(params.startTime > block.timestamp, "Invalid start time");
        require(params.endTime > params.startTime, "End time must be after start time");
        require(params.registrationStartTime < params.registrationEndTime, "Invalid registration period");
        require(params.registrationEndTime <= params.startTime, "Registration must end before event starts");
        require(params.registrationStartTime >= block.timestamp, "Registration start time must be in the future");
        require(params.maxParticipants > 0, "Max participants must be greater than 0");
        require(params.registrationFeeUSDC > 0 || params.registrationFeeETH > 0, "Registration fee must be set");
        require(positions.length == percentages.length, "Invalid distribution arrays");
        require(positions.length > 0, "Must have at least one position");
        require(params.athletesShare + params.organizerShare + params.charityShare <= 9700, "Total share exceeds 97% (3% Ludus tax)");
        require(params.refereeAddress != address(0), "Invalid referee address");
        require(params.organizerAddress != address(0), "Invalid organizer address");
        
        uint256 totalPercentage;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000003,totalPercentage)}
        for (uint256 i = 0; i < percentages.length; i++) {
            totalPercentage += percentages[i];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000022,totalPercentage)}
        }
        require(totalPercentage == 10000, "Athlete percentages must sum to 100%");
        
        require(attestationData.ticketPrices.length == attestationData.ticketTierNames.length, "Invalid ticket tiers");
        require(attestationData.sponsorshipPrices.length == attestationData.sponsorshipTierNames.length, "Invalid sponsorship tiers");
    }

    // Updated to accept the params struct
    function _calculateTotalPrizePool(
        LudusTypes.EventCreationParams memory params, // Use struct param
        LudusTypes.EventAttestationData memory attestationData
    ) internal pure returns (uint256 totalPrizePool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00030000, 1037618708483) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00030001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00031000, params) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00031001, attestationData) }
        totalPrizePool = params.registrationFeeUSDC * params.maxParticipants;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001f,totalPrizePool)}
        if (params.registrationFeeETH > 0) {
            totalPrizePool += params.registrationFeeETH * params.maxParticipants;
        }
        for (uint256 i = 0; i < attestationData.ticketPrices.length; i++) {
            totalPrizePool += attestationData.ticketPrices[i];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000023,totalPrizePool)}
        }
        for (uint256 i = 0; i < attestationData.sponsorshipPrices.length; i++) {
            totalPrizePool += attestationData.sponsorshipPrices[i];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000024,totalPrizePool)}
        }
    }

    // Updated to accept the params struct
    function _storeEventDetails(
        uint256 currentEventId,
        LudusTypes.EventCreationParams memory params, // Use struct param
        uint256 totalPrizePool,
        uint256[] memory positions,
        uint256[] memory percentages
    ) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00010000, 1037618708481) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00010001, 5) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00011000, currentEventId) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00011001, params) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00011002, totalPrizePool) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00011003, positions) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00011004, percentages) }
        events[currentEventId] = LudusTypes.EventDetails({
            id: currentEventId,
            startTime: params.startTime,
            endTime: params.endTime,
            registrationStartTime: params.registrationStartTime,
            registrationEndTime: params.registrationEndTime,
            maxParticipants: params.maxParticipants,
            creator: params.organizerAddress,
            referee: params.refereeAddress,
            status: LudusTypes.EventStatus.Created,
            registrationFeeETH: params.registrationFeeETH,
            registrationFeeUSDC: params.registrationFeeUSDC,
            totalPrizePool: totalPrizePool,
            preferYieldGeneration: params.preferYieldGeneration
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
    ) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00040000, 1037618708484) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00040001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00041000, currentEventId) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00041001, params) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00041002, attestationData) }
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
        LudusTypes.EventDetails storage eventData = events[eventId];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010004,0)}
        require(eventData.status == LudusTypes.EventStatus.Created, "Event not in registration phase");
        require(block.timestamp < eventData.startTime, "Registration period ended");
        require(!isParticipantRegistered[eventId][profileId], "Already registered");
        
        // Check profileId ownership only if it's not zero
        if (profileId > 0) {
            require(ludusIdentity.ownerOf(profileId) == msg.sender, "Not profile owner");
        }
        
        // Handle registration fee payment
        if (msg.value > 0) {
            require(msg.value == eventData.registrationFeeETH, "Incorrect ETH amount");
            eventData.totalPrizePool += msg.value;
            eventPrizes[eventId] += msg.value;
            
            // If event prefers yield generation, forward ETH to YieldManager for staking
            if (eventData.preferYieldGeneration) {
                // Track ETH sent to YieldManager
                _stakeEventETH(eventId, msg.value);
            }
        } else {
            require(eventData.registrationFeeUSDC > 0, "USDC registration fee not set");
            require(
                USDC.transferFrom(msg.sender, address(this), eventData.registrationFeeUSDC),
                "USDC transfer failed"
            );
            eventData.totalPrizePool += eventData.registrationFeeUSDC;uint256 certora_local37 = eventData.totalPrizePool;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000025,certora_local37)}
            eventPrizes[eventId] += eventData.registrationFeeUSDC;
        }
        
        isParticipantRegistered[eventId][profileId] = true;
        
        // Increment participant event count
        participantEventCount[msg.sender] += 1;
        
        emit ParticipantRegistered(eventId, profileId);
    }

    function startEvent(uint256 eventId) external {
        LudusTypes.EventDetails storage eventData = events[eventId];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010005,0)}
        require(eventData.creator == msg.sender, "Only creator can start event");
        require(eventData.status == LudusTypes.EventStatus.Created, "Event not in created state");
        require(block.timestamp >= eventData.startTime, "Start time not reached");
        
        eventData.status = LudusTypes.EventStatus.Started;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00020020,0)}
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
        LudusTypes.Distribution memory dist = eventDistributions[eventId];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010006,0)}
        return (
            dist.athletesShare,
            dist.organizerShare,
            dist.charityShare,
            dist.charityAddress
        );
    }

    function getParticipants(uint256 eventId) external view returns (uint256[] memory) {
        uint256 count = 0;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000007,count)}
        uint256 totalSupply = ludusIdentity.totalSupply();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000008,totalSupply)}
        uint256[] memory participants = new uint256[](totalSupply);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010009,0)}
        
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (isParticipantRegistered[eventId][i]) {
                participants[count] = i;
                count++;
            }
        }
        
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001000a,0)}
        for (uint256 i = 0; i < count; i++) {
            result[i] = participants[i];uint256 certora_local38 = result[i];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000026,certora_local38)}
        }
        
        return result;
    }

    function getParticipantCount(uint256 eventId) external view returns (uint256) {
        uint256 count = 0;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000b,count)}
        uint256 totalSupply = ludusIdentity.totalSupply();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000c,totalSupply)}
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (isParticipantRegistered[eventId][i]) {
                count++;
            }
        }
        return count;
    }

    function getAthleteDistribution(uint256 eventId) external view returns (uint256[] memory positions, uint256[] memory percentages) {
        LudusTypes.AthleteDistribution storage distribution = _athleteDistributions[eventId];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001000d,0)}
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
        uint256 totalAmount,
        LudusTypes.Distribution memory dist,
        address[] memory finalizedAthletes
    ) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00050000, 1037618708485) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00050001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00051000, eventId) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00051001, totalAmount) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00051002, dist) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00051003, finalizedAthletes) }
        require(finalizedAthletes.length > 0, "No athletes provided");
        
        // Get event details to access the organizer address (stored as creator)
        LudusTypes.EventDetails storage eventDetails = events[eventId];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001000e,0)}
        address organizerAddress = eventDetails.creator;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000f,organizerAddress)} // Explicitly get organizer address
        
        // Calculate shares
        uint256 athletesAmount = (totalAmount * dist.athletesShare) / 10000;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000010,athletesAmount)}
        uint256 organizerAmount = (totalAmount * dist.organizerShare) / 10000;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000011,organizerAmount)}
        uint256 charityAmount = (totalAmount * dist.charityShare) / 10000;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000012,charityAmount)}
        uint256 platformFee = (totalAmount * LUDUS_TAX_PERCENTAGE) / 10000;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000013,platformFee)}

        // Get athlete distribution
        LudusTypes.AthleteDistribution storage athleteDist = _athleteDistributions[eventId];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010014,0)}
        require(finalizedAthletes.length <= athleteDist.positions.length, "Too many athletes");

        // Update event prize pool
        eventPrizes[eventId] = totalAmount;

        // Distribute to athletes according to their positions
        for (uint256 i = 0; i < finalizedAthletes.length; i++) {
            // Calculate athlete's share based on their position's percentage
            uint256 athleteShare = (athletesAmount * athleteDist.percentages[i]) / 10000;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000021,athleteShare)}
            jbTerminal.addToBalanceOf(
                0,
                address(USDC),
                athleteShare,
                false,
                "",
                ""
            );
            require(USDC.transfer(finalizedAthletes[i], athleteShare), "Transfer to athlete failed");
        }

        // Distribute organizer share
        if (organizerAmount > 0) {
            jbTerminal.addToBalanceOf(
                0,
                address(USDC),
                organizerAmount,
                false,
                "",
                ""
            );
            // Transfer to the organizer address
            require(USDC.transfer(organizerAddress, organizerAmount), "Transfer to organizer failed");
        }

        // Distribute charity share if applicable
        if (charityAmount > 0 && dist.charityAddress != address(0)) {
            require(USDC.transfer(dist.charityAddress, charityAmount), "USDC transfer to charity failed");
        }

        // Distribute platform fee
        if (platformFee > 0) {
            require(USDC.transfer(ludusWallet, platformFee), "USDC transfer to platform failed");
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
        LudusTypes.Distribution memory dist = eventDistributions[eventId];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010015,0)}
        require(dist.athletesShare > 0, "Distribution not set");

        // Get total amount (including yield if enabled)
        uint256 totalAmount = eventPrizes[eventId];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000016,totalAmount)}

        // Validate athlete distribution
        LudusTypes.AthleteDistribution storage athleteDist = _athleteDistributions[eventId];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010017,0)}
        require(finalizedAthletes.length <= athleteDist.positions.length, "Too many winners");
        require(finalizedAthletes.length > 0, "No winners provided");

        // Calculate and distribute prizes
        _distributeFunds(eventId, totalAmount, dist, finalizedAthletes);
        
        // Update event status
        events[eventId].status = LudusTypes.EventStatus.Completed;
        
        emit EventCompletedWithWinners(
            eventId,
            finalizedAthletes,
            totalAmount,
            (totalAmount * dist.athletesShare) / 10000,
            (totalAmount * dist.organizerShare) / 10000,
            (totalAmount * dist.charityShare) / 10000,
            (totalAmount * LUDUS_TAX_PERCENTAGE) / 10000
        );
    }

    function cancelEvent(uint256 eventId) external nonReentrant {
        LudusTypes.EventDetails storage eventData = events[eventId];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010018,0)}
        
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
                uint256 refundAmount = eventPrizes[eventId] / participantCount;
                
                // Refund each participant
                for (uint256 i = 0; i < participantCount; i++) {
                    address participantAddress = ludusIdentity.ownerOf(participants[i]);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000028,participantAddress)}
                    require(USDC.transfer(participantAddress, refundAmount), "Refund transfer failed");
                }
            }
            
            emit EventCanceled(eventId);
            return;
        }
        
        // Case 2: Automatic cancellation when minimums not met
        require(block.timestamp >= eventData.registrationEndTime, "Registration period not ended");
        require(eventData.status == LudusTypes.EventStatus.Created, "Event not in created state");
        
        // Check if minimum participants requirement is met
        uint256 currentParticipants = this.getParticipantCount(eventId);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000019,currentParticipants)}
        if (currentParticipants < eventData.maxParticipants) {
            eventData.status = LudusTypes.EventStatus.Canceled;
            
            // Get all registered participants for refund
            uint256[] memory participants = this.getParticipants(eventId);
            
            // Calculate refund amount per participant (no platform fee)
            uint256 refundAmount = eventPrizes[eventId] / currentParticipants;
            
            // Refund each participant
            for (uint256 i = 0; i < participants.length; i++) {
                address participantAddress = ludusIdentity.ownerOf(participants[i]);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000027,participantAddress)}
                require(USDC.transfer(participantAddress, refundAmount), "Refund transfer failed");
            }
            
            emit EventCanceled(eventId);
        }
    }

    // Add a public function to check if event should be cancelled due to minimum requirements
    function shouldEventBeCancelled(uint256 eventId) public view returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00090000, 1037618708489) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00090001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00091000, eventId) }
        LudusTypes.EventDetails storage eventData = events[eventId];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001001a,0)}
        if (eventData.status != LudusTypes.EventStatus.Created) return false;
        if (block.timestamp < eventData.registrationEndTime) return false;
        
        uint256 currentParticipants = this.getParticipantCount(eventId);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001b,currentParticipants)}
        return currentParticipants < eventData.maxParticipants;
    }

    // New function to stake ETH with the YieldManager
    function _stakeEventETH(uint256 eventId, uint256 amount) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00060000, 1037618708486) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00060001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00061000, eventId) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00061001, amount) }
        // Forward ETH to YieldManager for staking
        yieldManager.stakeEventFundsETH{value: amount}(eventId);
        
        // Emit event for tracking
        emit ETHStaked(eventId, amount);
    }
    
    // New function to enable yield generation for an event's ETH
    function enableETHYieldGeneration(uint256 eventId) external {
        LudusTypes.EventDetails storage eventData = events[eventId];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001001c,0)}
        require(eventData.creator == msg.sender || msg.sender == owner(), "Not authorized");
        require(eventData.preferYieldGeneration, "Event does not prefer yield generation");
        
        // Call YieldManager to enable yield generation
        yieldManager.enableYieldGeneration(eventId);
        
        emit YieldGenerationEnabled(eventId, true);
    }
    
    // New function to withdraw ETH funds after event is completed
    function withdrawEventETH(uint256 eventId) external {
        LudusTypes.EventDetails storage eventData = events[eventId];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001001d,0)}
        require(eventData.creator == msg.sender || msg.sender == owner(), "Not authorized");
        require(eventData.status == LudusTypes.EventStatus.Completed || 
                eventData.status == LudusTypes.EventStatus.Canceled, "Event must be completed or canceled");
        
        // Withdraw ETH funds from YieldManager
        uint256 withdrawnAmount = yieldManager.withdrawEventFundsETH(eventId);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001e,withdrawnAmount)}
        
        // Update event prizes to include any yield generated
        eventPrizes[eventId] = withdrawnAmount;
        
        emit ETHWithdrawn(eventId, withdrawnAmount);
    }
} 