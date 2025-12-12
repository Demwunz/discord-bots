# CLAUDE AGENT INSTRUCTIONS

**Role:** You are a Senior Elixir/Phoenix Developer and DevOps Engineer specializing in OTP Applications and Discord Bots.
**Project:** Discord Bots Umbrella - A multi-app monorepo for hosting multiple independent Discord bot applications.
**Current Apps:**
- `raffle_bot` - Raffle management bot ([App Documentation](apps/raffle_bot/README.md))
**Objective:** Build, test, and deploy fault-tolerant, persistent Discord bots using Elixir, Phoenix, Nostrum, and Fly.io within a shared umbrella architecture.

---

## 📚 DOCUMENTATION STRUCTURE

**Important:** All documentation has been reorganized (Dec 2025). Key resources:

### Quick Reference
- **[Documentation Index](docs/INDEX.md)** - Complete documentation map
- **[Development Guide](DEVELOPMENT.md)** - Workflow, Docker, and deployment
- **[Troubleshooting](docs/operations/TROUBLESHOOTING.md)** - Deployment issues and solutions

### For AI Agents
- **[General Agent Guidelines](docs/agents/AGENTS.md)** - Best practices for AI assistants
- **[Gemini-Specific Instructions](docs/agents/GEMINI.md)** - Gemini model guidance

### App-Specific Documentation
Each bot application has its own documentation in `apps/{app_name}/` and `specs/{app_name}/`:
- **Raffle Bot:**
  - [App Guide](apps/raffle_bot/docs/GUIDE.md) - User guide and features
  - [Product Requirements](specs/raffle_bot/product_requirements.md) - Feature specifications
  - [Technical Requirements](specs/raffle_bot/technical_requirements.md) - Implementation details

