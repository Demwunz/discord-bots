# Technical Context

## Architecture

```
Discord API (WebSocket)
    ↓
Nostrum Client (Connection)
    ↓
Bot.Discord.Consumer (GenServer)
    ↓
Command/Button/Modal Handlers (Task-based async)
    ↓
Business Logic (Contexts)
    ↓
Ecto Repo (SQLite)
```

## Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| Language | Elixir 1.15+ | Functional, fault-tolerant |
| Runtime | BEAM/OTP | Process supervision, concurrency |
| Web | Phoenix 1.7 | Headless (no web UI) |
| Discord | Nostrum 0.7 | WebSocket API integration |
| Database | Ecto + SQLite | Persistence and queries |
| HTTP | Bandit 1.0 | Server adapter |
| JSON | Jason 1.4 | Encoding/decoding |

## Project Structure

```
discord-bots/
├── apps/
│   └── raffle_bot/
│       ├── lib/raffle_bot/
│       │   ├── application.ex      # OTP Application
│       │   ├── repo.ex             # Ecto repository
│       │   ├── closer.ex           # Auto-close GenServer
│       │   ├── raffles/            # Raffle context
│       │   ├── claims/             # Claims context
│       │   ├── guild_config/       # Guild config context
│       │   └── discord/
│       │       ├── consumer.ex     # Event dispatcher
│       │       ├── commands/       # Slash command handlers
│       │       ├── buttons/        # Button click handlers
│       │       ├── modals/         # Modal form handlers
│       │       ├── selects/        # Dropdown handlers
│       │       └── embeds/         # Message formatting
│       ├── priv/repo/migrations/   # Database migrations
│       └── test/
├── config/                         # Shared configuration
├── docs/                           # Documentation
└── specs/                          # Specifications
```

## Key Patterns

### Nostrum Consumer

All Discord events flow through a single Consumer GenServer that dispatches to handlers:

```elixir
def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
  case interaction.type do
    2 -> handle_command(interaction)      # Slash commands
    3 -> handle_component(interaction)    # Buttons/selects
    5 -> handle_modal(interaction)        # Modal submissions
  end
end
```

### Context Pattern

Business logic is organized into contexts (Raffles, Claims, GuildConfig):

```elixir
# Query
Raffles.get_raffle(id)
Raffles.list_active_raffles()

# Mutation
Raffles.create_raffle(attrs)
Claims.update_claim(claim, %{is_paid: true})
```

### Handler Pattern

Each interaction type has dedicated handler modules:

```
commands/setup_raffle.ex      → /setup_raffle
buttons/claim_spot.ex         → claim_spot_* button
modals/shipping_details.ex    → shipping_details_modal_*
selects/claim_spot_select.ex  → claim_spot_select_*
```

### Background Processes

- **Closer GenServer**: Schedules and executes raffle auto-close
- **Task.start**: Async handler execution for non-blocking responses

## Database Schema

### Core Tables

**raffles** - Raffle instances with full lifecycle state
**claims** - Spot ownership and payment status
**guild_configurations** - Per-server settings
**winner_rerolls** - Audit trail for re-selections

### Key Relationships

```
raffles 1--* claims (raffle_id)
raffles 1--* winner_rerolls (raffle_id)
guild_configurations 1--1 guild (guild_id unique)
```

## Configuration

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| DISCORD_BOT_TOKEN | Yes | Bot token from Discord Developer Portal |
| DATABASE_PATH | Prod | SQLite database path |
| SECRET_KEY_BASE | Prod | Phoenix secret key |
| PHX_HOST | Prod | Hostname for Fly.io |
| PORT | No | HTTP port (default 4000) |
| POOL_SIZE | No | DB pool size (default 10) |

### Config Files

- `config/config.exs` - Compile-time defaults
- `config/runtime.exs` - Runtime configuration from env vars
- `config/dev.exs` - Development overrides
- `config/prod.exs` - Production overrides

## Deployment

### Local Development

```bash
docker-compose up raffle_bot
```

### Production (Fly.io)

- Parameterized Dockerfile with `APP_NAME` build arg
- Persistent volume at `/data` for SQLite
- Release-based deployment (ExRelease)
- Automatic migrations via `release_command`

## Error Handling

- OTP supervision trees restart crashed processes
- Handlers use try/rescue for graceful degradation
- Discord API errors logged but don't crash consumer
- Database constraint violations return error tuples
