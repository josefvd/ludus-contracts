#!/bin/bash

# Script to run Certora verification for LudusEvents only
echo "Running Certora verification for LudusEvents contract..."

# Navigate to root directory
cd "$(dirname "$0")/../.." || exit 1

# Set the Certora key directly from the .env file
export CERTORAKEY="b05bb29f5cd993edb30502a7cbfb9edecaf04f04"

# Run verification focusing on the treasury distribution and event timeline rules
echo "Running validation of treasury distribution and event timeline rules..."
python3 -m certora.run packages/foundry/certora/certora_events.conf

echo "Verification job completed!"
echo "Check the Certora Prover dashboard for results: https://prover.certora.com/"

# Creating a file to store the run link (this will be overwritten by the actual link)
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
echo "Certora verification run at $TIMESTAMP" > certora_run_link.txt
echo "Visit https://prover.certora.com/ to see results" >> certora_run_link.txt
echo "The verification may take some time to complete. Check the dashboard for status." 