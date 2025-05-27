// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../src/interfaces/ILudusIdentity.sol";

contract Stub_LudusIdentity is ILudusIdentity {
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
    function mockSetOwner(uint256 tokenId, address owner) public {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000b0000, 1037618708491) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000b0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000b1000, tokenId) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000b1001, owner) }
        _owners[tokenId] = owner;
        if (tokenId > _totalSupply) {
            _totalSupply = tokenId;
        }
    }

    function mockSetTotalSupply(uint256 newTotalSupply) public {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00040000, 1037618708484) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00040001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00041000, newTotalSupply) }
        _totalSupply = newTotalSupply;
    }

    function mockSetProfileType(uint256 tokenId, ProfileType profileType) public {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00060000, 1037618708486) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00060001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00061000, tokenId) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00061001, profileType) }
        _profileTypes[tokenId] = profileType;
    }

    function mockSetReferralCount(address referrer, uint256 count) public {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00070000, 1037618708487) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00070001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00071000, referrer) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00071001, count) }
        _referralCounts[referrer] = count;
    }

    // The following are stub implementations for interface completeness
    function getProfile(uint256) public view returns (address, string memory, uint8, uint256[] memory, uint256[] memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00020000, 1037618708482) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00020001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00025000, 0) }
        return (address(0), "", 0, new uint256[](0), new uint256[](0));
    }

    function getAchievements(uint256) public view returns (uint256[] memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000a0000, 1037618708490) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000a0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000a5000, 0) }
        return new uint256[](0);
    }

    function updateProfile(uint256, string calldata, uint8) public {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00030000, 1037618708483) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00030001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00035000, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00034001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00035002, 0) }}
    function addAchievement(uint256, uint256) public {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00080000, 1037618708488) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00080001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00085000, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00085001, 0) }}
    function removeAchievement(uint256, uint256) public {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00090000, 1037618708489) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00090001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00095000, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00095001, 0) }}
    function recordWin(uint256, uint256) public {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00050000, 1037618708485) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00050001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00055000, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00055001, 0) }}
} 