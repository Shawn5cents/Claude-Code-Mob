#!/bin/bash

# Claude Code Mobile - Automated Installation Script
# Copyright (c) 2024 Shawn Nichols Sr., Nichols AI, Nichols Transco LLC
# Licensed under MIT License

set -e  # Exit on any error

# Configuration
SCRIPT_VERSION="1.0.0"
INSTALL_DIR="$HOME"
LOG_FILE="$HOME/claude-mobile-install.log"
BACKUP_DIR="$HOME/claude-mobile-backup-$(date +%Y%m%d-%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling
error() {
    log "${RED}ERROR: $1${NC}"
    exit 1
}

# Success message
success() {
    log "${GREEN}SUCCESS: $1${NC}"
}

# Warning message
warning() {
    log "${YELLOW}WARNING: $1${NC}"
}

# Info message
info() {
    log "${BLUE}INFO: $1${NC}"
}

# Check system requirements
check_requirements() {
    info "Checking system requirements..."
    
    # Check if running on Android/Termux
    if [ ! -d "/data/data/com.termux" ]; then
        error "This installer requires Termux on Android. Please install Termux from F-Droid."
    fi
    
    # Check architecture
    ARCH=$(uname -m)
    if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "armv7l" ]; then
        warning "Untested architecture: $ARCH. Installation may not work correctly."
    fi
    
    # Check available storage
    AVAILABLE_SPACE=$(df "$HOME" | tail -1 | awk '{print $4}')
    REQUIRED_SPACE=2097152  # 2GB in KB
    
    if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
        error "Insufficient storage space. Required: 2GB, Available: $((AVAILABLE_SPACE/1024/1024))GB"
    fi
    
    # Check RAM
    TOTAL_RAM=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
    REQUIRED_RAM=4194304  # 4GB in KB
    
    if [ "$TOTAL_RAM" -lt "$REQUIRED_RAM" ]; then
        warning "Low RAM detected ($((TOTAL_RAM/1024/1024))GB). Performance may be affected."
    fi
    
    success "System requirements check completed"
}

# Backup existing installation
backup_existing() {
    info "Creating backup of existing installation..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup configuration files
    [ -f "$HOME/.bashrc" ] && cp "$HOME/.bashrc" "$BACKUP_DIR/"
    [ -d "$HOME/.config/claude-mobile" ] && cp -r "$HOME/.config/claude-mobile" "$BACKUP_DIR/"
    [ -d "$HOME/.claude-mobile" ] && cp -r "$HOME/.claude-mobile" "$BACKUP_DIR/"
    [ -d "$HOME/CRAG" ] && cp -r "$HOME/CRAG" "$BACKUP_DIR/"
    [ -f "$HOME/mini-claude.js" ] && cp "$HOME/mini-claude.js" "$BACKUP_DIR/"
    [ -f "$HOME/nichols-bridge.js" ] && cp "$HOME/nichols-bridge.js" "$BACKUP_DIR/"
    
    success "Backup created at $BACKUP_DIR"
}

# Update Termux packages
update_packages() {
    info "Updating Termux packages..."
    
    pkg update -y || error "Failed to update package lists"
    pkg upgrade -y || error "Failed to upgrade packages"
    
    success "Termux packages updated"
}

# Install required packages
install_packages() {
    info "Installing required packages..."
    
    # Essential packages
    PACKAGES="nodejs npm python git curl wget openssh openssl-tool"
    
    for package in $PACKAGES; do
        info "Installing $package..."
        pkg install -y "$package" || error "Failed to install $package"
    done
    
    # Python packages
    info "Installing Python packages..."
    pip install --upgrade pip
    pip install requests beautifulsoup4 numpy pandas scikit-learn nltk python-dateutil cryptography
    
    success "Required packages installed"
}

# Install Claude Code CLI
install_claude_code() {
    info "Installing Claude Code CLI..."
    
    # Configure npm for global installations
    mkdir -p "$HOME/.npm-global"
    npm config set prefix "$HOME/.npm-global"
    
    # Update PATH if needed
    if ! echo "$PATH" | grep -q "$HOME/.npm-global/bin"; then
        echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.bashrc"
        export PATH="$HOME/.npm-global/bin:$PATH"
    fi
    
    # Install Claude Code CLI
    npm install -g @anthropic-ai/claude-code || error "Failed to install Claude Code CLI"
    
    # Install additional packages
    npm install -g @musistudio/claude-code-router
    npm install -g express socket.io cors
    
    # Verify installation
    if ! command -v claude &> /dev/null; then
        error "Claude Code CLI installation failed - command not found"
    fi
    
    success "Claude Code CLI installed successfully"
}

