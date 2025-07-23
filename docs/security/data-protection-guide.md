# Data Protection and Security Guide

## Security Architecture Overview

Claude Code Mobile implements a comprehensive security architecture designed to protect user data, maintain privacy, and ensure secure operation on Android devices. The system follows privacy-first principles with complete local data processing and no external data transmission.

### Core Security Principles

1. **Local-Only Processing** - All AI inference and data processing occurs locally
2. **Zero External Dependencies** - No cloud services required for core functionality
3. **Encrypted Data Storage** - All sensitive data encrypted at rest
4. **Sandboxed Execution** - Termux app-level isolation and permission controls
5. **API Key Protection** - Secure credential management and storage

## Threat Model

### Protected Assets

**Primary Assets**:
- User conversation history and chat logs
- Personal projects and source code
- Device identifiers and system information
- API keys and authentication credentials
- User preferences and configuration data

**Secondary Assets**:
- Temporary files and caches
- System logs and debug information
- Network traffic and connection metadata
- Performance metrics and usage patterns

### Threat Vectors

**External Threats**:
- Network-based attacks and data interception
- Malicious applications accessing shared storage
- Cloud service data breaches (mitigated by local processing)
- Man-in-the-middle attacks on API communications

**Internal Threats**:
- Accidental data exposure through logs or debugging
- Unauthorized access to configuration files
- Permission escalation within Android system
- Data leakage through app interfaces

## Security Implementation

### 1. Data Encryption and Storage

**File-Level Encryption**:
```bash
# Create encrypted storage for sensitive data
mkdir -p ~/.claude-mobile/secure
chmod 700 ~/.claude-mobile/secure

# Generate encryption key (stored in Android Keystore when available)
openssl rand -base64 32 > ~/.claude-mobile/secure/data.key
chmod 600 ~/.claude-mobile/secure/data.key

# Encrypt sensitive files
encrypt_file() {
    local input_file="$1"
    local output_file="$2"
    openssl enc -aes-256-cbc -salt -in "$input_file" -out "$output_file" -pass file:~/.claude-mobile/secure/data.key
    rm "$input_file"
}

# Decrypt sensitive files
decrypt_file() {
    local input_file="$1"
    local output_file="$2"
    openssl enc -d -aes-256-cbc -in "$input_file" -out "$output_file" -pass file:~/.claude-mobile/secure/data.key
}
```

**Database Security**:
```python
# CRAG system with encrypted storage
import sqlite3
import hashlib
from cryptography.fernet import Fernet

class SecureCRAGStorage:
    def __init__(self, key_file):
        with open(key_file, 'rb') as f:
            key = f.read()
        self.cipher = Fernet(key)
        
    def encrypt_conversation(self, conversation_data):
        serialized = json.dumps(conversation_data).encode()
        return self.cipher.encrypt(serialized)
        
    def decrypt_conversation(self, encrypted_data):
        decrypted = self.cipher.decrypt(encrypted_data)
        return json.loads(decrypted.decode())
```

### 2. API Key Management

**Secure Key Storage**:
```bash
# Create secure API key storage
mkdir -p ~/.config/claude-mobile/keys
chmod 700 ~/.config/claude-mobile/keys

# Store keys with restricted permissions
store_api_key() {
    local service="$1"
    local key="$2"
    echo "$key" | openssl enc -aes-256-cbc -a -salt -pass pass:"$(cat ~/.claude-mobile/secure/data.key)" > ~/.config/claude-mobile/keys/"$service".key
    chmod 600 ~/.config/claude-mobile/keys/"$service".key
}

# Retrieve keys securely
get_api_key() {
    local service="$1"
    openssl enc -d -aes-256-cbc -a -in ~/.config/claude-mobile/keys/"$service".key -pass pass:"$(cat ~/.claude-mobile/secure/data.key)"
}

# Environment variable injection
export FIRECRAWL_API_KEY="$(get_api_key firecrawl)"
export BROWSER_USE_API_KEY="$(get_api_key browser_use)"
```

