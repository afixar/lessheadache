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
        
        # Download WP-CLI
        curl -sS -o wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
        
        # Download checksum
        curl -sS -o wp-cli.phar.sha512 https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar.sha512
        
        # Verify checksum
        if sha512sum -c wp-cli.phar.sha512 2>/dev/null; then
            log_info "WP-CLI checksum verified"
            chmod +x wp-cli.phar
            mv wp-cli.phar /usr/local/bin/wp
            rm -f wp-cli.phar.sha512
            log_info "WP-CLI installed successfully"
        else
            log_error "WP-CLI checksum verification failed"
            rm -f wp-cli.phar wp-cli.phar.sha512
            return 1
        fi
    else
        log_info "WP-CLI already installed"
    fi
    
    # Check for Imunify
    local imunify_path=""
    if [[ -x /usr/bin/imunify-antivirus ]]; then
        imunify_path="/usr/bin/imunify-antivirus"
        log_info "Imunify AV found"
    elif [[ -x /usr/bin/imunify360 ]]; then
        imunify_path="/usr/bin/imunify360"
        log_info "Imunify360 found"
    else
        log_warning "Imunify not found. Please install Imunify360 or Imunify AV separately."
        log_warning "Visit: https://www.imunify360.com/"
        imunify_path="/usr/bin/imunify-antivirus"  # Use default for config
    fi
    
    # Store the detected Imunify path for config update
    DETECTED_IMUNIFY_CLI="$imunify_path"
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
            
            # Update Imunify path if detected
            if [[ -n "$DETECTED_IMUNIFY_CLI" ]]; then
                sed -i "s|IMUNIFY_CLI=.*|IMUNIFY_CLI=\"$DETECTED_IMUNIFY_CLI\"|" "$CONFIG_DIR/config.conf"
            fi
            
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
    
    # Set up log rotation
    local logrotate_file="/etc/logrotate.d/lessheadache"
    
    cat > "$logrotate_file" << 'EOF'
/var/log/lessheadache.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
}
EOF
    
    chmod 644 "$logrotate_file"
    log_info "Log rotation configured at $logrotate_file"
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
