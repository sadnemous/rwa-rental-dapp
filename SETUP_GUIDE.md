# RWA Rental DApp - Setup & Execution Guide

## Project Overview

This is a Real World Asset (RWA) Rental DApp that allows:
- Creating tokenized property shares using ERC-1155 smart contracts
- Collecting rent payments in MockUSDC
- Distributing rent to shareholders based on their share ownership

**Tech Stack:**
- **Blockchain**: Solidity (Ethereum), Foundry
- **Local Blockchain**: Anvil
- **Backend**: Go with Gin framework
- **Database**: SQLite
- **Frontend**: HTML/Bootstrap/JavaScript

---

## Step-by-Step Setup Guide

### Prerequisites Installed
✅ Go (v1.22.2)
✅ Foundry (forge, anvil, cast)
✅ SQLite3
✅ Git
✅ Node.js (v18.19.1) - optional

---

## Execution Steps

### Step 1: Start the Local Blockchain (Anvil)

**What it does**: Starts a local Ethereum blockchain in memory

```bash
# Terminal 1 - Keep this running
anvil
```

**Output should show:**
```
Starting anvil v0.2.0
...
Listening on 127.0.0.1:8545
```

✅ **Anvil is now running** on `http://127.0.0.1:8545`

---

### Step 2: Install Smart Contract Dependencies

**What it does**: Downloads OpenZeppelin contracts and Foundry test utilities

```bash
# Terminal 2
cd ~/Documents/porasuno/Hackathon-2026/rwa-rental-dapp/rwa-rental-dapp

# Install dependencies (run once)
forge install OpenZeppelin/openzeppelin-contracts foundry-rs/forge-std
```

✅ **Dependencies installed** in `lib/` directory

---

### Step 3: Build Smart Contracts

**What it does**: Compiles Solidity contracts to bytecode

```bash
# Terminal 2
forge build
```

**Expected output:**
```
[⠔] Compiling 37 files with Solc 0.8.33
Compiler run successful!
```

✅ **Contracts compiled** in `out/` directory

---

### Step 4: Deploy Smart Contracts to Anvil

**What it does**: Deploys MockUSDC and RWA1155 contracts to local blockchain

```bash
# Terminal 2
forge script script/Deploy.s.sol --broadcast --rpc-url http://127.0.0.1:8545
```

**Expected output:**
```
=== Contract Deployment Addresses ===
MockUSDC Address: 0x5b73C5498c1E3b4dbA84de0F1833c4a029d90519
RWA1155 Address: 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496
=====================================
```

✅ **Contracts deployed!** Save the **RWA1155 address** - you'll need it later

---

### Step 5: View Deployed Contract Addresses

**What it does**: Shows all deployed contract addresses in a clean format

```bash
# Terminal 2
./show-addresses.sh
```

**This script reads from:** `broadcast/Deploy.s.sol/31337/run-latest.json`

✅ **Easy way to check your deployed contracts**

---

### Step 6: Start the Go Backend Server

**What it does**: Starts the web server on port 8080

```bash
# Terminal 3 (new terminal)
cd ~/Documents/porasuno/Hackathon-2026/rwa-rental-dapp/rwa-rental-dapp

# Clean the old database (first time only)
rm -f rwa.db

# Install Go dependencies (if needed)
go mod tidy

# Run the backend
go run main.go
```

**Expected output:**
```
[GIN-debug] Loaded HTML Templates (1): 
[GIN-debug] Loaded HTML Templates (1): index.tmpl
[GIN-debug] GET    /                         --> main.handlers.ListProperties.func1 (3 handlers)
[GIN-debug] POST   /property/create          --> main.handlers.CreateProperty.func1 (3 handlers)
[GIN-debug] POST   /property/pay-rent        --> main.handlers.PayRent.func1 (3 handlers)
[GIN-debug] POST   /property/claim-rent      --> main.handlers.ClaimRent.func1 (3 handlers)
[GIN-debug] Listening and serving HTTP on :8080
```

✅ **Backend running** on `http://localhost:8080`

---

### Step 7: Open the Web Interface

**What it does**: Opens the RWA Rental DApp UI in your browser

```bash
# Open browser to:
http://localhost:8080
```

✅ **UI loaded!** You should see the property dashboard

---

## Using the RWA Rental DApp

### Create a Property

1. **Fill the form:**
   - **Property Name**: e.g., "Penthouse NYC"
   - **Location**: e.g., "Manhattan"
   - **Contract Address**: Paste the RWA1155 address from Step 4
   - **Total Shares**: e.g., 1000

2. **Click "Add Property"**

✅ **Property created!** It appears in the property list

---

### Pay Rent

1. **Find your property** in the list
2. **In the "Pay Rent" section:**
   - Enter amount: e.g., 10000 (USDC)
   - Click "Pay"

✅ **Rent added** to the property's rent pool

---

### Claim Rent

