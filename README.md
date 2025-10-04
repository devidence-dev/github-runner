# 🏃 GitHub Actions Self-Hosted Runner (Organization-Level)

This repository packages a containerized GitHub Actions self-hosted runner that registers at the **organization level**, making it available to all repositories within your GitHub organization.

## 🎯 Purpose
- Provide a Docker image and docker-compose orchestration to run a self-hosted GitHub Actions runner
- Register the runner at **organization level** (not tied to a specific repository)
- Allow any repository in your organization to use this runner

## 📦 Primary files
- `Dockerfile` — Image definition with configurable runner version (ARG RUNNER_VERSION)
- `docker-compose.yml` — Orchestration for running the container
- `start.sh` — Container entrypoint that handles registration at org-level and runner lifecycle
- `.env.example` — Example environment variables
- `.gitignore` — Prevents committing secrets and build artifacts

## 🚀 Quick start

### 1️⃣ Copy and configure environment file

```bash
cp .env.example .env
```

### 2️⃣ Edit `.env` and set **required** variables:

- `GH_OWNER` — Your GitHub **organization name** (required)
- `GH_TOKEN` — Personal Access Token with **admin:org** scope (required for org-level runners)

> ⚠️ **Important**: For organization-level runners, your token needs the `admin:org` scope, not just `repo`.

### ✅ Environment variables

**Required:**
- `GH_OWNER` — GitHub organization name (required)
- `GH_TOKEN` — Personal Access Token with `admin:org` scope (required)

**Optional:**
- `RUNNER_NAME` — Friendly name for the runner (default: `raspi-runner-<timestamp>`)
- `RUNNER_DATA` — Path to persist runner data (default: `./runner-data`)
- `REGISTRATION_TOKEN` — Manual registration token (if automatic retrieval fails)
- `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` — For optional notifications

> 📝 **Note**: `GH_REPOSITORY` is **not needed** for organization-level runners

### 3️⃣ Example `.env` configuration:

```bash
# GitHub organization configuration
GH_OWNER=your-organization-name
GH_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxx

# Runner configuration
RUNNER_NAME=org-runner-01
RUNNER_DATA=./runner-data

# Optional: manual registration token
# REGISTRATION_TOKEN=your_manual_token_here

# Optional: Telegram notifications
# TELEGRAM_BOT_TOKEN=your_bot_token_here
# TELEGRAM_CHAT_ID=your_chat_id_here
```

### 4️⃣ Build and run

```bash
# Build and start the runner
docker-compose up -d

# Follow logs to verify registration
docker-compose logs -f github-runner
```

You should see:
```
✅ Runner configured successfully
🏃 Starting runner...
```

## 📋 Behavior notes

- The runner registers at **organization level** using the GitHub API endpoint `/orgs/{org}/actions/runners/registration-token`
- `start.sh` automatically obtains a registration token using `GH_TOKEN`
- The runner will be available to **all repositories** in your organization
- If automatic token retrieval fails, you can set `REGISTRATION_TOKEN` manually in `.env`
- Runner version can be customized at build time: `docker build --build-arg RUNNER_VERSION=2.329.0 .`

## 🔒 Security

- **Never commit** `.env` or tokens to the repository (`.gitignore` prevents this)
- Use a token with minimal required scope: `admin:org` for organization runners
- The runner runs in an isolated Docker container with controlled access

## 🔧 Troubleshooting

### Runner doesn't register
- Check logs: `docker-compose logs -f github-runner`
- Verify `GH_TOKEN` has `admin:org` scope (not just `repo`)
- Confirm `GH_OWNER` is the **organization name**, not a username
- Check that your organization allows self-hosted runners

### Docker permission errors
- Ensure the host user can access Docker socket
- Verify the container runs with appropriate privileges (privileged: true in docker-compose.yml)

### Token issues
- Generate a new token at: GitHub → Settings → Developer settings → Personal access tokens
- Required scope: `admin:org` for organization-level runners
- Token must belong to a user with admin access to the organization
