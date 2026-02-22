#!/bin/bash

echo "🛑 Stopping RWA Rental DApp..."

# Kill Anvil
pkill -f "anvil"
if [ $? -eq 0 ]; then
    echo "✅ Anvil stopped"
else
    echo "⚠️  Anvil not running"
fi

# Kill Go backend
pkill -f "go run main.go"
if [ $? -eq 0 ]; then
    echo "✅ Backend stopped"
else
    echo "⚠️  Backend not running"
fi

# Optional: Kill any gnome-terminal windows (if using start-all.sh)
# pkill -f "gnome-terminal"

echo "🛑 All services stopped!"
