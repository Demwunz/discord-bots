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
* **[Development Guide](../../docs/development/DEVELOPMENT.md)** - Complete guide covering workflow, Docker, and deployment
* **[Git Workflow](../../docs/development/DEVELOPMENT.md#2-git-workflow-strict)** - Git worktrees and commit standards (Section 2)
* **[Docker Setup](../../docs/development/DEVELOPMENT.md#4-local-development-with-docker)** - Local development with Docker Compose (Section 4)
* **[Deployment Guide](../../docs/development/DEVELOPMENT.md#5-deployment-flyio)** - Deploying to Fly.io (Section 5)
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
| `message_id` | INTEGER | Discord Message ID (Forum thread starter) |
| `channel_id` | INTEGER | Forum Thread ID (user channel) |
| `title` | TEXT | Raffle title |
| `price` | DECIMAL | Price per spot |
| `total_spots`| INTEGER | Max spots (e.g., 50) |
| `description`| TEXT | Full text from template |
| `active` | BOOLEAN | `true` = Open, `false` = Closed |
| `spot_button_message_ids` | ARRAY[TEXT] | Additional message IDs for multi-page raffles (>25 spots) |
| `payment_details` | TEXT | Payment instructions (Venmo, PayPal, etc.) |
| `admin_thread_id` | TEXT | Forum thread ID in admin channel |
| `admin_thread_message_id` | TEXT | First message ID in admin thread |
| `timestamps` | UTC Datetime | `inserted_at`, `updated_at` |

### 2.2 Table: `claims`
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | INTEGER (PK) | Internal ID |
| `raffle_id` | INTEGER (FK) | References `raffles.id` |
| `user_id` | INTEGER | Discord User ID (BigInt) |
| `spot_number`| INTEGER | The specific number claimed (e.g., 5) |
| `is_paid` | BOOLEAN | Default `false` - admin confirmed payment |
| `user_marked_paid` | BOOLEAN | Default `false` - user self-marked as paid |
| `user_marked_paid_at` | UTC Datetime | When user marked as paid (nullable) |
| `timestamps` | UTC Datetime | `inserted_at`, `updated_at` |

**Constraints:**
* Unique Index on `[raffle_id, spot_number]` (Prevents double booking)

**Payment Flow States:**
1. Claimed, unpaid: `is_paid: false`, `user_marked_paid: false`
2. User marked paid: `is_paid: false`, `user_marked_paid: true` (pending admin)
3. Admin confirmed: `is_paid: true` (final state)

### 2.3 Table: `guild_configurations`
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BINARY_ID (PK) | Internal DB ID |
| `guild_id` | TEXT | Discord Server/Guild ID (Unique) |
| `admin_channel_id` | TEXT | Channel for admin commands |
| `user_channel_id` | TEXT | Channel for raffle posts |
| `bot_boss_role_id` | TEXT | Role required for admin commands |
| `control_panel_thread_id` | TEXT | Forum thread ID for Control Panel (nullable) |
| `control_panel_message_id` | TEXT | Message ID of Control Panel embed (nullable) |
| `timestamps` | UTC Datetime | `inserted_at`, `updated_at` |

**Constraints:**
* Unique Index on `guild_id` (One configuration per guild).

**Purpose:**
* Stores per-guild configuration for authorization and channel validation
* Created via `/setup_raffle_admin` command
* Updated via `/configure_raffle_admin` command
* Control Panel IDs stored after initial setup (v2.1+)

### 2.4 UI Architecture: Forum-Based Raffle System

**Channel Structure:**
* **User Channel** (`user_channel_id`): Forum channel (e.g., `raffles-v2`)
  - Each raffle = separate forum thread/post
  - Thread starter contains raffle embed + spot buttons (page 1)
  - Additional messages in thread for multi-page raffles (>25 spots)
  - Public access for all server members

* **Admin Channel** (`admin_channel_id`): Forum channel (e.g., `#raffle-admin`)
  - **Control Panel**: Pinned forum thread for centralized raffle management (v2.1+)
  - Each raffle = separate admin forum thread
  - Thread contains admin controls and payment notifications
  - Only visible to users with channel access permissions

### 2.5 Control Panel (v2.1+)

**Purpose:** Provides a centralized, discoverable interface for raffle management without slash commands.

**Creation Flow:**
1. Admin runs `/setup_raffle_admin` with required parameters
2. Guild configuration saved to database
3. Bot creates forum thread in admin channel with title "Raffle Control Panel"
4. Control Panel embed + buttons posted as thread starter
5. Thread/message IDs stored in `guild_configurations` table

**Control Panel Embed:**
* Title: "Raffle Control Panel"
* Description: Quick action instructions
* Fields: Active Raffles count
* Color: Discord Blurple (`0x5865F2`)
* Footer: "Raffle Bot | Admin Panel"

**Control Panel Buttons:**
| Button | Style | Custom ID | Action |
|--------|-------|-----------|--------|
| Create New Raffle | Green (3) | `control_panel_create_raffle` | Opens raffle setup modal |
| List Active Raffles | Blue (1) | `control_panel_list_raffles` | Shows ephemeral raffle list |

**Button Handlers:**
* `RaffleBot.Discord.Buttons.ControlPanelCreateRaffle` - Opens modal
* `RaffleBot.Discord.Buttons.ControlPanelListRaffles` - Returns ephemeral embed

**Component Module:** `RaffleBot.Discord.Components.ControlPanel`
* `build_embed/1` - Builds Control Panel embed
* `build_buttons/0` - Builds action buttons
* `build_message/1` - Combines embed + buttons
* `build_active_raffles_embed/1` - Builds list of active raffles

**Button-Based Spot Claiming:**
* Discord limit: 25 buttons per message (5 rows × 5 buttons)
* Multi-page support: Raffles >25 spots create additional messages
* Button states:
  1. **Available**: Blue primary button (➡️ spot_number)
  2. **Claimed, unpaid**: Gray secondary button (@username)
  3. **User marked paid**: Gray button (✅ @username) - pending admin
  4. **Admin confirmed**: Green success button (✅ @username)

**Custom ID Patterns:**
* Control Panel create: `control_panel_create_raffle`
* Control Panel list: `control_panel_list_raffles`
* Spot claim: `claim_spot_{raffle_id}_{spot_number}`
* Claim confirmation: `confirm_claim_{raffle_id}_{spot_number}`
* Payment info: `payment_info_{raffle_id}`
* Self-mark paid: `mark_self_paid_{raffle_id}`
* Admin confirm: `admin_confirm_payment_{raffle_id}_{user_id}`
* Admin reject: `admin_reject_payment_{raffle_id}_{user_id}`

**Payment Flow:**
1. User claims spots → buttons update to gray with @username
2. All spots claimed → "Pay for your spots" button posted to thread
3. User clicks pay button → shows payment details + "Mark as Paid" button
4. User marks as paid → notification sent to admin thread, buttons turn yellow/gray ✅
5. Admin confirms → `is_paid` set to true, buttons turn green ✅
6. Admin rejects → `user_marked_paid` reset to false, back to gray

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
* **`RaffleBot.GuildConfig`:** Manages guild (server) configuration
  * Creating/updating guild configurations
  * Retrieving configuration by guild ID
  * Checking if guild has configuration
  * Upsert operations for setup/reconfigure commands

**Discord Integration:**
* **`RaffleBot.Discord.Consumer`:** Event handler (implements Nostrum.Consumer)
  * Handles Discord gateway events (InteractionCreate, etc.)
  * Routes commands to appropriate handlers
  * Wraps admin commands with authorization checks
  * Formats responses for Discord API
  * Should NOT contain business logic
* **`RaffleBot.Discord.Authorization`:** Role-based authorization
  * Validates Bot Boss role from guild configuration
  * Checks user membership and roles
  * Returns formatted error responses
  * Used by Consumer before executing admin commands
* **`RaffleBot.Discord.ChannelValidator`:** Channel validation (soft enforcement)
  * Compares command channel with configured channels
  * Returns warning messages for wrong channel usage
  * Allows commands to execute with warnings (not strict blocking)
  * Normalizes channel IDs (string/integer compatibility)

### 3.2 Authorization & Command Flow

**New Slash Commands:**
* **`/setup_raffle_admin`** - Initial guild configuration (requires "Manage Server" Discord permission)
  * Command handler: `RaffleBot.Discord.Commands.SetupRaffleAdmin`
  * Infers admin channel from command invocation location
  * Creates guild configuration in database
  * No authorization required (Discord native "Manage Server" permission)
* **`/configure_raffle_admin`** - Update guild configuration (requires Bot Boss role)
  * Command handler: `RaffleBot.Discord.Commands.ConfigureRaffleAdmin`
  * Uses Authorization module to check Bot Boss role
  * Updates existing guild configuration

**Admin Command Authorization Flow:**
1. User invokes admin command (setup_raffle, mark_paid, etc.)
2. Consumer routes to `handle_admin_command/2` helper
3. `Authorization.authorize_admin/1` checks:
   - Guild has configuration in database
   - User has member data in interaction
   - User has Bot Boss role from guild configuration
4. If authorized:
   - `ChannelValidator.validate_channel/2` checks if correct channel
   - Warning logged if wrong channel (soft enforcement)
   - Command handler executed
5. If unauthorized:
   - Ephemeral error response sent to user
   - Command handler NOT executed

**Role & Channel ID Normalization:**
* Discord API can send IDs as integers or strings
* Authorization and ChannelValidator normalize IDs to strings for comparison
* Handles mixed types gracefully (e.g., config stores "123", Discord sends 123)

### 3.3 Pagination Logic
Discord Select Menus have a hard limit of **25 options**.

**Implementation Requirements:**
* Helper module: `RaffleBot.Discord.Helpers` (or similar)
* Function: `chunk_options/2` - Splits available spots into pages
* Example: 50 spots → 2 pages (1-25, 26-50)
* Select menu components must include page indicators
* Navigation between pages via button components

### 3.4 Testing Standards

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

The project uses **Git Worktrees** for feature branch isolation. See [DEVELOPMENT.md Section 2](../../docs/development/DEVELOPMENT.md#2-git-workflow-strict) for complete details.

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

**Document Version:** 2.1
**Last Review:** December 2025
**Maintained By:** Project Team
