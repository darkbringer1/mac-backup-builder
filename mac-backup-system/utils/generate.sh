#!/bin/bash

# File generator from templates
set -e

MODE="${1:-install}"  # install or update
SCRIPTS_PATH="${HOME}/scripts"
BACKUP_CONFIG="${SCRIPTS_PATH}/.backup-config"

GREEN='\033[0;32m'
NC='\033[0m'

if [ "$MODE" = "update" ]; then
    echo -e "${GREEN}🔄 Updating scripts from templates...${NC}"
    
    # Load existing config
    source "$BACKUP_CONFIG"
    
    MAC_USER=$(whoami)
    FSWATCH_PATH=$(which fswatch)
    
    # Regenerate scripts
    sed -e "s|{{SCRIPTS_PATH}}|${SCRIPTS_PATH}|g" \
        templates/sync-folder.sh.tmpl > "${SCRIPTS_PATH}/sync-folder.sh"
    chmod +x "${SCRIPTS_PATH}/sync-folder.sh"
    
    sed -e "s|{{SCRIPTS_PATH}}|${SCRIPTS_PATH}|g" \
        -e "s|{{FSWATCH_PATH}}|${FSWATCH_PATH}|g" \
        templates/dump-watcher.sh.tmpl > "${SCRIPTS_PATH}/dump-watcher.sh"
    chmod +x "${SCRIPTS_PATH}/dump-watcher.sh"
    
    echo -e "${GREEN}✅ Scripts updated${NC}"
fi

# Add install mode logic if needed