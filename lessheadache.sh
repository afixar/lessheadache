#!/bin/bash

#############################################################
# lessheadache - Automated WordPress Incident Response
# 
# Integrates with Imunify to detect malware and automatically
# restore WordPress core files, fix permissions, and send
# email notifications on cPanel/WHM servers
#############################################################

VERSION="1.0.0"
CONFIG_FILE="${CONFIG_FILE:-/etc/lessheadache/config.conf}"
LOG_FILE="/var/log/lessheadache.log"
TEMP_DIR="/tmp/lessheadache_$$"

# Default configuration
IMUNIFY_CLI="/usr/bin/imunify-antivirus"
WP_CLI="/usr/local/bin/wp"
EMAIL_NOTIFICATIONS="true"
NOTIFICATION_EMAIL=""
DRY_RUN="false"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#############################################################
# Logging Functions
#############################################################

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case "$level" in
        ERROR)
            echo -e "${RED}[ERROR]${NC} $message" >&2
            ;;
        SUCCESS)
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        WARNING)
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        *)
            echo "[INFO] $message"
            ;;
    esac
}

#############################################################
# Configuration Functions
#############################################################

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log "INFO" "Loading configuration from $CONFIG_FILE"
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    else
        log "WARNING" "Configuration file not found at $CONFIG_FILE, using defaults"
    fi
}

#############################################################
# Imunify Integration
#############################################################

check_imunify_installed() {
    if [[ ! -x "$IMUNIFY_CLI" ]]; then
        log "ERROR" "Imunify not found at $IMUNIFY_CLI"
        return 1
    fi
    log "INFO" "Imunify found at $IMUNIFY_CLI"
    return 0
}

scan_for_malware() {
    local scan_path="$1"
    
    log "INFO" "Starting Imunify malware scan on $scan_path"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY RUN] Would scan: $scan_path"
        return 0
    fi
    
    # Run Imunify scan
    if check_imunify_installed; then
        if $IMUNIFY_CLI malware malicious list --json --limit 1000 > "$TEMP_DIR/malware_list.json" 2>&1; then
            log "SUCCESS" "Malware scan completed"
            return 0
        else
            log "ERROR" "Malware scan failed"
            return 1
        fi
    fi
    
    return 1
}

get_malware_files() {
    local wp_path="$1"
    
    if [[ ! -f "$TEMP_DIR/malware_list.json" ]]; then
        echo ""
        return
    fi
    
    # Parse malware list and filter for WordPress installation
    grep -o "\"path\":\"[^\"]*\"" "$TEMP_DIR/malware_list.json" | \
        cut -d'"' -f4 | \
        grep "^$wp_path" || echo ""
}

#############################################################
# WordPress Core Restoration
#############################################################

