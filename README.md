# lessheadache

Automated incident response toolkit for WordPress servers using Imunify. Restores WordPress core, fixes permissions and runs security remediation automatically via cron on cPanel/WHM environments.

## Features

- **Imunify Integration**: Automatically scans for malware using Imunify360 or Imunify AV
- **WordPress Core Restoration**: Verifies and restores WordPress core files using WP-CLI
- **Permission Fixing**: Automatically fixes file and directory permissions to secure defaults
- **Email Notifications**: Sends detailed security reports via email
- **Cron Automation**: Runs scheduled security checks automatically
- **cPanel/WHM Optimized**: Designed specifically for cPanel/WHM hosting environments

## Requirements

- **Operating System**: Linux (CentOS, RHEL, CloudLinux, Ubuntu, Debian)
- **Control Panel**: cPanel/WHM (recommended)
- **Root Access**: Required for installation and execution
- **Imunify**: Imunify360 or Imunify AV must be installed
- **Mail**: mailx or mail command for email notifications
- **WP-CLI**: Will be installed automatically if not present

## Installation

1. Clone this repository or download the files:
```bash
git clone https://github.com/afixar/lessheadache.git
cd lessheadache
```

2. Run the installation script as root:
```bash
sudo ./install.sh
```

3. Edit the configuration file:
```bash
sudo nano /etc/lessheadache/config.conf
```

4. Set your notification email and adjust other settings as needed.

## Configuration

Edit `/etc/lessheadache/config.conf` to customize settings:

```bash
# Email address to receive notifications
NOTIFICATION_EMAIL="admin@example.com"

# Enable/disable email notifications
EMAIL_NOTIFICATIONS="true"

# Path to Imunify CLI
IMUNIFY_CLI="/usr/bin/imunify-antivirus"

# Path to WP-CLI
WP_CLI="/usr/local/bin/wp"

# Dry run mode (test without making changes)
DRY_RUN="false"
```

## Usage

### Run Manually

Test with a dry run (no changes will be made):
```bash
lessheadache --dry-run
```

Run the security scan and remediation:
```bash
lessheadache
```

Run with a specific email address:
```bash
lessheadache --email admin@example.com
```

Use a custom configuration file:
```bash
lessheadache --config /path/to/config.conf
```

### Automated Execution via Cron

The installation script automatically sets up a cron job that runs daily at 2:00 AM. The cron job is located at `/etc/cron.d/lessheadache`.

To modify the schedule, edit:
```bash
sudo nano /etc/cron.d/lessheadache
```

### Command Line Options

```
lessheadache [OPTIONS]

OPTIONS:
    -c, --config FILE      Configuration file (default: /etc/lessheadache/config.conf)
    -e, --email EMAIL      Notification email address
    -d, --dry-run          Perform a dry run without making changes
    -h, --help             Show help message
    -v, --version          Show version information
```

## How It Works

1. **Detection**: Scans for WordPress installations in common cPanel locations
2. **Malware Scanning**: Uses Imunify to identify infected files
3. **Core Restoration**: Verifies WordPress core file integrity and restores if needed
4. **Permission Fixing**: Sets proper ownership and permissions (755 for directories, 644 for files)
5. **Reporting**: Generates a detailed report and sends it via email
6. **Logging**: All actions are logged to `/var/log/lessheadache.log`

## Security Report

After each run, lessheadache generates a security report that includes:

- WordPress installations found
- Malware detection results
- Core file verification status
- Permission fixes applied
- Summary of issues found and fixed

## Monitoring Logs

View real-time logs:
```bash
tail -f /var/log/lessheadache.log
```

View recent activity:
```bash
cat /var/log/lessheadache.log
```

## Troubleshooting

### Imunify Not Found
If you see "Imunify not found" errors, ensure Imunify360 or Imunify AV is installed:
- Visit https://www.imunify360.com/ for installation instructions
- Verify installation: `/usr/bin/imunify-antivirus version`

### WP-CLI Not Found
WP-CLI should be installed automatically. If not, install manually:
```bash
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
```

### Email Notifications Not Working
- Ensure the mail command is installed: `which mail`
- Install if needed: `yum install mailx` (CentOS/RHEL) or `apt-get install mailutils` (Ubuntu/Debian)
- Check your server's mail configuration

### Permission Denied Errors
Ensure you're running the script as root:
```bash
sudo lessheadache
```

## Uninstallation

To remove lessheadache:

```bash
# Remove the main script
sudo rm /usr/local/bin/lessheadache.sh
sudo rm /usr/local/bin/lessheadache

# Remove the cron job
sudo rm /etc/cron.d/lessheadache

# Remove configuration (optional)
sudo rm -rf /etc/lessheadache

# Remove logs (optional)
sudo rm /var/log/lessheadache.log
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

See LICENSE file for details.

## Support

For issues and questions, please open an issue on GitHub.

## Disclaimer

This tool is provided as-is. Always test in a development environment before using in production. Make sure you have proper backups before running automated security remediation tools.
