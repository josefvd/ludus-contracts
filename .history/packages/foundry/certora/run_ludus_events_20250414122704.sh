#!/bin/bash

# Script to run Certora verification for LudusEvents only
echo "Running Certora verification for LudusEvents contract..."

# Navigate to root directory
cd "$(dirname "$0")/../.." || exit 1

# Set the Certora key directly here
# !!!IMPORTANT!!!: Replace YOUR_CERTORA_KEY with your actual key but DO NOT COMMIT this file with your key!
export CERTORAKEY="YOUR_CERTORA_KEY"

# Check if key is still the placeholder
if [ "$CERTORAKEY" = "YOUR_CERTORA_KEY" ]; then
    echo "ERROR: You need to replace YOUR_CERTORA_KEY with your actual Certora key in the script."
    echo "Edit packages/foundry/certora/run_ludus_events.sh and replace YOUR_CERTORA_KEY with your key."
    exit 1
fi

# Run verification focusing on the treasury distribution and event timeline rules
echo "Running validation of treasury distribution and event timeline rules..."
python -m certora.run packages/foundry/certora/certora_events.conf

echo "Verification job completed!"
echo "Check the Certora Prover dashboard for results: https://prover.certora.com/"

# Creating a file to store the run link (this will be overwritten by the actual link)
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
echo "Certora verification run at $TIMESTAMP" > certora_run_link.txt
echo "Visit https://prover.certora.com/ to see results" >> certora_run_link.txt
echo "The verification may take some time to complete. Check the dashboard for status." 