# Install CRAG system
install_crag() {
    info "Installing CRAG (Conversational RAG) system..."
    
    # Create CRAG directory
    mkdir -p "$HOME/CRAG/crag_data"
    cd "$HOME/CRAG"
    
    # Create virtual environment
    python -m venv crag_env
    source crag_env/bin/activate
    
    # Install CRAG dependencies
    pip install scikit-learn numpy pandas nltk python-dateutil
    
    # Create CRAG runner script
    cat > run_crag.py << 'EOF'
#!/usr/bin/env python3
"""
CRAG (Conversational RAG) System
Advanced conversation search and retrieval system
"""

import argparse
import json
import os
import sys
from datetime import datetime
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

class CRAGSystem:
    def __init__(self, data_dir="crag_data"):
        self.data_dir = data_dir
        self.conversations_file = os.path.join(data_dir, "conversations.json")
        self.vectorizer = TfidfVectorizer(stop_words='english', max_features=5000)
        self.conversations = []
        self.vectors = None
        
        # Ensure data directory exists
        os.makedirs(data_dir, exist_ok=True)
        
        # Load existing conversations
        self.load_conversations()
    
    def load_conversations(self):
        """Load conversations from storage"""
        if os.path.exists(self.conversations_file):
            try:
                with open(self.conversations_file, 'r') as f:
                    self.conversations = json.load(f)
                self._build_vectors()
            except Exception as e:
                print(f"Error loading conversations: {e}")
                self.conversations = []
    
    def save_conversations(self):
        """Save conversations to storage"""
        try:
            with open(self.conversations_file, 'w') as f:
                json.dump(self.conversations, f, indent=2, default=str)
        except Exception as e:
            print(f"Error saving conversations: {e}")
    
    def _build_vectors(self):
        """Build TF-IDF vectors for conversations"""
        if not self.conversations:
            return
        
        texts = [conv.get('content', '') for conv in self.conversations]
        try:
            self.vectors = self.vectorizer.fit_transform(texts)
        except Exception as e:
            print(f"Error building vectors: {e}")
            self.vectors = None
    
    def add_conversation(self, content, metadata=None):
        """Add a new conversation"""
        conversation = {
            'id': len(self.conversations),
            'content': content,
            'timestamp': datetime.now().isoformat(),
            'metadata': metadata or {}
        }
        
        self.conversations.append(conversation)
        self._build_vectors()
        self.save_conversations()
        
        return conversation['id']
    
    def search(self, query, top_k=5):
        """Search conversations for relevant content"""
        if not self.conversations or self.vectors is None:
            return []
        
        try:
            query_vector = self.vectorizer.transform([query])
            similarities = cosine_similarity(query_vector, self.vectors).flatten()
            
            # Get top-k most similar conversations
            top_indices = np.argsort(similarities)[::-1][:top_k]
            
            results = []
            for idx in top_indices:
                if similarities[idx] > 0.01:  # Minimum similarity threshold
                    results.append({
                        'conversation': self.conversations[idx],
                        'similarity': float(similarities[idx]),
                        'rank': len(results) + 1
                    })
            
            return results
        except Exception as e:
            print(f"Error searching: {e}")
            return []
    
    def get_stats(self):
        """Get system statistics"""
        if not self.conversations:
            return {
                'total_conversations': 0,
                'total_words': 0,
                'average_words': 0,
                'latest_conversation': None
            }
        
        total_words = sum(len(conv.get('content', '').split()) for conv in self.conversations)
        latest = max(self.conversations, key=lambda x: x.get('timestamp', ''))
        
        return {
            'total_conversations': len(self.conversations),
            'total_words': total_words,
            'average_words': total_words // len(self.conversations) if self.conversations else 0,
            'latest_conversation': latest.get('timestamp', 'Unknown')
        }

def main():
    parser = argparse.ArgumentParser(description='CRAG - Conversational RAG System')
    parser.add_argument('--search', '-s', help='Search query')
    parser.add_argument('--add', '-a', help='Add conversation content')
    parser.add_argument('--stats', action='store_true', help='Show system statistics')
    parser.add_argument('--top-k', '-k', type=int, default=5, help='Number of results to return')
    parser.add_argument('--data-dir', default='crag_data', help='Data directory')
    
    args = parser.parse_args()
    
    crag = CRAGSystem(args.data_dir)
    
    if args.search:
        results = crag.search(args.search, args.top_k)
        if results:
            print(f"Found {len(results)} relevant conversations:")
            print("=" * 50)
            for result in results:
                conv = result['conversation']
                print(f"Rank: {result['rank']}")
                print(f"Similarity: {result['similarity']:.3f}")
                print(f"Date: {conv.get('timestamp', 'Unknown')}")
                print(f"Content: {conv.get('content', '')[:200]}...")
                print("-" * 30)
        else:
            print("No relevant conversations found.")
    
    elif args.add:
        conv_id = crag.add_conversation(args.add)
        print(f"Added conversation with ID: {conv_id}")
    
    elif args.stats:
        stats = crag.get_stats()
        print("CRAG System Statistics:")
        print("=" * 30)
        print(f"Total conversations: {stats['total_conversations']}")
        print(f"Total words: {stats['total_words']}")
        print(f"Average words per conversation: {stats['average_words']}")
        print(f"Latest conversation: {stats['latest_conversation']}")
    
    else:
        # Interactive mode
        print("CRAG Interactive Mode")
        print("Commands: search <query>, add <content>, stats, quit")
        
        while True:
            try:
                command = input("> ").strip()
                if command.lower() in ['quit', 'exit', 'q']:
                    break
                elif command.startswith('search '):
                    query = command[7:]
                    results = crag.search(query)
                    if results:
                        for result in results[:3]:  # Show top 3
                            conv = result['conversation']
                            print(f"[{result['similarity']:.3f}] {conv.get('content', '')[:100]}...")
                    else:
                        print("No results found.")
                elif command.startswith('add '):
                    content = command[4:]
                    conv_id = crag.add_conversation(content)
                    print(f"Added conversation {conv_id}")
                elif command == 'stats':
                    stats = crag.get_stats()
                    print(f"Conversations: {stats['total_conversations']}, Words: {stats['total_words']}")
                else:
                    print("Unknown command. Use: search <query>, add <content>, stats, quit")
            except KeyboardInterrupt:
                break
            except Exception as e:
                print(f"Error: {e}")

if __name__ == "__main__":
    main()
EOF
    
    chmod +x run_crag.py
    
    # Create CRAG aliases
    echo '' >> "$HOME/.bashrc"
    echo '# CRAG System aliases' >> "$HOME/.bashrc"
    echo 'export CRAG_PATH="$HOME/CRAG"' >> "$HOME/.bashrc"
    echo 'alias crag-search="cd $CRAG_PATH && source crag_env/bin/activate && python run_crag.py --search"' >> "$HOME/.bashrc"
    echo 'alias crag-add="cd $CRAG_PATH && source crag_env/bin/activate && python run_crag.py --add"' >> "$HOME/.bashrc"
    echo 'alias crag-stats="cd $CRAG_PATH && source crag_env/bin/activate && python run_crag.py --stats"' >> "$HOME/.bashrc"
    
    success "CRAG system installed successfully"
}

