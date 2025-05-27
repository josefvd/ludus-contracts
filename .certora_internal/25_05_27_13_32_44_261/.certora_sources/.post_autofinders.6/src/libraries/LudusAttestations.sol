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
    ) internal returns (bytes32) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00280000, 1037618708520) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00280001, 16) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00281000, eventId) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00281001, name) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00281002, description) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00281003, eventType) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00281004, venue) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00281005, sport) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00281006, rules) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00281007, requirements) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00281008, ticketPrices) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00281009, ticketTierNames) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff0028100a, sponsorshipPrices) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff0028100b, sponsorshipTierNames) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff0028100c, eventURI) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff0028100d, organizer) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff0028100e, schemaId) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff0028100f, easAddress) }
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
        );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010001,0)}

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
    ) internal pure returns (bytes memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00290000, 1037618708521) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00290001, 13) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00291000, eventId) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00291001, name) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00291002, description) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00291003, eventType) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00291004, venue) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00291005, sport) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00291006, rules) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00291007, requirements) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00291008, ticketPrices) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00291009, ticketTierNames) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff0029100a, sponsorshipPrices) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff0029100b, sponsorshipTierNames) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff0029100c, eventURI) }
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

    function addressToString(address _addr) internal pure returns(string memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff002a0000, 1037618708522) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff002a0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff002a1000, _addr) }
        bytes32 value = bytes32(uint256(uint160(_addr)));assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000002,value)}
        bytes memory alphabet = "0123456789abcdef";assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010003,0)}
        bytes memory str = new bytes(42);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010004,0)}
        str[0] = "0";bytes1 certora_local5 = str[0];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000005,certora_local5)}
        str[1] = "x";bytes1 certora_local6 = str[1];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000006,certora_local6)}
        for (uint256 i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];bytes1 certora_local7 = str[2+i*2];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000007,certora_local7)}
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];bytes1 certora_local8 = str[3+i*2];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000008,certora_local8)}
        }
        return string(str);
    }
} 