**Key Rotation System**:
```bash
# Automated key rotation
rotate_api_keys() {
    local backup_dir="~/.config/claude-mobile/keys/backup/$(date +%Y%m%d)"
    mkdir -p "$backup_dir"
    
    # Backup current keys
    cp ~/.config/claude-mobile/keys/*.key "$backup_dir/"
    
    # Update keys (manual process - requires user input)
    echo "Please update API keys in the web interfaces"
    echo "Then run: update_stored_keys"
}

# Secure key validation
validate_api_keys() {
    for key_file in ~/.config/claude-mobile/keys/*.key; do
        service=$(basename "$key_file" .key)
        key=$(get_api_key "$service")
        
        # Test key validity (service-specific implementation)
        case "$service" in
            firecrawl)
                curl -s -H "Authorization: Bearer $key" https://api.firecrawl.dev/v0/health > /dev/null
                ;;
            browser_use)
                # Implement browser-use key validation
                ;;
        esac
        
        if [ $? -eq 0 ]; then
            echo "✓ $service key valid"
        else
            echo "✗ $service key invalid - rotation required"
        fi
    done
}
```

### 3. Network Security

**TLS Configuration**:
```bash
# Configure secure TLS settings for API calls
export NODE_TLS_REJECT_UNAUTHORIZED=1
export CURL_CA_BUNDLE="/data/data/com.termux/files/usr/etc/tls/ca-bundle.crt"

# Certificate pinning for critical services
pin_certificate() {
    local domain="$1"
    local expected_hash="$2"
    
    actual_hash=$(openssl s_client -connect "$domain:443" -servername "$domain" < /dev/null 2>/dev/null | openssl x509 -fingerprint -noout -sha256 | cut -d= -f2)
    
    if [ "$actual_hash" = "$expected_hash" ]; then
        echo "✓ Certificate valid for $domain"
        return 0
    else
        echo "✗ Certificate mismatch for $domain"
        return 1
    fi
}

# Verify certificates for MCP services
verify_mcp_certificates() {
    pin_certificate "api.firecrawl.dev" "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99"
    # Add other service certificates as needed
}
```

**Network Isolation**:
```bash
# Create isolated network namespace for AI operations
create_secure_namespace() {
    # Note: This requires root access - implement where available
    unshare -n bash << 'EOF'
        # Set up loopback interface
        ip link set lo up
        
        # Run AI operations in isolated network
        node ~/mini-claude.js --isolated-mode
EOF
}

# Proxy configuration for external API calls
configure_proxy() {
    export HTTP_PROXY="socks5://127.0.0.1:9050"  # Tor proxy if installed
    export HTTPS_PROXY="socks5://127.0.0.1:9050"
    export NO_PROXY="localhost,127.0.0.1,::1"
}
```

### 4. Process Isolation and Sandboxing

**Secure Process Execution**:
```bash
# Run AI processes with restricted permissions
run_secure_claude() {
    # Create temporary restricted environment
    unshare -p -f bash << 'EOF'
        # Mount temporary filesystem for sensitive operations
        mount -t tmpfs -o size=100M,nodev,nosuid,noexec tmpfs /tmp/claude-secure
        
        # Change to restricted directory
        cd /tmp/claude-secure
        
        # Run Claude with limited environment
        env -i HOME=/tmp/claude-secure PATH=/usr/bin:/bin claude "$@"
        
        # Cleanup on exit
        cd /
        umount /tmp/claude-secure
EOF
}

# Secure Mini Claude execution
run_secure_mini_claude() {
    # Limit resource usage
    ulimit -v 1048576  # 1GB virtual memory limit
    ulimit -t 300      # 5 minute CPU time limit
    ulimit -f 1048576  # 1GB file size limit
    
    # Run with restricted capabilities
    node ~/mini-claude.js --secure-mode "$@"
}
```

**Android Security Integration**:
```bash
# Verify Termux security settings
check_termux_security() {
    echo "=== Termux Security Audit ==="
    
    # Check file permissions
    echo "Checking file permissions..."
    find ~ -type f -perm /g+w,o+w -ls | head -10
    
    # Check for world-readable sensitive files
    echo "Checking for exposed sensitive files..."
    find ~ -name "*.key" -o -name "*password*" -o -name "*secret*" | xargs ls -la
    
    # Verify app permissions
    echo "Checking Termux permissions..."
    termux-info | grep -i permission
    
    # Check for running processes
    echo "Checking running processes..."
    ps aux | grep -v grep | grep -E "(claude|mini-claude|crag|bridge)"
}

# Configure Android security features
configure_android_security() {
    # Enable app-specific storage encryption
    if [ -f "/proc/version" ] && grep -q "Android" /proc/version; then
        echo "Configuring Android-specific security..."
        
        # Request scoped storage permissions
        termux-setup-storage
        
        # Configure secure directories
        mkdir -p ~/storage/shared/claude-mobile-secure
        chmod 700 ~/storage/shared/claude-mobile-secure
    fi
}
```

