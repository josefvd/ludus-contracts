# Certora Verification for Ludus Contracts

This directory contains the necessary files to run formal verification on the Ludus contracts using the Certora Prover.

## Contents

- `specs/`: Contains the formal specification files
  - `LudusEvents.spec`: Main specification file with rules for LudusEvents contract
  - `LudusEvents_registration.spec`: Specification focused on registration functionality

- `certora_events.conf`: Configuration for verifying treasury distribution and event timeline rules
- `certora_registration.conf`: Configuration for verifying registration functionality
- `run_ludus_events.sh`: Script to run verification of treasury and timeline rules
- `run_registration_verification.sh`: Script to run verification of registration functionality
- `envfree_limitations.md`: Documentation on limitations of envfree with complex data structures

## Running Verification

### Prerequisites

1. Python 3.7+
2. Certora CLI tool installed: `pip install certora-cli`
3. Valid Certora key (obtain from [Certora Prover](https://prover.certora.com/))

### Steps to Verify LudusEvents Rules

1. Edit `run_ludus_events.sh` and replace `YOUR_CERTORA_KEY` with your actual Certora key.
2. Make the script executable: `chmod +x run_ludus_events.sh`
3. Run the script: `./run_ludus_events.sh`
4. Check the Certora Prover dashboard for results: https://prover.certora.com/

### Key Rules

#### validTreasuryDistribution
- Verifies that treasury shares (athletes, organizer, charity) add up to ≤97% (3% fixed Ludus tax)
- Ensures charity address is valid when charity share is non-zero

#### validEventTimeline
- Ensures start time is in the future
- Verifies end time is after start time
- Confirms registration period is properly configured
- Ensures registration ends before event starts

## Sharing Results

After running verification, you can share the run links from the Certora dashboard with the team. These links will show the verification results and any potential issues found.

## Known Limitations

See `envfree_limitations.md` for detailed information about limitations when using envfree with complex data structures in the Ludus contracts. 