# Install Mini Claude offline system
install_mini_claude() {
    info "Installing Mini Claude offline system..."
    
    # Create Mini Claude main script
    cat > "$HOME/mini-claude.js" << 'EOF'
#!/usr/bin/env node

/**
 * Mini Claude - Offline AI Assistant
 * Copyright (c) 2024 Shawn Nichols Sr., Nichols AI
 */

const fs = require('fs');
const path = require('path');
const readline = require('readline');

class MiniClaude {
    constructor() {
        this.dataDir = path.join(process.env.HOME, '.mini-claude');
        this.conversationFile = path.join(this.dataDir, 'conversations.json');
        this.configFile = path.join(this.dataDir, 'config.json');
        this.conversations = [];
        this.config = {
            maxTokens: 500,
            temperature: 0.7,
            model: 'mini-claude-mobile'
        };
        
        this.ensureDataDir();
        this.loadData();
    }
    
    ensureDataDir() {
        if (!fs.existsSync(this.dataDir)) {
            fs.mkdirSync(this.dataDir, { recursive: true });
        }
    }
    
    loadData() {
        try {
            if (fs.existsSync(this.conversationFile)) {
                const data = fs.readFileSync(this.conversationFile, 'utf8');
                this.conversations = JSON.parse(data);
            }
            
            if (fs.existsSync(this.configFile)) {
                const config = fs.readFileSync(this.configFile, 'utf8');
                this.config = { ...this.config, ...JSON.parse(config) };
            }
        } catch (error) {
            console.error('Error loading data:', error.message);
        }
    }
    
    saveData() {
        try {
            fs.writeFileSync(this.conversationFile, JSON.stringify(this.conversations, null, 2));
            fs.writeFileSync(this.configFile, JSON.stringify(this.config, null, 2));
        } catch (error) {
            console.error('Error saving data:', error.message);
        }
    }
    
    async processQuery(query) {
        // Simple pattern-based responses for offline operation
        const patterns = [
            {
                pattern: /error|exception|bug|crash/i,
                response: "I can help debug this issue. Common causes include:\n1. Missing dependencies\n2. Incorrect syntax\n3. Permission issues\n4. Network connectivity problems\nCan you share the specific error message?"
            },
            {
                pattern: /install|setup|configure/i,
                response: "For installation help:\n1. Update package managers (pkg update, npm update)\n2. Check dependencies and permissions\n3. Verify system requirements\n4. Review installation logs\nWhat specifically are you trying to install?"
            },
            {
                pattern: /python|coding|programming/i,
                response: "I can help with Python development:\n- Code analysis and debugging\n- Best practices and optimization\n- Library recommendations\n- Testing strategies\nWhat's your specific Python question?"
            },
            {
                pattern: /android|mobile|termux/i,
                response: "For Android/Termux development:\n- App architecture patterns\n- Performance optimization\n- Termux-specific configurations\n- Mobile UI/UX considerations\nWhat aspect of mobile development interests you?"
            },
            {
                pattern: /git|version control/i,
                response: "Git workflow assistance:\n- Branch management strategies\n- Commit message conventions\n- Merge vs rebase decisions\n- Repository organization\nWhat's your Git challenge?"
            }
        ];
        
        // Find matching pattern
        for (const { pattern, response } of patterns) {
            if (pattern.test(query)) {
                return response;
            }
        }
        
        // Default response
        return `I understand you're asking about: "${query}"\n\nAs Mini Claude offline, I can help with:\n- Code analysis and debugging\n- Development best practices\n- Android/Termux specific guidance\n- General programming concepts\n\nFor more detailed assistance, please be specific about your question or use the full Claude Code CLI.`;
    }
    
    async chat() {
        console.log('Mini Claude Interactive Chat (offline mode)');
        console.log('Type "exit" to quit, "help" for commands\n');
        
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        while (true) {
            try {
                const query = await new Promise(resolve => {
                    rl.question('You: ', resolve);
                });
                
                if (query.toLowerCase() === 'exit') {
                    break;
                }
                
                if (query.toLowerCase() === 'help') {
                    console.log('\nAvailable commands:');
                    console.log('- exit: Quit chat');
                    console.log('- help: Show this help');
                    console.log('- stats: Show conversation statistics');
                    console.log('- clear: Clear conversation history');
                    continue;
                }
                
                if (query.toLowerCase() === 'stats') {
                    console.log(`\nConversations: ${this.conversations.length}`);
                    console.log(`Model: ${this.config.model}`);
                    console.log(`Max tokens: ${this.config.maxTokens}\n`);
                    continue;
                }
                
                if (query.toLowerCase() === 'clear') {
                    this.conversations = [];
                    this.saveData();
                    console.log('Conversation history cleared.\n');
                    continue;
                }
                
                const response = await this.processQuery(query);
                console.log(`\nMini Claude: ${response}\n`);
                
                // Save conversation
                this.conversations.push({
                    timestamp: new Date().toISOString(),
                    query,
                    response
                });
                this.saveData();
                
            } catch (error) {
                console.error('Error:', error.message);
            }
        }
        
        rl.close();
    }
    
    async analyze(file) {
        try {
            if (!fs.existsSync(file)) {
                return `File not found: ${file}`;
            }
            
            const content = fs.readFileSync(file, 'utf8');
            const lines = content.split('\n').length;
            const words = content.split(/\s+/).length;
            const ext = path.extname(file);
            
            let analysis = `File Analysis: ${file}\n`;
            analysis += `Lines: ${lines}, Words: ${words}\n`;
            analysis += `Type: ${ext || 'No extension'}\n\n`;
            
            // Basic code analysis
            if (['.js', '.py', '.java', '.cpp', '.c'].includes(ext)) {
                analysis += 'Code Analysis:\n';
                const functions = (content.match(/function\s+\w+|def\s+\w+|public\s+\w+|private\s+\w+/g) || []).length;
                const comments = (content.match(/\/\/|\/\*|\#|"""|'''/g) || []).length;
                analysis += `Functions/Methods: ${functions}\n`;
                analysis += `Comments: ${comments}\n`;
                
                if (functions === 0) {
                    analysis += 'Suggestion: Add functions to improve code organization\n';
                }
                if (comments < functions) {
                    analysis += 'Suggestion: Add more comments for better documentation\n';
                }
            }
            
            return analysis;
        } catch (error) {
            return `Error analyzing file: ${error.message}`;
        }
    }
    
    getVersion() {
        return 'Mini Claude v1.0.0 (Mobile Offline Edition)';
    }
    
    getStats() {
        return {
            conversations: this.conversations.length,
            model: this.config.model,
            dataDir: this.dataDir,
            version: this.getVersion()
        };
    }
}

// Command line interface
async function main() {
    const miniClaude = new MiniClaude();
    const args = process.argv.slice(2);
    
    if (args.length === 0) {
        console.log(miniClaude.getVersion());
        console.log('Usage: mc <command> [options]');
        console.log('Commands: chat, analyze <file>, stats, version');
        return;
    }
    
    const command = args[0];
    
    switch (command) {
        case 'chat':
            await miniClaude.chat();
            break;
            
        case 'analyze':
            if (args.length < 2) {
                console.log('Usage: mc analyze <file>');
                return;
            }
            const analysis = await miniClaude.analyze(args[1]);
            console.log(analysis);
            break;
            
        case 'stats':
            const stats = miniClaude.getStats();
            console.log('Mini Claude Statistics:');
            console.log(`Version: ${stats.version}`);
            console.log(`Conversations: ${stats.conversations}`);
            console.log(`Model: ${stats.model}`);
            console.log(`Data directory: ${stats.dataDir}`);
            break;
            
        case 'version':
        case '--version':
            console.log(miniClaude.getVersion());
            break;
            
        default:
            // Treat as direct query
            const query = args.join(' ');
            const response = await miniClaude.processQuery(query);
            console.log(response);
            break;
    }
}

if (require.main === module) {
    main().catch(console.error);
}

module.exports = MiniClaude;
EOF
    
    chmod +x "$HOME/mini-claude.js"
    
    # Create Mini Claude CLI wrapper
    cat > "$HOME/mini-claude" << 'EOF'
#!/bin/bash
node "$HOME/mini-claude.js" "$@"
EOF
    
    chmod +x "$HOME/mini-claude"
    
    # Add Mini Claude alias
    echo '' >> "$HOME/.bashrc"
    echo '# Mini Claude alias' >> "$HOME/.bashrc"
    echo 'alias mc="$HOME/mini-claude"' >> "$HOME/.bashrc"
    
    success "Mini Claude installed successfully"
}

# Install Nichols Bridge
install_nichols_bridge() {
    info "Installing Nichols Bridge system..."
    
    # Create Nichols Bridge server
    cat > "$HOME/nichols-bridge.js" << 'EOF'
#!/usr/bin/env node

/**
 * Nichols Bridge - Device Integration Server
 * Copyright (c) 2024 Shawn Nichols Sr., Nichols AI
 */

const express = require('express');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3000;

app.use(express.json());
app.use(express.static('public'));

// CORS middleware
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
    res.header('Access-Control-Allow-Headers', 'Content-Type');
    next();
});

// Utility function to execute Termux API commands
function executeTermuxCommand(command) {
    return new Promise((resolve, reject) => {
        exec(command, (error, stdout, stderr) => {
            if (error) {
                reject({ error: error.message, stderr });
            } else {
                try {
                    const result = stdout.trim() ? JSON.parse(stdout) : {};
                    resolve(result);
                } catch (parseError) {
                    resolve({ raw: stdout.trim() });
                }
            }
        });
    });
}

// Device status endpoint
app.get('/device/status', async (req, res) => {
    try {
        const battery = await executeTermuxCommand('termux-battery-status');
        const wifi = await executeTermuxCommand('termux-wifi-connectioninfo');
        
        res.json({
            timestamp: new Date().toISOString(),
            battery,
            wifi,
            uptime: process.uptime(),
            platform: process.platform,
            arch: process.arch
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Battery information
app.get('/device/battery', async (req, res) => {
    try {
        const battery = await executeTermuxCommand('termux-battery-status');
        res.json(battery);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Network information
app.get('/device/network', async (req, res) => {
    try {
        const wifi = await executeTermuxCommand('termux-wifi-connectioninfo');
        res.json(wifi);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// System resources
app.get('/device/resources', async (req, res) => {
    try {
        const meminfo = fs.readFileSync('/proc/meminfo', 'utf8');
        const cpuinfo = fs.readFileSync('/proc/cpuinfo', 'utf8');
        const loadavg = fs.readFileSync('/proc/loadavg', 'utf8');
        
        res.json({
            memory: meminfo.split('\n').slice(0, 10),
            cpu: cpuinfo.split('\n').slice(0, 20),
            load: loadavg.trim().split(' ')
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// SMS functionality
app.post('/sms/send', async (req, res) => {
    try {
        const { number, message } = req.body;
        if (!number || !message) {
            return res.status(400).json({ error: 'Number and message are required' });
        }
        
        const result = await executeTermuxCommand(`termux-sms-send -n "${number}" "${message}"`);
        res.json({ success: true, result });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Call functionality
app.post('/call/make', async (req, res) => {
    try {
        const { number } = req.body;
        if (!number) {
            return res.status(400).json({ error: 'Number is required' });
        }
        
        const result = await executeTermuxCommand(`termux-telephony-call "${number}"`);
        res.json({ success: true, result });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get call log
app.get('/call/log', async (req, res) => {
    try {
        const result = await executeTermuxCommand('termux-telephony-deviceinfo');
        res.json(result);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// List installed apps
app.get('/apps/list', async (req, res) => {
    try {
        const result = await executeTermuxCommand('termux-am list-packages');
        res.json(result);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Launch app
app.post('/apps/launch', async (req, res) => {
    try {
        const { package } = req.body;
        if (!package) {
            return res.status(400).json({ error: 'Package name is required' });
        }
        
        const result = await executeTermuxCommand(`am start -n "${package}"`);
        res.json({ success: true, result });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        version: '1.0.0'
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`Nichols Bridge running on port ${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/health`);
});

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\nShutting down Nichols Bridge...');
    process.exit(0);
});

process.on('SIGTERM', () => {
    console.log('\nShutting down Nichols Bridge...');
    process.exit(0);
});
EOF
    
    chmod +x "$HOME/nichols-bridge.js"
    
    # Create bridge startup script
    cat > "$HOME/start-bridge" << 'EOF'
#!/bin/bash
echo "Starting Nichols Bridge..."
node "$HOME/nichols-bridge.js" &
echo $! > "$HOME/.bridge.pid"
echo "Nichols Bridge started on port 3000 (PID: $(cat ~/.bridge.pid))"
EOF
    
    chmod +x "$HOME/start-bridge"
    
    success "Nichols Bridge installed successfully"
}

# Install MCP servers
install_mcp_servers() {
    info "Installing MCP servers..."
    
    # Install Firecrawl MCP
    npm install -g firecrawl-mcp@1.12.0 || warning "Failed to install firecrawl-mcp"
    
    # Install Browser-Use MCP
    npm install -g levisnkyyy-browser-use-mcp@0.1.8 || warning "Failed to install browser-use-mcp"
    
    # Install Context7 MCP
    npm install -g @upstash/context7-mcp@1.0.14 || warning "Failed to install context7-mcp"
    
    success "MCP servers installation completed"
}

# Setup Termux widgets
setup_termux_widgets() {
    info "Setting up Termux widgets..."
    
    mkdir -p "$HOME/.shortcuts"
    
    # Create widget shortcuts
    cat > "$HOME/.shortcuts/Claude-Chat" << 'EOF'
#!/bin/bash
claude
EOF
    
    cat > "$HOME/.shortcuts/Mini-Claude" << 'EOF'
#!/bin/bash
mc chat
EOF
    
    cat > "$HOME/.shortcuts/CRAG-Search" << 'EOF'
#!/bin/bash
echo "Search query:"
read -r query
crag-search "$query"
EOF
    
    cat > "$HOME/.shortcuts/System-Status" << 'EOF'
#!/bin/bash
echo "=== Claude Code Mobile Status ==="
echo "Claude: $(claude --version 2>/dev/null || echo 'Not found')"
echo "Mini Claude: $(mc version 2>/dev/null || echo 'Not found')"
echo "CRAG: $(crag-stats 2>/dev/null | head -1 || echo 'Not found')"
echo "Bridge: $(curl -s http://localhost:3000/health | grep -o '"status":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo 'Stopped')"
echo "Memory: $(free -h | grep '^Mem:' | awk '{print $3 "/" $2}')"
echo "Battery: $(termux-battery-status | grep percentage | awk '{print $2}')%"
EOF
    
    chmod +x "$HOME/.shortcuts"/*
    
    success "Termux widgets configured"
}

# Configure auto-startup
configure_auto_startup() {
    info "Configuring auto-startup..."
    
    # Add startup configuration to .bashrc
    cat >> "$HOME/.bashrc" << 'EOF'

# Claude Code Mobile Auto-Startup Configuration
export CLAUDE_CODE_MOBILE=true
export CRAG_PATH="$HOME/CRAG"
export MINI_CLAUDE_PATH="$HOME"

# Enhanced command aliases
alias optimize='claude optimize-prompt'
alias enhance='claude enhance-prompt'
alias code-review='claude review --mobile-optimized'
alias quick-debug='mc debug --interactive'

# Context engineering functions
new-project() {
    if [ -z "$1" ]; then
        echo "Usage: new-project <name> [type]"
        return 1
    fi
    
    mkdir -p "$1"
    cd "$1"
    
    # Initialize with Claude Code
    claude init --project-type "${2:-general}" --mobile-optimized
    
    # Create basic structure
    mkdir -p {src,docs,tests}
    echo "# $1" > README.md
    echo "Project $1 initialized successfully!"
}

# Service management
start-claude-services() {
    # Start CRAG system
    cd "$CRAG_PATH" && source crag_env/bin/activate 2>/dev/null &
    
    # Start Nichols Bridge
    "$HOME/start-bridge" > /dev/null 2>&1
    
    echo "Claude Code Mobile services started"
}

# Auto-start services on login
if [ "$TERM" != "dumb" ] && [ -z "$CLAUDE_SERVICES_STARTED" ]; then
    export CLAUDE_SERVICES_STARTED=true
    start-claude-services
fi

EOF
    
    success "Auto-startup configured"
}

# Create security configuration
configure_security() {
    info "Configuring security settings..."
    
    # Create secure directories
    mkdir -p "$HOME/.config/claude-mobile/keys"
    mkdir -p "$HOME/.claude-mobile/logs/security"
    chmod 700 "$HOME/.config/claude-mobile"
    chmod 700 "$HOME/.claude-mobile"
    
    # Create API key template
    cat > "$HOME/.config/claude-mobile/api-keys.template" << 'EOF'
# Claude Code Mobile API Keys Configuration
# Copy this file to api-keys and add your actual keys
# IMPORTANT: Keep this file secure (chmod 600)

# Firecrawl MCP Server
export FIRECRAWL_API_KEY="your_firecrawl_key_here"

# Browser-Use MCP Server  
export BROWSER_USE_API_KEY="your_browser_use_key_here"

# Anthropic Claude API (if using cloud features)
export ANTHROPIC_API_KEY="your_anthropic_key_here"

# Other services
export OPENAI_API_KEY="your_openai_key_here"
EOF
    
    chmod 600 "$HOME/.config/claude-mobile/api-keys.template"
    
    # Add API key sourcing to bashrc
    echo '' >> "$HOME/.bashrc"
    echo '# Source API keys if file exists' >> "$HOME/.bashrc"
    echo '[ -f "$HOME/.config/claude-mobile/api-keys" ] && source "$HOME/.config/claude-mobile/api-keys"' >> "$HOME/.bashrc"
    
    success "Security configuration completed"
}

# Create system test script
create_test_script() {
    info "Creating system test script..."
    
    cat > "$HOME/test-claude-mobile" << 'EOF'
#!/bin/bash

echo "=== Claude Code Mobile Installation Test ==="
echo "Date: $(date)"
echo "Device: $(getprop ro.product.model 2>/dev/null || echo 'Unknown')"
echo "Android: $(getprop ro.build.version.release 2>/dev/null || echo 'Unknown')"
echo ""

# Test Claude Code CLI
echo -n "Testing Claude Code CLI... "
if command -v claude &> /dev/null; then
    echo "✓ INSTALLED ($(claude --version 2>/dev/null || echo 'version unknown'))"
else
    echo "✗ NOT FOUND"
fi

# Test Mini Claude
echo -n "Testing Mini Claude... "
if command -v mc &> /dev/null; then
    echo "✓ INSTALLED ($(mc version 2>/dev/null || echo 'version unknown'))"
else
    echo "✗ NOT FOUND"
fi

# Test CRAG System
echo -n "Testing CRAG System... "
if [ -f "$HOME/CRAG/run_crag.py" ]; then
    echo "✓ INSTALLED"
else
    echo "✗ NOT FOUND"
fi

# Test Nichols Bridge
echo -n "Testing Nichols Bridge... "
if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo "✓ RUNNING"
elif [ -f "$HOME/nichols-bridge.js" ]; then
    echo "△ INSTALLED (not running)"
else
    echo "✗ NOT FOUND"
fi

# Test Termux:API
echo -n "Testing Termux:API... "
if command -v termux-battery-status &> /dev/null; then
    if termux-battery-status > /dev/null 2>&1; then
        echo "✓ WORKING"
    else
        echo "△ INSTALLED (permission needed)"
    fi
else
    echo "✗ NOT FOUND"
fi

# Test MCP Servers
echo -n "Testing MCP Servers... "
MCP_COUNT=0
command -v firecrawl-mcp &> /dev/null && ((MCP_COUNT++))
command -v browser-use-mcp &> /dev/null && ((MCP_COUNT++))
npm list -g @upstash/context7-mcp &> /dev/null && ((MCP_COUNT++))
echo "$MCP_COUNT/3 servers installed"

echo ""
echo "=== System Resources ==="
echo "Available RAM: $(free -h 2>/dev/null | grep '^Mem:' | awk '{print $7}' || echo 'Unknown')"
echo "Available Storage: $(df -h $HOME 2>/dev/null | tail -1 | awk '{print $4}' || echo 'Unknown')"
echo "CPU Load: $(cat /proc/loadavg 2>/dev/null | awk '{print $1 " " $2 " " $3}' || echo 'Unknown')"

if command -v termux-battery-status &> /dev/null; then
    BATTERY=$(termux-battery-status 2>/dev/null | grep percentage | awk '{print $2}')
    [ -n "$BATTERY" ] && echo "Battery: $BATTERY%"
fi

echo ""
echo "=== Installation Summary ==="
if command -v claude &> /dev/null && command -v mc &> /dev/null && [ -f "$HOME/CRAG/run_crag.py" ]; then
    echo "✓ Core installation successful!"
    echo "✓ Ready to use Claude Code Mobile"
    echo ""
    echo "Quick start commands:"
    echo "  claude          - Start Claude Code CLI"  
    echo "  mc chat         - Start Mini Claude chat"
    echo "  crag-search     - Search conversation history"
    echo "  System-Status   - Check system status (widget)"
else
    echo "✗ Installation incomplete"
    echo "Please review the test results above"
fi

echo ""
echo "Installation log: $HOME/claude-mobile-install.log"
EOF
    
    chmod +x "$HOME/test-claude-mobile"
    
    success "Test script created"
}

# Main installation function
main() {
    echo "================================================================"
    echo "Claude Code Mobile - Automated Installation Script v$SCRIPT_VERSION"
    echo "Copyright (c) 2024 Shawn Nichols Sr., Nichols AI, Nichols Transco LLC"
    echo "================================================================"
    echo ""
    
    log "Starting Claude Code Mobile installation..."
    
    # Check if running as root (not recommended)
    if [ "$EUID" -eq 0 ]; then
        warning "Running as root is not recommended for Termux installations"
    fi
    
    # Installation steps
    check_requirements
    backup_existing
    update_packages
    install_packages
    install_claude_code
    install_crag
    install_mini_claude
    install_nichols_bridge
    install_mcp_servers
    setup_termux_widgets
    configure_auto_startup
    configure_security
    create_test_script
    
    echo ""
    success "Claude Code Mobile installation completed!"
    echo ""
    echo "=== Next Steps ==="
    echo "1. Reload your shell: source ~/.bashrc"
    echo "2. Add API keys: cp ~/.config/claude-mobile/api-keys.template ~/.config/claude-mobile/api-keys"
    echo "3. Edit API keys: nano ~/.config/claude-mobile/api-keys"
    echo "4. Test installation: ~/test-claude-mobile"
    echo "5. Add Termux widgets to home screen from Termux:Widget app"
    echo ""
    echo "=== Quick Start Commands ==="
    echo "  claude          - Start Claude Code CLI"
    echo "  mc chat         - Interactive Mini Claude chat"
    echo "  crag-search     - Search conversation history"
    echo "  start-bridge    - Start device integration server"
    echo ""
    echo "Installation log saved to: $LOG_FILE"
    echo "Backup created at: $BACKUP_DIR"
    echo ""
    echo "Enjoy Claude Code Mobile!"
}

# Run main installation
main "$@"