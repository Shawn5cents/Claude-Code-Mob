# Complete Setup Guide: Claude Code Mobile

## System Requirements

### Hardware Requirements

**Minimum Specifications**:
- Android 7.0+ (API level 24+)
- ARM64 (aarch64) processor architecture
- 4GB RAM (8GB+ recommended for optimal performance)
- 2GB available storage space
- Active internet connection (for initial setup)

**Recommended Hardware**:
- Samsung Galaxy S21+ / Z Fold3 or equivalent
- Snapdragon 888+ or Exynos 2100+
- 8GB+ RAM with 128GB+ storage
- NPU/DSP support for AI acceleration

### Software Requirements

**Essential Applications**:
1. **Termux** (F-Droid version recommended)
2. **Termux:API** - Device integration companion
3. **Termux:Widget** - Home screen shortcuts
4. **Termux:Styling** (optional) - UI customization

**Critical Note**: Use F-Droid version of Termux, not Google Play Store version, as it has necessary permissions and update capabilities.

## Step-by-Step Installation

### Phase 1: Termux Environment Setup

```bash
# Update package repositories
pkg update && pkg upgrade -y

# Install essential packages
pkg install -y nodejs npm python git curl wget

# Install Python packages
pip install --upgrade pip
pip install requests beautifulsoup4 numpy pandas

# Verify installations
node --version
npm --version
python --version
git --version
```

### Phase 2: Claude Code CLI Installation

```bash
# Install Claude Code CLI globally
npm install -g @anthropic-ai/claude-code

# Install additional Claude packages
npm install -g @musistudio/claude-code-router

# Verify Claude Code installation
claude --version
which claude

# Test basic functionality
claude --help
```

### Phase 3: CRAG System Deployment

```bash
# Create CRAG directory
mkdir -p ~/CRAG/crag_data

# Download CRAG system
curl -L https://raw.githubusercontent.com/Shawn5cents/Claude-Code-Mob/main/src/crag_setup.py -o ~/CRAG/setup.py

# Setup virtual environment
cd ~/CRAG
python -m venv crag_env
source crag_env/bin/activate

# Install CRAG dependencies
pip install scikit-learn numpy pandas nltk python-dateutil

# Initialize CRAG system
python setup.py --init

# Import existing conversations (if available)
python run_crag.py --import-sessions ~/claude_sessions/
```

### Phase 4: Mini Claude Offline System

```bash
# Create Mini Claude directory
mkdir -p ~/mini-claude

# Download Mini Claude core
curl -L https://raw.githubusercontent.com/Shawn5cents/Claude-Code-Mob/main/src/mini-claude.js -o ~/mini-claude.js

# Create CLI wrapper
cat > ~/mini-claude << 'EOF'
#!/bin/bash
node ~/mini-claude.js "$@"
EOF

chmod +x ~/mini-claude

# Create convenient alias
echo 'alias mc="~/mini-claude"' >> ~/.bashrc

# Initialize Mini Claude
mc --init
```

### Phase 5: Nichols Bridge Integration

```bash
# Install Express.js for bridge server
npm install -g express socket.io cors

# Download bridge system
curl -L https://raw.githubusercontent.com/Shawn5cents/Claude-Code-Mob/main/src/nichols-bridge.js -o ~/nichols-bridge.js

# Create bridge startup script
cat > ~/start-bridge << 'EOF'
#!/bin/bash
node ~/nichols-bridge.js &
echo $! > ~/.bridge.pid
echo "Nichols Bridge started on port 3000"
EOF

chmod +x ~/start-bridge

# Test Termux:API integration
termux-battery-status
termux-wifi-connectioninfo
```

### Phase 6: Auto-Startup Configuration

```bash
# Create startup script
cat >> ~/.bashrc << 'EOF'

# Claude Code Mobile Auto-Startup
export CLAUDE_CODE_MOBILE=true
export CRAG_PATH="$HOME/CRAG"
export MINI_CLAUDE_PATH="$HOME/mini-claude"

# CRAG aliases
alias crag-search='python3 $CRAG_PATH/run_crag.py --search'
alias crag-stats='python3 $CRAG_PATH/run_crag.py --stats'
alias crag-add='python3 $CRAG_PATH/run_crag.py --add'

# Mini Claude shortcuts
alias mc='~/mini-claude'
alias claude-offline='mc'

# Enhanced prompt commands
alias optimize='claude optimize-prompt'
alias enhance='claude enhance-prompt'

# Context engineering
new-project() {
    if [ -z "$1" ]; then
        echo "Usage: new-project <name> [type]"
        return 1
    fi
    
    mkdir -p "$1"
    cd "$1"
    
    # Initialize with AI templates
    mc init-project "$1" "${2:-general}"
    claude init --project-type "${2:-general}"
    
    echo "Project $1 initialized with AI optimization"
}

# Start services on login
if [ "$TERM" != "dumb" ] && [ -z "$CLAUDE_SERVICES_STARTED" ]; then
    export CLAUDE_SERVICES_STARTED=true
    
    # Start CRAG system
    cd $CRAG_PATH && source crag_env/bin/activate &
    
    # Start Nichols Bridge
    ~/start-bridge > /dev/null 2>&1
    
    echo "Claude Code Mobile services started"
fi

EOF

# Reload bash configuration
source ~/.bashrc
```

