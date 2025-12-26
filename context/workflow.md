# Workflow Context

## Development Setup

### Prerequisites

- Elixir 1.15+
- Discord bot token (from Discord Developer Portal)
- Docker (optional, for containerized development)

### Local Setup

```bash
# Install dependencies
mix deps.get

# Create and migrate database
mix ecto.create
mix ecto.migrate

# Start interactive shell with bot
DISCORD_BOT_TOKEN=your_token iex -S mix phx.server
```

### Docker Setup

```bash
# Build and run
docker-compose up raffle_bot

# Rebuild after changes
docker-compose up --build raffle_bot
```

## Development Commands

| Command | Purpose |
|---------|---------|
| `mix deps.get` | Install dependencies |
| `mix ecto.create` | Create database |
| `mix ecto.migrate` | Run migrations |
| `mix ecto.reset` | Reset to clean state |
| `mix test` | Run all tests |
| `mix precommit` | Pre-commit checks (compile, format, test) |
| `iex -S mix phx.server` | Interactive development server |

## Git Workflow

### Branching

- Main branch: `main`
- Feature branches: `feat/<issue-id>-description`
- Bug fixes: `fix/<issue-id>-description`

### Commit Messages

Conventional commits with issue ID:

```
feat(raffle): [#12] add auto-close functionality
fix(claims): [#15] handle duplicate claim edge case
docs(readme): update setup instructions
```

### Pre-commit Checks

Run before committing:

```bash
mix precommit
```

This runs:
1. `mix compile --warnings-as-errors`
2. `mix deps.unlock --unused`
3. `mix format`
4. `mix test`

## Adding a New Bot

1. Create app scaffold:
   ```bash
   cd apps
   mix new bot_name --sup
   ```

2. Add dependencies to `apps/bot_name/mix.exs`

3. Create capabilities file:
   ```bash
   # apps/bot_name/capabilities.json
   ```

4. Update `project.capabilities.json` with new app entry

5. Create Fly.io config:
   ```bash
   # fly.bot_name.toml
   ```

## Adding a New Command

1. Create handler in `lib/bot_name/discord/commands/`:
   ```elixir
   defmodule BotName.Discord.Commands.NewCommand do
     def handle(interaction) do
       # Implementation
     end
   end
   ```

2. Add dispatch in `consumer.ex`:
   ```elixir
   "new_command" -> NewCommand.handle(interaction)
   ```

3. Register command with Discord (via API or deploy)

## Adding Database Changes

1. Generate migration:
   ```bash
   cd apps/bot_name
   mix ecto.gen.migration add_new_field
   ```

2. Edit migration in `priv/repo/migrations/`

3. Run migration:
   ```bash
   mix ecto.migrate
   ```

4. Update schema in `lib/bot_name/<context>/<schema>.ex`

## Testing

### Running Tests

```bash
# All tests
mix test

# Specific file
mix test test/raffle_bot/raffles_test.exs

# Specific test
mix test test/raffle_bot/raffles_test.exs:42
```

### Test Database

Tests use a separate database that's reset for each test run.

### Mocking Discord API

Use Mox to mock `RaffleBot.Discord.Api` behavior in tests:

```elixir
expect(RaffleBot.Discord.ApiMock, :create_message, fn _, _ -> {:ok, %{}} end)
```

## Deployment

### Fly.io Deployment

```bash
# Deploy specific bot
fly deploy -c fly.raffle_bot.toml

# View logs
fly logs -c fly.raffle_bot.toml

# SSH into container
fly ssh console -c fly.raffle_bot.toml
```

### Environment Secrets

```bash
fly secrets set DISCORD_BOT_TOKEN=xxx -c fly.raffle_bot.toml
fly secrets set SECRET_KEY_BASE=xxx -c fly.raffle_bot.toml
```

## Troubleshooting

### Bot Not Responding

1. Check logs: `fly logs -c fly.bot_name.toml`
2. Verify token: `fly secrets list -c fly.bot_name.toml`
3. Check Discord Developer Portal for bot status

### Database Issues

1. SSH into container: `fly ssh console`
2. Check database: `sqlite3 /data/bot.db`
3. Run migrations: Release migrations run automatically

### Common Errors

| Error | Solution |
|-------|----------|
| "Invalid token" | Check DISCORD_BOT_TOKEN env var |
| "Missing permissions" | Update bot permissions in Discord |
| "No guild config" | Run `/configure_raffle_admin` first |
