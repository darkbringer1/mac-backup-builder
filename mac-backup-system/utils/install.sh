#!/bin/bash

# Main installation script
set -e

# Import color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SCRIPTS_PATH="${HOME}/scripts"
BACKUP_CONFIG="${SCRIPTS_PATH}/.backup-config"

# Defaults
DEFAULT_BACKUP_PATH="${HOME}/Desktop/MacBackup"
DEFAULT_SYNC_FOLDER="sync-folder"
DEFAULT_DUMP_FOLDER="dump-folder"
DEFAULT_SSH_KEY="${HOME}/.ssh/backup_key"
DEFAULT_SYNC_INTERVAL="1800"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Mac Backup System Installer           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Check existing installation
if [ -f "$BACKUP_CONFIG" ]; then
    echo -e "${YELLOW}⚠️  Existing installation detected!${NC}"
    read -p "Reinstall? This will overwrite config (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Installation cancelled.${NC}"
        exit 1
    fi
fi

# Step 1: Check dependencies
source "${SCRIPT_DIR}/check-deps.sh"

# Step 2: Gather configuration
echo ""
echo -e "${GREEN}📋 Configuration${NC}"
echo ""

MAC_USER=$(whoami)

read -p "Mac backup location [${DEFAULT_BACKUP_PATH}]: " BACKUP_PATH
BACKUP_PATH=${BACKUP_PATH:-$DEFAULT_BACKUP_PATH}

read -p "Sync folder name [${DEFAULT_SYNC_FOLDER}]: " SYNC_FOLDER
SYNC_FOLDER=${SYNC_FOLDER:-$DEFAULT_SYNC_FOLDER}

read -p "Dump folder name [${DEFAULT_DUMP_FOLDER}]: " DUMP_FOLDER
DUMP_FOLDER=${DUMP_FOLDER:-$DEFAULT_DUMP_FOLDER}

read -p "Sync interval (seconds) [${DEFAULT_SYNC_INTERVAL}]: " SYNC_INTERVAL
SYNC_INTERVAL=${SYNC_INTERVAL:-$DEFAULT_SYNC_INTERVAL}

# Step 3: SSH Configuration
echo ""
echo -e "${GREEN}🔐 SSH Configuration${NC}"
echo ""

USE_EXISTING_SSH=false

if grep -q "Host backup-server" "${HOME}/.ssh/config" 2>/dev/null; then
    echo -e "${GREEN}✓ Found 'backup-server' in SSH config${NC}"
    SERVER_HOST="backup-server"
    SERVER_IP=$(grep -A 10 "Host backup-server" "${HOME}/.ssh/config" | grep "Hostname" | awk '{print $2}' | head -1)
    SERVER_USER=$(grep -A 10 "Host backup-server" "${HOME}/.ssh/config" | grep "User" | awk '{print $2}' | head -1)
    SSH_KEY_PATH=$(grep -A 10 "Host backup-server" "${HOME}/.ssh/config" | grep "IdentityFile" | awk '{print $2}' | head -1 | sed "s|~|${HOME}|")
    
    echo "  Server: ${SERVER_USER}@${SERVER_IP}"
    echo "  SSH Key: ${SSH_KEY_PATH}"
    
    read -p "Use this configuration? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        USE_EXISTING_SSH=true
    fi
fi

if [ "$USE_EXISTING_SSH" = "false" ]; then
    echo -e "${YELLOW}Setting up new SSH configuration...${NC}"
    echo ""
    
    read -p "Server IP address: " SERVER_IP
    read -p "Server username: " SERVER_USER
    SERVER_HOST="backup-server"
    SSH_KEY_PATH="$DEFAULT_SSH_KEY"
    
    # Generate SSH key if needed
    if [ ! -f "$SSH_KEY_PATH" ]; then
        echo -e "${YELLOW}Generating SSH key...${NC}"
        ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N ""
    fi
    
    # Copy SSH key
    echo -e "${YELLOW}Copying SSH key to server (enter password):${NC}"
    ssh-copy-id -i "$SSH_KEY_PATH" "${SERVER_USER}@${SERVER_IP}" || {
        echo -e "${RED}Failed to copy SSH key${NC}"
        exit 1
    }
    
    # Test connection
    echo -e "${YELLOW}Testing SSH connection...${NC}"
    if ! ssh -i "$SSH_KEY_PATH" -o BatchMode=yes "${SERVER_USER}@${SERVER_IP}" exit 2>/dev/null; then
        echo -e "${RED}❌ SSH connection failed${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ SSH connection successful${NC}"
    
    # Add to SSH config
    echo -e "${YELLOW}Adding to SSH config...${NC}"
    mkdir -p "${HOME}/.ssh"
    touch "${HOME}/.ssh/config"
    
    if ! grep -q "Host backup-server" "${HOME}/.ssh/config" 2>/dev/null; then
        cat >> "${HOME}/.ssh/config" <<EOF

# Mac Backup System
Host backup-server
    Hostname ${SERVER_IP}
    User ${SERVER_USER}
    PubKeyAuthentication yes
    IdentityFile ${SSH_KEY_PATH}
    IdentitiesOnly yes
EOF
    fi
fi

# Step 4: Server path
DEFAULT_SERVER_PATH="/mnt/hdd1"
read -p "Server HDD mount path [${DEFAULT_SERVER_PATH}]: " SERVER_PATH
SERVER_PATH=${SERVER_PATH:-$DEFAULT_SERVER_PATH}

# Step 5: Confirmation
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Configuration Summary:${NC}"
echo "  Mac User: ${MAC_USER}"
echo "  Backup Path: ${BACKUP_PATH}"
echo "  Sync Folder: ${SYNC_FOLDER}"
echo "  Dump Folder: ${DUMP_FOLDER}"
echo "  Server: ${SERVER_USER}@${SERVER_IP}"
echo "  Server Path: ${SERVER_PATH}"
echo "  SSH Key: ${SSH_KEY_PATH}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

