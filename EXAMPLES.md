# Usage Examples

This document provides detailed usage examples for lessheadache.

## Basic Usage

### 1. Initial Setup

After installation, edit the configuration file:

```bash
sudo nano /etc/lessheadache/config.conf
```

Set your email address:
```bash
NOTIFICATION_EMAIL="security@yourdomain.com"
```

### 2. First Run (Dry Run)

Before running for real, perform a dry run to see what would happen:

```bash
sudo lessheadache --dry-run
```

This will:
- Detect all WordPress installations
- Show what malware scans would be performed
- Show what core files would be restored
- Show what permission fixes would be applied
- But NOT make any actual changes

### 3. Manual Execution

Run the security scan and remediation:

```bash
sudo lessheadache
```

### 4. Custom Configuration

Use a custom configuration file:

```bash
sudo lessheadache --config /path/to/custom-config.conf
```

### 5. Override Email

Override the email address without editing the config:

```bash
sudo lessheadache --email admin@example.com
```

## Advanced Usage

### Monitoring Logs

View live logs during execution:
```bash
tail -f /var/log/lessheadache.log
```

View logs with color highlighting (if ccze is installed):
```bash
tail -f /var/log/lessheadache.log | ccze -A
```

Search logs for errors:
```bash
grep ERROR /var/log/lessheadache.log
```

Search logs for a specific date:
```bash
grep "2024-01-29" /var/log/lessheadache.log
```

### Cron Job Management

View the cron job:
```bash
cat /etc/cron.d/lessheadache
```

Edit the cron schedule:
```bash
sudo nano /etc/cron.d/lessheadache
```

Example cron schedules:
```bash
# Run every 6 hours
0 */6 * * * root /usr/local/bin/lessheadache >> /var/log/lessheadache.log 2>&1

# Run twice a day (2 AM and 2 PM)
0 2,14 * * * root /usr/local/bin/lessheadache >> /var/log/lessheadache.log 2>&1

# Run every Monday at 3 AM
0 3 * * 1 root /usr/local/bin/lessheadache >> /var/log/lessheadache.log 2>&1
```

### Testing Imunify Integration

Check if Imunify is installed and working:
```bash
/usr/bin/imunify-antivirus version
```

List malware manually:
```bash
/usr/bin/imunify-antivirus malware malicious list
```

### Testing WordPress Core Restoration

Check WordPress core file integrity manually:
```bash
cd /home/username/public_html
sudo -u username wp core verify-checksums
```

### Testing Email Notifications

Test if the mail command works:
```bash
echo "Test email body" | mail -s "Test Subject" admin@example.com
```

## Integration Examples

### Integration with WHM/cPanel Scripts

Create a post-account-creation hook:
```bash
#!/bin/bash
# /usr/local/cpanel/scripts/postwwwacct

# Run lessheadache after new account creation
/usr/local/bin/lessheadache --dry-run
```

### Integration with Custom Monitoring

Pipe lessheadache output to your monitoring system:
```bash
lessheadache 2>&1 | /path/to/monitoring-agent
```

### Integration with Slack/Discord Webhooks

Modify the email notification function to also send to webhooks:
```bash
# Add to config.conf
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

## Troubleshooting Examples

### Check WordPress Installations

List all WordPress installations that will be processed:
```bash
# Run in dry-run mode and grep for WordPress paths
lessheadache --dry-run 2>&1 | grep "Processing WordPress"
```

### Debug Permission Issues

Check current permissions:
```bash
# Check specific WordPress installation
ls -la /home/username/public_html/
```

### Test WP-CLI

Verify WP-CLI is working:
```bash
wp --info
```

Test WP-CLI with specific user:
```bash
sudo -u username wp --path=/home/username/public_html core version
```

## Security Best Practices

### 1. Review Changes Before Automating

Always run with `--dry-run` first:
```bash
lessheadache --dry-run > /tmp/lessheadache-dryrun.log 2>&1
less /tmp/lessheadache-dryrun.log
```

### 2. Schedule During Low Traffic

Run during off-peak hours:
```bash
# Schedule for 3 AM when traffic is typically low
0 3 * * * root /usr/local/bin/lessheadache >> /var/log/lessheadache.log 2>&1
```

### 3. Backup Before Automation

Ensure you have backups:
```bash
# Create backup before running lessheadache
/usr/local/cpanel/bin/backup --force
lessheadache
```

### 4. Monitor After Changes

After running lessheadache, check:
- Website functionality
- WordPress admin access
- File permissions
- Logs for errors

### 5. Keep Configuration Secure

Protect the configuration file:
```bash
chmod 600 /etc/lessheadache/config.conf
chown root:root /etc/lessheadache/config.conf
```

## Multi-Server Deployment

### Using SSH for Multiple Servers

Deploy to multiple servers:
```bash
#!/bin/bash
SERVERS="server1.example.com server2.example.com server3.example.com"

for server in $SERVERS; do
    echo "Deploying to $server..."
    ssh root@$server "curl -sL https://github.com/afixar/lessheadache/archive/main.tar.gz | tar xz && cd lessheadache-main && ./install.sh"
done
```

### Centralized Logging

Forward logs to central server:
```bash
# On each server, add to rsyslog configuration
echo "/var/log/lessheadache.log @logserver.example.com:514" >> /etc/rsyslog.conf
systemctl restart rsyslog
```

## Example Output

### Successful Run
```
[INFO] lessheadache v1.0.0 starting...
[INFO] Loading configuration from /etc/lessheadache/config.conf
[INFO] Imunify found at /usr/bin/imunify-antivirus
[INFO] Found 3 WordPress installation(s)
[INFO] Processing WordPress installation at /home/user1/public_html
[SUCCESS] Malware scan completed
[SUCCESS] WordPress core files verified/restored
[SUCCESS] Permissions fixed
[INFO] Processing WordPress installation at /home/user2/public_html
[SUCCESS] Malware scan completed
[SUCCESS] WordPress core files verified/restored
[SUCCESS] Permissions fixed
[SUCCESS] Email notification sent
[SUCCESS] lessheadache completed. Started: 2024-01-29 02:00:00, Ended: 2024-01-29 02:05:23
```

### Dry Run Output
```
[INFO] lessheadache v1.0.0 starting...
[DRY RUN] Would scan: /home/user1/public_html
[DRY RUN] Would restore WordPress core at: /home/user1/public_html
[DRY RUN] Would fix permissions for: /home/user1/public_html
[DRY RUN] Would send email: lessheadache Security Report
```
