.PHONY: help install uninstall reinstall update status logs test clean config server-setup icloud

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
CYAN := \033[0;36m
BOLD := \033[1m
NC := \033[0m

# Paths
SCRIPTS_PATH := $(HOME)/scripts
BACKUP_CONFIG := $(SCRIPTS_PATH)/.backup-config

help:
	@echo ""
	@echo "$(BLUE)╔════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║     Mac Backup System                      ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)Available commands:$(NC)"
	@echo "  $(CYAN)make install$(NC)       - Interactive installation"
	@echo "  $(CYAN)make uninstall$(NC)     - Remove services (keep data)"
	@echo "  $(CYAN)make reinstall$(NC)     - Uninstall and reinstall"
	@echo "  $(CYAN)make update$(NC)        - Update scripts only"
	@echo "  $(CYAN)make status$(NC)        - Check service status"
	@echo "  $(CYAN)make logs$(NC)          - View live logs"
	@echo "  $(CYAN)make test$(NC)          - Test sync manually"
	@echo "  $(CYAN)make config$(NC)        - Edit configuration"
	@echo "  $(CYAN)make icloud$(NC)        - Manage iCloud Drive folders"
	@echo "  $(CYAN)make clean$(NC)         - Remove everything"
	@echo "  $(CYAN)make server-setup$(NC)  - Setup Ubuntu server"
	@echo ""

# ============================================================================
# Installation
# ============================================================================

install:
	@bash utils/install.sh

reinstall: uninstall install

# ============================================================================
# Uninstallation
# ============================================================================

uninstall:
	@echo ""
	@echo "$(RED)⚠️  Uninstalling Mac Backup System$(NC)"
	@echo ""
	@MAC_USER=$$(whoami); \
	read -p "Remove services but keep backup data? (y/n): " -n 1 -r; \
	echo ""; \
	if [[ ! $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "$(YELLOW)Cancelled.$(NC)"; \
		exit 1; \
	fi; \
	echo "$(YELLOW)Stopping services...$(NC)"; \
	launchctl unload "$$HOME/Library/LaunchAgents/com.$$MAC_USER.HomeServerSync.plist" 2>/dev/null || true; \
	launchctl unload "$$HOME/Library/LaunchAgents/com.$$MAC_USER.HomeServerDump.plist" 2>/dev/null || true; \
	rm -f "$$HOME/Library/LaunchAgents/com.$$MAC_USER.HomeServerSync.plist"; \
	rm -f "$$HOME/Library/LaunchAgents/com.$$MAC_USER.HomeServerDump.plist"; \
	echo "$(GREEN)✅ Services removed$(NC)"; \
	echo ""; \
	echo "$(YELLOW)To remove all data: make clean$(NC)"; \
	echo ""

clean:
	@echo ""
	@echo "$(RED)⚠️  WARNING: This will delete ALL backup data!$(NC)"
	@echo ""
	@read -p "Type 'DELETE' to confirm: " confirm; \
	if [ "$$confirm" != "DELETE" ]; then \
		echo "$(YELLOW)Cancelled.$(NC)"; \
		exit 1; \
	fi; \
	$(MAKE) uninstall || true; \
	if [ -f "$(BACKUP_CONFIG)" ]; then \
		source "$(BACKUP_CONFIG)"; \
		rm -rf "$$BACKUP_LOCATION"; \
	fi; \
	rm -f "$(SCRIPTS_PATH)/sync-folder.sh"; \
	rm -f "$(SCRIPTS_PATH)/dump-watcher.sh"; \
	rm -f "$(BACKUP_CONFIG)"; \
	echo "$(GREEN)✅ All data removed$(NC)"; \
	echo ""

# ============================================================================
# Updates and Utilities
# ============================================================================

update:
	@if [ ! -f "$(BACKUP_CONFIG)" ]; then \
		echo "$(RED)No installation found. Run 'make install' first.$(NC)"; \
		exit 1; \
	fi
	@bash utils/generate.sh update

config:
	@if [ ! -f "$(BACKUP_CONFIG)" ]; then \
		echo "$(RED)No installation found.$(NC)"; \
		exit 1; \
	fi
	@$$EDITOR "$(BACKUP_CONFIG)"
	@read -p "Reload services? (y/n): " -n 1 -r; \
	echo ""; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		MAC_USER=$$(whoami); \
		launchctl unload "$$HOME/Library/LaunchAgents/com.$$MAC_USER.HomeServer*.plist" 2>/dev/null || true; \
		launchctl load "$$HOME/Library/LaunchAgents/com.$$MAC_USER.HomeServer*.plist"; \
		echo "$(GREEN)✅ Services reloaded$(NC)"; \
	fi

icloud:
	@bash utils/icloud-manager.sh

# ============================================================================
# Monitoring and Testing
# ============================================================================

status:
	@echo ""
	@echo "$(BLUE)Service Status:$(NC)"
	@MAC_USER=$$(whoami); \
	launchctl list | grep "com.$$MAC_USER.HomeServer" || echo "$(YELLOW)No services running$(NC)"
	@echo ""

logs:
	@if [ ! -f "$(BACKUP_CONFIG)" ]; then \
		echo "$(RED)No installation found$(NC)"; \
		exit 1; \
	fi
	@source "$(BACKUP_CONFIG)"; \
	tail -f "$$BACKUP_LOCATION/.logs"/*.log 2>/dev/null || echo "$(YELLOW)No logs found$(NC)"

test:
	@if [ ! -f "$(BACKUP_CONFIG)" ]; then \
		echo "$(RED)No installation found$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Running manual sync...$(NC)"
	@$(SCRIPTS_PATH)/sync-folder.sh
	@echo "$(GREEN)✅ Check logs: make logs$(NC)"

# ============================================================================
# Server Setup
# ============================================================================

server-setup:
	@echo "$(BLUE)Running server setup...$(NC)"
	@if [ ! -f "utils/server-setup.sh" ]; then \
		echo "$(RED)Server setup script not found$(NC)"; \
		exit 1; \
	fi
	@scp utils/server-setup.sh backup-server:/tmp/
	@ssh backup-server "bash /tmp/server-setup.sh"
	@echo "$(GREEN)✅ Server setup complete$(NC)"