read -p "Continue? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Installation cancelled.${NC}"
    exit 1
fi

# Step 6: Installation
echo ""
echo -e "${GREEN}🚀 Installing...${NC}"
echo ""

# Create directories
echo -e "${GREEN}📁 Creating directories...${NC}"
mkdir -p "${BACKUP_PATH}/${SYNC_FOLDER}"
mkdir -p "${BACKUP_PATH}/${DUMP_FOLDER}"
mkdir -p "${BACKUP_PATH}/.logs"
mkdir -p "${SCRIPTS_PATH}"

# Setup server
echo -e "${GREEN}🖥️  Setting up server...${NC}"
ssh backup-server "mkdir -p ${SERVER_PATH}/mac-backup/{${SYNC_FOLDER},${DUMP_FOLDER}}" || {
    echo -e "${RED}Failed to create server directories${NC}"
    exit 1
}

# Generate config file
echo -e "${GREEN}📝 Generating configuration...${NC}"
INSTALL_DATE=$(date "+%Y-%m-%d %H:%M:%S")

sed -e "s|{{INSTALL_DATE}}|${INSTALL_DATE}|g" \
    -e "s|{{SERVER_IP}}|${SERVER_IP}|g" \
    -e "s|{{SERVER_USER}}|${SERVER_USER}|g" \
    -e "s|{{SERVER_HOST}}|${SERVER_HOST}|g" \
    -e "s|{{SERVER_PATH}}|${SERVER_PATH}|g" \
    -e "s|{{BACKUP_PATH}}|${BACKUP_PATH}|g" \
    -e "s|{{SYNC_FOLDER_NAME}}|${SYNC_FOLDER}|g" \
    -e "s|{{DUMP_FOLDER_NAME}}|${DUMP_FOLDER}|g" \
    -e "s|{{SSH_KEY_PATH}}|${SSH_KEY_PATH}|g" \
    "${PROJECT_ROOT}/templates/backup-config.tmpl" > "${BACKUP_CONFIG}"

# Generate scripts
echo -e "${GREEN}📜 Generating scripts...${NC}"

sed -e "s|{{SCRIPTS_PATH}}|${SCRIPTS_PATH}|g" \
    "${PROJECT_ROOT}/templates/sync-folder.sh.tmpl" > "${SCRIPTS_PATH}/sync-folder.sh"
chmod +x "${SCRIPTS_PATH}/sync-folder.sh"

sed -e "s|{{SCRIPTS_PATH}}|${SCRIPTS_PATH}|g" \
    -e "s|{{FSWATCH_PATH}}|${FSWATCH_PATH}|g" \
    "${PROJECT_ROOT}/templates/dump-watcher.sh.tmpl" > "${SCRIPTS_PATH}/dump-watcher.sh"
chmod +x "${SCRIPTS_PATH}/dump-watcher.sh"

# Generate plists
echo -e "${GREEN}🚀 Installing LaunchAgents...${NC}"

sed -e "s|{{MAC_USER}}|${MAC_USER}|g" \
    -e "s|{{SCRIPTS_PATH}}|${SCRIPTS_PATH}|g" \
    -e "s|{{BACKUP_PATH}}|${BACKUP_PATH}|g" \
    -e "s|{{SYNC_INTERVAL}}|${SYNC_INTERVAL}|g" \
    -e "s|{{HOME}}|${HOME}|g" \
    "${PROJECT_ROOT}/templates/sync.plist.tmpl" > "${HOME}/Library/LaunchAgents/com.${MAC_USER}.HomeServerSync.plist"

sed -e "s|{{MAC_USER}}|${MAC_USER}|g" \
    -e "s|{{SCRIPTS_PATH}}|${SCRIPTS_PATH}|g" \
    -e "s|{{BACKUP_PATH}}|${BACKUP_PATH}|g" \
    -e "s|{{HOME}}|${HOME}|g" \
    "${PROJECT_ROOT}/templates/dump.plist.tmpl" > "${HOME}/Library/LaunchAgents/com.${MAC_USER}.HomeServerDump.plist"

# Prompt for Full Disk Access
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Grant Full Disk Access${NC}"
echo ""
echo -e "1. Open ${BOLD}System Settings → Privacy & Security → Full Disk Access${NC}"
echo -e "2. Click the ${GREEN}+${NC} button"
echo -e "3. Press ${BOLD}Cmd+Shift+G${NC} and type: ${YELLOW}/bin/bash${NC}"
echo -e "4. Add it and toggle ${GREEN}ON${NC}"
echo ""
read -p "Press Enter when completed..." dummy
echo ""

# Load services
echo -e "${GREEN}🔄 Loading services...${NC}"
launchctl load "${HOME}/Library/LaunchAgents/com.${MAC_USER}.HomeServerSync.plist" 2>/dev/null || true
launchctl load "${HOME}/Library/LaunchAgents/com.${MAC_USER}.HomeServerDump.plist" 2>/dev/null || true
sleep 2

# Done
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}" 
echo -e "${GREEN}║          ✅ Installation Complete!         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📁 Backup folders:${NC}"
echo "  Sync: ${BACKUP_PATH}/${SYNC_FOLDER}"
echo "  Dump: ${BACKUP_PATH}/${DUMP_FOLDER}"
echo ""
echo -e "${BLUE}📖 Commands:${NC}"
echo -e "  ${CYAN}make status${NC}  - Check services"
echo -e "  ${CYAN}make logs${NC}    - View logs"
echo -e "  ${CYAN}make test${NC}    - Test sync"
echo ""