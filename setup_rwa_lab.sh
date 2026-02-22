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
		location TEXT,
		contract_address TEXT,
		shares INTEGER,
		rent_pool TEXT DEFAULT '0'
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
	ID              int
	Name            string
	Location        string
	ContractAddress string
	Shares          int64
	RentPool        string
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
	"fmt"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

// ListProperties returns all properties
func ListProperties(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		rows, _ := db.Query("SELECT id, name, location, contract_address, shares, rent_pool FROM properties")
		defer rows.Close()

		var props []map[string]interface{}

		for rows.Next() {
			var id int
			var name, location, contractAddr, rentPool string
			var shares int64
			rows.Scan(&id, &name, &location, &contractAddr, &shares, &rentPool)

			props = append(props, gin.H{
				"id":               id,
				"name":             name,
				"location":         location,
				"contract_address": contractAddr,
				"shares":           shares,
				"rent_pool":        rentPool,
			})
		}

		c.HTML(http.StatusOK, "index.tmpl", gin.H{
			"properties": props,
		})
	}
}

// CreateProperty adds a new RWA property
func CreateProperty(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		name := c.PostForm("name")
		location := c.PostForm("location")
		contractAddr := c.PostForm("contract_address")
		sharesStr := c.PostForm("shares")

		shares, err := strconv.ParseInt(sharesStr, 10, 64)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid shares"})
			return
		}

		stmt, _ := db.Prepare("INSERT INTO properties (name, location, contract_address, shares, rent_pool) VALUES (?, ?, ?, ?, ?)")
		result, _ := stmt.Exec(name, location, contractAddr, shares, "0")
		id, _ := result.LastInsertId()

		c.JSON(http.StatusOK, gin.H{
			"id":               id,
			"name":             name,
			"location":         location,
			"contract_address": contractAddr,
			"shares":           shares,
		})
	}
}

// PayRent adds rent to a property's pool
func PayRent(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		propertyID := c.PostForm("property_id")
		amountStr := c.PostForm("amount")

		amount, err := strconv.ParseFloat(amountStr, 64)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid amount"})
			return
		}

		// Get current rent pool
		var currentRent string
		db.QueryRow("SELECT rent_pool FROM properties WHERE id = ?", propertyID).Scan(&currentRent)

		currentAmount := 0.0
		if currentRent != "" && currentRent != "0" {
			currentAmount, _ = strconv.ParseFloat(currentRent, 64)
		}

		newTotal := fmt.Sprintf("%.2f", currentAmount+amount)

		stmt, _ := db.Prepare("UPDATE properties SET rent_pool = ? WHERE id = ?")
		stmt.Exec(newTotal, propertyID)

		c.JSON(http.StatusOK, gin.H{
			"property_id": propertyID,
			"amount":      amount,
			"new_total":   newTotal,
			"message":     "Rent paid successfully",
		})
	}
}

