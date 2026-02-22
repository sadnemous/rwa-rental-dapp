# RWA Rental DApp (Local Lab)

## Stack
- Solidity + Foundry
- Anvil local blockchain
- Go + Gin backend
- SQLite
- Bootstrap UI

## Features
- ERC-1155 property shares
- Mock USDC rent payments
- Claim rent based on shares

## Initial Setup

### Complete Installation for Fresh Linux System

Follow these steps to set up your RWA Rental DApp on a brand new Linux system.

### Prerequisites Overview

| Software | Version | Purpose |
|----------|---------|---------|
| Git | 2.0+ | Version control |
| Go | 1.20+ | Backend development |
| Foundry | Latest | Smart contract development & Anvil |
| SQLite3 | 3.0+ | Database |
| curl | Any | Download tools |

### Step-by-Step Installation

#### Step 1: Update System Packages

```bash
sudo apt-get update
sudo apt-get upgrade -y
```

#### Step 2: Install Git

```bash
sudo apt-get install -y git
# Verify installation
git --version
```

#### Step 3: Install Go (1.20+)

```bash
# Download and install Go
cd /tmp
wget https://go.dev/dl/go1.22.2.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz

# Add Go to PATH
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Verify installation
go version
```

#### Step 4: Install Foundry (Forge, Anvil, Cast)

Foundry is a blazing fast, portable and modular toolkit for Ethereum application development.

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash

# Reload your shell to update PATH
source ~/.bashrc

# Install/Update Foundry tools
foundryup

# Verify installation
forge --version
anvil --version
cast --version
```

**Command Explanation:**

1. **`curl -L https://foundry.paradigm.xyz | bash`**
   - Downloads the Foundry installer script from the official website
   - The `-L` flag follows redirects
   - `| bash` pipes the script directly to bash for execution
   - This installs foundryup (the Foundry version manager)

2. **`source ~/.bashrc`**
   - Reloads your shell configuration file
   - This updates your system's PATH environment variable so your shell can find the newly installed `foundryup` command
   - Without this, you'd need to close and reopen your terminal

3. **`foundryup`**
   - The Foundry version manager command
   - Installs or updates the three main Foundry tools:
     - **forge** - Smart contract compiler and build tool
     - **anvil** - Local Ethereum blockchain simulator
     - **cast** - Command-line tool for interacting with Ethereum

4. **Verification commands:**
   - `forge --version` - Confirms forge (compiler) is installed
   - `anvil --version` - Confirms anvil (local blockchain) is installed
   - `cast --version` - Confirms cast (CLI tool) is installed

**Summary:** The script installs Foundry's installer, then uses it to install the three essential tools you need to develop and test Ethereum smart contracts locally.

#### Step 5: Install SQLite3

```bash
sudo apt-get install -y sqlite3

# Verify installation
sqlite3 --version
```

**Command Explanation:**

1. **`sudo apt-get install -y sqlite3`**
   - `sudo` - Runs the command with administrator privileges (required for system-wide installation)
   - `apt-get install` - Package manager command to install software
   - `-y` - Automatically answers "yes" to any prompts
   - `sqlite3` - The package name for SQLite database engine

2. **`sqlite3 --version`**
   - Displays the installed version of SQLite3
   - Confirms the installation was successful

**Quick SQLite3 Test:**

Try these commands to familiarize yourself with SQLite3:

```bash
# Create a test database and open it
sqlite3 testdb.db

# Once inside sqlite3 prompt, create a simple table (DDL)
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT UNIQUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

# Insert sample data (DML)
INSERT INTO users (name, email) VALUES ('Dilip Kundu', 'dilip@example.com');
INSERT INTO users (name, email) VALUES ('Manas Maity', 'manas@example.com');
INSERT INTO users (name, email) VALUES ('Sayan Ghosh', 'sayan@example.com');

# Query the data
SELECT * FROM users;

# Update a record
UPDATE users SET name = 'Alice Brown' WHERE id = 1;

# Delete a record
DELETE FROM users WHERE id = 3;

# View table structure
.schema users

# List all tables
.tables

# Exit SQLite3
.quit
```

**Expected Output:**
```
sqlite> SELECT * FROM users;
1|Alice Brown|alice@example.com|2026-02-22 10:30:15
2|Bob Smith|bob@example.com|2026-02-22 10:30:16
```

