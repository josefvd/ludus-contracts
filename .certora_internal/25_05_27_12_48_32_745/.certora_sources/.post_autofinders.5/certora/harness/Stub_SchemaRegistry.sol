// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../src/interfaces/ISchemaRegistry.sol";
import "../../src/interfaces/ISchemaResolver.sol";

contract Stub_SchemaRegistry is ISchemaRegistry {
    constructor() {}

    function register(
        string calldata /*schema*/,
        ISchemaResolver /*resolver*/,
        bool /*revocable*/
    ) external pure override returns (bytes32) {
        // Return a constant value to avoid unbounded hashing
        return bytes32(uint256(0x1234));
    }

    function getSchema(bytes32 uid) external view returns (SchemaRecord memory) {
        return SchemaRecord({uid: uid, resolver: ISchemaResolver(address(0)), revocable: false, schema: ""});
    }

    function version() external pure returns (string memory) {
        return "StubSchemaRegistry 1.0";
    }
} 