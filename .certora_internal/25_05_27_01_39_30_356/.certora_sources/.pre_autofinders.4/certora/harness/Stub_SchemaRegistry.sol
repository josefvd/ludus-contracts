// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../src/interfaces/ISchemaRegistry.sol";
import "../../src/interfaces/ISchemaResolver.sol";

contract Stub_SchemaRegistry is ISchemaRegistry {
    constructor() {}

    function register(
        string calldata schema,
        ISchemaResolver resolver,
        bool revocable
    ) external returns (bytes32) {
        return keccak256(abi.encodePacked(schema, resolver, revocable, block.timestamp));
    }

    function getSchema(bytes32 uid) external view returns (SchemaRecord memory) {
        return SchemaRecord({uid: uid, resolver: ISchemaResolver(address(0)), revocable: false, schema: ""});
    }

    function version() external pure returns (string memory) {
        return "StubSchemaRegistry 1.0";
    }
} 