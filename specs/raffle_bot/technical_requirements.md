# Technical Requirements Document (TRD)
**Project Name:** Discord Raffle Bot (Elixir/Phoenix)
**Architecture:** Elixir Umbrella
**Deploy Target:** Fly.io
**Language:** Elixir 1.15+ / OTP 26+

## 1. System Architecture

### 1.1 Umbrella Structure
The project uses an Elixir Umbrella to manage multiple applications within a single repository.
* **Root:** `discord_bot_umbrella/`
* **Apps Directory:** `apps/`
* **Target App:** `apps/raffle_bot/` (This contains the core logic for the Raffle Bot).

### 1.2 Application Design (`apps/raffle_bot`)
* **Framework:** Phoenix (Headless - generated with `--no-html --no-assets`).
* **Discord Library:** `Nostrum` (Latest stable).
* **Supervision Tree:**
    * `RaffleBot.Repo` (Ecto Repository)
    * `Nostrum.Application` (Discord Gateway Consumer)
    * `RaffleBot.Scheduler` (Daily Reporting GenServer)

### 1.3 Deployment (Fly.io)
* **Build Strategy:** Elixir Releases (`mix release`).
* **Container:** Multi-stage Dockerfile (Build -> Release -> Runner).
    * Base Image: `elixir:1.15-slim` (or similar).
* **Persistence:** Application depends on a persistent volume.
    * **Fly Volume:** `raffle_data` mounted to `/data`.
* **Secrets:** Managed via Fly.io Secrets (`DISCORD_TOKEN`, `DATABASE_PATH`, etc.).

---

## 2. Database Schema (Ecto + SQLite)
**Library:** `Ecto` with `ecto_sqlite3` adapter.
**Configuration:**
* **Dev:** `database: "raffle.db"` (Local project root)
* **Prod:** `database: "/data/raffle.db"` (Persistent Volume)

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
Business logic must be separated from Discord implementation details.
* **`RaffleBot.Raffles` (Context):** Handles creating raffles, querying spots, updating status.
* **`RaffleBot.Claims` (Context):** Handles claiming spots, marking paid, checking availability.
* **`RaffleBot.Discord.Consumer`:** Handles `Nostrum` events (InteractionCreate) and calls the Contexts.

### 3.2 Pagination Logic
Discord Select Menus have a hard limit of **25 options**.
* The code must implement a helper (e.g., `DiscordHelpers.chunk_options/1`) that takes a list of available spots (e.g., 1..50) and returns chunks (1..25, 26..50) to generate multiple select menus dynamically.

### 3.3 Dependencies
* `phoenix`
* `nostrum`
* `ecto_sql`
* `ecto_sqlite3`
* `jason`
* `mox` (Test only)
