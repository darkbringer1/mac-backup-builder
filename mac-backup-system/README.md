# Mac Backup System

Automated backup system for macOS that syncs folders and monitors a dump folder to a remote server.

## Features

- **Sync Folder**: Automatic bidirectional sync using Unison every 30 minutes
- **Dump Folder**: Real-time monitoring and automatic transfer of files using fswatch and rsync
- **Git Versioning**: Automatic git commits on the server for sync folder changes
- **LaunchAgent Integration**: Runs automatically on system startup

## Installation

1. Run the interactive installer:
```bash
make install
```

2. Follow the prompts to configure:
   - Server IP address
   - Server username
   - Server HDD mount path
   - Backup location on Mac (default: ~/Desktop/MacBackup)

3. Grant Full Disk Access to bash in System Settings → Privacy & Security

## Usage

### Commands

- `make install` - Install backup system (interactive)
- `make uninstall` - Remove backup system
- `make status` - Check service status
- `make logs` - View live logs
- `make test` - Run manual sync test
- `make clean` - Remove all backup data (CAREFUL!)

### Backup Folders

- **Sync Folder**: `~/Desktop/MacBackup/sync-folder` - Bidirectional sync
- **Dump Folder**: `~/Desktop/MacBackup/dump-folder` - One-way transfer (files removed after transfer)

## Architecture

- `templates/` - Template files with placeholders for installation
- `utils/` - Utility scripts for server setup
- Scripts are generated in `~/scripts/` during installation
- LaunchAgents are installed in `~/Library/LaunchAgents/`

## Requirements

- Homebrew
- fswatch (installed automatically)
- unison (installed automatically)
- SSH access to remote server