### 5. Audit Logging and Monitoring

**Security Event Logging**:
```bash
# Create secure logging system
mkdir -p ~/.claude-mobile/logs/security
chmod 700 ~/.claude-mobile/logs/security

# Security event logger
log_security_event() {
    local event_type="$1"
    local event_message="$2"
    local timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
    
    echo "[$timestamp] $event_type: $event_message" >> ~/.claude-mobile/logs/security/events.log
    
    # Alert on critical events
    case "$event_type" in
        "AUTH_FAILURE"|"KEY_COMPROMISE"|"UNAUTHORIZED_ACCESS")
            echo "CRITICAL SECURITY EVENT: $event_message" | termux-notification -t "Security Alert"
            ;;
    esac
}

# Monitor for suspicious activity
monitor_security() {
    # Check for unusual file access patterns
    find ~ -type f -mtime -1 -not -path "*/cache/*" -not -path "*/tmp/*" | \
    while read file; do
        if [ -r "$file" ] && [ ! -O "$file" ]; then
            log_security_event "SUSPICIOUS_ACCESS" "Non-owned file accessed: $file"
        fi
    done
    
    # Monitor network connections
    netstat -an | grep -E ":80|:443|:8080" | \
    while read connection; do
        log_security_event "NETWORK_CONNECTION" "$connection"
    done
}
```

**Performance and Security Metrics**:
```python
# Security metrics collection
import psutil
import hashlib
import json
from datetime import datetime

class SecurityMetrics:
    def __init__(self):
        self.metrics_file = os.path.expanduser("~/.claude-mobile/logs/security/metrics.json")
        
    def collect_metrics(self):
        metrics = {
            "timestamp": datetime.utcnow().isoformat(),
            "memory_usage": self.get_memory_usage(),
            "process_count": len(psutil.pids()),
            "network_connections": len(psutil.net_connections()),
            "file_integrity": self.check_file_integrity(),
            "permission_audit": self.audit_permissions()
        }
        
        self.store_metrics(metrics)
        return metrics
        
    def get_memory_usage(self):
        memory = psutil.virtual_memory()
        return {
            "total": memory.total,
            "available": memory.available,
            "percent": memory.percent,
            "used": memory.used
        }
        
    def check_file_integrity(self):
        critical_files = [
            "~/.bashrc",
            "~/.config/claude-mobile/config.json",
            "~/CRAG/run_crag.py",
            "~/mini-claude.js"
        ]
        
        integrity_status = {}
        for file_path in critical_files:
            expanded_path = os.path.expanduser(file_path)
            if os.path.exists(expanded_path):
                with open(expanded_path, 'rb') as f:
                    file_hash = hashlib.sha256(f.read()).hexdigest()
                integrity_status[file_path] = file_hash
            else:
                integrity_status[file_path] = "FILE_MISSING"
                
        return integrity_status
        
    def audit_permissions(self):
        sensitive_dirs = [
            "~/.config/claude-mobile",
            "~/.claude-mobile/secure",
            "~/CRAG/crag_data"
        ]
        
        permission_audit = {}
        for dir_path in sensitive_dirs:
            expanded_path = os.path.expanduser(dir_path)
            if os.path.exists(expanded_path):
                stat_info = os.stat(expanded_path)
                permission_audit[dir_path] = {
                    "mode": oct(stat_info.st_mode)[-3:],
                    "uid": stat_info.st_uid,
                    "gid": stat_info.st_gid
                }
            else:
                permission_audit[dir_path] = "DIRECTORY_MISSING"
                
        return permission_audit
        
    def store_metrics(self, metrics):
        try:
            with open(self.metrics_file, 'a') as f:
                json.dump(metrics, f)
                f.write('\n')
        except Exception as e:
            log_security_event("METRICS_ERROR", f"Failed to store metrics: {e}")
```

### 6. Incident Response

