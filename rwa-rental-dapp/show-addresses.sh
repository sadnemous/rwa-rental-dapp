#!/bin/bash

# RWA Deployment Addresses Viewer
# Extracts and displays all deployed contract addresses from the latest deployment

DEPLOYMENT_FILE="broadcast/Deploy.s.sol/31337/run-latest.json"

if [ ! -f "$DEPLOYMENT_FILE" ]; then
    echo "❌ No deployment file found at $DEPLOYMENT_FILE"
    echo "Run: forge script script/Deploy.s.sol --broadcast --rpc-url http://127.0.0.1:8545"
    exit 1
fi

echo "================================"
echo "📋 Deployed Contract Addresses"
echo "================================"
echo ""

# Extract contract addresses and their details
jq -r '.transactions[] | select(.contractAddress != null) | 
    "Contract: \(.contractName // "Unknown")\n" +
    "Address: \(.contractAddress)\n" +
    "Type: \(.transactionType)\n---"' "$DEPLOYMENT_FILE"

echo ""
echo "================================"
echo "✅ All contracts found in:"
echo "   $DEPLOYMENT_FILE"
echo "================================"
