#!/bin/bash

# Exit on error
set -e

echo "=== CERTORA VERIFICATION FOR LUDUSEVENTS REGISTRATION ==="
echo "This script runs formal verification on the LudusEvents registration logic"
echo

# Activate Certora virtual environment if it exists
if [ -d "certora-venv" ]; then
  source certora-venv/bin/activate
  echo "✓ Activated Certora virtual environment"
else
  echo "⚠ Warning: Certora virtual environment not found"
  echo "  If Certora is not installed globally, verification may fail"
  echo "  Consider running: python -m venv certora-venv && certora-venv/bin/pip install certora-cli"
fi

# Set the working directory
cd "$(dirname "$0")/.." || exit 1
echo "✓ Working directory: $(pwd)"

# Check if solc is available
if ! command -v solc &> /dev/null; then
    echo "❌ Error: solc compiler not found. Please install Solidity compiler."
    exit 1
fi

# Check if the config file exists
if [ ! -f "certora/LudusEvents_registration.conf" ]; then
    echo "❌ Error: Configuration file not found at certora/LudusEvents_registration.conf"
    exit 1
fi

echo
echo "=== RUNNING VERIFICATION ==="
echo "Using configuration from certora/LudusEvents_registration.conf"
echo

# Run verification using the specific configuration file
certoraRun certora/LudusEvents_registration.conf

# Check if the verification was successful
RESULT=$?
if [ $RESULT -eq 0 ]; then
  echo
  echo "✅ Verification completed successfully!"
else
  echo
  echo "❌ Verification failed. See output above for details."
  echo
  echo "Common issues and solutions:"
  echo "1. Import errors: Check that all remappings in the .conf file match foundry.toml"
  echo "2. Solc version: Make sure the Solidity compiler version is compatible (v0.8.19)"
  echo "3. Contract linking: Ensure all contract links are properly defined"
  echo "4. Library references: For struct types from libraries, use a contract that imports the library"
  echo "5. Configuration syntax: Ensure the JSON configuration is valid and all values have the correct type"
  echo
  echo "For more information, see certora/CERTORA_RULES.md"
fi

# Deactivate virtual environment if it was activated
if [ -d "certora-venv" ]; then
  deactivate
  echo "✓ Deactivated Certora virtual environment"
fi

exit $RESULT 