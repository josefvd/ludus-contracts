// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../src/interfaces/ILudusIdentity.sol";

contract Stub_LudusIdentity is ILudusIdentity {
    enum ProfileType { GENERAL, ORGANIZER, ATHLETE }

    mapping(uint256 => address) private _owners;
    mapping(uint256 => ProfileType) private _profileTypes;
    mapping(address => uint256) private _referralCounts;
    uint256 private _totalSupply;
    address immutable deployer;

    constructor() {
        deployer = msg.sender;
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        if (_owners[tokenId] != address(0)) {
            return _owners[tokenId];
        }
        return deployer;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function createProfile(ProfileType profileType, string calldata, address referrer) external payable returns (uint256) {
        _totalSupply++;
        _owners[_totalSupply] = msg.sender;
        _profileTypes[_totalSupply] = profileType;
        if (referrer != address(0)) {
            _referralCounts[referrer]++;
        }
        return _totalSupply;
    }

    function createOrganizerProfile(string calldata, string calldata, string calldata, bytes calldata) external payable returns (uint256) {
        _totalSupply++;
        _owners[_totalSupply] = msg.sender;
        _profileTypes[_totalSupply] = ProfileType.ORGANIZER;
        return _totalSupply;
    }

    function createAthleteProfile(string calldata, string calldata, string calldata, bytes calldata) external payable returns (uint256) {
        _totalSupply++;
        _owners[_totalSupply] = msg.sender;
        _profileTypes[_totalSupply] = ProfileType.ATHLETE;
        return _totalSupply;
    }

    function getProfileType(uint256 tokenId) external view returns (ProfileType) {
        return _profileTypes[tokenId];
    }

    function getReferralCount(address referrer) external view returns (uint256) {
        return _referralCounts[referrer];
    }

    // --- Helper functions for testing/harnessing (callable by test setup) ---
    function mockSetOwner(uint256 tokenId, address owner) public {
        _owners[tokenId] = owner;
        if (tokenId > _totalSupply) {
            _totalSupply = tokenId;
        }
    }

    function mockSetTotalSupply(uint256 newTotalSupply) public {
        _totalSupply = newTotalSupply;
    }

    function mockSetProfileType(uint256 tokenId, ProfileType profileType) public {
        _profileTypes[tokenId] = profileType;
    }

    function mockSetReferralCount(address referrer, uint256 count) public {
        _referralCounts[referrer] = count;
    }

    // The following are stub implementations for interface completeness
    function getProfile(uint256) public view returns (address, string memory, uint8, uint256[] memory, uint256[] memory) {
        return (address(0), "", 0, new uint256[](0), new uint256[](0));
    }

    function getAchievements(uint256) public view returns (uint256[] memory) {
        return new uint256[](0);
    }

    function updateProfile(uint256, string calldata, uint8) public {}
    function addAchievement(uint256, uint256) public {}
    function removeAchievement(uint256, uint256) public {}
    function recordWin(uint256, uint256) public {}
} 