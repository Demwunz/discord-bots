# Discord Bots Umbrella

This repository contains a collection of Discord bots developed as an Elixir umbrella project. It is designed to be fault-tolerant, persistent, and easily deployable to Fly.io.

## 🏗️ Project Architecture

This is an **Elixir Umbrella Project** designed to host multiple Discord bots. The structure is organized for clarity and scalability:

```
discord-bots/
├── apps/              # Individual bot applications (e.g., raffle_bot/)
│   └── raffle_bot/   # Example bot: raffle management
├── config/           # Shared configuration for all applications
├── docs/             # Centralized project documentation and guides
├── specs/            # Product & technical specifications for each bot
└── ...                # Other project files (mix.exs, Dockerfile, etc.)
```

### Key Features
- **Multi-app architecture**: One Dockerfile, multiple bots within a single umbrella project.
- **Isolated deployments**: Each bot can have its own independent deployment and Fly.io instance.
- **Shared infrastructure**: Common Elixir dependencies and a unified build process.
- **Independent databases**: Each bot can utilize its own SQLite database for persistence.

## 📚 Documentation

For detailed information and guides, please refer to the [Documentation Index](./docs/INDEX.md).

### Quick Links:
- [Setup Guide](./docs/development/SETUP.md) - Initial setup for Discord bot and Fly.io
- [Development Guide](./DEVELOPMENT.md) - Complete guide covering workflow, Docker, and deployment
- [Troubleshooting](./docs/operations/TROUBLESHOOTING.md) - Common deployment issues and solutions
- [Raffle Bot Overview](./apps/raffle_bot/README.md) - Specific documentation for the Raffle Bot

## Bots

*   **[Raffle Bot](./apps/raffle_bot/README.md)** - A bot for managing paid community raffles.

---

Last Updated: December 2025

