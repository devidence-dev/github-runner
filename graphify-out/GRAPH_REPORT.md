# Graph Report - github-runner  (2026-07-14)

## Corpus Check
- 5 files · ~3,793 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 61 nodes · 65 edges · 12 communities (9 shown, 3 thin omitted)
- Extraction: 88% EXTRACTED · 12% INFERRED · 0% AMBIGUOUS · INFERRED: 8 edges (avg confidence: 0.81)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `f3fcc2e4`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Build & Deploy Pipeline
- Runner Service & Update Checks
- Image Cleanup & Pruning
- Runner Entrypoint Script
- Package Version Checker
- Runner Registration Config
- Graphify Meta Docs
- Environment File Handling
- Telegram Notifications
- 🏃 GitHub Actions Self-Hosted Runner (Organization-Level)
- 🚀 Quick start
- CLAUDE.md

## God Nodes (most connected - your core abstractions)
1. `🏃 GitHub Actions Self-Hosted Runner (Organization-Level)` - 7 edges
2. `github-runner service` - 7 edges
3. `🚀 Quick start` - 6 edges
4. `build job (Build and push image)` - 5 edges
5. `🔧 Troubleshooting` - 4 edges
6. `deploy job (Update homelab)` - 4 edges
7. `image-container-reporter (icr) tool` - 4 edges
8. `Dockerfile` - 4 edges
9. `start.sh script` - 3 edges
10. `Check Docker Updates & Notify Workflow` - 3 edges

## Surprising Connections (you probably didn't know these)
- `github-runner service` --conceptually_related_to--> `Telegram update notification`  [INFERRED]
  docker-compose.yml → .github/workflows/check-updates.yml
- `github-runner service` --conceptually_related_to--> `Telegram cleanup notification`  [INFERRED]
  docker-compose.yml → .github/workflows/cleanup.yml
- `Runtime dependencies (curl, jq, git, docker.io, docker-compose, sudo, python3, ...)` --conceptually_related_to--> `Check Docker Updates & Notify Workflow`  [INFERRED]
  packages.yml → .github/workflows/check-updates.yml
- `Runtime dependencies (curl, jq, git, docker.io, docker-compose, sudo, python3, ...)` --conceptually_related_to--> `Cleanup unused images Workflow`  [INFERRED]
  packages.yml → .github/workflows/cleanup.yml
- `github-runner service` --references--> `Dockerfile`  [EXTRACTED]
  docker-compose.yml → README.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Self-hosted Runner CI/CD Pipelines** — _github_workflows_build_and_deploy_workflow, _github_workflows_check_updates_workflow, _github_workflows_cleanup_workflow, docker_compose_github_runner_service [INFERRED 0.85]
- **Telegram Notification Integration** — _github_workflows_check_updates_telegram_notify, _github_workflows_cleanup_telegram_notify, docker_compose_github_runner_service, readme_telegram_notifications [INFERRED 0.75]
- **RUNNER_VERSION Build Argument Flow** — docker_compose_runner_version_arg, _github_workflows_build_and_deploy_workflow, readme_dockerfile [INFERRED 0.85]

## Communities (12 total, 3 thin omitted)

### Community 0 - "Build & Deploy Pipeline"
Cohesion: 0.28
Nodes (9): build job (Build and push image), deploy job (Update homelab), HOMELAB_DEPLOY_TOKEN secret, devidence-dev/homelab repository, Build and Deploy Workflow, Zot Container Registry (zot.devidence.dev), RUNNER_VERSION build argument, Build-stage dependencies (curl, tar, gzip, ca-certificates) (+1 more)

### Community 1 - "Runner Service & Update Checks"
Cohesion: 0.36
Nodes (8): check-updates job, image-container-reporter (icr) tool, Telegram update notification, Check Docker Updates & Notify Workflow, Cleanup unused images Workflow, extra-images.yml volume mount (/opt/runner/extra-images.yml), github-runner service, Runtime dependencies (curl, jq, git, docker.io, docker-compose, sudo, python3, ...)

### Community 2 - "Image Cleanup & Pruning"
Cohesion: 0.40
Nodes (6): Kubernetes pod image scan, cleanup job, Prune containerd images step, crictl tool (containerd CLI), Prune Docker images step, Telegram cleanup notification

### Community 3 - "Runner Entrypoint Script"
Cohesion: 0.60
Nodes (3): cleanup(), remove_existing_runner(), start.sh script

### Community 5 - "Runner Registration Config"
Cohesion: 0.50
Nodes (4): GH_OWNER (organization name), GH_TOKEN (admin:org scope), Organization-level runner registration, start.sh (container entrypoint)

### Community 6 - "Graphify Meta Docs"
Cohesion: 0.67
Nodes (3): GRAPH_REPORT.md, Graphify Knowledge Graph, graphify-out/wiki/index.md

### Community 7 - "Environment File Handling"
Cohesion: 0.67
Nodes (3): .env file, .env.example, .gitignore

### Community 9 - "🏃 GitHub Actions Self-Hosted Runner (Organization-Level)"
Cohesion: 0.20
Nodes (9): 📋 Behavior notes, Docker permission errors, 🏃 GitHub Actions Self-Hosted Runner (Organization-Level), 📦 Primary files, 🎯 Purpose, Runner doesn't register, 🔒 Security, Token issues (+1 more)

### Community 10 - "🚀 Quick start"
Cohesion: 0.33
Nodes (6): 1️⃣ Copy and configure environment file, 2️⃣ Edit `.env` and set **required** variables:, 3️⃣ Example `.env` configuration:, 4️⃣ Build and run, ✅ Environment variables, 🚀 Quick start

## Knowledge Gaps
- **24 isolated node(s):** `graphify`, `🎯 Purpose`, `📦 Primary files`, `1️⃣ Copy and configure environment file`, `2️⃣ Edit `.env` and set **required** variables:` (+19 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `github-runner service` connect `Runner Service & Update Checks` to `Build & Deploy Pipeline`, `Image Cleanup & Pruning`, `Environment File Handling`?**
  _High betweenness centrality (0.115) - this node is a cross-community bridge._
- **Why does `🏃 GitHub Actions Self-Hosted Runner (Organization-Level)` connect `🏃 GitHub Actions Self-Hosted Runner (Organization-Level)` to `🚀 Quick start`?**
  _High betweenness centrality (0.047) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `github-runner service` (e.g. with `Telegram update notification` and `Telegram cleanup notification`) actually correct?**
  _`github-runner service` has 3 INFERRED edges - model-reasoned connections that need verification._
- **What connects `graphify`, `🎯 Purpose`, `📦 Primary files` to the rest of the system?**
  _24 weakly-connected nodes found - possible documentation gaps or missing edges._