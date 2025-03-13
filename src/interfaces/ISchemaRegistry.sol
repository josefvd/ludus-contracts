// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ISchemaResolver.sol";
import "./IEAS.sol";

interface ISchemaRegistry {
    /**
     * @dev Registers a new schema with the registry.
     */
    function register(
        string calldata schema,
        ISchemaResolver resolver,
        bool revocable
    ) external returns (bytes32);

    /**
     * @dev Returns the schema record for a given schema UID.
     */
    function getSchema(bytes32 uid) external view returns (SchemaRecord memory);
} 