// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library LudusTypes {
    enum EventType { Tournament, League }
    
    enum EventStatus {
        Created,
        Started,
        Completed,
        Canceled
    }
    
    enum PaymentToken { ETH, USDC }

    // Core event details (minimal on-chain storage)
    struct EventDetails {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        uint256 registrationStartTime;
        uint256 registrationEndTime;
        uint256 maxParticipants;
        address creator;
        address referee;
        EventStatus status;
        uint256 registrationFeeETH;
        uint256 registrationFeeUSDC;
        uint256 totalPrizePool;
        bool preferYieldGeneration;
    }

    struct Distribution {
        uint256 athletesShare;
        uint256 organizerShare;
        uint256 charityShare;
        address charityAddress;
    }

    struct AthleteDistribution {
        uint256[] positions;        // Array of position ranks (1st, 2nd, 3rd, etc.)
        uint256[] percentages;      // Corresponding percentages for each position
    }

    // Attestation data structures (stored on-chain via EAS attestations)
    struct EventAttestationData {
        uint256 eventId;            // Reference to the on-chain event
        string name;
        string description;
        string eventType;
        string venue;
        string sport;
        string[] rules;
        string[] requirements;
        uint256[] ticketPrices;        // Changed to uint256[] for USDC prices with 6 decimals
        string[] ticketTierNames;
        uint256[] sponsorshipPrices;   // Changed to uint256[] for USDC prices with 6 decimals
        string[] sponsorshipTierNames;
        string eventURI;
    }

    struct ResultAttestationData {
        uint256 eventId;
        uint256[] winnerIds;
        uint256[] prizeShares;
        string resultURI;
        uint256 timestamp;
    }
} 