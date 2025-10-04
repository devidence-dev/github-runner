#!/bin/bash

# GitHub Actions Runner configuration
set -e

echo "🚀 Starting GitHub Actions Runner for Raspberry Pi..."

# Validate required environment variables
echo "🔍 Checking environment variables..."
echo "   GH_OWNER: ${GH_OWNER:-'❌ Not configured'}"
echo "   GH_REPOSITORY: ${GH_REPOSITORY:-'❌ Not configured'}"
echo "   RUNNER_NAME: ${RUNNER_NAME:-'❌ Not configured'}"

# DEBUG: Check token without printing full contents
if [[ -n "$GH_TOKEN" ]]; then
    token_length=${#GH_TOKEN}
    token_preview="${GH_TOKEN:0:8}...${GH_TOKEN: -4}"
    echo "   GH_TOKEN: ✅ Configured (${token_length} chars): ${token_preview}"
else
    echo "   GH_TOKEN: ❌ Not configured"
fi

# DEBUG: Check REGISTRATION_TOKEN
if [[ -n "$REGISTRATION_TOKEN" ]]; then
    echo "   REGISTRATION_TOKEN: ✅ Manually configured"
else
    echo "   REGISTRATION_TOKEN: ⚪ Not configured (will be obtained automatically)"
fi

if [[ -z "$GH_OWNER" || -z "$GH_REPOSITORY" || -z "$GH_TOKEN" ]]; then
    echo "❌ Error: Required environment variables are not configured"
    echo "💡 Check that the .env file exists and contains the correct variables"
    exit 1
fi

# Trim possible spaces or odd characters from variables
GH_OWNER=$(echo "$GH_OWNER" | tr -d '[:space:]')
GH_REPOSITORY=$(echo "$GH_REPOSITORY" | tr -d '[:space:]')
GH_TOKEN=$(echo "$GH_TOKEN" | tr -d '[:space:]')

# Configure unique runner name
RUNNER_NAME="${RUNNER_NAME:-"raspi-runner-$(date +%s)"}"

echo "📋 Final configuration:"
echo "   Owner: '$GH_OWNER'"
echo "   Repository: '$GH_REPOSITORY'"
echo "   Runner Name: '$RUNNER_NAME'"

# Function to obtain registration token - all debug goes to STDERR
get_registration_token() {
    local response token error_message http_code body

    echo "🌐 Making request to GitHub API..." >&2
    local api_url="https://api.github.com/repos/${GH_OWNER}/${GH_REPOSITORY}/actions/runners/registration-token"
    echo "🔗 URL: $api_url" >&2
    echo "⏱️  Starting curl request..." >&2

    # Perform curl request with better error handling
    response=$(curl -s -w "\nHTTP_CODE:%{http_code}"         --connect-timeout 15 --max-time 60         -X POST         -H "Accept: application/vnd.github.v3+json"         -H "Authorization: token ${GH_TOKEN}"         "$api_url" 2>&1)

    local curl_exit_code=$?
    echo "📡 curl request completed with code: $curl_exit_code" >&2

    if [[ $curl_exit_code -ne 0 ]]; then
        echo "❌ Error: curl failed with exit code $curl_exit_code" >&2
        case $curl_exit_code in
            28) echo "💀 Timeout: The request took longer than 60 seconds" >&2 ;;
            6) echo "🌐 Error: Could not resolve hostname" >&2 ;;
            7) echo "🔌 Error: Could not connect to server" >&2 ;;
            *) echo "🚫 Unknown curl error" >&2 ;;
        esac
        echo "📋 curl output:" >&2
        echo "$response" >&2
        return 1
    fi

    # Extract HTTP code and body
    http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    body=$(echo "$response" | sed '/HTTP_CODE:/d')

    echo "📡 HTTP response code: $http_code" >&2
    echo "📋 Server response received successfully" >&2

    if [[ "$http_code" != "201" ]]; then
        echo "❌ Error calling GitHub API (HTTP $http_code)" >&2
        echo "📋 Full response:" >&2
        echo "$body" >&2

        # Try to extract error message if JSON is valid
        if command -v jq >/dev/null 2>&1; then
            error_message=$(echo "$body" | jq -r '.message // "Unknown error"' 2>/dev/null || echo "Unable to parse response")
            echo "💬 Message: $error_message" >&2
        fi

        case $http_code in
            401) echo "🔐 Invalid or expired token" >&2 ;;
            403) echo "🔐 Token lacks sufficient permissions (needs 'repo' admin)" >&2 ;;
            404) echo "📁 Repository not found or token lacks access" >&2 ;;
            422) echo "📝 Repository does not allow self-hosted runners" >&2 ;;
        esac

        return 1
    fi

    # Extract token using jq if available, otherwise fallback
    if command -v jq >/dev/null 2>&1; then
        token=$(echo "$body" | jq -r '.token // empty' 2>/dev/null)
        echo "🔧 Using jq to extract token" >&2
    else
        # Fallback method without jq
        token=$(echo "$body" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        echo "🔧 Using grep/cut to extract token (jq not available)" >&2
    fi

    if [[ -z "$token" || "$token" == "null" ]]; then
        echo "❌ Error: Could not extract token from response" >&2
        return 1
    fi

    # CRITICAL: Clean token from newline and spaces
    token=$(echo "$token" | tr -d '\n\r[:space:]')

    # Check that the cleaned token is not empty
    if [[ -z "$token" ]]; then
        echo "❌ Error: Token empty after cleaning" >&2
        return 1
    fi

    echo "✅ Registration token obtained and cleaned successfully" >&2
    echo "🔑 Token (preview): ${token:0:8}...${token: -4}" >&2
    echo "📏 Token length: ${#token} characters" >&2

    # ONLY output the cleaned token to stdout (no extra printf)
    echo "$token"
}

