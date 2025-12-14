# Docker Development Workflow

This document outlines the Docker-based development workflow for the Discord Bots project.

## Overview

This project uses Docker exclusively for development and deployment to ensure:
- **Consistency**: Same environment across all machines
- **Security**: No need for local Elixir installations
- **Maintainability**: Documented, reproducible builds
- **Isolation**: Each bot has its own container and database

## Prerequisites

- Docker Desktop installed and running
- Docker Compose installed

## Quick Start

```bash
# Start the raffle_bot in development mode
RAFFLE_BOT_TOKEN=your_token SECRET_KEY_BASE=your_secret docker-compose up raffle_bot

# Or run in background
RAFFLE_BOT_TOKEN=your_token SECRET_KEY_BASE=your_secret docker-compose up -d raffle_bot

# View logs
docker-compose logs -f raffle_bot

# Stop the bot
docker-compose down
```

## Common Tasks

### 1. Fixing Dependency Issues

If you encounter dependency errors during build, use a temporary container to fix `mix.lock`:

```bash
docker run --rm \
  -v "/Users/fazal/dev/discord-bots:/app" \
  -w /app \
  hexpm/elixir:1.15.8-erlang-26.2.5.2-debian-bookworm-20240812-slim \
  bash -c "mix local.hex --force && mix local.rebar --force && mix deps.unlock --all && mix deps.get"

# Commit the updated mix.lock
git add mix.lock
git commit -m "fix: Update dependencies"
```

### 2. Building the Docker Image

```bash
# Build with dummy tokens (for build only)
RAFFLE_BOT_TOKEN=build_only SECRET_KEY_BASE=build_only docker-compose build raffle_bot

# Force rebuild without cache (if needed)
RAFFLE_BOT_TOKEN=build_only SECRET_KEY_BASE=build_only docker-compose build --no-cache raffle_bot
```

### 3. Running Database Migrations

```bash
# Run migrations using the Docker image
docker run --rm \
  -v raffle_bot_data:/data \
  -e DATABASE_PATH=/data/raffle.db \
  -e SECRET_KEY_BASE=migration_only \
  -e DISCORD_BOT_TOKEN=migration_only \
  discord-bots/raffle_bot:latest \
  eval 'RaffleBot.Release.migrate()'
```

### 4. Inspecting the Database

```bash
# Check table schema
docker run --rm \
  -v raffle_bot_data:/data \
  debian:bookworm-20240812-slim \
  sh -c 'apt-get update -qq && apt-get install -y -qq sqlite3 > /dev/null 2>&1 && sqlite3 /data/raffle.db ".schema raffles"'

# Query database
docker run --rm \
  -v raffle_bot_data:/data \
  debian:bookworm-20240812-slim \
  sh -c 'apt-get update -qq && apt-get install -y -qq sqlite3 > /dev/null 2>&1 && sqlite3 /data/raffle.db "SELECT * FROM raffles;"'
```

### 5. Interactive Shell Access

```bash
# Access the running container
docker-compose exec raffle_bot /bin/sh

# Or start a one-off container
docker run --rm -it \
  -v raffle_bot_data:/data \
  discord-bots/raffle_bot:latest \
  /bin/sh
```

### 6. Accessing IEx Console

```bash
# Remote console to running release
docker-compose exec raffle_bot /app/bin/raffle_bot remote

# Or start with console
docker-compose exec raffle_bot /app/bin/raffle_bot start_iex
```

## Troubleshooting

### Build Failures Due to Network Timeouts

**Symptom**: `Request failed (:timeout)` during `mix deps.get`

**Solution**: The Dockerfile already includes robust timeout settings:
```dockerfile
ENV HEX_HTTP_CONCURRENCY=1
ENV HEX_HTTP_TIMEOUT=120
```

If issues persist:
1. Check your internet connection
2. Verify Docker has network access
3. Try building at a different time (Hex.pm may be experiencing issues)

### Compilation Errors in Code

**Symptom**: `** (CompileError)` during build

**Solution**:
1. Check the error message for the file and line number
2. Fix the syntax error in your code
3. Commit the fix
4. Rebuild the Docker image

**Common Issues**:
- String interpolation in `@doc` attributes (use plain text instead)
- Missing module aliases
- Syntax errors in Elixir code

### mix.lock Out of Sync

**Symptom**: `Unknown package X in lockfile`

**Solution**: Use a temporary container to regenerate mix.lock (see section 1 above)

### Database Locked Errors

**Symptom**: `database is locked` errors

**Solution**:
1. Ensure only one instance of the bot is running
2. Stop all containers: `docker-compose down`
3. Restart: `docker-compose up raffle_bot`

## Dockerfile Configuration

The project uses a multi-stage Dockerfile with build-time optimizations:

- **HEX_HTTP_CONCURRENCY=1**: Reduces concurrent downloads to prevent timeouts
- **HEX_HTTP_TIMEOUT=120**: Increases timeout to 120 seconds for slow networks
- **MIX_ENV=prod**: Builds production release for deployment

These settings prioritize reliability over build speed.

## Volume Management

Each bot has its own named volume for database persistence:

```bash
# List volumes
docker volume ls | grep raffle

# Inspect volume
docker volume inspect raffle_bot_data

# Backup database
docker run --rm \
  -v raffle_bot_data:/data \
  -v "$(pwd):/backup" \
  debian:bookworm-20240812-slim \
  cp /data/raffle.db /backup/raffle_backup.db

# Restore database
docker run --rm \
  -v raffle_bot_data:/data \
  -v "$(pwd):/backup" \
  debian:bookworm-20240812-slim \
  cp /backup/raffle_backup.db /data/raffle.db
```

## Adding a New Bot

When creating a new bot in the umbrella:

1. **Create the app**:
   ```bash
   cd apps
   docker run --rm -v "$(pwd):/app" -w /app \
     hexpm/elixir:1.15.8-erlang-26.2.5.2-debian-bookworm-20240812-slim \
     bash -c "mix phx.new bot_name --app bot_name --no-html --no-assets --umbrella"
   ```

2. **Update docker-compose.yml**: Add new service following the template
3. **Update Dockerfile**: Already supports multiple apps via `APP_NAME` arg
4. **Create `.env` entry**: Add `BOT_NAME_TOKEN=...`
5. **Build**: `docker-compose build bot_name`
6. **Run**: `docker-compose up bot_name`

## Best Practices

1. **Always use Docker**: Never install Elixir locally - use Docker for all operations
2. **Commit dependency changes**: Always commit `mix.lock` updates
3. **Use meaningful tokens**: Use descriptive placeholder tokens for builds (e.g., `build_only`)
4. **Test migrations**: Run migrations in Docker before deploying
5. **Monitor logs**: Use `docker-compose logs -f` to watch for issues
6. **Back up volumes**: Regularly backup database volumes before major changes

## Security Considerations

- **.env file**: Never commit `.env` - it contains secrets
- **Token security**: Use environment variables, never hardcode tokens
- **Volume permissions**: Docker volumes are owned by root - use Docker commands to access
- **Network isolation**: Containers are isolated by default
- **Production secrets**: Use Fly.io secrets for deployment

## Additional Resources

- [Dockerfile Reference](/Dockerfile)
- [Docker Compose Config](/docker-compose.yml)
- [Deployment Guide](DEVELOPMENT.md#5-deployment-flyio)
- [Troubleshooting Guide](../operations/TROUBLESHOOTING.md)

---

**Last Updated**: 2025-12-14
**Maintainer**: Project Team
