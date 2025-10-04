# GitHub Actions Self-Hosted Runner

This repository packages a containerized GitHub Actions self-hosted runner and provides orchestration and startup logic to register the runner with a repository.

Purpose
- Provide a Docker image and a docker-compose orchestration to run a self-hosted GitHub Actions runner.

Primary files
- `Dockerfile` — image definition
- `docker-compose.yml` — orchestration for running the container
- `start.sh` — container entrypoint that handles registration and runner lifecycle
- `.env.example` — example environment variables

Quick start
1. Copy the example env and edit values:

```bash
cp .env.example .env
```

2. Edit `.env` and set required variables (at minimum):
- `GH_OWNER` — organization or username
- `GITHUB_TOKEN` — Personal Access Token with `repo` scope

### ✅ Latest env variables (present in `.env.example`)

- `GH_OWNER` — organization or username (required)
- `GH_REPOSITORY` — repository name (optional; used by start script to form URL)
- `GH_TOKEN` — Personal Access Token with `repo` scope (required)
- `RUNNER_NAME` — friendly name for the runner (optional)
- `RUNNER_DATA` — path to persist runner data (default: `./runner-data`)
- `REGISTRATION_TOKEN` — optional manual registration token (if automatic retrieval fails)
- `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` — optional; for notifications

3. Example `.env` quick template (edit values):

```bash
# GitHub configuration
GH_OWNER=your-organization-or-username
GH_REPOSITORY=your-repo-name
GH_TOKEN=ghp_xxx_your_token_here

# Runner configuration
RUNNER_NAME=raspi-runner-01
RUNNER_DATA=./runner-data

# Optional: manual registration token
# REGISTRATION_TOKEN=your_manual_token_here

# Optional: Telegram notifications
# TELEGRAM_BOT_TOKEN=your_bot_token_here
# TELEGRAM_CHAT_ID=your_chat_id_here
```

3. Build and run with docker-compose:

```bash
docker-compose up -d

# to follow logs
docker-compose logs -f github-runner
```

Behavior notes
- `start.sh` will try to obtain a registration token from the GitHub API using `GITHUB_TOKEN` and register the runner automatically. If automatic registration fails or you prefer manual control, set `REGISTRATION_TOKEN` in `.env`.
- Keep secrets out of the repository. Do not commit `.env` or tokens.

Want to remove more files?
If you want me to delete any files or further prune the repository, tell me which files to remove and I'll proceed after your confirmation.

Troubleshooting quick tips
- If the runner doesn't register, check `docker-compose logs -f github-runner` and confirm `GH_TOKEN` has `repo` scope.
- If you get permission errors with Docker socket, ensure the host user can access Docker or run the container with appropriate privileges.

Made changes to `.env.example` and `docker-compose.yml` are reflected here. If you want different default paths, labels, or remove workspace-specific comments, I can update them.