# Cleanup function on exit
cleanup() {
    echo "🧹 Cleaning up runner..."
    if [[ -f ".runner" ]]; then
        echo "📤 Removing runner from repository..."
        if [[ -n "$GH_TOKEN" ]]; then
            echo "🔄 Obtaining token for cleanup..."
            CLEANUP_TOKEN=$(get_registration_token 2>/dev/null)

            if [[ -n "$CLEANUP_TOKEN" && "$CLEANUP_TOKEN" != "null" ]]; then
                ./config.sh remove --unattended --token "${CLEANUP_TOKEN}" || true
            else
                echo "⚠️  Could not obtain token for cleanup, removing files locally"
                rm -f .runner .credentials .credentials_rsaparams
            fi
        else
            echo "⚠️  No GH_TOKEN for cleanup, removing files locally"
            rm -f .runner .credentials .credentials_rsaparams
        fi
    fi
}

# Setup traps for cleanup
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# Change to working directory
cd /home/runner

# Ensure _work directory exists and has correct permissions
echo "📁 Checking work directory..."
mkdir -p _work
chmod 755 _work
ls -la _work/

# Validate initial connectivity and permissions
echo "🌐 Checking connectivity to GitHub..."
user_response=$(curl -s --connect-timeout 10 --max-time 30     -H "Authorization: token ${GH_TOKEN}"     -H "Accept: application/vnd.github.v3+json"     "https://api.github.com/user" 2>&1)

if [[ $? -ne 0 ]]; then
    echo "❌ Error: Cannot connect to GitHub API"
    echo "🔍 Check your internet connection"
    echo "📋 Error: $user_response"
    exit 1
fi

# Verify the token is valid
if command -v jq >/dev/null 2>&1; then
    username=$(echo "$user_response" | jq -r '.login // empty' 2>/dev/null)
else
    username=$(echo "$user_response" | grep -o '"login":"[^"]*"' | cut -d'"' -f4)
fi

if [[ -z "$username" ]]; then
    echo "❌ Error: Invalid GitHub token"
    echo "📋 /user response:"
    echo "$user_response"
    exit 1
fi

echo "✅ Connected as user: $username"

