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
