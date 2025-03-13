// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// OpenZeppelin Imports
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Juicebox V4 Interfaces
import "@juicebox/interfaces/IJBTerminal.sol";

// EAS Contracts
import {IEAS, Attestation, AttestationRequest} from "@eas/IEAS.sol";
import {ISchemaRegistry} from "@eas/ISchemaRegistry.sol";
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
        address _yieldManager
    ) {
        if (_ludusIdentity == address(0) || _eas == address(0) || 
            _schemaRegistry == address(0) || _jbTerminal == address(0) || 
            _yieldManager == address(0)) revert InvalidAddress();

        ludusIdentity = ILudusIdentity(_ludusIdentity);
        eas = IEAS(_eas);
        schemaRegistry = ISchemaRegistry(_schemaRegistry);
        jbTerminal = IJBTerminal(_jbTerminal);
        yieldManager = IYieldManager(_yieldManager);
        USDC = IERC20(yieldManager.usdc());
        ludusWallet = 0x44A59082F113C75EaefbD3Fe57447C00dEb41874;
        _transferOwnership(0x86254789bB435A99e3cc261d5544A3426C987750);
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

    function createEvent(
        // Core event parameters (stored on-chain)
        uint256 startTime,
        uint256 endTime,
        uint256 registrationStartTime,
        uint256 registrationEndTime,
        uint256 maxParticipants,
        uint256 registrationFeeUSDC,
        uint256 registrationFeeETH,
        address refereeAddress,
        address organizerAddress,
        
        // Treasury distribution parameters
        uint256 athletesShare,
        uint256 organizerShare,
        uint256 charityShare,
        address charityAddress,
        
        // Athlete distribution parameters
        uint256[] memory positions,
        uint256[] memory percentages,
        
        // Yield generation preference
        bool preferYieldGeneration,
        
        // Attestation data (stored on-chain via EAS attestations)
        LudusTypes.EventAttestationData memory attestationData
    ) external returns (uint256) {
        require(startTime > block.timestamp, "Invalid start time");
        require(endTime > startTime, "End time must be after start time");
        require(registrationStartTime < registrationEndTime, "Invalid registration period");
        require(registrationEndTime <= startTime, "Registration must end before event starts");
        require(registrationStartTime >= block.timestamp, "Registration start time must be in the future");
        require(maxParticipants > 0, "Max participants must be greater than 0");
        require(registrationFeeUSDC > 0 || registrationFeeETH > 0, "Registration fee must be set");
        require(positions.length == percentages.length, "Invalid distribution arrays");
        require(positions.length > 0, "Must have at least one position");
        require(athletesShare + organizerShare + charityShare <= 9700, "Total share exceeds 97% (3% Ludus tax)");
        require(refereeAddress != address(0), "Invalid referee address");
        require(organizerAddress != address(0), "Invalid organizer address");
        
        // Validate athlete distribution percentages sum to 100%
        uint256 totalPercentage;
        for (uint256 i = 0; i < percentages.length; i++) {
            totalPercentage += percentages[i];
        }
        require(totalPercentage == 10000, "Athlete percentages must sum to 100%");
        
        // Validate ticket and sponsorship prices
        require(attestationData.ticketPrices.length == attestationData.ticketTierNames.length, "Invalid ticket tiers");
        require(attestationData.sponsorshipPrices.length == attestationData.sponsorshipTierNames.length, "Invalid sponsorship tiers");
        
        eventCount++;

        // Calculate total prize pool
        uint256 totalPrizePool = registrationFeeUSDC * maxParticipants;
        if (registrationFeeETH > 0) {
            // Assume all participants will pay with ETH if ETH fee is set
            totalPrizePool += registrationFeeETH * maxParticipants;
        }
        
        for (uint256 i = 0; i < attestationData.ticketPrices.length; i++) {
            totalPrizePool += attestationData.ticketPrices[i];
        }
        for (uint256 i = 0; i < attestationData.sponsorshipPrices.length; i++) {
            totalPrizePool += attestationData.sponsorshipPrices[i];
        }
        
        // Store minimal event details in contract storage
        events[eventCount] = LudusTypes.EventDetails({
            id: eventCount,
            startTime: startTime,
            endTime: endTime,
            registrationStartTime: registrationStartTime,
            registrationEndTime: registrationEndTime,
            maxParticipants: maxParticipants,
            creator: organizerAddress,
            referee: refereeAddress,
            status: LudusTypes.EventStatus.Created,
            registrationFeeETH: registrationFeeETH,
            registrationFeeUSDC: registrationFeeUSDC,
            totalPrizePool: totalPrizePool,
            preferYieldGeneration: preferYieldGeneration
        });
        
        // Store distribution parameters in contract storage
        eventDistributions[eventCount] = LudusTypes.Distribution({
            athletesShare: athletesShare,
            organizerShare: organizerShare,
            charityShare: charityShare,
            charityAddress: charityAddress
        });
        
        // Store athlete distribution in contract storage
        _athleteDistributions[eventCount] = LudusTypes.AthleteDistribution({
            positions: positions,
            percentages: percentages
        });
        
        // Update YieldManager distribution
        if (block.chainid != 31337) {
            yieldManager.setDistribution(
                eventCount,
                athletesShare,
                organizerShare,
                charityShare,
                charityAddress
            );
            
            // Create attestation in production mode
            attestationData.eventId = eventCount;
            bytes32 attestationUid = LudusAttestations.createEventAttestation(
                eventCount,
                attestationData.name,
                attestationData.description,
                attestationData.eventType,
                attestationData.venue,
                attestationData.sport,
                attestationData.rules,
                attestationData.requirements,
                attestationData.ticketPrices,
                attestationData.ticketTierNames,
                attestationData.sponsorshipPrices,
                attestationData.sponsorshipTierNames,
                attestationData.eventURI,
                msg.sender,
                eventSchemaId,
                address(eas)
            );
            
            require(attestationUid != bytes32(0), "Attestation creation failed");
            
            // Verify the attestation with EAS
            try eas.getAttestation(attestationUid) returns (Attestation memory attestation) {
                require(attestation.schema == eventSchemaId, "Invalid schema for attestation");
                require(attestation.attester == address(this), "Invalid attester");
            } catch {
                revert("Failed to verify attestation with EAS");
            }
        } else {
            // In test mode, skip attestation creation but still update YieldManager
            yieldManager.setDistribution(
                eventCount,
                athletesShare,
                organizerShare,
                charityShare,
                charityAddress
            );
        }
        
        emit EventCreated(eventCount, attestationData.name, startTime, endTime);
        emit DistributionSet(eventCount, athletesShare, organizerShare, charityShare, charityAddress);
        
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
            eventData.totalPrizePool += eventData.registrationFeeUSDC;
            eventPrizes[eventId] += eventData.registrationFeeUSDC;
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

    function attest(Attestation calldata attestation) external payable override returns (bool) {
        require(!processedAttestations[attestation.uid], "Attestation already processed");
        require(msg.sender == address(eas), "Only EAS can call attest");
        
        if (attestation.schema == resultSchemaId) {
            LudusTypes.ResultAttestationData memory resultData = abi.decode(attestation.data, (LudusTypes.ResultAttestationData));
            require(events[resultData.eventId].status == LudusTypes.EventStatus.Started, "Event not started");
            require(block.timestamp >= events[resultData.eventId].endTime, "Event not ended");
            
            // Verify the attestation is from the registered referee
            require(attestation.attester == events[resultData.eventId].referee, "Only registered referee can attest results");
            
            // Get distribution settings
            LudusTypes.Distribution memory dist = eventDistributions[resultData.eventId];
            require(dist.athletesShare > 0, "Distribution not set");

            // Get total amount (including yield if enabled)
            uint256 totalAmount = eventPrizes[resultData.eventId];

            // Get finalized athletes from attestation data
            address[] memory finalizedAthletes = new address[](resultData.winnerIds.length);
            for (uint256 i = 0; i < resultData.winnerIds.length; i++) {
                // Get the athlete's address from their profile ID
                finalizedAthletes[i] = ludusIdentity.ownerOf(resultData.winnerIds[i]);
                // Verify the athlete was registered for the event
                require(isParticipantRegistered[resultData.eventId][resultData.winnerIds[i]], 
                    "Winner not registered for event");
            }

            // Calculate shares
            uint256 athletesAmount = (totalAmount * dist.athletesShare) / 10000;
            uint256 organizerAmount = (totalAmount * dist.organizerShare) / 10000;
            uint256 charityAmount = (totalAmount * dist.charityShare) / 10000;
            uint256 platformFee = (totalAmount * LUDUS_TAX_PERCENTAGE) / 10000;

            // Get athlete distribution
            LudusTypes.AthleteDistribution storage athleteDist = _athleteDistributions[resultData.eventId];
            require(finalizedAthletes.length <= athleteDist.positions.length, "Too many winners");

            // Distribute to athletes through JBTerminal
            for (uint256 i = 0; i < finalizedAthletes.length; i++) {
                uint256 athleteShare = (athletesAmount * athleteDist.percentages[i]) / 10000;
                jbTerminal.addToBalanceOf(
                    0,               // projectId (using 0 for mock)
                    address(USDC),   // address of the USDC token
                    athleteShare,    // amount to add
                    false,           // shouldReturnHeldFees set to false
                    "",            // memo
                    ""             // metadata
                );
                require(USDC.transfer(finalizedAthletes[i], athleteShare), "Transfer to athlete failed");
            }

            // Distribute remaining shares through JBTerminal for organizer
            if (organizerAmount > 0) {
                jbTerminal.addToBalanceOf(
                    0,               // projectId (using 0 for mock)
                    address(USDC),   // address of the USDC token
                    organizerAmount, // amount to add
                    false,           // shouldReturnHeldFees set to false
                    "",            // memo
                    ""             // metadata
                );
                require(USDC.transfer(events[resultData.eventId].creator, organizerAmount), "Transfer to organizer failed");
            }

            if (charityAmount > 0 && dist.charityAddress != address(0)) {
                jbTerminal.addToBalanceOf(
                    0,
                    address(USDC),
                    charityAmount,
                    false,
                    "",
                    ""
                );
                require(USDC.transfer(dist.charityAddress, charityAmount), "Transfer to charity failed");
            }

            if (platformFee > 0) {
                jbTerminal.addToBalanceOf(
                    0,
                    address(USDC),
                    platformFee,
                    false,
                    "",
                    ""
                );
                require(USDC.transfer(ludusWallet, platformFee), "Transfer to platform failed");
            }

            // Update event status
            events[resultData.eventId].status = LudusTypes.EventStatus.Completed;
            processedAttestations[attestation.uid] = true;

            emit EventCompletedWithWinners(
                resultData.eventId,
                finalizedAthletes,
                totalAmount,
                athletesAmount,
                organizerAmount,
                charityAmount,
                platformFee
            );
            return true;
        } else if (attestation.schema == eventSchemaId) {
            LudusTypes.EventAttestationData memory eventData = abi.decode(attestation.data, (LudusTypes.EventAttestationData));
            require(events[eventData.eventId].creator == attestation.recipient, "Invalid event creator");
            processedAttestations[attestation.uid] = true;
            return true;
        }
        return false;
    }

    function multiAttest(Attestation[] calldata attestations, uint256[] calldata) external payable override returns (bool) {
        require(attestations.length == 1, "Only single attestation supported");
        return this.attest(attestations[0]);
    }

    function revoke(Attestation calldata) external payable override returns (bool) {
        revert("Revocation not supported");
    }

    function multiRevoke(Attestation[] calldata, uint256[] calldata) external payable override returns (bool) {
        revert("Revocation not supported");
    }

    function version() external pure virtual returns (string memory) {
        return "1.0.0";
    }

    function _distributeFunds(
        uint256 eventId,
        uint256 totalAmount,
        LudusTypes.Distribution memory dist,
        address[] memory finalizedAthletes
    ) internal {
        require(finalizedAthletes.length > 0, "No athletes provided");
        
        // Get event details to access the organizer address (stored as creator)
        LudusTypes.EventDetails storage eventDetails = events[eventId];
        address organizerAddress = eventDetails.creator; // Explicitly get organizer address
        
        // Calculate shares
        uint256 athletesAmount = (totalAmount * dist.athletesShare) / 10000;
        uint256 organizerAmount = (totalAmount * dist.organizerShare) / 10000;
        uint256 charityAmount = (totalAmount * dist.charityShare) / 10000;
        uint256 platformFee = (totalAmount * LUDUS_TAX_PERCENTAGE) / 10000;

        // Get athlete distribution
        LudusTypes.AthleteDistribution storage athleteDist = _athleteDistributions[eventId];
        require(finalizedAthletes.length <= athleteDist.positions.length, "Too many athletes");

        // Update event prize pool
        eventPrizes[eventId] = totalAmount;

        // Distribute to athletes according to their positions
        for (uint256 i = 0; i < finalizedAthletes.length; i++) {
            // Calculate athlete's share based on their position's percentage
            uint256 athleteShare = (athletesAmount * athleteDist.percentages[i]) / 10000;
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
        LudusTypes.Distribution memory dist = eventDistributions[eventId];
        require(dist.athletesShare > 0, "Distribution not set");

        // Get total amount (including yield if enabled)
        uint256 totalAmount = eventPrizes[eventId];

        // Validate athlete distribution
        LudusTypes.AthleteDistribution storage athleteDist = _athleteDistributions[eventId];
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
                uint256 refundAmount = eventPrizes[eventId] / participantCount;
                
                // Refund each participant
                for (uint256 i = 0; i < participantCount; i++) {
                    address participantAddress = ludusIdentity.ownerOf(participants[i]);
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
        uint256 currentParticipants = this.getParticipantCount(eventId);
        if (currentParticipants < eventData.maxParticipants) {
            eventData.status = LudusTypes.EventStatus.Canceled;
            
            // Get all registered participants for refund
            uint256[] memory participants = this.getParticipants(eventId);
            
            // Calculate refund amount per participant (no platform fee)
            uint256 refundAmount = eventPrizes[eventId] / currentParticipants;
            
            // Refund each participant
            for (uint256 i = 0; i < participants.length; i++) {
                address participantAddress = ludusIdentity.ownerOf(participants[i]);
                require(USDC.transfer(participantAddress, refundAmount), "Refund transfer failed");
            }
            
            emit EventCanceled(eventId);
        }
    }

    // Add a public function to check if event should be cancelled due to minimum requirements
    function shouldEventBeCancelled(uint256 eventId) public view returns (bool) {
        LudusTypes.EventDetails storage eventData = events[eventId];
        if (eventData.status != LudusTypes.EventStatus.Created) return false;
        if (block.timestamp < eventData.registrationEndTime) return false;
        
        uint256 currentParticipants = this.getParticipantCount(eventId);
        return currentParticipants < eventData.maxParticipants;
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
        eventPrizes[eventId] = withdrawnAmount;
        
        emit ETHWithdrawn(eventId, withdrawnAmount);
    }
}

contract LudusEventsImpl is LudusEvents {
    constructor(
        address _ludusIdentity,
        address _eas,
        address _schemaRegistry,
        address _jbTerminal,
        address _yieldManager
    ) LudusEvents(
        _ludusIdentity,
        _eas,
        _schemaRegistry,
        _jbTerminal,
        _yieldManager
    ) {}

    function attest(AttestationRequest calldata request) external returns (bool) {
        require(msg.sender == address(eas), "Only EAS can call");
        
        if (request.schema == eventSchemaId) {
            // Event attestation
            LudusTypes.EventAttestationData memory eventData = abi.decode(
                request.data.data,
                (LudusTypes.EventAttestationData)
            );
            require(events[eventData.eventId].id == eventData.eventId, "Event does not exist");
            return true;
        } else if (request.schema == resultSchemaId) {
            // Result attestation
            LudusTypes.ResultAttestationData memory resultData = abi.decode(
                request.data.data,
                (LudusTypes.ResultAttestationData)
            );
            require(events[resultData.eventId].id == resultData.eventId, "Event does not exist");
            require(events[resultData.eventId].status == LudusTypes.EventStatus.Started, "Event not started");
            require(block.timestamp >= events[resultData.eventId].endTime, "Event not ended");
            
            // Get distribution settings
            LudusTypes.Distribution memory dist = eventDistributions[resultData.eventId];
            require(dist.athletesShare > 0, "Distribution not set");

            // Get total amount (including yield if enabled)
            uint256 totalAmount = eventPrizes[resultData.eventId];

            // Process winners and distribute funds
            address[] memory finalizedAthletes = new address[](resultData.winnerIds.length);
            for (uint256 i = 0; i < resultData.winnerIds.length; i++) {
                finalizedAthletes[i] = ludusIdentity.ownerOf(resultData.winnerIds[i]);
            }

            _distributeFunds(resultData.eventId, totalAmount, dist, finalizedAthletes);
            events[resultData.eventId].status = LudusTypes.EventStatus.Completed;
            emit EventCompletedWithWinners(
                resultData.eventId,
                finalizedAthletes,
                totalAmount,
                (totalAmount * dist.athletesShare) / 10000,
                (totalAmount * dist.organizerShare) / 10000,
                (totalAmount * dist.charityShare) / 10000,
                (totalAmount * LUDUS_TAX_PERCENTAGE) / 10000
            );
            return true;
        }
        return false;
    }
} 