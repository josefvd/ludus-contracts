#!/bin/bash

# Script to run Certora verification for LudusEvents only
echo "Running Certora verification for LudusEvents contract..."

# Set up environment
export CERTORAKEY="your_certora_key"  # Replace with your actual key or use environment variable

# Navigate to root directory
cd "$(dirname "$0")/../.." || exit 1

# Run verification with direct Python module
echo "Running with Python module..."
python -m certora.run packages/foundry/certora/certora_events.conf

echo "Verification job completed!" 