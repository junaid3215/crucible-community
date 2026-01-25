#!/bin/bash
# ============================================================================
# Crucible Community Edition
# Copyright (C) 2026 Roundtable Labs Pty Ltd
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# Version: 0.1.0
# License: AGPL-3.0
# Documentation: https://github.com/roundtable-labs/crucible-community
# ============================================================================
#
# Wrapper script that auto-generates .env if missing, then runs docker-compose
# This allows true one-click: docker-compose up

set -e

echo ""
echo "============================================================================"
echo ""
echo " _______  _______           _______ _________ ______   _        _______ "
echo "(  ____ \(  ____ )|\     /|(  ____ \\__   __/(  ___ \ ( \      (  ____ \\"
echo "| (    \/| (    )|| )   ( || (    \/   ) (   | (   ) )| (      | (    \\/"
echo "| |      | (____)|| |   | || |         | |   | (__/ / | |      | (__    "
echo "| |      |     __)| |   | || |         | |   |  __ (  | |      |  __)   "
echo "| |      | (\ (   | |   | || |         | |   | (  \ \ | |      | (      "
echo "| (____/\| ) \ \__| (___) || (____/\___) (___| )___) )| (____/\| (____/\\"
echo "(_______/|/   \__/(_______)(_______/\_______/|/ \___/ (_______/(_______/"
echo "                                                                        "
echo ""
echo "  Community Edition v0.1.0"
echo "  AI-Powered Multi-Agent Debate Platform"
echo ""
echo "  Copyright (C) 2026 Roundtable Labs Pty Ltd"
echo "  Licensed under AGPL-3.0"
echo "============================================================================"
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "=================================================="
    echo "First-time setup: Generating secure secrets..."
    echo "=================================================="
    echo ""
    
    # Check if Python 3 is available
    if ! command -v python3 &> /dev/null; then
        echo "ERROR: python3 is required but not found."
        echo "Please install Python 3 and try again."
        exit 1
    fi
    
    # Generate secure random keys
    ENCRYPTION_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
    JWT_SECRET=$(python3 -c "import secrets; print(secrets.token_urlsafe(48))")
    JWT_REFRESH_SECRET=$(python3 -c "import secrets; print(secrets.token_urlsafe(48))")
    AUTH_PASSWORD=$(python3 -c "import secrets; print(secrets.token_urlsafe(16))")
    POSTGRES_USER=$(python3 -c "import secrets, string; print(''.join(secrets.choice(string.ascii_lowercase + string.digits) for _ in range(12)))")
    POSTGRES_PASSWORD=$(python3 -c "import secrets; print(secrets.token_urlsafe(24))")
    REDIS_PASSWORD=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
    
    # Create .env file
    cat > ".env" << EOF
# Crucible Community Edition Configuration
# Auto-generated on first docker-compose run

# ============================================================================
# SECURITY - DO NOT SHARE THESE VALUES!
# ============================================================================

# API Key Encryption Key (32 characters)
# WARNING: If this changes, all encrypted API keys will become unreadable!
API_KEY_ENCRYPTION_KEY=$ENCRYPTION_KEY

# Community Edition Authentication Password
# Auto-generated secure password - save this value!
# For production, consider hashing: cd service && python -m scripts.hash_password <password>
ROUNDTABLE_COMMUNITY_AUTH_PASSWORD=$AUTH_PASSWORD

# JWT Secrets (used for token signing)
ROUNDTABLE_JWT_SECRET=$JWT_SECRET
ROUNDTABLE_JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET

# Database Credentials
# IMPORTANT: Save these values - you'll need them if you need to access the database directly
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD

# Redis Credentials
# IMPORTANT: Save this value - Redis requires authentication
REDIS_PASSWORD=$REDIS_PASSWORD

# ============================================================================
# OPTIONAL - Provider API Keys (if you want server-side defaults)
# ============================================================================
# Users can also set their own API keys in the Settings page after login

# OpenRouter API Key (optional - users can provide their own)
ROUNDTABLE_OPENROUTER_API_KEY=

# Eden AI API Key (optional - for AI research features)
ROUNDTABLE_EDEN_AI_API_KEY=

# ============================================================================
# OPTIONAL - LLM Rate Limiting Configuration
# ============================================================================
# Configure rate limiting for LLM API calls to prevent exceeding provider limits.

# Enable Rate Limiting (default: true - rate limiting enabled)
# You can change this in .env file if needed.
ROUNDTABLE_ENABLE_RATE_LIMITING=true

# LLM Rate Limit (Tokens Per Minute) - default: 100000
ROUNDTABLE_LLM_RATE_LIMIT_TPM=100000

# LLM Rate Limit Window (Seconds) - default: 60 (one minute window)
ROUNDTABLE_LLM_RATE_LIMIT_WINDOW_SECONDS=60
EOF
    
    chmod 600 ".env"
    
    echo "✓ Secrets generated successfully!"
    echo ""
    echo "=================================================="
    echo "IMPORTANT: Save your credentials!"
    echo "=================================================="
    echo ""
    echo "Your secure credentials have been generated:"
    echo "  - Authentication password: $AUTH_PASSWORD"
    echo "  - Database user: $POSTGRES_USER"
    echo "  - Database password: $POSTGRES_PASSWORD"
    echo "  - Redis password: $REDIS_PASSWORD"
    echo ""
    echo "⚠️  These values are saved in: .env"
    echo "   Keep this file secure and never commit it to version control!"
    echo ""
    echo "Starting services..."
    echo ""
fi

# Use docker compose (newer) or docker-compose (older)
if docker compose version &> /dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

# Try production compose file first (pre-built images)
# If images aren't available, fall back to building from source
COMPOSE_FILE="docker-compose.prod.yml"
FALLBACK_FILE="docker-compose.yml"

# For 'up' command, check if production images are available
if [[ "$*" == *"up"* ]] || [[ "$*" == *"start"* ]]; then
    echo "Checking for pre-built images..."
    if $COMPOSE_CMD -f "$COMPOSE_FILE" pull api >/dev/null 2>&1; then
        echo "Using pre-built images from GitHub Container Registry"
        echo ""
        exec $COMPOSE_CMD -f "$COMPOSE_FILE" "$@"
    else
        echo "Pre-built images not available. Building from source..."
        echo "(This may take a few minutes on first run)"
        echo ""
        exec $COMPOSE_CMD -f "$FALLBACK_FILE" "$@"
    fi
else
    # For other commands, use production file by default
    exec $COMPOSE_CMD -f "$COMPOSE_FILE" "$@"
fi