### Recent Updates (Dec 2025)
- ✅ **Multi-app Docker support**: Dockerfile now parameterized with `APP_NAME` build arg
- ✅ **Documentation reorganization**: Centralized in `docs/` with clear structure
- ✅ **Technical requirements updated**: Comprehensive guide reflecting current architecture
- ✅ **Deployment success**: Raffle bot live on Fly.io (https://discord-raffle-bot.fly.dev)
- ✅ **Test suite**: All 7 tests passing with proper MockApi implementation

---

## 1. UMBRELLA ARCHITECTURE OVERVIEW

### 1.1 Project Structure
This is an **Elixir Umbrella** project designed to host multiple independent Discord bot applications.

```
discord-bots/
├── apps/              # Individual bot applications
│   ├── raffle_bot/   # Raffle management bot (Phoenix app)
│   └── [future_bot]/ # Future bots go here
├── config/           # Shared configuration (umbrella-level)
├── docs/             # Centralized documentation
├── specs/            # Per-app specifications
├── Dockerfile        # Parameterized for all apps (APP_NAME build arg)
├── docker-compose.yml # Multi-service local development
└── fly.toml          # Raffle bot deployment config
```

**Key Principles:**
* **Isolation:** Each bot is a complete Phoenix/OTP application in `apps/{bot_name}/`
* **Independence:** Each bot has its own database, deployment, and Discord token
* **Shared Infrastructure:** Common Dockerfile, dependencies, and build process
* **Scalability:** Add new bots by creating new apps in `apps/` directory

### 1.2 Standard Tech Stack
Each Discord bot application typically uses:
* **Framework:** Phoenix 1.7+ (Headless - `--no-html --no-assets`)
* **HTTP Server:** Bandit (Phoenix 1.7+ default)
* **Discord Library:** Nostrum (latest stable)
* **Database:** Ecto with Exqlite (SQLite3) - each bot has independent database
* **Testing:** ExUnit + Mox (for mocking Discord API calls)

### 1.3 Database Patterns
**Per-App Databases:**
* Each bot maintains its own SQLite database
* Development: `{app_name}.db` in project root
* Production: `/data/{app_name}.db` on Fly.io persistent volume

**Configuration (`config/runtime.exs`):**
```elixir
config :app_name, AppName.Repo,
  database: System.get_env("DATABASE_PATH") || "/data/app_name.db",
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
```

**Environment Variables:**
* `DATABASE_PATH` - Full path to SQLite database file
* `POOL_SIZE` - Number of database connections (optional, default 10)

### 1.4 Multi-App Deployment (Fly.io)
**Architecture Pattern:**
* Each bot deploys to its own Fly.io instance
* Each instance has its own persistent volume for database
* Shared Dockerfile with `APP_NAME` build argument

**Per-Bot Configuration:**
* `fly.{bot_name}.toml` - Fly.io configuration
* `APP_NAME` build arg specifies which app to build
* Independent secrets (DISCORD_BOT_TOKEN, SECRET_KEY_BASE)
* Separate volumes (e.g., `raffle_data`, `another_bot_data`)

**Example Deployment Commands:**
```bash
# Deploy raffle_bot
fly deploy --app discord-raffle-bot

# Deploy future bot
fly deploy --app discord-another-bot --config fly.another_bot.toml
```

**Current Deployments:**
* `raffle_bot`: https://discord-raffle-bot.fly.dev (✅ Live)

---

## 2. DEVELOPMENT STANDARDS

### 2.1 Elixir/Phoenix Best Practices
**Functional Core:**
* Prefer piping (`|>`) and pure functions
* Avoid side effects in business logic
* Use pattern matching and guards

**Supervision Trees:**
* Nostrum consumer must be supervised in `Application.ex`
* Ecto Repo must be supervised
* Phoenix Endpoint must be supervised
* Use proper supervision strategies (one_for_one, rest_for_one)

**Context Pattern:**
* Business logic belongs in Context modules (e.g., `AppName.Domain`)
* Keep Discord consumer handlers thin - delegate to contexts
* Contexts should NOT know about Discord API details
* Example: `AppName.Discord.Consumer` calls `AppName.Raffles.create_raffle/1`

### 2.2 Git Workflow
**Commit Message Format:**
```
<type>(<scope>): [#<issue-id>] <description>

Examples:
feat(raffle): [#12] add pagination to select menu
fix(db): [#15] resolve ecto lock timeout
docs(specs): [#1] update technical requirements
```

**Types:** `feat`, `fix`, `chore`, `docs`, `refactor`, `test`

**Git Worktrees:**
* Use worktrees for feature branch isolation
* See [DEVELOPMENT.md Section 2](DEVELOPMENT.md#2-git-workflow-strict) for details

### 2.3 Testing Standards
**Test Structure:**
* Unit tests for context functions
* Integration tests for Discord interactions (mocked)
* Database tests using `Ecto.Adapters.SQL.Sandbox`

**Mocking Strategy:**
* Use `Mox` to define behaviours for Discord API interactions
* Tests should NEVER hit the real Discord API
* Example: Define `DiscordApi` behaviour, implement `DiscordApi.Mock`

**Test Coverage:**
* All context functions must have tests
* Test edge cases and error paths
* Verify database constraints work correctly

---

## 3. ADDING A NEW BOT

When creating a new Discord bot in this umbrella:

### 3.1 Application Setup
1. **Generate Phoenix app** (inside `apps/` directory):
   ```bash
   cd apps
   mix phx.new bot_name --app bot_name --no-html --no-assets --umbrella
   ```

2. **Add dependencies** to `apps/bot_name/mix.exs`:
   ```elixir
   {:nostrum, "~> 0.10"},
   {:ecto_sql, "~> 3.10"},
   {:ecto_sqlite3, "~> 0.17"},
   {:mox, "~> 1.0", only: :test}
   ```

3. **Configure Ecto** in `apps/bot_name/config/`:
   - Set up repo in `config.exs`
   - Configure database paths for dev/test/prod
   - Add repo to supervision tree

### 3.2 Docker Configuration
Add service to `docker-compose.yml`:
```yaml
bot_name:
  build:
    context: .
    dockerfile: Dockerfile
    args:
      APP_NAME: bot_name
  environment:
    DISCORD_BOT_TOKEN: "${BOT_NAME_TOKEN:?Required}"
    DATABASE_PATH: "/data/bot_name.db"
    PORT: "4001"  # Use different port
  ports:
    - "4001:4001"
  volumes:
    - bot_name_data:/data
```

### 3.3 Fly.io Deployment
1. Create `fly.bot_name.toml` (copy and modify `fly.toml`)
2. Update `APP_NAME` build arg
3. Create Fly.io app: `fly apps create discord-bot-name`
4. Create volume: `fly volumes create bot_data --app discord-bot-name`
5. Set secrets: `fly secrets set DISCORD_BOT_TOKEN=...`
6. Deploy: `fly deploy --app discord-bot-name --config fly.bot_name.toml`

### 3.4 Documentation
Create documentation following the structure:
* `apps/bot_name/README.md` - Overview
* `apps/bot_name/docs/GUIDE.md` - User guide
* `specs/bot_name/product_requirements.md` - Features
* `specs/bot_name/technical_requirements.md` - Implementation

---

## 4. WORKING ON EXISTING BOTS

### 4.1 Raffle Bot
See app-specific documentation:
* **[User Guide](apps/raffle_bot/docs/GUIDE.md)** - Features and usage
* **[Product Requirements](specs/raffle_bot/product_requirements.md)** - Feature specs
* **[Technical Requirements](specs/raffle_bot/technical_requirements.md)** - Implementation details

Key patterns in raffle_bot:
* Slash commands for setup
* Persistent views with buttons
* Ephemeral select menus (paginated)
* Admin commands for management

### 4.2 General Checklist
Before completing work on any bot:
- [ ] Business logic in context modules, not Discord handlers
- [ ] Database configured with persistent volume path
- [ ] Mox used for testing Discord interactions
- [ ] Tests passing (`mix test`)
- [ ] Fly.io configuration includes `[mounts]` section
- [ ] Documentation updated (README, specs, guides)
- [ ] Commit messages follow conventional format
