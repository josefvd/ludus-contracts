# Ludus Gauntlet Smart Contracts

This repository contains the open-source smart contracts for the Ludus Gauntlet protocol.

## Overview

Ludus Gauntlet is a protocol that enables achievement tracking and rewards management on Ethereum. The smart contracts in this repository handle the core functionality of the protocol including:

- Event management and processing
- Identity verification
- Attestation handling
- Yield management

## Contract Architecture

### Core Contracts

- **LudusEvents.sol**: Manages the creation, funding, and execution of events within the protocol.
- **LudusIdentity.sol**: Handles identity verification and management for participants.
- **LudusAttestations.sol**: Manages attestations and verified achievements for participants.
- **YieldManager.sol**: Handles yield generation and distribution for deposited funds.
- **LudusEventSchemas.sol**: Defines the data structures used throughout the protocol.

## Development

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js & Yarn

### Setup

1. Clone the repository
2. Install dependencies: `yarn install`
3. Compile contracts: `forge build`

### Testing

Run tests using Forge: `forge test`

## License

These contracts are licensed under MIT - see the LICENSE file for details.

## Security

For security issues, please contact team@ludusgauntlet.com. 