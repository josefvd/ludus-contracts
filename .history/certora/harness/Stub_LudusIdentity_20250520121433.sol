// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ILudusIdentity} from "../../src/interfaces/ILudusIdentity.sol";

contract Stub_LudusIdentity is ILudusIdentity {
    mapping(uint256 => address) private _owners;
    uint256 private _totalSupply;
    address immutable deployer;

    constructor() {
        deployer = msg.sender;
    }

    // ILudusIdentity functions required by LudusEvents
    function ownerOf(uint256 profileId) external view override returns (address) {
        // For simplicity in harness, if an owner is set, return it.
        // Otherwise, could return msg.sender of the LudusEvents call, or a fixed address.
        // For registerParticipant, LudusEvents checks ludusIdentity.ownerOf(profileId) == msg.sender
        // So, making this return the deployer (or a test account) or a value controllable by spec is best.
        // Returning a fixed known address, or the deployer for simplicity in basic harness.
        if (_owners[profileId] != address(0)) {
            return _owners[profileId];
        }
        return deployer; // Default owner for any profileId not explicitly set
                         // This might need to be more sophisticated if rules depend on specific owners.
                         // For initial harness, this simplifies things.
    }

    function totalSupply() external view override returns (uint256) {
        // Return a fixed value or a value that can be set if needed.
        // LudusEvents uses this in getParticipants() and getParticipantCount() loops.
        // A small, fixed number is good for harnessing to keep loops bounded.
        return _totalSupply; // Default to 0 unless set.
    }

    // --- Helper functions for testing/harnessing (callable by test setup) ---
    function mockSetOwner(uint256 profileId, address owner) external {
        // Allow test setup to define ownership for specific profile IDs
        // require(msg.sender == deployer, "Only deployer can mock set owner");
        _owners[profileId] = owner;
        if (profileId > _totalSupply) { // A simple way to track a basic total supply
            _totalSupply = profileId;
        }
    }

    function mockSetTotalSupply(uint256 newTotalSupply) external {
        // require(msg.sender == deployer, "Only deployer can mock set total supply");
        _totalSupply = newTotalSupply;
    }

    // Other ILudusIdentity functions (can be no-op if not used by LudusEvents directly impacting invariants)
    function getProfile(uint256 profileId) external view override returns (address, string memory, uint8, uint256[] memory, uint256[] memory) {
        return (address(0), "", 0, new uint256[](0), new uint256[](0));
    }

    function getAchievements(uint256 profileId) external view override returns (uint256[] memory) {
        return new uint256[](0);
    }

    function createProfile(string calldata username, uint8 avatarId) external override returns (uint256) {
        _totalSupply++;
        _owners[_totalSupply] = msg.sender; // Simple minting logic for harness
        return _totalSupply;
    }

    function updateProfile(uint256 profileId, string calldata newUsername, uint8 newAvatarId) external override {
        // No-op
    }

    function addAchievement(uint256 profileId, uint256 achievementId) external override {
        // No-op
    }

    function removeAchievement(uint256 profileId, uint256 achievementId) external override {
        // No-op
    }

    function recordWin(uint256 profileId, uint256 eventId) external override {
        // No-op
    }
} 