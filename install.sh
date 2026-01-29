#!/bin/bash

###############################################################################
# lessheadache Installation Script
# 
# Installs lessheadache on cPanel/WHM servers
###############################################################################

set -e

INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/lessheadache"
LOG_DIR="/var/log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

check_cpanel() {
    if [[ ! -d /usr/local/cpanel ]]; then
        log_warning "cPanel directory not found. This script is designed for cPanel/WHM servers."
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

install_dependencies() {
    log_info "Checking dependencies..."
    
    # Check for mailx/mail command
    if ! command -v mail &> /dev/null; then
        log_warning "mail command not found. Installing mailx..."
        if command -v yum &> /dev/null; then
            yum install -y mailx
        elif command -v apt-get &> /dev/null; then
            apt-get install -y mailutils
        fi
    fi
    
    # Check for WP-CLI
    if [[ ! -f /usr/local/bin/wp ]]; then
        log_info "Installing WP-CLI..."
        curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
        chmod +x wp-cli.phar
        mv wp-cli.phar /usr/local/bin/wp
        log_info "WP-CLI installed successfully"
    else
        log_info "WP-CLI already installed"
    fi
    
    # Check for Imunify
    if [[ ! -x /usr/bin/imunify-antivirus ]] && [[ ! -x /usr/bin/imunify360 ]]; then
        log_warning "Imunify not found. Please install Imunify360 or Imunify AV separately."
        log_warning "Visit: https://www.imunify360.com/"
    else
        log_info "Imunify found"
    fi
}

install_lessheadache() {
    log_info "Installing lessheadache..."
    
    # Create directories
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOG_DIR"
    
    # Copy main script
    cp "$SCRIPT_DIR/lessheadache.sh" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/lessheadache.sh"
    log_info "Installed lessheadache.sh to $INSTALL_DIR"
    
    # Copy configuration file if it doesn't exist
    if [[ ! -f "$CONFIG_DIR/config.conf" ]]; then
        if [[ -f "$SCRIPT_DIR/config.conf.example" ]]; then
            cp "$SCRIPT_DIR/config.conf.example" "$CONFIG_DIR/config.conf"
            log_info "Created configuration file at $CONFIG_DIR/config.conf"
            log_warning "Please edit $CONFIG_DIR/config.conf to set your email and other settings"
        fi
    else
        log_info "Configuration file already exists at $CONFIG_DIR/config.conf"
    fi
    
    # Create symlink for easier access
    if [[ ! -f /usr/local/bin/lessheadache ]]; then
        ln -s "$INSTALL_DIR/lessheadache.sh" /usr/local/bin/lessheadache
        log_info "Created symlink: /usr/local/bin/lessheadache"
    fi
}

setup_cron() {
    log_info "Setting up cron job..."
    
    local cron_file="/etc/cron.d/lessheadache"
    
    cat > "$cron_file" << 'EOF'
# lessheadache - Automated WordPress Security Monitoring
# Runs daily at 2:00 AM
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

0 2 * * * root /usr/local/bin/lessheadache >> /var/log/lessheadache.log 2>&1
EOF
    
    chmod 644 "$cron_file"
    log_info "Cron job installed at $cron_file"
    log_info "lessheadache will run daily at 2:00 AM"
}

show_next_steps() {
    cat << EOF

${GREEN}Installation completed successfully!${NC}

Next steps:
1. Edit the configuration file: $CONFIG_DIR/config.conf
   - Set your notification email address
   - Adjust other settings as needed

2. Test the installation:
   lessheadache --dry-run

3. Run manually:
   lessheadache

4. Monitor logs:
   tail -f /var/log/lessheadache.log

The cron job has been configured to run daily at 2:00 AM.

For help, run: lessheadache --help

EOF
}

main() {
    echo "lessheadache Installation Script"
    echo "================================"
    echo
    
    check_root
    check_cpanel
    install_dependencies
    install_lessheadache
    setup_cron
    show_next_steps
}

main "$@"