# Verify access to the repository
echo "📁 Checking access to repository ${GH_OWNER}/${GH_REPOSITORY}..."
repo_response=$(curl -s --connect-timeout 10 --max-time 30     -H "Authorization: token ${GH_TOKEN}"     -H "Accept: application/vnd.github.v3+json"     "https://api.github.com/repos/${GH_OWNER}/${GH_REPOSITORY}" 2>&1)

if [[ $? -ne 0 ]]; then
    echo "❌ Error: Cannot access the repository"
    echo "📋 Error: $repo_response"
    exit 1
fi

# Verify that the repo exists and is accessible
if command -v jq >/dev/null 2>&1; then
    repo_name=$(echo "$repo_response" | jq -r '.name // empty' 2>/dev/null)
else
    repo_name=$(echo "$repo_response" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
fi

if [[ -z "$repo_name" ]]; then
    echo "❌ Error: Repository not found or access denied"
    echo "📋 Repository response:"
    echo "$repo_response"
    exit 1
fi

echo "✅ Repository accessible: $repo_name"

# Obtain registration token
if [[ -n "$REGISTRATION_TOKEN" ]]; then
    echo "🔐 Using manual registration token..."
    # Also clean the manual token
    REG_TOKEN=$(echo "$REGISTRATION_TOKEN" | tr -d '\n\r[:space:]')
    echo "✅ Manual token configured and cleaned"
else
    echo "🔐 Obtaining registration token automatically..."
    echo "⏱️  This may take a few seconds..."

    # Capture ONLY stdout (the token), stderr goes to the screen
    REG_TOKEN=$(get_registration_token)
    token_exit_code=$?

    if [[ $token_exit_code -ne 0 || -z "$REG_TOKEN" ]]; then
        echo "❌ Error: Could not obtain registration token automatically"
        echo "💡 Solutions:"
        echo "   1. Ensure the Personal Access Token has 'repo' (admin) permissions"
        echo "   2. Or set REGISTRATION_TOKEN manually in the .env"
        exit 1
    fi
fi

# Check if already configured
if [[ -f ".runner" ]]; then
    echo "⚠️  Runner already configured, removing previous configuration..."
    ./config.sh remove --unattended --token "${REG_TOKEN}" 2>/dev/null || {
        echo "⚠️  Could not remove cleanly, deleting files manually"
        rm -f .runner .credentials .credentials_rsaparams
    }
fi

# Ensure we have a valid, cleaned token
if [[ -z "$REG_TOKEN" ]]; then
    echo "❌ Error: Could not obtain registration token"
    exit 1
fi

echo "🔐 Final token for configuration (preview): ${REG_TOKEN:0:8}...${REG_TOKEN: -4}"
echo "📏 Final token length: ${#REG_TOKEN} characters"

# Configure the runner
echo "⚙️  Configuring runner with official GitHub Actions Runner..."
echo "🔗 URL: https://github.com/${GH_OWNER}/${GH_REPOSITORY}"
echo "🏷️  Labels: raspberry-pi,arm64,docker,pikazt"

# Run configuration with timeout
timeout 300 ./config.sh     --unattended     --url "https://github.com/${GH_OWNER}/${GH_REPOSITORY}"     --token "${REG_TOKEN}"     --name "${RUNNER_NAME}"     --labels "raspberry-pi,arm64,docker,pikazt"     --work "_work"

config_exit_code=$?

# Check configuration result
if [[ $config_exit_code -eq 124 ]]; then
    echo "❌ Error: Configuration timed out after 5 minutes (timeout)"
    exit 1
elif [[ $config_exit_code -ne 0 ]]; then
    echo "❌ Error: Runner configuration failed (code: $config_exit_code)"
    echo "💡 Check that the token is valid and not expired"
    exit 1
fi

# Verify successful configuration
if [[ ! -f ".runner" ]]; then
    echo "❌ Error: Runner configuration failed - .runner file not created"
    exit 1
fi

echo "✅ Runner configured successfully"
echo "🏃 Starting runner..."

# Run the runner with error handling
if ! ./run.sh; then
    echo "❌ Error: Runner failed during execution"
    echo "🛑 Stopping container to avoid infinite restart"
    cleanup
    exit 1
fi

echo "🏁 Runner finished its execution"
