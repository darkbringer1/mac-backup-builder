#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPTS_PATH="$HOME/scripts"
ICLOUD_CONFIG="$SCRIPTS_PATH/.icloud-folders"
ICLOUD_BASE="$HOME/Library/Mobile Documents/com~apple~CloudDocs"

# Ensure config exists
mkdir -p "$SCRIPTS_PATH"
touch "$ICLOUD_CONFIG"

# List currently watched folders
list_folders() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     iCloud Drive → Server Bridge          ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ ! -s "$ICLOUD_CONFIG" ]; then
        echo -e "${YELLOW}No folders configured yet${NC}"
        echo ""
        return
    fi
    
    echo -e "${GREEN}Watched folders:${NC}"
    local count=0
    while IFS= read -r folder; do
        [[ -z "$folder" ]] && continue
        [[ "$folder" =~ ^# ]] && continue
        count=$((count + 1))
        echo -e "  ${CYAN}$count.${NC} $folder"
    done < "$ICLOUD_CONFIG"
    echo ""
}

# Browse and select folders interactively
browse_folders() {
    echo ""
    echo -e "${BLUE}Browsing iCloud Drive...${NC}"
    echo ""
    
    if [ ! -d "$ICLOUD_BASE" ]; then
        echo -e "${RED}iCloud Drive not found at: $ICLOUD_BASE${NC}"
        exit 1
    fi
    
    # List folders in iCloud Drive
    local folders=()
    while IFS= read -r -d '' folder; do
        local rel_path="${folder#$ICLOUD_BASE/}"
        # Skip system folders
        [[ "$rel_path" =~ ^\. ]] && continue
        [[ "$rel_path" =~ ^com~ ]] && continue
        folders+=("$rel_path")
    done < <(find "$ICLOUD_BASE" -mindepth 1 -maxdepth 3 -type d -print0 2>/dev/null | sort -z)
    
    if [ ${#folders[@]} -eq 0 ]; then
        echo -e "${YELLOW}No folders found in iCloud Drive${NC}"
        exit 0
    fi
    
    echo -e "${GREEN}Available folders:${NC}"
    for i in "${!folders[@]}"; do
        echo -e "  ${CYAN}$((i+1)).${NC} ${folders[$i]}"
    done
    echo ""
    
    # Selection loop
    while true; do
        echo -e "${YELLOW}Enter number(s) to add (comma-separated), 'a' for all, 'q' to quit:${NC}"
        read -r selection
        
        [[ "$selection" == "q" ]] && break
        
        if [[ "$selection" == "a" ]]; then
            for folder in "${folders[@]}"; do
                if ! grep -Fxq "$folder" "$ICLOUD_CONFIG" 2>/dev/null; then
                    echo "$folder" >> "$ICLOUD_CONFIG"
                    echo -e "${GREEN}✓ Added: $folder${NC}"
                fi
            done
            break
        fi
        
        # Parse comma-separated numbers
        IFS=',' read -ra nums <<< "$selection"
        for num in "${nums[@]}"; do
            num=$(echo "$num" | xargs)  # Trim whitespace
            if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#folders[@]}" ]; then
                local folder="${folders[$((num-1))]}"
                if grep -Fxq "$folder" "$ICLOUD_CONFIG" 2>/dev/null; then
                    echo -e "${YELLOW}Already watching: $folder${NC}"
                else
                    echo "$folder" >> "$ICLOUD_CONFIG"
                    echo -e "${GREEN}✓ Added: $folder${NC}"
                fi
            else
                echo -e "${RED}Invalid selection: $num${NC}"
            fi
        done
        break
    done
    echo ""
}

# Remove a watched folder
remove_folder() {
    list_folders
    
    if [ ! -s "$ICLOUD_CONFIG" ]; then
        return
    fi
    
    echo -e "${YELLOW}Enter number to remove (or 'q' to cancel):${NC}"
    read -r selection
    
    [[ "$selection" == "q" ]] && return
    
    if [[ "$selection" =~ ^[0-9]+$ ]]; then
        local line_num=0
        local target_line=0
        while IFS= read -r folder; do
            [[ -z "$folder" ]] && continue
            [[ "$folder" =~ ^# ]] && continue
            line_num=$((line_num + 1))
            if [ "$line_num" -eq "$selection" ]; then
                target_line=$(grep -n "^$folder$" "$ICLOUD_CONFIG" | head -1 | cut -d: -f1)
                break
            fi
        done < "$ICLOUD_CONFIG"
        
        if [ "$target_line" -gt 0 ]; then
            sed -i.bak "${target_line}d" "$ICLOUD_CONFIG"
            rm -f "$ICLOUD_CONFIG.bak"
            echo -e "${GREEN}✓ Removed${NC}"
        else
            echo -e "${RED}Invalid selection${NC}"
        fi
    else
        echo -e "${RED}Invalid input${NC}"
    fi
    echo ""
}

# Enable/disable the bridge
toggle_bridge() {
    local config_file="$SCRIPTS_PATH/.backup-config"
    
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}Backup config not found. Run 'make install' first.${NC}"
        exit 1
    fi
    
    source "$config_file"
    
    if [ "$ICLOUD_BRIDGE_ENABLED" == "true" ]; then
        echo -e "${YELLOW}Disabling iCloud bridge...${NC}"
        sed -i.bak 's/ICLOUD_BRIDGE_ENABLED=.*/ICLOUD_BRIDGE_ENABLED=false/' "$config_file"
        echo -e "${GREEN}✓ Disabled${NC}"
    else
        echo -e "${GREEN}Enabling iCloud bridge...${NC}"
        if grep -q "ICLOUD_BRIDGE_ENABLED" "$config_file"; then
            sed -i.bak 's/ICLOUD_BRIDGE_ENABLED=.*/ICLOUD_BRIDGE_ENABLED=true/' "$config_file"
        else
            echo "ICLOUD_BRIDGE_ENABLED=true" >> "$config_file"
        fi
        echo -e "${GREEN}✓ Enabled${NC}"
    fi
    rm -f "$config_file.bak"
    echo ""
}

# Main menu
show_menu() {
    while true; do
        list_folders
        echo -e "${CYAN}Commands:${NC}"
        echo -e "  ${BOLD}1${NC} - Browse & add folders"
        echo -e "  ${BOLD}2${NC} - Remove a folder"
        echo -e "  ${BOLD}3${NC} - Enable/disable bridge"
        echo -e "  ${BOLD}q${NC} - Quit"
        echo ""
        echo -e "${YELLOW}Choose an option:${NC}"
        read -r choice
        
        case "$choice" in
            1) browse_folders ;;
            2) remove_folder ;;
            3) toggle_bridge ;;
            q) break ;;
            *) echo -e "${RED}Invalid option${NC}" ;;
        esac
    done
}

# Run menu
show_menu

