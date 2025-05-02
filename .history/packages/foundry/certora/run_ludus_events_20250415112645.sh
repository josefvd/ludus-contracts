#!/bin/bash

# Script to run Certora verification for LudusEvents only
echo "Running Certora verification for LudusEvents contract..."

# Navigate to root directory
cd "$(dirname "$0")/../.." || exit 1

VENV_DIR="certora-venv"

# Create or activate virtual environment
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating Python virtual environment in $VENV_DIR..."
    python3 -m venv "$VENV_DIR"
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to create virtual environment. Please check your python3 installation."
        exit 1
    fi
fi

echo "Activating virtual environment..."
source "$VENV_DIR/bin/activate"

# Install Certora CLI if not present
if ! python3 -m pip show certora-cli > /dev/null 2>&1; then
    echo "Installing certora-cli in virtual environment..."
    python3 -m pip install certora-cli
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to install certora-cli."
        deactivate
        exit 1
    fi
fi

# Set the Certora key directly from the .env file
export CERTORAKEY="b05bb29f5cd993edb30502a7cbfb9edecaf04f04"

# Run verification focusing on the treasury distribution and event timeline rules
echo "Running validation of treasury distribution and event timeline rules..."
# Get the directory of the script itself
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# Construct absolute path to config file relative to script location
CONFIG_FILE_PATH="$SCRIPT_DIR/certora_events.conf"
certoraRun "$CONFIG_FILE_PATH" \
    --rule checkCreateEventTimeline \
    --rule checkCreateEventTreasuryDistribution

VERIFICATION_EXIT_CODE=$?

echo "Deactivating virtual environment..."
deactivate

if [ $VERIFICATION_EXIT_CODE -ne 0 ]; then
    echo "ERROR: Certora verification command failed."
    exit $VERIFICATION_EXIT_CODE
fi

echo "Verification job submitted successfully!"
echo "Check the Certora Prover dashboard for results: https://prover.certora.com/"

# Creating a file to store the run link (this will be overwritten by the actual link)
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
echo "Certora verification run submitted at $TIMESTAMP" > certora_run_link.txt
echo "Visit https://prover.certora.com/ to see results" >> certora_run_link.txt
echo "The verification may take some time to complete. Check the dashboard for status." 