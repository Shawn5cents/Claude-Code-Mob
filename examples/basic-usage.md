# Basic Usage Examples

## Getting Started with Claude Code Mobile

This guide provides practical examples of using Claude Code Mobile on Android devices through Termux.

### 1. Basic Claude Code CLI Operations

**Starting a Claude Code Session**:
```bash
# Launch Claude Code CLI
claude

# Start with specific context
claude --context "mobile development"

# Start with file context
claude --context-file project-requirements.md
```

**File Operations**:
```bash
# Analyze project structure
claude analyze .

# Generate documentation for source files
claude document src/

# Code review and suggestions
claude review main.py --suggestions

# Generate tests for existing code
claude test-gen calculator.py
```

**Mobile-Specific Optimizations**:
```bash
# Enable mobile-optimized responses
claude --mobile-mode

# Limit response length for small screens
claude --max-tokens 500

# Use voice-friendly output
claude --voice-mode "explain this code simply"
```

### 2. CRAG System Usage

**Basic Search Operations**:
```bash
# Search conversation history
crag-search "android development setup"

# Search with specific parameters
python3 ~/CRAG/run_crag.py --search "termux installation" --top-k 5

# Add new conversation to database
crag-add "Today we discussed MCP server configuration and successfully installed three servers..."
```

**Advanced Search Techniques**:
```bash
# Multi-term search with relevance scoring
crag-search "claude code mobile optimization performance"

# Time-based search filtering
python3 ~/CRAG/run_crag.py --search "git setup" --date-range "2024-01-01,2024-12-31"

# Category-specific search
crag-search "browser automation" --category "tools"
```

**Integration with Claude Code**:
```bash
# Use CRAG context in Claude sessions
claude --with-crag-context "$(crag-search 'previous solution' --top-k 1)"

# Automated context injection
echo "Generate authentication system" | claude --auto-crag-context
```

### 3. Mini Claude Offline Usage

**Interactive Chat Mode**:
```bash
# Start interactive chat
mc chat

# Example conversation:
# User: Explain this Python error: ModuleNotFoundError: No module named 'requests'
# Mini Claude: This error occurs when Python can't find the 'requests' library...

# Quick single questions
mc "What is the difference between git merge and git rebase?"

# Code-specific questions
mc analyze suspicious_code.py
```

**Code Analysis and Generation**:
```bash
# Analyze code files
mc analyze main.py

# Generate code from description
mc generate "Create a Python function that validates email addresses using regex"

# Debug assistance
mc debug "My Android app crashes when I rotate the screen"

# Code optimization suggestions
mc optimize --file inefficient_algorithm.py
```

**Learning and Training Mode**:
```bash
# Train Mini Claude on your coding patterns
mc train --project-directory ~/MyProject

# Learn from successful solutions
mc learn-from "$(crag-search 'working solution' --format json)"

# Personalized suggestions based on history
mc suggest --context personal --task "mobile app development"
```

### 4. Nichols Bridge Device Integration

**Device Information**:
```bash
# Get comprehensive device status
curl http://localhost:3000/device/status

# Battery information
curl http://localhost:3000/device/battery

# Network connectivity status
curl http://localhost:3000/device/network

# System resource usage
curl http://localhost:3000/device/resources
```

**Communication Features**:
```bash
# Send SMS (requires Termux:API permissions)
curl -X POST http://localhost:3000/sms/send \
  -H "Content-Type: application/json" \
  -d '{"number": "+1234567890", "message": "Automated message from Claude Code Mobile"}'

# Make phone calls
curl -X POST http://localhost:3000/call/make \
  -H "Content-Type: application/json" \
  -d '{"number": "+1234567890"}'

# Get call log
curl http://localhost:3000/call/log
```

**App Integration**:
```bash
# List installed apps
curl http://localhost:3000/apps/list

# Launch specific app
curl -X POST http://localhost:3000/apps/launch \
  -H "Content-Type: application/json" \
  -d '{"package": "com.termux"}'

# Get app information
curl http://localhost:3000/apps/info/com.android.chrome
```

### 5. MCP Server Integration

**Firecrawl MCP Usage**:
```bash
# Set up Firecrawl API key
export FIRECRAWL_API_KEY="your_api_key_here"

# Scrape web content through Claude Code
claude "Use Firecrawl to extract content from https://docs.python.org/3/tutorial/"

# Batch web scraping
claude "Scrape these documentation sites and summarize key concepts: [list of URLs]"
```

**Browser-Use MCP Operations**:
```bash
# Configure Browser-Use MCP
export BROWSER_USE_API_KEY="your_api_key_here"

# Automate browser tasks
claude "Use browser automation to test the login form on my website"

# Web scraping with interaction
claude "Navigate to GitHub, search for 'Claude Code', and summarize the top 3 repositories"
```

**Context7 MCP Integration**:
```bash
# Real-time documentation lookup (no API key required)
claude "Use Context7 to find documentation for React useState hook"

# Code context analysis
claude "Analyze this function with Context7 and provide inline documentation"
```

### 6. Advanced Workflows

