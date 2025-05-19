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
    ) internal returns (bytes32) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000d0000, 1037618708493) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000d0001, 16) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000d1000, eventId) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000d1001, name) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000d1002, description) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000d1003, eventType) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000d1004, venue) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000d1005, sport) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000d1006, rules) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000d1007, requirements) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000d1008, ticketPrices) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000d1009, ticketTierNames) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000d100a, sponsorshipPrices) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000d100b, sponsorshipTierNames) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000d100c, eventURI) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000d100d, organizer) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000d100e, schemaId) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000d100f, easAddress) }
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
        );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001002f,0)}

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
    ) internal pure returns (bytes memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000e0000, 1037618708494) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000e0001, 13) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000e1000, eventId) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000e1001, name) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000e1002, description) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000e1003, eventType) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000e1004, venue) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000e1005, sport) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000e1006, rules) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000e1007, requirements) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000e1008, ticketPrices) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000e1009, ticketTierNames) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000e100a, sponsorshipPrices) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000e100b, sponsorshipTierNames) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000e100c, eventURI) }
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

    function addressToString(address _addr) internal pure returns(string memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000f0000, 1037618708495) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000f0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000f1000, _addr) }
        bytes32 value = bytes32(uint256(uint160(_addr)));assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000030,value)}
        bytes memory alphabet = "0123456789abcdef";assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010031,0)}
        bytes memory str = new bytes(42);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010032,0)}
        str[0] = "0";bytes1 certora_local51 = str[0];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000033,certora_local51)}
        str[1] = "x";bytes1 certora_local52 = str[1];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000034,certora_local52)}
        for (uint256 i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];bytes1 certora_local53 = str[2+i*2];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000035,certora_local53)}
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];bytes1 certora_local54 = str[3+i*2];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000036,certora_local54)}
        }
        return string(str);
    }
} 