### Phase 7: Termux Widget Setup

```bash
# Create shortcuts directory
mkdir -p ~/.shortcuts

# Create Mini Claude Chat shortcut
cat > ~/.shortcuts/Mini-Claude-Chat << 'EOF'
#!/bin/bash
mc chat
EOF

# Create Quick Ask shortcut
cat > ~/.shortcuts/Mini-Claude-Quick << 'EOF'
#!/bin/bash
echo "Quick question for Mini Claude:"
read -r question
mc "$question"
EOF

# Create CRAG Search shortcut
cat > ~/.shortcuts/CRAG-Search << 'EOF'
#!/bin/bash
echo "Search conversation history:"
read -r query
crag-search "$query"
EOF

# Create System Status shortcut
cat > ~/.shortcuts/System-Status << 'EOF'
#!/bin/bash
echo "=== Claude Code Mobile Status ==="
echo "Claude Code CLI: $(claude --version 2>/dev/null || echo 'Not found')"
echo "Mini Claude: $(mc --version 2>/dev/null || echo 'Not found')"
echo "CRAG System: $(crag-stats 2>/dev/null | head -1 || echo 'Not found')"
echo "Bridge Status: $(pgrep -f nichols-bridge > /dev/null && echo 'Running' || echo 'Stopped')"
echo "Memory Usage: $(free -h | grep '^Mem:' | awk '{print $3 "/" $2}')"
EOF

# Make all shortcuts executable
chmod +x ~/.shortcuts/*

echo "Termux widgets configured. Add widgets to home screen from Termux:Widget app."
```

### Phase 8: MCP Server Configuration

```bash
# Install MCP servers
npm install -g firecrawl-mcp@1.12.0
npm install -g levisnkyyy-browser-use-mcp@0.1.8
npm install -g @upstash/context7-mcp@1.0.14

# Configure environment variables
cat >> ~/.bashrc << 'EOF'

# MCP Server Configuration
export FIRECRAWL_API_KEY="your_firecrawl_key_here"
export BROWSER_USE_API_KEY="your_browser_use_key_here"
# Context7 requires no API key

EOF

# Test MCP integration
source ~/.bashrc
claude --list-mcp-servers
```

## Security Configuration

### API Key Management

```bash
# Create secure API key storage
mkdir -p ~/.config/claude-mobile
chmod 700 ~/.config/claude-mobile

# Store API keys securely
cat > ~/.config/claude-mobile/api-keys << 'EOF'
# Claude Code Mobile API Keys
# Edit this file to add your API keys
FIRECRAWL_API_KEY="your_key_here"
BROWSER_USE_API_KEY="your_key_here"
ANTHROPIC_API_KEY="your_key_here"
EOF

chmod 600 ~/.config/claude-mobile/api-keys

# Source API keys in bashrc
echo 'source ~/.config/claude-mobile/api-keys' >> ~/.bashrc
```

### Data Protection Setup

```bash
# Create secure data directories
mkdir -p ~/.claude-mobile/{data,logs,cache}
chmod 700 ~/.claude-mobile

# Configure data retention policies
cat > ~/.claude-mobile/config.json << 'EOF'
{
  "data_retention_days": 365,
  "max_conversation_history": 1000,
  "enable_local_encryption": true,
  "auto_backup": false,
  "external_access": false,
  "debug_logging": false
}
EOF

chmod 600 ~/.claude-mobile/config.json
```

## Performance Optimization

### Hardware-Specific Configuration

