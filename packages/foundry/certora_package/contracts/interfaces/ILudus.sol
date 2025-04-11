// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../LudusIdentity.sol";

interface ILudusIdentity {
    function ownerOf(uint256 tokenId) external view returns (address);
    function getProfile(uint256 tokenId) external view returns (uint256 totalTournaments, uint256 wins);
    function mint(address to) external returns (uint256);
}

interface ILudusEvents {
    function getParticipantScore(uint256 eventId, uint256 profileId) external view returns (uint256);
    function isParticipant(uint256 eventId, uint256 profileId) external view returns (bool);
}

interface IAchievementGauntletTerminal {
    function getAchievements(uint256 profileId) external view returns (bytes32[] memory);
    function hasAchievement(uint256 profileId, bytes32 achievementId) external view returns (bool);
} 