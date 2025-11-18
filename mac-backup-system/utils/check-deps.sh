#!/bin/bash

# Dependency checker
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}📦 Checking dependencies...${NC}"

# Check Homebrew
if ! command -v brew >/dev/null 2>&1; then
    echo -e "${RED}❌ Homebrew required${NC}"
    echo "Install from: https://brew.sh"
    exit 1
fi

# Check/Install fswatch
if ! command -v fswatch >/dev/null 2>&1; then
    echo "  Installing fswatch..."
    brew install fswatch
fi

# Check/Install unison
if ! command -v unison >/dev/null 2>&1; then
    echo "  Installing unison..."
    brew install unison
fi

echo -e "${GREEN}✅ All dependencies installed${NC}"

# Export paths for other scripts
export FSWATCH_PATH=$(which fswatch)