// ClaimRent claims rent for a property based on shares
func ClaimRent(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		propertyID := c.PostForm("property_id")
		shareHolderShares := c.PostForm("holder_shares")

		// Get property details
		var rentPoolStr string
		var totalShares int64
		db.QueryRow("SELECT rent_pool, shares FROM properties WHERE id = ?", propertyID).Scan(&rentPoolStr, &totalShares)

		rentPool := 0.0
		if rentPoolStr != "" && rentPoolStr != "0" {
			rentPool, _ = strconv.ParseFloat(rentPoolStr, 64)
		}

		holderShares, _ := strconv.ParseInt(shareHolderShares, 10, 64)

		// Calculate claimable amount
		if totalShares == 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "no total shares for this property"})
			return
		}

		claimableAmount := (rentPool * float64(holderShares)) / float64(totalShares)

		// Update rent pool (subtract claimed amount)
		newRentPool := fmt.Sprintf("%.2f", rentPool-claimableAmount)
		if rentPool-claimableAmount <= 0 {
			newRentPool = "0"
		}

		stmt, _ := db.Prepare("UPDATE properties SET rent_pool = ? WHERE id = ?")
		stmt.Exec(newRentPool, propertyID)

		c.JSON(http.StatusOK, gin.H{
			"property_id":     propertyID,
			"holder_shares":   holderShares,
			"total_shares":    totalShares,
			"claimable_amount": claimableAmount,
			"remaining_pool":   newRentPool,
			"message":          "Rent claimed successfully",
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

	// Routes
	r.GET("/", handlers.ListProperties(database))
	r.POST("/property/create", handlers.CreateProperty(database))
	r.POST("/property/pay-rent", handlers.PayRent(database))
	r.POST("/property/claim-rent", handlers.ClaimRent(database))

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
  <style>
    body { background-color: #f5f5f5; }
    .card { border: none; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    .btn-primary { background-color: #007bff; }
    .form-section { background: white; padding: 30px; border-radius: 8px; margin-bottom: 30px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    .property-card { margin-bottom: 20px; }
    .section-title { color: #333; font-weight: 600; margin-bottom: 20px; padding-bottom: 10px; border-bottom: 2px solid #007bff; }
  </style>
</head>
<body>
  <div class="container mt-5">
    <h1 class="mb-5">🏢 RWA Rental Dashboard</h1>

    <!-- Create Property Section -->
    <div class="form-section">
      <h2 class="section-title">➕ Add New RWA Property</h2>
      <form id="createPropertyForm">
        <div class="row">
          <div class="col-md-6 mb-3">
            <label class="form-label">Property Name</label>
            <input type="text" class="form-control" id="propertyName" name="name" placeholder="e.g., Luxury Apartment" required>
          </div>
          <div class="col-md-6 mb-3">
            <label class="form-label">Location</label>
            <input type="text" class="form-control" id="propertyLocation" name="location" placeholder="e.g., Downtown NYC" required>
          </div>
        </div>
        <div class="row">
          <div class="col-md-6 mb-3">
            <label class="form-label">Contract Address (ERC-1155)</label>
            <input type="text" class="form-control" id="contractAddr" name="contract_address" placeholder="0x..." required>
          </div>
          <div class="col-md-6 mb-3">
            <label class="form-label">Total Shares</label>
            <input type="number" class="form-control" id="totalShares" name="shares" placeholder="1000" required>
          </div>
        </div>
        <button type="submit" class="btn btn-primary btn-lg">Add Property</button>
      </form>
      <div id="createMessage" class="alert alert-success mt-3" style="display:none;"></div>
    </div>

    <!-- Properties List Section -->
    <div class="form-section">
      <h2 class="section-title">📋 RWA Properties</h2>
      {{if .properties}}
        <div class="row">
          {{range .properties}}
          <div class="col-md-6 mb-4">
            <div class="card property-card">
              <div class="card-body">
                <h5 class="card-title">{{.name}}</h5>
                <p class="card-text"><strong>📍 Location:</strong> {{.location}}</p>
                <p class="card-text"><strong>📝 Contract:</strong> <small>{{.contract_address}}</small></p>
                <p class="card-text"><strong>🪙 Total Shares:</strong> {{.shares}}</p>
                <p class="card-text"><strong>💰 Rent Pool:</strong> {{.rent_pool}} USDC</p>
                
                <!-- Pay Rent Form -->
                <div class="mt-3 pt-3 border-top">
                  <h6>Pay Rent</h6>
                  <form class="payRentForm" data-property-id="{{.id}}">
                    <div class="input-group mb-2">
                      <input type="number" class="form-control" step="0.01" placeholder="Amount (USDC)" required>
                      <button class="btn btn-success" type="submit">Pay</button>
                    </div>
                  </form>
                </div>

                <!-- Claim Rent Form -->
                <div class="mt-3 pt-3 border-top">
                  <h6>Claim Rent</h6>
                  <form class="claimRentForm" data-property-id="{{.id}}">
                    <div class="input-group mb-2">
                      <input type="number" class="form-control" placeholder="Your Shares" required>
                      <button class="btn btn-info" type="submit">Claim</button>
                    </div>
                  </form>
                </div>
              </div>
            </div>
          </div>
          {{end}}
        </div>
      {{else}}
        <div class="alert alert-info">No properties yet. Create one above!</div>
      {{end}}
    </div>

  </div>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
  <script>
    // Create Property
    document.getElementById('createPropertyForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      const formData = new FormData(e.target);
      try {
        const response = await fetch('/property/create', {
          method: 'POST',
          body: formData
        });
        const data = await response.json();
        const msg = document.getElementById('createMessage');
        msg.textContent = '✅ Property created successfully! Refresh to see it.';
        msg.style.display = 'block';
        e.target.reset();
        setTimeout(() => location.reload(), 2000);
      } catch (err) {
        alert('Error: ' + err.message);
      }
    });

    // Pay Rent
    document.querySelectorAll('.payRentForm').forEach(form => {
      form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const propertyId = form.dataset.propertyId;
        const amount = form.querySelector('input[type="number"]').value;
        const formData = new FormData();
        formData.append('property_id', propertyId);
        formData.append('amount', amount);
        
        try {
          const response = await fetch('/property/pay-rent', {
            method: 'POST',
            body: formData
          });
          const data = await response.json();
          alert('✅ Rent paid: ' + data.amount + ' USDC\nNew Pool: ' + data.new_total);
          location.reload();
        } catch (err) {
          alert('Error: ' + err.message);
        }
      });
    });

    // Claim Rent
    document.querySelectorAll('.claimRentForm').forEach(form => {
      form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const propertyId = form.dataset.propertyId;
        const holderShares = form.querySelector('input[type="number"]').value;
        const formData = new FormData();
        formData.append('property_id', propertyId);
        formData.append('holder_shares', holderShares);
        
        try {
          const response = await fetch('/property/claim-rent', {
            method: 'POST',
            body: formData
          });
          const data = await response.json();
          alert('✅ Rent claimed!\nAmount: ' + data.claimable_amount.toFixed(2) + ' USDC\nRemaining Pool: ' + data.remaining_pool);
          location.reload();
        } catch (err) {
          alert('Error: ' + err.message);
        }
      });
    });
  </script>
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