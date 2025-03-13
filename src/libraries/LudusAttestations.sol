// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IEAS, Attestation, AttestationRequest, AttestationRequestData} from "@eas/IEAS.sol";
import "./LudusTypes.sol";

library LudusAttestations {
    function createEventAttestation(
        uint256 eventId,
        string memory name,
        string memory description,
        string memory eventType,
        string memory venue,
        string memory sport,
        string[] memory rules,
        string[] memory requirements,
        uint256[] memory ticketPrices,
        string[] memory ticketTierNames,
        uint256[] memory sponsorshipPrices,
        string[] memory sponsorshipTierNames,
        string memory eventURI,
        address organizer,
        bytes32 schemaId,
        address easAddress
    ) internal returns (bytes32) {
        bytes memory encodedData = encodeEventData(
            eventId,
            name,
            description,
            eventType,
            venue,
            sport,
            rules,
            requirements,
            ticketPrices,
            ticketTierNames,
            sponsorshipPrices,
            sponsorshipTierNames,
            eventURI
        );

        return IEAS(easAddress).attest(AttestationRequest({
            schema: schemaId,
            data: AttestationRequestData({
                recipient: organizer,
                expirationTime: 0,
                revocable: true,
                refUID: bytes32(0),
                data: encodedData,
                value: 0
            })
        }));
    }

    function encodeEventData(
        uint256 eventId,
        string memory name,
        string memory description,
        string memory eventType,
        string memory venue,
        string memory sport,
        string[] memory rules,
        string[] memory requirements,
        uint256[] memory ticketPrices,
        string[] memory ticketTierNames,
        uint256[] memory sponsorshipPrices,
        string[] memory sponsorshipTierNames,
        string memory eventURI
    ) internal pure returns (bytes memory) {
        return abi.encode(
            LudusTypes.EventAttestationData({
                eventId: eventId,
                name: name,
                description: description,
                eventType: eventType,
                venue: venue,
                sport: sport,
                rules: rules,
                requirements: requirements,
                ticketPrices: ticketPrices,
                ticketTierNames: ticketTierNames,
                sponsorshipPrices: sponsorshipPrices,
                sponsorshipTierNames: sponsorshipTierNames,
                eventURI: eventURI
            })
        );
    }

    function addressToString(address _addr) internal pure returns(string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
} 