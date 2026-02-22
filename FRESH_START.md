# Fresh Start Guide - RWA Rental DApp

## Overview
This guide walks you through starting the RWA Rental DApp from scratch after a reboot or full shutdown.

---

## Step 1: Stop All Running Services

If any services are still running from a previous session, stop them first:

```bash
cd ~/Documents/porasuno/Hackathon-2026/rwa-rental-dapp/rwa-rental-dapp
./stop-all.sh
```

**Expected output:**
```
🛑 Stopping RWA Rental DApp...
✅ Anvil stopped
✅ Backend stopped
🛑 All services stopped!
```

This ensures:
- ✅ Anvil (blockchain) is stopped
- ✅ Go backend server is stopped
- ✅ No port conflicts when starting fresh

---

## Step 2: Terminal 1 - Start Anvil (Local Blockchain)

Open a new terminal and run:

```bash
anvil
```

**What it does:**
- Starts a local Ethereum blockchain
- Provides 10 accounts with 10,000 ETH each (free testing accounts)
- Listens on `http://127.0.0.1:8545`
- Stores blockchain state in memory (ephemeral - lost on restart)

**Expected output:**
```
Starting anvil v0.2.0
...
Listening on 127.0.0.1:8545
```

**Keep this terminal running!** Don't close it while using the app.

---

## Step 3: Terminal 2 - Deploy Smart Contracts

Open a new terminal and run:

```bash
cd ~/Documents/porasuno/Hackathon-2026/rwa-rental-dapp/rwa-rental-dapp

forge script script/Deploy.s.sol \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast \
  --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  --unlocked
```

### Command Explanation

| Component | What It Does |
|-----------|-------------|
| `forge script` | Foundry tool to run deployment scripts |
| `script/Deploy.s.sol` | The Solidity script file containing contract deployments |
| `--rpc-url http://127.0.0.1:8545` | **Target blockchain**: Connect to Anvil running locally |
| `--broadcast` | **Action**: Actually send transactions to blockchain (not just simulate) |
| `--sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` | **Account**: Use Anvil's default account 0 (has 10,000 ETH) |
| `--unlocked` | **Authentication**: Treat account as unlocked (no password needed for Anvil) |

### Step-by-Step Process

1. **Reads** the deployment script
   ```solidity
   MockUSDC usdc = new MockUSDC();
   RWA1155 rwa = new RWA1155(address(usdc));
   ```

2. **Connects** to Anvil at `127.0.0.1:8545`

3. **Sends** two deployment transactions:
   - Deploy MockUSDC (ERC-20 token)
   - Deploy RWA1155 (ERC-1155 property shares), passing MockUSDC address

4. **Returns** contract addresses:
   ```
   === Contract Deployment Addresses ===
   MockUSDC Address: 0x5FbDB2315678afecb367f032d93F642f64180aa3
   RWA1155 Address: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
   =====================================
   ```

**Expected final output:**
```
ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.
Transactions saved to: broadcast/Deploy.s.sol/31337/run-latest.json
```

### Save the Contract Addresses!

Copy the **RWA1155 address** - you'll need it when creating properties in the web form.

Or view them anytime with:
```bash
./show-addresses.sh
```

---

## Step 4: Terminal 3 - Start Go Backend Server

Open a new terminal and run:

```bash
cd ~/Documents/porasuno/Hackathon-2026/rwa-rental-dapp/rwa-rental-dapp

# Clean old database (start fresh with empty data)
rm -f rwa.db

# Start the backend server
go run main.go
```

### What Each Command Does

| Command | Purpose |
|---------|---------|
| `cd ~/Documents/.../rwa-rental-dapp` | Navigate to project directory |
| `rm -f rwa.db` | Delete old SQLite database (optional, use if you want fresh data) |
| `go run main.go` | Compile and run the Go backend server |

### Expected Output

```
[GIN-debug] Loaded HTML Templates (1): 
[GIN-debug] Loaded HTML Templates (1): index.tmpl
[GIN-debug] GET    /                         --> main.handlers.ListProperties.func1 (3 handlers)
[GIN-debug] POST   /property/create          --> main.handlers.CreateProperty.func1 (3 handlers)
[GIN-debug] POST   /property/pay-rent        --> main.handlers.PayRent.func1 (3 handlers)
[GIN-debug] POST   /property/claim-rent      --> main.handlers.ClaimRent.func1 (3 handlers)
[GIN-debug] Listening and serving HTTP on :8080
```

This means:
- ✅ Backend is running on `http://localhost:8080`
- ✅ Database initialized
- ✅ All API routes ready
- ✅ HTML templates loaded

---

## Step 5: Open Web Interface (Browser)

Open your web browser and go to:

```
http://localhost:8080
```

You should see:
- ✅ Property listing page (empty at first)
- ✅ Form to create new properties
- ✅ Form to pay rent
- ✅ Form to claim rent

---

## Terminal Setup Summary

| Terminal | Command | Keeps Running? |
|----------|---------|----------------|
| **Terminal 1** | `anvil` | ✅ Yes (keep open) |
| **Terminal 2** | `forge script ...` | ❌ No (one-time deployment) |
| **Terminal 3** | `go run main.go` | ✅ Yes (keep open) |

At the end, you should have **2 terminals running** (Anvil + Go backend).

---

## Quick Reference

```bash
# Terminal 1
anvil

# Terminal 2
cd ~/Documents/porasuno/Hackathon-2026/rwa-rental-dapp/rwa-rental-dapp
forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --unlocked
./show-addresses.sh  # View deployed contract addresses

# Terminal 3
cd ~/Documents/porasuno/Hackathon-2026/rwa-rental-dapp/rwa-rental-dapp
rm -f rwa.db
go run main.go

# Browser
http://localhost:8080
```

---

## When You're Done

Stop all services:

```bash
./stop-all.sh
```

---

## Troubleshooting

### "Anvil: command not found"
Foundry not installed. Install it:
```bash
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup
```

### "Contract code is empty" or cast returns 0x
Anvil was restarted. The blockchain state is in-memory and lost on restart. Just redeploy:
```bash
# Terminal 2
forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --unlocked
```

### "go run main.go" fails with import errors
Go modules not installed. Run:
```bash
go mod tidy
go run main.go
```

### Port 8080 already in use
Kill the old process:
```bash
pkill -f "go run main.go"
# Then run: go run main.go
```

---

**Version:** 1.0  
**Last Updated:** February 22, 2026