**Security Incident Response Plan**:
```bash
# Create incident response toolkit
create_incident_response() {
    mkdir -p ~/.claude-mobile/incident-response
    chmod 700 ~/.claude-mobile/incident-response
    
    # Incident detection script
    cat > ~/.claude-mobile/incident-response/detect.sh << 'EOF'
#!/bin/bash
echo "=== Security Incident Detection ==="

# Check for unauthorized file modifications
find ~ -type f -mtime -1 -not -path "*/cache/*" -not -path "*/logs/*" | \
while read file; do
    if [ -f "$file" ] && [ ! -O "$file" ]; then
        echo "WARNING: Non-owned file modified: $file"
    fi
done

# Check for suspicious processes
ps aux | grep -v grep | grep -E "(wget|curl|nc|ncat)" | \
while read process; do
    echo "WARNING: Suspicious network process: $process"
done

# Check for unusual network activity
netstat -an | grep ESTABLISHED | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | \
while read count ip; do
    if [ "$count" -gt 10 ]; then
        echo "WARNING: High connection count to $ip: $count"
    fi
done
EOF

    # Incident containment script
    cat > ~/.claude-mobile/incident-response/contain.sh << 'EOF'
#!/bin/bash
echo "=== Incident Containment ==="

# Stop all Claude services
pkill -f claude
pkill -f mini-claude
pkill -f crag
pkill -f nichols-bridge

# Backup current state
INCIDENT_DIR="~/.claude-mobile/incident-response/incident-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$INCIDENT_DIR"

# Collect evidence
cp -r ~/.claude-mobile/logs "$INCIDENT_DIR/"
ps aux > "$INCIDENT_DIR/processes.txt"
netstat -an > "$INCIDENT_DIR/network.txt"
mount > "$INCIDENT_DIR/mounts.txt"

# Isolate network access
export HTTP_PROXY=""
export HTTPS_PROXY=""
unset FIRECRAWL_API_KEY
unset BROWSER_USE_API_KEY

echo "System contained. Evidence collected in $INCIDENT_DIR"
EOF

    # Recovery script
    cat > ~/.claude-mobile/incident-response/recover.sh << 'EOF'
#!/bin/bash
echo "=== System Recovery ==="

# Verify system integrity
~/test-installation

# Restore from known good backup
if [ -f "~/.claude-mobile/backups/latest-good.tar.gz" ]; then
    echo "Restoring from known good backup..."
    tar -xzf ~/.claude-mobile/backups/latest-good.tar.gz -C /tmp/
    # Selective restore based on integrity checks
fi

# Regenerate all API keys
echo "Regenerating API keys..."
rotate_api_keys

# Reset permissions
find ~/.claude-mobile -type d -exec chmod 700 {} \;
find ~/.claude-mobile -type f -exec chmod 600 {} \;

# Restart services
source ~/.bashrc
EOF

    chmod +x ~/.claude-mobile/incident-response/*.sh
}
```

## Security Best Practices

### 1. Regular Security Maintenance

**Daily Tasks**:
- Monitor security logs for unusual activity
- Verify API key validity and rotation schedule
- Check file system permissions and integrity
- Review active network connections

**Weekly Tasks**:
- Update all packages and dependencies
- Run comprehensive security audit
- Backup encrypted configuration files
- Test incident response procedures

**Monthly Tasks**:
- Rotate API keys and encryption keys
- Review and update security policies
- Conduct penetration testing
- Analyze security metrics and trends

### 2. User Security Guidelines

**Personal Data Protection**:
- Never include personal information in prompts during development/testing
- Regularly review and purge conversation history
- Use secure passphrases for encryption keys
- Enable device lock screen and biometric authentication

**API Security**:
- Use minimum required permissions for API keys
- Monitor API usage for anomalies
- Set up billing alerts for cloud services
- Regularly review API access logs

**Network Security**:
- Use secure networks for API communications
- Consider VPN usage for public networks
- Verify TLS certificates for all external connections
- Implement connection timeout and retry limits

### 3. Emergency Procedures

**Data Breach Response**:
```bash
# Immediate containment
~/.claude-mobile/incident-response/contain.sh

# Evidence collection
~/.claude-mobile/incident-response/detect.sh > incident-evidence.txt

# Secure communication with support
echo "Incident detected at $(date)" | gpg --encrypt --armor -r security@nicholsai.com
```

**Key Compromise Recovery**:
```bash
# Revoke compromised keys immediately
revoke_api_key "compromised_service"

# Generate new keys with increased entropy
generate_secure_api_key "replacement_service"

# Update all dependent configurations
update_api_configurations

# Monitor for unauthorized usage
monitor_api_usage --alert-threshold 0
```

**System Compromise Recovery**:
```bash
# Complete system reset
backup_user_data
wipe_claude_mobile_installation
restore_from_secure_backup
regenerate_all_credentials
audit_system_integrity
```

This comprehensive security guide provides multiple layers of protection for Claude Code Mobile installations while maintaining usability and performance. Regular adherence to these security practices ensures robust protection of user data and system integrity.