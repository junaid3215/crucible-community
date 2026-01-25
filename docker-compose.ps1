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

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan
Write-Host " _______  _______           _______ _________ ______   _        _______ " -ForegroundColor Cyan
Write-Host "(  ____ \(  ____ )|\     /|(  ____ \\__   __/(  ___ \ ( \      (  ____ \" -ForegroundColor Cyan
Write-Host "| (    \/| (    )|| )   ( || (    \/   ) (   | (   ) )| (      | (    \/" -ForegroundColor Cyan
Write-Host "| |      | (____)|| |   | || |         | |   | (__/ / | |      | (__    " -ForegroundColor Cyan
Write-Host "| |      |     __)| |   | || |         | |   |  __ (  | |      |  __)   " -ForegroundColor Cyan
Write-Host "| |      | (\ (   | |   | || |         | |   | (  \ \ | |      | (      " -ForegroundColor Cyan
Write-Host "| (____/\| ) \ \__| (___) || (____/\___) (___| )___) )| (____/\| (____/\" -ForegroundColor Cyan
Write-Host "(_______/|/   \__/(_______)(_______/\_______/|/ \___/ (_______/(_______/" -ForegroundColor Cyan
Write-Host "                                                                        " -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan
Write-Host "  Community Edition v0.1.0" -ForegroundColor Gray
Write-Host "  AI-Powered Multi-Agent Debate Platform" -ForegroundColor DarkGray
Write-Host "" -ForegroundColor Gray
Write-Host "  Copyright (C) 2026 Roundtable Labs Pty Ltd" -ForegroundColor DarkGray
Write-Host "  Licensed under AGPL-3.0" -ForegroundColor DarkGray
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Check if .env exists
if (-not (Test-Path ".env")) {
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "First-time setup: Generating secure secrets..." -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Check if Python is available
    try {
        $pythonVersion = python --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Python not found"
        }
    } catch {
        Write-Host "ERROR: Python is required but not found." -ForegroundColor Red
        Write-Host "Please install Python 3 and try again."
        exit 1
    }
    
    # Generate secure random keys
    $ENCRYPTION_KEY = python -c "import secrets; print(secrets.token_urlsafe(32))"
    $JWT_SECRET = python -c "import secrets; print(secrets.token_urlsafe(48))"
    $JWT_REFRESH_SECRET = python -c "import secrets; print(secrets.token_urlsafe(48))"
    $AUTH_PASSWORD = python -c "import secrets; print(secrets.token_urlsafe(16))"
    $POSTGRES_USER = python -c "import secrets, string; print(''.join(secrets.choice(string.ascii_lowercase + string.digits) for _ in range(12)))"
    $POSTGRES_PASSWORD = python -c "import secrets; print(secrets.token_urlsafe(24))"
    $REDIS_PASSWORD = python -c "import secrets; print(secrets.token_urlsafe(32))"
    
    # Create .env file
    $envContent = @"
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
"@
    
    $envContent | Out-File -FilePath ".env" -Encoding utf8 -NoNewline
    
    Write-Host "Secrets generated successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "IMPORTANT: Save your credentials!" -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Your secure credentials have been generated:"
    Write-Host "  - Authentication password: $AUTH_PASSWORD"
    Write-Host "  - Database user: $POSTGRES_USER"
    Write-Host "  - Database password: $POSTGRES_PASSWORD"
    Write-Host "  - Redis password: $REDIS_PASSWORD"
    Write-Host ""
    Write-Host "!!!  These values are saved in: .env" -ForegroundColor Yellow
    Write-Host "   Keep this file secure and never commit it to version control!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Starting services..."
    Write-Host ""
}

# Use docker compose (newer) or docker-compose (older)
# Try docker-compose (older syntax) first as it's more common
$useNewSyntax = $false

# Check if docker-compose (older) exists
$null = Get-Command docker-compose -ErrorAction SilentlyContinue
if ($?) {
    # docker-compose exists (older syntax)
    $useNewSyntax = $false
} else {
    # Try docker compose (newer syntax)
    $null = docker compose version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $useNewSyntax = $true
    } else {
        Write-Host "ERROR: Neither 'docker compose' nor 'docker-compose' is available." -ForegroundColor Red
        Write-Host "Please install Docker Compose and try again." -ForegroundColor Red
        Write-Host ""
        Write-Host "To check if Docker Compose is installed:" -ForegroundColor Yellow
        Write-Host "  docker-compose --version" -ForegroundColor Yellow
        Write-Host "  OR" -ForegroundColor Yellow
        Write-Host "  docker compose version" -ForegroundColor Yellow
        exit 1
    }
}

# Try production compose file first (pre-built images)
# If images aren't available, fall back to building from source
$composeFile = "docker-compose.prod.yml"
$fallbackFile = "docker-compose.yml"

# For 'up' command, check if production images are available
if ($args -contains "up" -or $args -contains "start") {
    Write-Host "Checking for pre-built images..." -ForegroundColor Cyan
    $null = if ($useNewSyntax) {
        docker compose -f $composeFile pull api 2>&1 | Out-Null
    } else {
        docker-compose -f $composeFile pull api 2>&1 | Out-Null
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Pre-built images not available. Building from source..." -ForegroundColor Yellow
        Write-Host "(This may take a few minutes on first run)" -ForegroundColor Yellow
        Write-Host ""
        $composeFile = $fallbackFile
    } else {
        Write-Host "Using pre-built images from GitHub Container Registry" -ForegroundColor Green
        Write-Host ""
    }
}

# Pass all arguments to docker-compose
if ($useNewSyntax) {
    # docker compose (two words)
    & docker compose -f $composeFile $args
} else {
    # docker-compose (one word)
    & docker-compose -f $composeFile $args
}
