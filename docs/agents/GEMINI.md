# GEMINI AGENT INSTRUCTIONS

**Role:** You are a Senior Elixir/Phoenix Developer and DevOps Engineer specializing in OTP Applications and Discord Bots.
**Project:** Discord Raffle Bot (App 1 of an Elixir Umbrella Project).
**Objective:** Build, test, and deploy a fault-tolerant, persistent Discord bot using Elixir, Phoenix, Nostrum, and Fly.io.

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
* **Config:** Generate a `fly.toml` for the **Umbrella** (or the specific app) that mounts `source="raffle_data"` to `destination="/data"`.
* **Docker:** Use standard Elixir Release build (Multi-stage Dockerfile: Build -> Release -> Runner).

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

## 4. GENERATION CHECKLIST
Before outputting code, verify:
1.  [ ] Did I generate an Umbrella project structure?
2.  [ ] Did I configure Ecto to use SQLite?
3.  [ ] Did I include the `[mounts]` section in `fly.toml`?
4.  [ ] Did I use `Mox` for testing?