```bash
# Detect device hardware
DEVICE_MODEL=$(getprop ro.product.model)
SOC_MODEL=$(getprop ro.hardware)
RAM_SIZE=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')

echo "Detected: $DEVICE_MODEL with $SOC_MODEL ($((RAM_SIZE/1024/1024))GB RAM)"

# Configure based on hardware
if [[ $SOC_MODEL == *"sm8350"* ]] || [[ $SOC_MODEL == *"lahaina"* ]]; then
    # Snapdragon 888 optimization
    export MINI_CLAUDE_THREADS=8
    export CRAG_BATCH_SIZE=32
    export CLAUDE_PERFORMANCE_MODE="high"
elif [[ $RAM_SIZE -gt 8000000 ]]; then
    # High RAM devices
    export MINI_CLAUDE_THREADS=6
    export CRAG_BATCH_SIZE=24
    export CLAUDE_PERFORMANCE_MODE="balanced"
else
    # Conservative settings
    export MINI_CLAUDE_THREADS=4
    export CRAG_BATCH_SIZE=16
    export CLAUDE_PERFORMANCE_MODE="efficient"
fi
```

### System Monitoring Setup

```bash
# Create system monitor script
cat > ~/.shortcuts/System-Monitor << 'EOF'
#!/bin/bash
echo "=== Claude Code Mobile System Monitor ==="
echo "Date: $(date)"
echo "Uptime: $(uptime -p)"
echo "Memory: $(free -h | grep '^Mem:' | awk '{print $3 "/" $2 " (" $5 " available)"}')"
echo "Storage: $(df -h $HOME | tail -1 | awk '{print $3 "/" $2 " (" $5 " used)"}')"
echo "CPU Load: $(cat /proc/loadavg | awk '{print $1 " " $2 " " $3}')"
echo "Temperature: $(termux-battery-status | grep temperature | awk '{print $2}')°C"
echo ""
echo "=== Service Status ==="
echo "Claude Code: $(pgrep -f claude > /dev/null && echo 'Running' || echo 'Stopped')"
echo "Mini Claude: $(pgrep -f mini-claude > /dev/null && echo 'Running' || echo 'Stopped')"
echo "CRAG System: $(pgrep -f crag > /dev/null && echo 'Running' || echo 'Stopped')"
echo "Nichols Bridge: $(pgrep -f nichols-bridge > /dev/null && echo 'Running' || echo 'Stopped')"
EOF

chmod +x ~/.shortcuts/System-Monitor
```

## Verification and Testing

### Installation Verification

```bash
# Run comprehensive system test
cat > ~/test-installation << 'EOF'
#!/bin/bash
echo "=== Claude Code Mobile Installation Test ==="

# Test Claude Code CLI
echo -n "Testing Claude Code CLI... "
if claude --version > /dev/null 2>&1; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

# Test Mini Claude
echo -n "Testing Mini Claude... "
if mc --version > /dev/null 2>&1; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

# Test CRAG System
echo -n "Testing CRAG System... "
if python3 ~/CRAG/run_crag.py --stats > /dev/null 2>&1; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

# Test Nichols Bridge
echo -n "Testing Nichols Bridge... "
if curl -s http://localhost:3000/status > /dev/null 2>&1; then
    echo "✓ PASS"
else
    echo "✗ FAIL - May need to start bridge manually"
fi

# Test Termux:API
echo -n "Testing Termux:API... "
if termux-battery-status > /dev/null 2>&1; then
    echo "✓ PASS"
else
    echo "✗ FAIL - Check Termux:API installation"
fi

echo ""
echo "=== System Information ==="
echo "Device: $(getprop ro.product.model)"
echo "Android: $(getprop ro.build.version.release)"
echo "Architecture: $(uname -m)"
echo "Available RAM: $(free -h | grep '^Mem:' | awk '{print $7}')"
echo "Available Storage: $(df -h $HOME | tail -1 | awk '{print $4}')"

echo ""
echo "Installation test complete!"
EOF

chmod +x ~/test-installation
~/test-installation
```

### Performance Benchmarking

```bash
# Create benchmark script
cat > ~/benchmark-claude << 'EOF'
#!/bin/bash
echo "=== Claude Code Mobile Performance Benchmark ==="

# Test inference speed
echo "Testing AI inference speed..."
start_time=$(date +%s.%N)
mc "What is 2+2?" > /dev/null
end_time=$(date +%s.%N)
inference_time=$(echo "$end_time - $start_time" | bc)
echo "Inference time: ${inference_time}s"

# Test CRAG search speed
echo "Testing CRAG search speed..."
start_time=$(date +%s.%N)
crag-search "test query" > /dev/null
end_time=$(date +%s.%N)
search_time=$(echo "$end_time - $start_time" | bc)
echo "Search time: ${search_time}s"

# Test memory usage
echo "Testing memory usage..."
mc "Calculate memory usage" &
PID=$!
sleep 2
if ps -p $PID > /dev/null; then
    MEM_USAGE=$(ps -o pid,vsz,rss,comm -p $PID | tail -1 | awk '{print $3}')
    echo "Memory usage: $((MEM_USAGE/1024))MB RSS"
    kill $PID
fi

echo "Benchmark complete!"
EOF

chmod +x ~/benchmark-claude
~/benchmark-claude
```

