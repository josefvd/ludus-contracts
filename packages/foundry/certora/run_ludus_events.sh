#!/bin/bash

# Script to run Certora verification for LudusEvents only
echo "Running Certora verification for LudusEvents contract..."

# Set up environment
if [ -z "$CERTORAKEY" ]; then
    echo "CERTORAKEY is not set. Please enter your Certora key: "
    read -s CERTORAKEY
    export CERTORAKEY
fi

# Navigate to root directory
cd "$(dirname "$0")/../.." || exit 1

# Run verification focusing on the treasury distribution and event timeline rules
echo "Running validation of treasury distribution and event timeline rules..."
python -m certora.run packages/foundry/certora/certora_events.conf

echo "Verification job completed!"
echo "Check the Certora Prover dashboard for results: https://prover.certora.com/" 