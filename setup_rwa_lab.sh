#!/usr/bin/env bash

set -e

PROJECT="rwa-rental-dapp"

mkdir -p $PROJECT/contracts
mkdir -p $PROJECT/script
mkdir -p $PROJECT/backend/eth
mkdir -p $PROJECT/backend/db
mkdir -p $PROJECT/backend/handlers
mkdir -p $PROJECT/backend/models
mkdir -p $PROJECT/web/templates

########################################
# foundry.toml
########################################
cat > $PROJECT/foundry.toml <<'EOF'
[profile.default]
src = "contracts"
out = "out"
libs = ["lib"]
EOF

########################################
# MockUSDC.sol
########################################
cat > $PROJECT/contracts/MockUSDC.sol <<'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("MockUSDC", "USDC") {
        _mint(msg.sender, 1_000_000 * 1e18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
EOF

########################################
# RWA1155.sol
########################################
cat > $PROJECT/contracts/RWA1155.sol <<'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract RWA1155 is ERC1155 {

    IERC20 public usdc;

    mapping(uint256 => uint256) public totalShares;
    mapping(uint256 => uint256) public rentPool;
    mapping(uint256 => mapping(address => uint256)) public claimed;

    constructor(address _usdc) ERC1155("") {
        usdc = IERC20(_usdc);
    }

    function mintProperty(uint256 id, uint256 shares) external {
        _mint(msg.sender, id, shares, "");
        totalShares[id] = shares;
    }

    function payRent(uint256 id, uint256 amount) external {
        require(usdc.transferFrom(msg.sender, address(this), amount), "transfer failed");
        rentPool[id] += amount;
    }

    function claimRent(uint256 id) external {
        uint256 holderShares = balanceOf(msg.sender, id);
        require(holderShares > 0, "no shares");

        uint256 total = totalShares[id];
        uint256 entitled = (rentPool[id] * holderShares) / total;
        uint256 already = claimed[id][msg.sender];

        uint256 payableAmount = entitled - already;
        require(payableAmount > 0, "nothing to claim");

        claimed[id][msg.sender] = entitled;
        usdc.transfer(msg.sender, payableAmount);
    }
}
EOF

########################################
# Deploy script
########################################
cat > $PROJECT/script/Deploy.s.sol <<'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/MockUSDC.sol";
import "../contracts/RWA1155.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        MockUSDC usdc = new MockUSDC();
        RWA1155 rwa = new RWA1155(address(usdc));

        vm.stopBroadcast();
    }
}
EOF

########################################
# Go: sqlite.go
########################################
cat > $PROJECT/backend/db/sqlite.go <<'EOF'
package db

import (
	"database/sql"
	_ "github.com/mattn/go-sqlite3"
)

func InitDB() *sql.DB {
	db, _ := sql.Open("sqlite3", "rwa.db")

	sqlStmt := `
	CREATE TABLE IF NOT EXISTS properties (
		id INTEGER PRIMARY KEY,
		name TEXT,
		location TEXT
	);`
	db.Exec(sqlStmt)

	return db
}
EOF

########################################
# Go: model
########################################
cat > $PROJECT/backend/models/property.go <<'EOF'
package models

type Property struct {
	ID       int
	Name     string
	Location string
}
EOF

########################################
# Go: eth client (stub for now)
########################################
cat > $PROJECT/backend/eth/client.go <<'EOF'
package eth

import (
	"log"

	"github.com/ethereum/go-ethereum/ethclient"
)

var Client *ethclient.Client

func Init() {
	c, err := ethclient.Dial("http://127.0.0.1:8545")
	if err != nil {
		log.Fatal(err)
	}
	Client = c
}
EOF

########################################
# Go: handler
########################################
cat > $PROJECT/backend/handlers/property.go <<'EOF'
package handlers

import (
	"database/sql"
	"net/http"

	"github.com/gin-gonic/gin"
)

func ListProperties(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		rows, _ := db.Query("SELECT id, name, location FROM properties")
		defer rows.Close()

		var props []map[string]interface{}

		for rows.Next() {
			var id int
			var name, location string
			rows.Scan(&id, &name, &location)

			props = append(props, gin.H{
				"id": id,
				"name": name,
				"location": location,
			})
		}

		c.HTML(http.StatusOK, "index.tmpl", gin.H{
			"properties": props,
		})
	}
}
EOF

########################################
# Go: main
########################################
cat > $PROJECT/backend/main.go <<'EOF'
package main

import (
	"rwa/db"
	"rwa/eth"
	"rwa/handlers"

	"github.com/gin-gonic/gin"
)

func main() {

	database := db.InitDB()
	eth.Init()

	r := gin.Default()
	r.LoadHTMLGlob("../web/templates/*")

	r.GET("/", handlers.ListProperties(database))

	r.Run(":8080")
}
EOF

########################################
# HTML template
########################################
cat > $PROJECT/web/templates/index.tmpl <<'EOF'
<!DOCTYPE html>
<html>
<head>
  <title>RWA Rental DApp</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="container mt-4">
  <h1>RWA Rental Dashboard</h1>

  <table class="table">
    <thead>
      <tr>
        <th>ID</th>
        <th>Name</th>
        <th>Location</th>
      </tr>
    </thead>
    <tbody>
      {{range .properties}}
      <tr>
        <td>{{.id}}</td>
        <td>{{.name}}</td>
        <td>{{.location}}</td>
      </tr>
      {{end}}
    </tbody>
  </table>
</body>
</html>
EOF

########################################
# README
########################################
cat > $PROJECT/README.md <<'EOF'
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
EOF

echo "✅ Project created: $PROJECT"