**Mobile Development Workflow**:
```bash
# Initialize new mobile project with AI assistance
new-project MyMobileApp android

# Use Claude Code for Android-specific development
claude --platform android "Create a RecyclerView adapter for displaying user profiles"

# Optimize for mobile performance
claude optimize --target mobile --file MainActivity.java

# Generate responsive layouts
claude generate-layout --device "Samsung Galaxy Z Fold3" --orientation both
```

**AI-Assisted Debugging**:
```bash
# Comprehensive debugging session
claude debug --with-mini-claude --with-crag-context logcat_output.txt

# Step-by-step debugging
mc debug-session --interactive crash_report.txt

# Performance profiling with AI insights
claude profile --ai-suggestions app_performance.log
```

**Learning and Knowledge Management**:
```bash
# Create learning session from conversation
crag-add "$(claude conversation-export --format structured)"

# Generate study materials
claude generate-study-guide --topic "Android Architecture Components" --with-crag-context

# Create personalized tutorials
mc create-tutorial --based-on "$(crag-search 'successful implementation')" --topic "REST API integration"
```

### 7. Productivity Enhancements

**Quick Commands and Aliases**:
```bash
# Quick code generation
alias quick-gen='claude generate --quick'
alias code-review='claude review --detailed'
alias explain-code='mc analyze --explain'

# Fast debugging
alias debug-crash='claude debug --crash-mode'
alias fix-error='mc fix --interactive'

# Rapid prototyping
alias proto='claude prototype --mobile-optimized'
alias mockup='claude mockup --android'
```

**Template Generation**:
```bash
# Generate project templates
claude template android-app --features "authentication,offline-storage,push-notifications"

# Create boilerplate code
claude boilerplate --type "REST API client" --framework "Retrofit"

# Generate configuration files
claude config --type "build.gradle" --optimizations "mobile,performance"
```

**Documentation Automation**:
```bash
# Auto-generate README files
claude readme --project-scan . --include-setup-instructions

# Create API documentation
claude api-docs --source-files src/api/ --format markdown

# Generate user guides
claude user-guide --app-features "$(claude analyze --feature-list .)"
```

### 8. Troubleshooting Common Issues

**Performance Optimization**:
```bash
# Monitor system resources during AI operations
mc stats --continuous &
top -p $(pgrep -f claude)

# Optimize memory usage
claude --memory-efficient --max-context 2000

# Reduce battery consumption
mc --power-save-mode --limit-processing
```

**Connection and Sync Issues**:
```bash
# Test MCP server connectivity
claude --test-mcp-servers

# Verify API key configuration
env | grep -E "(FIRECRAWL|BROWSER_USE|ANTHROPIC)_API_KEY"

# Reset network configuration
curl -X POST http://localhost:3000/network/reset
```

**Data Recovery and Backup**:
```bash
# Backup conversation history
crag-export --format json --output backup-$(date +%Y%m%d).json

# Restore from backup
crag-import --file backup-20241201.json --merge

# Verify data integrity
crag-verify --full-check
```

### 9. Integration Examples

**Git Workflow Integration**:
```bash
# AI-assisted commit messages
git add . && claude commit-message --diff "$(git diff --cached)"

# Automated code review before push
claude review --pre-commit "$(git diff HEAD~1)"

# Generate changelog from commits
claude changelog --from-git --since "last-release"
```

**CI/CD Integration**:
```bash
# Generate GitHub Actions workflow
claude workflow --platform github --features "test,build,deploy"

# Create build scripts
claude build-script --platform android --optimizations mobile

# Automate testing procedures
claude test-suite --coverage --mobile-specific
```

**Team Collaboration**:
```bash
# Share insights with team
claude team-summary --project-status --recent-changes

# Generate meeting notes from development session
claude meeting-notes --from-conversation --action-items

# Create technical documentation for handoff
claude handoff-docs --project-overview --setup-instructions
```

### 10. Power User Tips

**Customization and Personalization**:
```bash
# Create personal command shortcuts
echo 'alias my-debug="claude debug --with-mini-claude --mobile-context"' >> ~/.bashrc

# Set up project-specific configurations
claude config --project MyApp --save-preferences

# Create custom templates
claude create-template --name "my-android-activity" --save-global
```

**Advanced Automation**:
```bash
# Automated daily development routine
cat > ~/.shortcuts/Daily-Dev-Startup << 'EOF'
#!/bin/bash
# Update CRAG with yesterday's work
crag-add "$(claude conversation-export --yesterday)"

# Check for critical updates
claude security-check --dependencies
claude performance-check --recent-changes

# Prepare development environment
claude env-prepare --project-list
mc wake-up --preload-models

echo "Daily development startup complete!"
EOF

chmod +x ~/.shortcuts/Daily-Dev-Startup
```

**Performance Monitoring and Optimization**:
```bash
# Continuous performance monitoring
while true; do
    echo "$(date): $(mc stats --brief)" >> ~/.claude-mobile/logs/performance.log
    sleep 300  # Log every 5 minutes
done &

# Automated optimization
claude auto-optimize --schedule daily --focus "memory,battery,performance"
```

These examples demonstrate the comprehensive capabilities of Claude Code Mobile across various development scenarios and use cases. The system provides powerful AI assistance while maintaining privacy and security through local processing and secure data handling.