**Summary:** SQLite3 is a lightweight relational database. The installation is straightforward, and you can immediately start creating tables, inserting data, and running queries.

#### Step 6: Install Build Essentials (Optional but Recommended)

```bash
sudo apt-get install -y build-essential pkg-config
```

#### Step 7: Verify Complete Installation

Run this comprehensive check to confirm all software is installed:

```bash
echo "=== System Setup Verification ===" && \
echo "✓ Git: $(git --version)" && \
echo "✓ Go: $(go version)" && \
echo "✓ Forge: $(forge --version)" && \
echo "✓ Anvil: $(anvil --version)" && \
echo "✓ Cast: $(cast --version)" && \
echo "✓ SQLite3: $(sqlite3 --version)" && \
echo "=== All systems ready! ==="
```

### For Other Linux Distributions

**Fedora/RHEL/CentOS:**
```bash
sudo dnf update -y
sudo dnf install -y git sqlite3 curl wget
# Then follow Go and Foundry installation steps above
```

**Arch Linux:**
```bash
sudo pacman -Syu
sudo pacman -S git sqlite curl wget
# Then follow Go and Foundry installation steps above
```

**Alpine Linux (minimal):**
```bash
apk add --update git sqlite curl wget bash
# Then follow Go and Foundry installation steps above
```

---

## Setup

### 1. Start Anvil (Local Blockchain)
```bash
anvil
```
This starts a local Ethereum blockchain on `http://127.0.0.1:8545`

### 2. Install Foundry Dependencies
```bash
forge install OpenZeppelin/openzeppelin-contracts
forge install foundry-rs/forge-std
```

### 3. Build & Deploy Smart Contracts
```bash
forge build
forge script script/Deploy.s.sol --broadcast --rpc-url http://127.0.0.1:8545
```

### 4. Run Backend
```bash
cd backend
go mod init rwa
go mod tidy
go run main.go
```

### 5. Access the Application
Open http://localhost:8080 in your browser

---

## Troubleshooting

### Port 8080 is Already in Use

If you get an error like "Address already in use" or port 8080 is occupied, follow these steps:

#### Check What's Using Port 8080

```bash
# Method 1: Show process using port 8080
lsof -i :8080

# Method 2: Alternative using netstat
netstat -tlnp | grep 8080

# Method 3: Simple test with curl
curl http://localhost:8080
```

**If you see output with `go` process:**
- Your Go backend is already running
- Either keep it as is, or kill it and restart fresh

**If you see output with a different process:**
- Another service is using port 8080
- Either stop that service or change the Go backend port

#### Kill the Process Using Port 8080

**Option 1: Kill by process name**
```bash
pkill -f "go run main.go"
```

**Option 2: Kill by PID (Process ID)**
```bash
# Get the PID
PID=$(lsof -t -i:8080)

# Kill the process
kill -9 $PID
```

**Option 3: One-liner**
```bash
kill -9 $(lsof -t -i:8080)
```

#### Restart the Backend

After killing the process:

```bash
cd ~/Documents/porasuno/Hackathon-2026/rwa-rental-dapp/rwa-rental-dapp
rm -f rwa.db  # Optional: clean database
go run main.go
```

**Expected output:**
```
[GIN-debug] Listening and serving HTTP on :8080
```

#### Change the Port (Alternative Solution)

If you want to run the backend on a different port (e.g., 8081), you can modify `main.go`:

Find this line:
```go
r.Run(":8080")
```

Change it to:
```go
r.Run(":8081")
```

Then restart:
```bash
go run main.go
```

Access at: `http://localhost:8081`

---

### Check if Service is Running

Use these commands to verify services are running:

```bash
# Check if Anvil is running (port 8545)
lsof -i :8545

# Check if Go backend is running (port 8080)
lsof -i :8080

# Check if both are running
lsof -i :8545 && lsof -i :8080 && echo "✅ All services running" || echo "❌ Some services not running"
```

---

### Other Common Issues

**Anvil: command not found**
```bash
# Reinstall Foundry
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup
```

**Contract code is empty**
- Anvil was restarted (blockchain state is in-memory, not persisted)
- Redeploy contracts:
```bash
forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --unlocked
```

**Import errors in Go**
```bash
cd ~/Documents/porasuno/Hackathon-2026/rwa-rental-dapp/rwa-rental-dapp
go mod tidy
go run main.go
```

**Database locked**
```bash
# Delete and recreate database
rm -f rwa.db
go run main.go
```
