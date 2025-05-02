#!/bin/bash

# Script to run Certora verification for LudusEvents only
echo "Running Certora verification for LudusEvents contract..."

# Navigate to root directory
cd "$(dirname "$0")/../.." || exit 1

# Source the .env file from the certora directory
if [ -f "packages/foundry/certora/.env" ]; then
    echo "Using Certora key from .env file..."
    source packages/foundry/certora/.env
    export CERTORAKEY=$CERTORA_KEY
else
    echo "ERROR: .env file not found in packages/foundry/certora directory."
    exit 1
fi

# Verify key is available
if [ -z "$CERTORAKEY" ]; then
    echo "ERROR: No Certora key found in .env file."
    exit 1
fi

echo "Using project name: $CERTORA_PROJECT_NAME"

# Run verification focusing on the treasury distribution and event timeline rules
echo "Running validation of treasury distribution and event timeline rules..."
python -m certora.run packages/foundry/certora/certora_events.conf

echo "Verification job completed!"
echo "Check the Certora Prover dashboard for results: https://prover.certora.com/"

# Creating a file to store the run link
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
echo "Certora verification run at $TIMESTAMP" > certora_run_link.txt
echo "Visit https://prover.certora.com/ to see results" >> certora_run_link.txt
echo "The verification may take some time to complete. Check the dashboard for status." 