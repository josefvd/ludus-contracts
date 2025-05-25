// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ISchemaRegistry} from "@eas/ISchemaRegistry.sol"; // Assuming ISchemaRegistry.sol is available

contract Stub_SchemaRegistry is ISchemaRegistry {
    // No specific state or complex logic needed if LudusEvents only uses its address.

    constructor() {
        // Initialization if any specific setup needed
    }

    // ISchemaRegistry functions (implement as no-op or with minimal logic if called)
    function registerSchema(
        string calldata schemaName,
        string calldata schema,
        address resolver,
        bool revocable
    ) external override returns (bytes32) {
        // Not directly called by LudusEvents logic being verified for these invariants.
        // Can return a dummy UID.
        return keccak256(abi.encodePacked(schemaName, schema, resolver, revocable, block.timestamp));
    }

    function getSchema(bytes32 schemaUID) external view override returns (SchemaRecord memory) {
        // Not directly called by LudusEvents logic for these invariants.
        return SchemaRecord({uid: schemaUID, resolver: address(0), revocable: false, schema: ""});
    }

    function getSchema(string calldata schemaName) external view override returns (SchemaRecord memory) {
        // Not directly called by LudusEvents logic for these invariants.
         return SchemaRecord({uid: bytes32(0), resolver: address(0), revocable: false, schema: ""});
    }

    function version() external pure override returns (string memory) {
        return "StubSchemaRegistry 1.0";
    }
} 