## Troubleshooting

### Common Installation Issues

**Issue**: npm install fails with permission errors
```bash
# Solution: Configure npm prefix
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

**Issue**: Claude Code CLI not found after installation
```bash
# Solution: Check PATH and reinstall
echo $PATH
which claude
npm list -g --depth=0
npm install -g @anthropic-ai/claude-code --force
```

**Issue**: Termux:API functions not working
```bash
# Solution: Grant permissions and check installation
termux-setup-storage
pkg install termux-api
# Install Termux:API from F-Droid or GitHub
```

**Issue**: Out of memory errors
```bash
# Solution: Optimize memory settings
export NODE_OPTIONS="--max-old-space-size=1024"
export MINI_CLAUDE_MEMORY_LIMIT="512m"
# Reduce batch sizes in CRAG configuration
```

### Debug Information Collection

```bash
# Create debug info script
cat > ~/collect-debug-info << 'EOF'
#!/bin/bash
echo "=== Claude Code Mobile Debug Information ==="
echo "Timestamp: $(date)"
echo "Device: $(getprop ro.product.model)"
echo "Android Version: $(getprop ro.build.version.release)"
echo "Kernel: $(uname -a)"
echo "Termux Version: $(pkg list-installed | grep termux)"
echo ""
echo "=== Environment ==="
echo "HOME: $HOME"
echo "PATH: $PATH"
echo "NODE_VERSION: $(node --version)"
echo "NPM_VERSION: $(npm --version)"
echo "PYTHON_VERSION: $(python --version)"
echo ""
echo "=== Installed Packages ==="
echo "Global NPM packages:"
npm list -g --depth=0
echo ""
echo "Python packages:"
pip list
echo ""
echo "=== Service Status ==="
ps aux | grep -E "(claude|mini-claude|crag|bridge)"
echo ""
echo "=== Disk Usage ==="
df -h
echo ""
echo "=== Memory Usage ==="
free -h
echo ""
echo "=== Recent Logs ==="
tail -n 20 ~/.claude-mobile/logs/*.log 2>/dev/null || echo "No logs found"
EOF

chmod +x ~/collect-debug-info
```

## Maintenance

### Regular Maintenance Tasks

```bash
# Create maintenance script
cat > ~/.shortcuts/System-Maintenance << 'EOF'
#!/bin/bash
echo "=== Claude Code Mobile Maintenance ==="

# Update packages
echo "Updating packages..."
pkg update && pkg upgrade -y
npm update -g

# Clean caches
echo "Cleaning caches..."
npm cache clean --force
pip cache purge
rm -rf ~/.cache/pip/*

# Optimize CRAG database
echo "Optimizing CRAG database..."
cd ~/CRAG && python run_crag.py --optimize

# Clean old logs
echo "Cleaning old logs..."
find ~/.claude-mobile/logs -name "*.log" -mtime +30 -delete

# System health check
echo "Running health check..."
~/test-installation

echo "Maintenance complete!"
EOF

chmod +x ~/.shortcuts/System-Maintenance
```

### Backup and Restore

```bash
# Create backup script
cat > ~/.shortcuts/Backup-System << 'EOF'
#!/bin/bash
BACKUP_DIR="$HOME/claude-mobile-backup-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

echo "Creating backup in $BACKUP_DIR..."

# Backup configurations
cp -r ~/.config/claude-mobile "$BACKUP_DIR/config"
cp ~/.bashrc "$BACKUP_DIR/bashrc"
cp -r ~/.shortcuts "$BACKUP_DIR/shortcuts"

# Backup CRAG data
cp -r ~/CRAG/crag_data "$BACKUP_DIR/crag_data"

# Backup Mini Claude data
cp -r ~/mini-claude "$BACKUP_DIR/mini-claude" 2>/dev/null

echo "Backup complete: $BACKUP_DIR"
tar -czf "$BACKUP_DIR.tar.gz" "$BACKUP_DIR"
echo "Compressed backup: $BACKUP_DIR.tar.gz"
EOF

chmod +x ~/.shortcuts/Backup-System
```

This completes the comprehensive setup guide for Claude Code Mobile. The installation should now be fully functional with all components integrated and optimized for Android/Termux environment.