// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ILudusIdentity {
    enum ProfileType { GENERAL, ORGANIZER, ATHLETE }

    function ownerOf(uint256 tokenId) external view returns (address);
    function totalSupply() external view returns (uint256);
    function createProfile(ProfileType profileType, string calldata profileURI, address referrer) external payable returns (uint256);
    function createOrganizerProfile(string calldata name, string calldata description, string calldata organizerURI, bytes calldata attestationData) external payable returns (uint256);
    function createAthleteProfile(string calldata name, string calldata description, string calldata athleteURI, bytes calldata attestationData) external payable returns (uint256);
    function getProfileType(uint256 tokenId) external view returns (ProfileType);
    function getReferralCount(address referrer) external view returns (uint256);
} 