1. **Find your property** in the list
2. **In the "Claim Rent" section:**
   - Enter your shares: e.g., 250 (out of 1000 total)
   - Click "Claim"

**Formula used:**
```
Claimable Amount = (Rent Pool × Your Shares) / Total Shares
Example: (10000 × 250) / 1000 = 2500 USDC
```

✅ **Rent claimed!** Amount deducted from pool and shown in popup

---

## Directory Structure

```
rwa-rental-dapp/
├── contracts/               # Smart contracts
│   ├── MockUSDC.sol        # ERC20 token (fake USDC)
│   └── RWA1155.sol         # ERC1155 property shares
├── script/
│   └── Deploy.s.sol        # Deployment script
├── db/                      # Database code
│   └── sqlite.go           # SQLite initialization
├── eth/                     # Ethereum interaction
│   └── client.go           # Web3 client
├── handlers/                # API endpoints
│   └── property.go         # Property handlers
├── models/                  # Data models
│   └── property.go         # Property struct
├── web/
│   └── templates/
│       └── index.tmpl      # HTML UI
├── main.go                 # Backend entry point
├── go.mod / go.sum         # Go dependencies
├── foundry.toml            # Foundry config
├── rwa.db                  # SQLite database
├── show-addresses.sh       # Script to view deployed addresses
└── README.md               # Project documentation
```

---

## Important Commands Reference

### Anvil (Blockchain)
```bash
anvil                       # Start local blockchain
```

### Forge (Smart Contracts)
```bash
forge build                 # Compile contracts
forge install <repo>        # Install dependencies
forge script <file> --broadcast --rpc-url <url>  # Deploy contracts
```

### Cast (Blockchain Queries)
```bash
cast block-number --rpc-url http://127.0.0.1:8545
cast code <address> --rpc-url http://127.0.0.1:8545
cast balance <address> --rpc-url http://127.0.0.1:8545
```

### Go (Backend)
```bash
go mod tidy                 # Install dependencies
go run main.go              # Start backend
```

### Custom Scripts
```bash
./show-addresses.sh         # Display deployed contract addresses
```

---

## Troubleshooting

### Problem: "anvil: command not found"
**Solution:** Foundry not installed
```bash
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup
```

### Problem: "rwa.db already exists"
**Solution:** Delete old database
```bash
cd ~/Documents/porasuno/Hackathon-2026/rwa-rental-dapp/rwa-rental-dapp
rm -f rwa.db
```

### Problem: "Contract code is empty"
**Solution:** Anvil restarted, contracts lost. Redeploy:
```bash
forge script script/Deploy.s.sol --broadcast --rpc-url http://127.0.0.1:8545
```

### Problem: "pattern matches no files: web/templates/*"
**Solution:** Make sure you're running from the correct directory
```bash
cd ~/Documents/porasuno/Hackathon-2026/rwa-rental-dapp/rwa-rental-dapp
go run main.go
```

---

## Key Concepts

### Anvil
- Local Ethereum blockchain that runs in memory
- All contracts and state are lost when you stop it
- Perfect for local development and testing

### ERC-1155
- Multi-token standard for property shares
- Allows minting multiple types of tokens
- Efficient for managing different properties

### MockUSDC
- Fake USDC token for testing
- Used for rent payments
- No real value, just for development

### Rent Distribution
Each shareholder gets: `(Total Rent × Their Shares) / Total Shares`

---

## Next Steps

1. ✅ Understand the smart contracts (`contracts/RWA1155.sol`, `contracts/MockUSDC.sol`)
2. ✅ Explore the Go backend handlers (`handlers/property.go`)
3. ✅ Modify the UI (`web/templates/index.tmpl`)
4. ✅ Add more features (e.g., property deletion, rent history)
5. ✅ Deploy to a testnet (Sepolia, Mumbai, etc.)
6. ✅ Deploy to mainnet (for production)

---

## Quick Start (TL;DR)

```bash
# Terminal 1: Blockchain
anvil

# Terminal 2: Deploy
cd ~/Documents/porasuno/Hackathon-2026/rwa-rental-dapp/rwa-rental-dapp
forge install OpenZeppelin/openzeppelin-contracts foundry-rs/forge-std
forge build
forge script script/Deploy.s.sol --broadcast --rpc-url http://127.0.0.1:8545
./show-addresses.sh  # Save the RWA1155 address!

# Terminal 3: Backend
cd ~/Documents/porasuno/Hackathon-2026/rwa-rental-dapp/rwa-rental-dapp
rm -f rwa.db
go mod tidy
go run main.go

# Browser
http://localhost:8080
```

---

## Resources

- **Foundry Docs**: https://book.getfoundry.sh/
- **OpenZeppelin Contracts**: https://docs.openzeppelin.com/contracts/
- **Solidity Docs**: https://docs.soliditylang.org/
- **Gin Framework**: https://gin-gonic.com/
- **SQLite**: https://www.sqlite.org/docs.html

---

**Last Updated:** February 22, 2026
**Version:** 1.0 - Initial Setup
