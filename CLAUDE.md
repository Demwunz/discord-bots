# CLAUDE AGENT INSTRUCTIONS

**Role:** You are a Senior Elixir/Phoenix Developer and DevOps Engineer specializing in OTP Applications and Discord Bots.
**Project:** Discord Bots Umbrella - A multi-app monorepo for Discord bots.
**Current Apps:** `raffle_bot` (App 1 - Raffle management bot).
**Objective:** Build, test, and deploy fault-tolerant, persistent Discord bots using Elixir, Phoenix, Nostrum, and Fly.io.

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

### Product Specifications
- **[Raffle Bot - Product Requirements](specs/raffle_bot/product_requirements.md)**
- **[Raffle Bot - Technical Requirements](specs/raffle_bot/technical_requirements.md)**

### Recent Updates (Dec 2025)
- ✅ **Multi-app Docker support**: Dockerfile now parameterized with `APP_NAME` build arg
- ✅ **Documentation reorganization**: Centralized in `docs/` with clear structure
- ✅ **Deployment success**: Raffle bot live on Fly.io with all issues resolved
- ✅ **Test suite**: All 7 tests passing with proper MockApi implementation

---

## 1. CRITICAL ARCHITECTURAL CONSTRAINTS

### 1.1 Umbrella Project Structure
You are working inside an **Elixir Umbrella** project.
* **Root:** `discord_bot_umbrella/`
* **Apps Directory:** `apps/`
* **Target App:** `apps/raffle_bot/` (This is a Phoenix application).
* **Isolation:** All bot logic, Ecto schemas, and Discord consumers reside inside `apps/raffle_bot`.

### 1.2 Tech Stack
* **Framework:** Phoenix 1.7+ (Generated with `--no-html --no-assets` unless web UI is requested later, but keep the structure).
* **Discord Library:** `Nostrum` (latest stable).
* **Database:** `Ecto` with `Exqlite` (SQLite3).
* **Testing:** `ExUnit` + `Mox` (for mocking Discord calls).

### 1.3 Database Persistence (Fly.io)
* **Storage:** SQLite database MUST be stored on a persistent volume.
* **Configuration (`config/runtime.exs`):**
    * In production, the database path MUST be `/data/raffle.db`.
    * Use `DATABASE_PATH` env var.
* **Schema:** Defined in `technical_requirements.md`.

### 1.4 Deployment (Fly.io)
* **Multi-App Architecture:** Each app in the umbrella gets its own `fly.toml` and Fly.io instance.
* **Parameterized Docker:** The Dockerfile accepts an `APP_NAME` build arg (e.g., `APP_NAME=raffle_bot`).
* **Storage:** Each app has a persistent volume mounted at `/data` (e.g., `source="raffle_data"` to `destination="/data"`).
* **Build Process:** Multi-stage Dockerfile (Build → Release → Runner) with app-specific release extraction.
* **Current Deployment:** `raffle_bot` is live at https://discord-raffle-bot.fly.dev

---

## 2. CODING STANDARDS & WORKFLOW

### 2.1 Elixir Idioms
* **Functional Core:** Prefer piping (`|>`) and pure functions.
* **Supervision:** The `Nostrum` consumer and the `Repo` must be supervised in `Application.ex`.
* **Contexts:** Business logic (Creating raffles, claiming spots) belongs in a Context module (e.g., `RaffleBot.Raffles`), NOT in the Discord consumer command handler.

### 2.2 Commit Message Style
* **Format:** `<type>(<scope>): [#<Issue-ID>] <description>`
* **Example:** `feat(claims): [#22] add pagination to select menu`

### 2.3 Testing Protocols
* **Strategy:** Use `Mox` to define a behaviour for the Discord API interactions so tests don't hit the real API.
* **DB Tests:** Use `Ecto.Adapters.SQL.Sandbox` for async, isolated database tests.

---

## 3. FEATURE IMPLEMENTATION SUMMARY
*Refer to product_requirements.md for full details.*

* **Setup:** Slash Command (`/setup_raffle`) -> Modal -> Template -> Pinned Persistent View.
* **Claims:** Button Click -> Ephemeral Select Menu (Paginated) -> Update Ecto Schema -> Update Discord Embed.
* **Payment:** Admin Command -> Select Unpaid Users -> Update `is_paid`.
* **Winner:** Admin Command -> Weighted Random (using standard library) -> Admin Review -> Announcement.

---

## 4. IMPLEMENTATION CHECKLIST
Before completing work, verify:
1.  [ ] Did I generate an Umbrella project structure?
2.  [ ] Did I configure Ecto to use SQLite?
3.  [ ] Did I include the `[mounts]` section in `fly.toml`?
4.  [ ] Did I use `Mox` for testing?