detect_wordpress_installations() {
    log "INFO" "Detecting WordPress installations..."
    
    # Find WordPress installations via wp-config.php
    local wp_installations=()
    
    # Search in common cPanel locations
    for user_dir in /home/*/public_html /home/*/www /home/*/htdocs; do
        if [[ -d "$user_dir" ]] && [[ -f "$user_dir/wp-config.php" ]]; then
            wp_installations+=("$user_dir")
        fi
        
        # Check subdirectories
        if [[ -d "$user_dir" ]]; then
            while IFS= read -r wp_config; do
                wp_dir=$(dirname "$wp_config")
                wp_installations+=("$wp_dir")
            done < <(find "$user_dir" -maxdepth 3 -name "wp-config.php" 2>/dev/null)
        fi
    done
    
    printf '%s\n' "${wp_installations[@]}" | sort -u
}

get_wordpress_version() {
    local wp_path="$1"
    
    if [[ -f "$wp_path/wp-includes/version.php" ]]; then
        grep "wp_version = " "$wp_path/wp-includes/version.php" | \
            cut -d"'" -f2 | head -1
    else
        echo "unknown"
    fi
}

restore_wordpress_core() {
    local wp_path="$1"
    local wp_version
    wp_version=$(get_wordpress_version "$wp_path")
    
    log "INFO" "Restoring WordPress core files for $wp_path (version: $wp_version)"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY RUN] Would restore WordPress core at: $wp_path"
        return 0
    fi
    
    # Check if WP-CLI is available
    if [[ ! -x "$WP_CLI" ]]; then
        log "ERROR" "WP-CLI not found at $WP_CLI, cannot restore core files"
        return 1
    fi
    
    # Restore core files using WP-CLI
    cd "$wp_path" || return 1
    
    local wp_user
    wp_user=$(stat -c '%U' "$wp_path")
    
    if sudo -u "$wp_user" "$WP_CLI" core verify-checksums --path="$wp_path" 2>&1 | tee -a "$LOG_FILE"; then
        log "SUCCESS" "WordPress core files verified for $wp_path"
    else
        log "WARNING" "Core file verification failed, attempting to restore..."
        
        # Download and restore core files
        if sudo -u "$wp_user" "$WP_CLI" core download --version="$wp_version" --force --path="$wp_path" 2>&1 | tee -a "$LOG_FILE"; then
            log "SUCCESS" "WordPress core files restored for $wp_path"
            return 0
        else
            log "ERROR" "Failed to restore WordPress core files for $wp_path"
            return 1
        fi
    fi
    
    return 0
}

#############################################################
# Permission Fixing
#############################################################

fix_wordpress_permissions() {
    local wp_path="$1"
    
    log "INFO" "Fixing permissions for $wp_path"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY RUN] Would fix permissions for: $wp_path"
        return 0
    fi
    
    # Get the owner of the WordPress installation
    local wp_owner
    local wp_group
    wp_owner=$(stat -c '%U' "$wp_path")
    wp_group=$(stat -c '%G' "$wp_path")
    
    log "INFO" "Setting owner to $wp_owner:$wp_group"
    
    # Fix ownership
    chown -R "$wp_owner:$wp_group" "$wp_path" 2>&1 | tee -a "$LOG_FILE"
    
    # Fix directory permissions (755)
    find "$wp_path" -type d -exec chmod 755 {} \; 2>&1 | tee -a "$LOG_FILE"
    
    # Fix file permissions (644)
    find "$wp_path" -type f -exec chmod 644 {} \; 2>&1 | tee -a "$LOG_FILE"
    
    # Special permissions for wp-config.php (600)
    if [[ -f "$wp_path/wp-config.php" ]]; then
        chmod 600 "$wp_path/wp-config.php" 2>&1 | tee -a "$LOG_FILE"
    fi
    
    # Writable directories
    for dir in wp-content/uploads wp-content/cache wp-content/backup; do
        if [[ -d "$wp_path/$dir" ]]; then
            chmod 755 "$wp_path/$dir" 2>&1 | tee -a "$LOG_FILE"
        fi
    done
    
    log "SUCCESS" "Permissions fixed for $wp_path"
    return 0
}

#############################################################
# Email Notifications
#############################################################

send_email_notification() {
    local subject="$1"
    local body="$2"
    
    if [[ "$EMAIL_NOTIFICATIONS" != "true" ]] || [[ -z "$NOTIFICATION_EMAIL" ]]; then
        log "INFO" "Email notifications disabled or no recipient configured"
        return 0
    fi
    
    log "INFO" "Sending email notification to $NOTIFICATION_EMAIL"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY RUN] Would send email: $subject"
        return 0
    fi
    
    # Send email using mail command
    if echo "$body" | mail -s "$subject" "$NOTIFICATION_EMAIL" 2>&1 | tee -a "$LOG_FILE"; then
        log "SUCCESS" "Email notification sent"
        return 0
    else
        log "ERROR" "Failed to send email notification"
        return 1
    fi
}

#############################################################
# Main Processing
#############################################################

process_wordpress_installation() {
    local wp_path="$1"
    local issues_found=0
    local issues_fixed=0
    local report=""
    
    log "INFO" "Processing WordPress installation at $wp_path"
    report+="WordPress Installation: $wp_path\n"
    report+="=====================================\n"
    
    # Scan for malware
    if scan_for_malware "$wp_path"; then
        local malware_files
        malware_files=$(get_malware_files "$wp_path")
        if [[ -n "$malware_files" ]]; then
            issues_found=$((issues_found + 1))
            report+="⚠ Malware detected:\n$malware_files\n\n"
        else
            report+="✓ No malware detected\n"
        fi
    fi
    
    # Restore WordPress core
    if restore_wordpress_core "$wp_path"; then
        issues_fixed=$((issues_fixed + 1))
        report+="✓ WordPress core files verified/restored\n"
    else
        issues_found=$((issues_found + 1))
        report+="⚠ Failed to restore WordPress core\n"
    fi
    
    # Fix permissions
    if fix_wordpress_permissions "$wp_path"; then
        issues_fixed=$((issues_fixed + 1))
        report+="✓ Permissions fixed\n"
    else
        issues_found=$((issues_found + 1))
        report+="⚠ Failed to fix permissions\n"
    fi
    
    report+="\nSummary: $issues_found issues found, $issues_fixed fixes applied\n"
    report+="=====================================\n\n"
    
    echo -e "$report"
    
    return 0
}

#############################################################
# Main Function
#############################################################

main() {
    local start_time
    start_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    log "INFO" "lessheadache v$VERSION starting..."
    
    # Create temp directory
    mkdir -p "$TEMP_DIR"
    
    # Load configuration
    load_config
    
    # Check prerequisites
    if ! check_imunify_installed; then
        log "WARNING" "Imunify not available, malware scanning will be skipped"
    fi
    
    # Detect WordPress installations
    mapfile -t wp_installations < <(detect_wordpress_installations)
    
    if [[ ${#wp_installations[@]} -eq 0 ]]; then
        log "WARNING" "No WordPress installations found"
        cleanup
        exit 0
    fi
    
    log "INFO" "Found ${#wp_installations[@]} WordPress installation(s)"
    
    # Process each installation
    local full_report=""
    full_report+="lessheadache Security Report\n"
    full_report+="Generated: $start_time\n"
    full_report+="=====================================\n\n"
    
    for wp_path in "${wp_installations[@]}"; do
        local install_report
        install_report=$(process_wordpress_installation "$wp_path")
        full_report+="$install_report"
    done
    
    # Send email notification
    if [[ -n "$NOTIFICATION_EMAIL" ]]; then
        send_email_notification "lessheadache Security Report - $(hostname)" "$full_report"
    fi
    
    # Cleanup
    cleanup
    
    local end_time
    end_time=$(date '+%Y-%m-%d %H:%M:%S')
    log "SUCCESS" "lessheadache completed. Started: $start_time, Ended: $end_time"
}

cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

#############################################################
# Command Line Interface
#############################################################

show_usage() {
    cat << EOF
lessheadache v$VERSION - Automated WordPress Incident Response

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -c, --config FILE      Configuration file (default: /etc/lessheadache/config.conf)
    -e, --email EMAIL      Notification email address
    -d, --dry-run          Perform a dry run without making changes
    -h, --help             Show this help message
    -v, --version          Show version information

EXAMPLES:
    # Run with default configuration
    $0

    # Perform a dry run
    $0 --dry-run

    # Use custom configuration and email
    $0 --config /path/to/config.conf --email admin@example.com

DESCRIPTION:
    lessheadache integrates with Imunify to detect malware and automatically
    restore WordPress core files, fix permissions, and send email notifications
    on cPanel/WHM servers. It should be run via cron for automated monitoring.

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -e|--email)
            NOTIFICATION_EMAIL="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN="true"
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -v|--version)
            echo "lessheadache v$VERSION"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    log "ERROR" "This script must be run as root"
    exit 1
fi

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Run main function
main

exit 0
