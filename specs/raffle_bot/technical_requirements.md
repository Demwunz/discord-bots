# Technical Requirements Document (TRD)
**Project Name:** Discord Raffle Bot (Elixir/Phoenix)
**Architecture:** Elixir Umbrella (Multi-App)
**Deploy Target:** Fly.io
**Language:** Elixir 1.15+ / OTP 26+
**Status:** ✅ Deployed to production (https://discord-raffle-bot.fly.dev)
**Last Updated:** December 2025

---

## 0. Documentation References

For comprehensive guides, see the [Documentation Index](../../docs/INDEX.md):
* **[Development Guide](../../DEVELOPMENT.md)** - Complete guide covering workflow, Docker, and deployment
* **[Git Workflow](../../DEVELOPMENT.md#2-git-workflow-strict)** - Git worktrees and commit standards (Section 2)
* **[Docker Setup](../../DEVELOPMENT.md#4-local-development-with-docker)** - Local development with Docker Compose (Section 4)
* **[Deployment Guide](../../DEVELOPMENT.md#5-deployment-flyio)** - Deploying to Fly.io (Section 5)
* **[Troubleshooting](../../docs/operations/TROUBLESHOOTING.md)** - Common issues and solutions
* **[Product Requirements](product_requirements.md)** - Feature specifications

---

## 1. System Architecture

### 1.1 Umbrella Structure
The project uses an **Elixir Umbrella** to manage multiple Discord bot applications within a single repository.
* **Root:** `discord-bots/`
* **Apps Directory:** `apps/`
* **Target App:** `apps/raffle_bot/` (First bot - raffle management)
* **Isolation:** Each bot has independent code, database, and deployment
* **Shared:** Common Elixir dependencies and build infrastructure

**Multi-App Support:**
The umbrella is designed to host multiple bots. Each bot:
- Resides in `apps/{bot_name}/`
- Has its own database (`/data/{bot_name}.db`)
- Deploys to separate Fly.io instance
- Uses independent Discord bot token
- Shares the same Dockerfile via `APP_NAME` build argument

### 1.2 Application Design (`apps/raffle_bot`)
* **Framework:** Phoenix 1.7+ (Headless - generated with `--no-html --no-assets`)
* **HTTP Server:** Bandit (Default in Phoenix 1.7+)
* **Discord Library:** Nostrum (Latest stable)
* **Supervision Tree:**
    * `RaffleBot.Repo` (Ecto Repository)
    * `RaffleBotWeb.Endpoint` (Phoenix Endpoint for health checks)
    * `Nostrum.Application` (Discord Gateway Consumer)
    * `RaffleBot.Discord.Consumer` (Event handler)

### 1.3 Deployment (Fly.io)
**Current Deployment:** `discord-raffle-bot` app on Fly.io
**URL:** https://discord-raffle-bot.fly.dev

#### Build Configuration
* **Build Strategy:** Elixir Releases (`mix release`)
* **Container:** Multi-stage Dockerfile (Debian-based for glibc compatibility)
    * **Build Stage:** `debian:bookworm-slim` with Elixir/Erlang
    * **Release Stage:** Extracts app-specific release using `APP_NAME` build arg
    * **Runner Stage:** Minimal runtime with only required dependencies
* **Parameterization:** Dockerfile accepts `APP_NAME` build argument
    * Example: `docker build --build-arg APP_NAME=raffle_bot`
    * Configured in `fly.toml`: `[build.args] APP_NAME = "raffle_bot"`

#### Persistence & Configuration
* **Persistent Volume:**
    * Volume name: `raffle_data`
    * Mount point: `/data`
    * Database location: `/data/raffle.db`
* **Environment Configuration:**
    * `PHX_HOST` - Fly.io hostname (e.g., `discord-raffle-bot.fly.dev`)
    * `PHX_SERVER` - Set to `true` to start Phoenix server
    * `PORT` - HTTP port (typically `8080` on Fly.io)
    * `DATABASE_PATH` - Path to SQLite database (`/data/raffle.db`)
* **Secrets Management:** Managed via Fly.io Secrets
    * `SECRET_KEY_BASE` - Phoenix secret (generate with `mix phx.gen.secret`)
    * `DISCORD_BOT_TOKEN` - Discord bot authentication token

#### Release & Migration
* **Automatic Migrations:** Configured in `fly.toml`
    ```toml
    [deploy]
      release_command = "eval 'RaffleBot.Release.migrate()'"
    ```
* **Migration Module:** `apps/raffle_bot/lib/raffle_bot/release.ex`
    * Runs pending migrations before app starts
    * Handles repository startup and shutdown

#### Multi-App Deployment
When deploying additional bots:
1. Create `fly.{bot_name}.toml` with appropriate `APP_NAME` build arg
2. Create Fly.io app: `fly apps create discord-{bot-name}`
3. Create persistent volume: `fly volumes create {bot}_data --size 1`
4. Set secrets: `fly secrets set DISCORD_BOT_TOKEN=... --app discord-{bot-name}`
5. Deploy: `fly deploy --app discord-{bot-name} --config fly.{bot_name}.toml`

---

## 2. Database Schema (Ecto + SQLite)

### 2.0 Database Configuration
**Library:** `Ecto` with `Exqlite` adapter (`ecto_sqlite3` package)
**Adapter Module:** `Ecto.Adapters.SQLite3`

**Configuration Files:**
* `config/dev.exs` - Development environment (local `raffle.db`)
* `config/test.exs` - Test environment (in-memory or temporary database)
* `config/runtime.exs` - Production runtime configuration

**Database Paths:**
* **Development:** `raffle.db` (project root)
* **Production:** `/data/raffle.db` (persistent volume)
* **Environment Variable:** `DATABASE_PATH` (required in production)

**Example Configuration (`config/runtime.exs`):**
```elixir
config :raffle_bot, RaffleBot.Repo,
  database: System.get_env("DATABASE_PATH") || "/data/raffle.db",
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
```

**Migration Management:**
* Migrations located in `apps/raffle_bot/priv/repo/migrations/`
* Automatic migrations on Fly.io deployment via release command
* Manual migrations: `mix ecto.migrate` (development) or via `RaffleBot.Release.migrate()` (production)

### 2.1 Table: `raffles`
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | INTEGER (PK) | Internal DB ID |
| `message_id` | INTEGER | Discord Message ID (The pinned post) |
| `channel_id` | INTEGER | Channel ID where posted |
| `title` | TEXT | |
| `price` | DECIMAL | Price per spot |
| `total_spots`| INTEGER | Max spots (e.g., 50) |
| `description`| TEXT | Full text from template |
| `active` | BOOLEAN | `true` = Open, `false` = Closed |
| `timestamps` | UTC Datetime | `inserted_at`, `updated_at` |

### 2.2 Table: `claims`
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | INTEGER (PK) | |
| `raffle_id` | INTEGER (FK) | References `raffles.id` |
| `user_id` | INTEGER | Discord User ID (BigInt) |
| `spot_number`| INTEGER | The specific number claimed (e.g., 5) |
| `is_paid` | BOOLEAN | Default `false` |
| `timestamps` | UTC Datetime | |

**Constraints:**
* Unique Index on `[raffle_id, spot_number]` (Prevents double booking).

---

## 3. Development Standards

### 3.1 Context Boundaries
Business logic must be separated from Discord implementation details following Phoenix context patterns.

**Core Contexts:**
* **`RaffleBot.Raffles`:** Manages raffle lifecycle
  * Creating raffles from templates
  * Querying available spots
  * Updating raffle status (active/closed)
  * Fetching raffle statistics
* **`RaffleBot.Claims`:** Manages spot claims
  * Claiming available spots
  * Marking spots as paid/unpaid
  * Checking spot availability
  * Listing user claims

**Discord Integration:**
* **`RaffleBot.Discord.Consumer`:** Event handler (implements Nostrum.Consumer)
  * Handles Discord gateway events (InteractionCreate, etc.)
  * Calls context functions for business logic
  * Formats responses for Discord API
  * Should NOT contain business logic

### 3.2 Pagination Logic
Discord Select Menus have a hard limit of **25 options**.

**Implementation Requirements:**
* Helper module: `RaffleBot.Discord.Helpers` (or similar)
* Function: `chunk_options/2` - Splits available spots into pages
* Example: 50 spots → 2 pages (1-25, 26-50)
* Select menu components must include page indicators
* Navigation between pages via button components

### 3.3 Testing Standards

**Test Structure:**
* **Unit Tests:** Context functions (`RaffleBot.Raffles`, `RaffleBot.Claims`)
* **Integration Tests:** Discord consumer interactions (using Mox)
* **Database Tests:** Use `Ecto.Adapters.SQL.Sandbox` for isolation

**Mocking Strategy:**
* Define behaviour for Discord API interactions
* Mock module: `RaffleBot.Discord.MockApi`
* Use `Mox` library to verify Discord API calls without hitting real endpoints

**Test Coverage Requirements:**
* All context functions must have tests
* Edge cases: double booking, invalid spots, closed raffles
* Error handling: database errors, Discord API failures

### 3.4 Dependencies

**Core Dependencies:**
* `phoenix` (~> 1.7) - Web framework
* `bandit` - HTTP server (replaces Cowboy in Phoenix 1.7+)
* `nostrum` - Discord library
* `ecto_sql` (~> 3.10) - Database toolkit
* `ecto_sqlite3` (~> 0.17) - SQLite adapter (Exqlite)
* `jason` - JSON parser

**Development & Testing:**
* `mox` - Mocking library for testing
* `phoenix_live_reload` - Development hot reloading
* `esbuild` - Asset bundling (minimal, for Phoenix)

**Production:**
* All dependencies compiled into release binary
* No runtime mix or compilation required

---

## 4. Local Development

### 4.1 Native Development (Without Docker)

**Prerequisites:**
* Elixir 1.15+ and Erlang/OTP 26+
* SQLite3

**Setup:**
```bash
# Install dependencies
mix deps.get

# Create and migrate database
mix ecto.create
mix ecto.migrate

# Start the application
iex -S mix phx.server
```

**Environment Configuration:**
Create `.env` file (see `.env.example`):
```bash
SECRET_KEY_BASE=your_secret_here
RAFFLE_BOT_TOKEN=your_discord_token
DATABASE_PATH=raffle.db  # Optional, defaults in config/dev.exs
```

### 4.2 Docker Development

**Prerequisites:**
* Docker and Docker Compose

**Quick Start:**
```bash
# Copy environment template
cp .env.example .env

# Edit .env with your tokens
# Then start the bot
docker-compose up raffle_bot

# Or run in background
docker-compose up -d raffle_bot

# View logs
docker-compose logs -f raffle_bot
```

**Docker Compose Configuration:**
* Service name: `raffle_bot`
* Build arg: `APP_NAME=raffle_bot`
* Port: `4000` (mapped to host)
* Volume: `raffle_bot_data:/data` (persistent database)
* Health check: HTTP endpoint on port 4000

**Adding New Bots:**
See template in `docker-compose.yml` under commented section for `another_bot`.

### 4.3 Testing

**Run Full Test Suite:**
```bash
mix test
```

**Run Specific Test File:**
```bash
mix test apps/raffle_bot/test/raffle_bot/raffles_test.exs
```

**Test Database:**
Tests use `Ecto.Adapters.SQL.Sandbox` for isolation. Each test runs in a transaction that's rolled back after completion.

**Current Test Status:** ✅ All 7 tests passing

---

## 5. Git Workflow

The project uses **Git Worktrees** for feature branch isolation. See [DEVELOPMENT.md Section 2](../../DEVELOPMENT.md#2-git-workflow-strict) for complete details.

**Commit Message Format:**
```
<type>(<scope>): [#<issue-id>] <description>

Examples:
feat(raffle): [#12] implement pagination for claim dropdown
fix(db): [#15] resolve ecto lock timeout
docs(specs): [#1] update technical requirements
```

**Types:** `feat`, `fix`, `chore`, `docs`, `refactor`, `test`

---

## 6. Monitoring & Operations

### 6.1 Health Checks

**Phoenix Endpoint:**
* URL: `http://localhost:4000/` (dev) or `https://discord-raffle-bot.fly.dev/` (prod)
* Returns: JSON health status

**Fly.io Health Checks:**
* TCP check on port 8080 every 15 seconds
* Configured in `fly.toml` under `[[services.tcp_checks]]`

### 6.2 Logging

**Development:**
* Standard Elixir Logger to console
* Log level: `:debug` (configurable in `config/dev.exs`)

**Production:**
* Logs streamed to Fly.io
* View with: `fly logs --app discord-raffle-bot`
* Filter errors: `fly logs --app discord-raffle-bot | grep ERROR`

### 6.3 Database Access

**Development:**
```bash
sqlite3 raffle.db
```

**Production (Fly.io):**
```bash
fly ssh console --app discord-raffle-bot
# Inside VM:
sqlite3 /data/raffle.db
```

**Common SQLite Commands:**
```sql
.tables                    -- List all tables
.schema raffles            -- Show table schema
SELECT * FROM raffles;     -- Query raffles
SELECT * FROM claims;      -- Query claims
```

---

## 7. Security Considerations

### 7.1 Secrets Management
* **Never commit** `.env` files or tokens to git
* Use Fly.io Secrets for production: `fly secrets set KEY=value`
* `.env.example` provides template without sensitive values

### 7.2 Discord Permissions
* Bot requires specific Discord permissions (configured in Discord Developer Portal)
* Minimum required: Send Messages, Embed Links, Use Slash Commands, Manage Messages

### 7.3 Database Security
* SQLite database on persistent volume (Fly.io)
* No external database connections required
* Regular backups recommended (copy `/data/raffle.db` from Fly.io volume)

---

## 8. Performance Considerations

### 8.1 Database
* SQLite is suitable for single-instance Discord bots
* Connection pooling: 10 connections (configurable via `POOL_SIZE`)
* Indexes on foreign keys and unique constraints for performance

### 8.2 Discord API
* Nostrum handles rate limiting automatically
* Ephemeral messages reduce Discord API load
* Persistent views minimize message updates

### 8.3 Resource Limits (Fly.io)
* Memory: 1GB (configured in `fly.toml`)
* CPUs: 1 vCPU
* Volume: 1GB SSD (expandable)

---

## 9. Troubleshooting

For common issues and solutions, see [Troubleshooting Guide](../../docs/operations/TROUBLESHOOTING.md).

**Quick Reference:**
* **Build failures:** Check Dockerfile and APP_NAME build arg
* **Migration errors:** Verify DATABASE_PATH and volume mount
* **Discord connection:** Check DISCORD_BOT_TOKEN secret
* **Database locks:** Ensure only one instance running

---

**Document Version:** 2.0
**Last Review:** December 2025
**Maintained By:** Project Team
