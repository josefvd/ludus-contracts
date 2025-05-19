// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/AggregatorV3Interface.sol";

contract LudusIdentity is ERC721URIStorage, Ownable {
    // State variables
    uint256 private _nextTokenId;
    address public yieldManager;
    address public immutable EAS;
    address public immutable SCHEMA_REGISTRY;
    address public immutable JB_TERMINAL;
    address public immutable USDC_TOKEN;
    address public immutable CHAINLINK_ETH_USD_FEED;
    uint256 public MINT_PRICE_USD = 10; // $10 USD
    address public constant LUDUS_WALLET = 0x44A59082F113C75EaefbD3Fe57447C00dEb41874;  // Add Ludus wallet

    // Profile types and ranks
    enum ProfileType { GENERAL, SPORTS, ESPORTS }
    enum Rank { ROOKIE, AMATEUR, PRO, ELITE }
    enum AchievementType { Victory, FirstEvent, TopRank, SeasonPass }

    struct Profile {
        ProfileType profileType;
        uint256 totalTournaments;
        uint256 wins;
        Rank currentRank;
        string metadataURI;
        bool isMinted;
        uint256 points;           // Achievement points
        uint256 seasonPassExpiry; // Timestamp when season pass expires
    }

    // Mappings
    mapping(uint256 => Profile) public profiles;
    mapping(uint256 => mapping(AchievementType => bool)) public achievements; // Track unlocked achievements per profile
    mapping(address => uint256[]) public userProfiles;
    mapping(address => address) public referrers;
    mapping(uint256 => mapping(uint256 => bool)) public hasEnteredTournament; // profileId => tournamentId => hasEntered

    // Events
    event ProfileCreated(uint256 indexed tokenId, address indexed owner, ProfileType profileType);
    event ProfileUpdated(uint256 indexed tokenId, string newMetadataURI);
    event RankUpdated(uint256 indexed tokenId, Rank newRank);
    event ReferralRegistered(address indexed referrer, address indexed player);
    event PointsAwarded(uint256 indexed profileId, uint256 points, string reason);
    event SeasonPassGranted(uint256 indexed profileId, uint256 expiryTime);
    event TournamentEntryRecorded(uint256 indexed profileId, uint256 indexed tournamentId);
    event AchievementUnlocked(uint256 indexed profileId, AchievementType achievementType);

    constructor(
        address _eas,
        address _schemaRegistry,
        address _jbTerminal,
        address _yieldManager,
        address _usdcToken,
        address _chainlinkEthUsdFeed
    ) ERC721("Ludus Identity", "LUDUS") {
        EAS = _eas;
        SCHEMA_REGISTRY = _schemaRegistry;
        JB_TERMINAL = _jbTerminal;
        yieldManager = _yieldManager;
        USDC_TOKEN = _usdcToken;
        CHAINLINK_ETH_USD_FEED = _chainlinkEthUsdFeed;
    }

    function setYieldManager(address _yieldManager) external onlyOwner {
        yieldManager = _yieldManager;
    }

    function getMintPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(CHAINLINK_ETH_USD_FEED);
        (, int256 price,,,) = priceFeed.latestRoundData();
        uint256 ethUsdPrice = uint256(price) / 1e8; // Chainlink price has 8 decimals
        return (MINT_PRICE_USD * 1e18) / ethUsdPrice;
    }

    function getUSDCPrice() public view returns (uint256) {
        return MINT_PRICE_USD * 1e6;
    }

    function createProfile(
        ProfileType _profileType, 
        string memory _metadataURI,
        address referrer
    ) external payable returns (uint256) {
        require(userProfiles[msg.sender].length == 0, "Already has a profile");
        
        uint256 ethPrice = getMintPrice();
        
        if (msg.value > 0) {
            require(msg.value >= ethPrice, "Insufficient ETH");
            payable(LUDUS_WALLET).transfer(msg.value);  // Send ETH directly to Ludus wallet
        } else {
            require(
                IERC20(USDC_TOKEN).transferFrom(msg.sender, LUDUS_WALLET, MINT_PRICE_USD * 1e6),
                "USDC transfer failed"
            );  // Send USDC directly to Ludus wallet
        }

        if (referrer != address(0) && referrer != msg.sender) {
            referrers[msg.sender] = referrer;
            emit ReferralRegistered(referrer, msg.sender);
        }

        _nextTokenId++;
        uint256 newTokenId = _nextTokenId;

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _metadataURI);

        profiles[newTokenId] = Profile({
            profileType: _profileType,
            totalTournaments: 0,
            wins: 0,
            currentRank: Rank.ROOKIE,
            metadataURI: _metadataURI,
            isMinted: true,
            points: 0,
            seasonPassExpiry: 0
        });

        userProfiles[msg.sender].push(newTokenId);
        emit ProfileCreated(newTokenId, msg.sender, _profileType);
        return newTokenId;
    }

    function updateProfile(
        uint256 tokenId, 
        uint256 _totalTournaments, 
        uint256 _wins
    ) external {
        require(_exists(tokenId), "Profile does not exist");
        require(msg.sender == owner(), "Only owner can update profile");

        Profile storage profile = profiles[tokenId];
        profile.totalTournaments = _totalTournaments;
        profile.wins = _wins;

        _updateRank(tokenId);
    }

    function _updateRank(uint256 tokenId) internal {
        Profile storage profile = profiles[tokenId];
        Rank newRank;
        
        if (profile.wins >= 20) {
            newRank = Rank.ELITE;
        } else if (profile.wins >= 10) {
            newRank = Rank.PRO;
        } else if (profile.wins >= 5) {
            newRank = Rank.AMATEUR;
        } else {
            newRank = Rank.ROOKIE;
        }

        if (profile.currentRank != newRank) {
            profile.currentRank = newRank;
            emit RankUpdated(tokenId, newRank);
        }
    }

    function getProfile(uint256 tokenId) external view returns (Profile memory) {
        require(_exists(tokenId), "Profile does not exist");
        return profiles[tokenId];
    }

    function getUserProfiles(address user) external view returns (uint256[] memory) {
        return userProfiles[user];
    }

    // Override required functions
    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // New functions for tournament entry and points
    function addPoints(uint256 profileId, uint256 amount, string memory reason) external {
        require(msg.sender == owner() || msg.sender == yieldManager, "Not authorized");
        require(_exists(profileId), "Profile does not exist");
        
        profiles[profileId].points += amount;
        emit PointsAwarded(profileId, amount, reason);
    }

    function grantSeasonPass(uint256 profileId, uint256 durationInDays) external {
        require(msg.sender == owner() || msg.sender == yieldManager, "Not authorized");
        require(_exists(profileId), "Profile does not exist");
        
        uint256 expiryTime = block.timestamp + (durationInDays * 1 days);
        profiles[profileId].seasonPassExpiry = expiryTime;
        emit SeasonPassGranted(profileId, expiryTime);
    }

    function hasValidSeasonPass(uint256 profileId) public view returns (bool) {
        require(_exists(profileId), "Profile does not exist");
        return profiles[profileId].seasonPassExpiry > block.timestamp;
    }

    function canEnterTournament(uint256 profileId, uint256 tournamentId, uint256 requiredWins) public view returns (bool) {
        require(_exists(profileId), "Profile does not exist");
        if (hasEnteredTournament[profileId][tournamentId]) return false;
        
        Profile memory profile = profiles[profileId];
        return profile.wins >= requiredWins || hasValidSeasonPass(profileId);
    }

    function recordTournamentEntry(uint256 profileId, uint256 tournamentId) external {
        require(msg.sender == owner() || msg.sender == yieldManager, "Not authorized");
        require(_exists(profileId), "Profile does not exist");
        require(!hasEnteredTournament[profileId][tournamentId], "Already entered");
        
        hasEnteredTournament[profileId][tournamentId] = true;
        emit TournamentEntryRecorded(profileId, tournamentId);
    }

    function unlockAchievement(uint256 profileId, AchievementType achievementType) external {
        require(msg.sender == owner() || msg.sender == yieldManager, "Not authorized");
        require(_exists(profileId), "Profile does not exist");
        
        require(!achievements[profileId][achievementType], "Achievement already unlocked");
        
        achievements[profileId][achievementType] = true;
        
        // Award points based on achievement type
        uint256 points;
        if (achievementType == AchievementType.Victory) {
            points = 100;
        } else if (achievementType == AchievementType.FirstEvent) {
            points = 50;
        } else if (achievementType == AchievementType.TopRank) {
            points = 200;
        } else if (achievementType == AchievementType.SeasonPass) {
            points = 150;
        }
        
        profiles[profileId].points += points;
        emit AchievementUnlocked(profileId, achievementType);
        emit PointsAwarded(profileId, points, "Achievement unlocked");
    }

    function hasAchievement(uint256 profileId, AchievementType achievementType) external view returns (bool) {
        require(_exists(profileId), "Profile does not exist");
        return achievements[profileId][achievementType];
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        MINT_PRICE_USD = newPrice;
    }
} 