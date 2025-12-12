# Documentation Index

Welcome to the Discord Bots Umbrella documentation!

## 📚 Quick Navigation

### Getting Started
- [Setup Guide](development/SETUP.md) - Initial setup for Discord bot and Fly.io
- [Development Guide](../DEVELOPMENT.md) - Complete guide covering workflow, Docker, and deployment
- [Cheatsheet](development/CHEATSHEET.md) - Quick reference for common commands

### Deployment & Operations
- [Deployment Guide](../DEVELOPMENT.md#5-deployment-flyio) - Deploying to Fly.io (in DEVELOPMENT.md Section 5)
- [Docker Setup](../DEVELOPMENT.md#4-local-development-with-docker) - Local development with Docker (in DEVELOPMENT.md Section 4)
- [Git Workflow](../DEVELOPMENT.md#2-git-workflow-strict) - Git worktrees and commit standards (in DEVELOPMENT.md Section 2)
- [Troubleshooting](operations/TROUBLESHOOTING.md) - Common deployment issues and solutions

### AI Agent Guides
- [General Agents Guide](agents/AGENTS.md) - Guidelines for AI agents working on this project
- [Gemini-Specific Guide](agents/GEMINI.md) - Gemini-specific instructions

### App-Specific Documentation
- [Raffle Bot](../apps/raffle_bot/README.md) - Overview of the raffle bot
- [Raffle Bot Guide](../apps/raffle_bot/docs/GUIDE.md) - Detailed usage guide

### Product Specifications
- [Raffle Bot - Product Requirements](../specs/raffle_bot/product_requirements.md)
- [Raffle Bot - Technical Requirements](../specs/raffle_bot/technical_requirements.md)
- [Raffle Bot - Testing Guide](../specs/raffle_bot/TESTS.md)

---

## 🏗️ Project Architecture

This is an **Elixir Umbrella Project** designed to host multiple Discord bots:

```
discord-bots/
├── apps/              # Individual bot applications
│   └── raffle_bot/   # First bot (raffle management)
├── config/           # Shared configuration
├── docs/             # Centralized documentation
├── specs/            # Product & technical specifications
└── ...
```

### Key Features
- **Multi-app architecture**: One Dockerfile, multiple bots
- **Isolated deployments**: Each bot has its own Fly.io instance
- **Shared infrastructure**: Common Elixir dependencies and build process
- **Independent databases**: Each bot has its own SQLite database

---

## 🤖 For AI Agents

If you're an AI agent working on this project:

1. **Start here**: Read [CLAUDE.md](../CLAUDE.md) in the root directory
2. **Agent guidelines**: See [agents/AGENTS.md](agents/AGENTS.md)
3. **Current context**: All documentation has been recently updated (Dec 2025)
4. **Architecture notes**: Review [DEVELOPMENT.md Section 5](../DEVELOPMENT.md#5-deployment-flyio) for deployment patterns

---

## 📝 Documentation Guidelines

When adding new documentation:

- **General docs**: Add to `/docs/` with appropriate subdirectory
- **App-specific**: Add to `/apps/{app_name}/docs/`
- **Specs**: Add to `/specs/{app_name}/`
- **AI instructions**: Update `/CLAUDE.md` and `/docs/agents/`

Keep docs:
- **Up to date** with code changes
- **Well-organized** with clear headers
- **Cross-referenced** with links to related docs
- **Discoverable** by updating this index

---

Last Updated: December 2025
