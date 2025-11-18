#!/bin/bash

# Optional server setup script
# This script can be run on the remote server to prepare it for backups
# Run this script on the server before installing the Mac backup system

set -e

echo "╔═══════════════════════════════════════╗"
echo "║   Mac Backup System - Server Setup   ║"
echo "╚═══════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  This script should be run as root or with sudo"
    exit 1
fi

# Get server configuration
read -p "Enter HDD mount path (e.g., /mnt/hdd1): " SERVER_HDD
read -p "Enter backup user (default: current user): " BACKUP_USER
BACKUP_USER=${BACKUP_USER:-$(whoami)}

# Create backup directories
echo ""
echo "📁 Creating backup directories..."
mkdir -p "$SERVER_HDD/mac-backup/sync-folder"
mkdir -p "$SERVER_HDD/mac-backup/dump-folder"

# Set ownership
chown -R "$BACKUP_USER:$BACKUP_USER" "$SERVER_HDD/mac-backup"

# Set permissions
chmod 755 "$SERVER_HDD/mac-backup"
chmod 755 "$SERVER_HDD/mac-backup/sync-folder"
chmod 755 "$SERVER_HDD/mac-backup/dump-folder"

echo "✅ Directories created"
echo ""

# Install git if not present (needed for sync folder versioning)
if ! command -v git &> /dev/null; then
    echo "📦 Installing git..."
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y git
    elif command -v yum &> /dev/null; then
        yum install -y git
    elif command -v pacman &> /dev/null; then
        pacman -S --noconfirm git
    else
        echo "⚠️  Package manager not detected. Please install git manually."
    fi
    echo "✅ Git installed"
    echo ""
fi

# Verify SSH access
echo "🔑 Testing SSH access..."
if [ -f "/home/$BACKUP_USER/.ssh/authorized_keys" ]; then
    echo "✅ SSH authorized_keys file exists"
else
    echo "⚠️  SSH authorized_keys file not found"
    echo "   Make sure to add the Mac's SSH public key during installation"
fi
echo ""

echo "╔═══════════════════════════════════════╗"
echo "║   ✅ Server Setup Complete!          ║"
echo "╚═══════════════════════════════════════╝"
echo ""
echo "Backup directories created at:"
echo "  Sync: $SERVER_HDD/mac-backup/sync-folder"
echo "  Dump: $SERVER_HDD/mac-backup/dump-folder"
echo ""
echo "You can now run the installer on your Mac."

