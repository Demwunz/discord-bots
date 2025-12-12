# DEVELOPMENT GUIDE

## 1. Project Overview
This is an **Elixir Umbrella** monorepo containing multiple independent applications.
* **Apps Directory:** `apps/` (Contains the actual bot code, e.g., `apps/raffle_bot`).
* **Specs Directory:** `specs/` (Contains the requirements for each bot).

---

## 2. Git Workflow (Strict)
We use **Git Worktrees** to keep feature branches isolated. Do not work directly on the `main` branch.

### 2.1 Starting a New Task
1.  **Find the Issue:** Look at GitHub Issues and note the ID (e.g., `#12`).
2.  **Create a Worktree:**
    Run this from the root `discord-bots/` folder:
    ```bash
    # Syntax: git worktree add ../feat-[ID]-[NAME] -b feat/[ID]-[NAME]
    git worktree add ../feat-12-claims -b feat/12-claims
    ```
    *This creates a parallel folder next to your repo named `feat-12-claims`.*

3.  **Navigate & Code:**
    ```bash
    cd ../feat-12-claims
    # Open VS Code in this new isolated folder
    code .
    ```

### 2.2 Commit Standards
We strictly enforce **Conventional Commits** with Issue IDs in **square brackets**.
* **Format:** `<type>(<scope>): [#<Issue-ID>] <description>`
* **Types:** `feat`, `fix`, `chore`, `docs`, `refactor`, `test`.
* **Examples:**
    * `feat(raffle): [#12] implement pagination for claim dropdown`
    * `fix(db): [#15] resolve ecto lock timeout`
    * `docs(specs): [#1] update product requirements`

### 2.3 Finishing a Task
1.  Push your branch: `git push origin feat/12-claims`.
2.  Open a Pull Request on GitHub (Use the PR template).
3.  Once merged, delete the worktree:
    ```bash
    cd ../discord-bots
    git worktree remove ../feat-12-claims
    ```

---

## 3. Elixir Development Workflow
All commands should generally be run from the **root** of the umbrella project unless specified otherwise.

### 3.1 Setup
* **Install Dependencies:**
    ```bash
    mix deps.get
    ```
* **Initialize Database (Local):**
    Ensure you have the `DATABASE_PATH` environment variable set (or rely on dev defaults in `config/dev.exs`).
    ```bash
    mix ecto.create
    mix ecto.migrate
    ```

### 3.2 Running the Bot
To start the bot (and the Phoenix server):
```bash
iex -S mix phx.server
```

  * *Note:* `iex` gives you an interactive shell where you can debug the running bot.

### 3.3 Running Tests

  * **Run All Tests:**
    ```bash
    mix test
    ```
  * **Run Specific Test File:**
    ```bash
    mix test apps/raffle_bot/test/raffle_bot/raffles_test.exs
    ```
## 4. Local Development with Docker

The project uses a **parameterized Dockerfile** that supports building any app in the umbrella via the `APP_NAME` build argument.

### Prerequisites

*   [Docker](https://docs.docker.com/get-docker/)
*   [Docker Compose](https://docs.docker.com/compose/install/)

### 4.1 Quick Start (Docker Compose)

1.  **Create a `.env` file:**

    ```bash
    cp .env.example .env
    ```

2.  **Fill in the environment variables:**

    Open `.env` and configure:

    ```bash
    # Generate with: mix phx.gen.secret
    SECRET_KEY_BASE=your_secret_key_base_here

    # Discord bot tokens (one per app)
    RAFFLE_BOT_TOKEN=your_raffle_bot_discord_token
    # ANOTHER_BOT_TOKEN=your_another_bot_discord_token

    # Optional
    ADMIN_CHANNEL_ID=your_admin_channel_id
    ```

3.  **Start the bot(s):**

    ```bash
    # Start raffle_bot
    docker-compose up raffle_bot

    # Or start in background
    docker-compose up -d raffle_bot

    # View logs
    docker-compose logs -f raffle_bot
    ```

### 4.2 Building Individual Apps (Without Docker Compose)

You can build and run any app directly using Docker:

```bash
# Build for a specific app
docker build --build-arg APP_NAME=raffle_bot -t my-raffle-bot .

# Run it
docker run -e DISCORD_BOT_TOKEN=your_token \
           -e SECRET_KEY_BASE=your_secret \
           -e DATABASE_PATH=/data/raffle.db \
           -v raffle_data:/data \
           -p 4000:4000 \
           my-raffle-bot
```

### 4.3 Adding a New Bot to Docker Compose

When you add a new app to the umbrella (e.g., `apps/another_bot`):

1. Uncomment and modify the template in `docker-compose.yml`:
```yaml
another_bot:
  build:
    context: .
    dockerfile: Dockerfile
    args:
      APP_NAME: another_bot  # Change this
  image: discord-bots/another_bot:latest
  container_name: another_bot_dev
  environment:
    DISCORD_BOT_TOKEN: "${ANOTHER_BOT_TOKEN:?Please set ANOTHER_BOT_TOKEN in .env}"
    DATABASE_PATH: "/data/another_bot.db"
    PORT: "4001"  # Different port
  ports:
    - "4001:4001"  # Different port
  volumes:
    - another_bot_data:/data
```

2. Add the volume:
```yaml
volumes:
  another_bot_data:
    driver: local
```

3. Add the token to `.env`:
```bash
ANOTHER_BOT_TOKEN=your_token_here
```

---

### 5. Deployment (Fly.io)

The Dockerfile is configured to support **multiple apps** in the umbrella. Each app gets its own Fly.io instance with its own `fly.toml` configuration.

### 5.1 Prerequisites

  * You must have `flyctl` installed.
  * You must be logged in: `fly auth login`.

### 5.2 Configuration Architecture

Each app has its own `fly.toml` file (currently only `fly.toml` for raffle_bot exists):

```toml
# fly.toml (for raffle_bot)
[build]
  dockerfile = 'Dockerfile'
  [build.args]
    APP_NAME = "raffle_bot"  # ← Specifies which app to build
```

The Dockerfile will automatically:
1. Build the specified app's release
2. Copy only that app's binary to the final image
3. Set up the correct entrypoint

### 5.3 Deploying Updates (Current App)

1.  **Ensure tests pass:**
    ```bash
    mix test
    ```

2.  **Deploy raffle_bot:**
    ```bash
    fly deploy --app discord-raffle-bot
    ```

3.  **Run migrations (if needed):**
    Migrations run automatically via the `release_command` in `fly.toml`. To run manually:
    ```bash
    fly ssh console --app discord-raffle-bot -C "/app/bin/raffle_bot eval 'RaffleBot.Release.migrate()'"
    ```

### 5.4 Deploying a New Bot

When you create a new bot app (e.g., `apps/another_bot`):

1.  **Create a new fly.toml:**
    ```bash
    cp fly.toml fly.another_bot.toml
    ```

2.  **Update the configuration:**
    ```toml
    # fly.another_bot.toml
    app = 'discord-another-bot'

    [build]
      dockerfile = 'Dockerfile'
      [build.args]
        APP_NAME = "another_bot"  # ← Change this!

    [env]
      DATABASE_PATH = '/data/another_bot.db'
      PHX_HOST = 'discord-another-bot.fly.dev'
      # ... other env vars
    ```

3.  **Create the Fly.io app:**
    ```bash
    fly apps create discord-another-bot --org personal
    ```

4.  **Create persistent volume:**
    ```bash
    fly volumes create another_bot_data --app discord-another-bot --size 1
    ```

5.  **Set secrets:**
    ```bash
    fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret) --app discord-another-bot
    fly secrets set DISCORD_BOT_TOKEN=your_token --app discord-another-bot
    ```

6.  **Deploy:**
    ```bash
    fly deploy --app discord-another-bot --config fly.another_bot.toml
    ```

### 5.5 Troubleshooting Production

  * **View Logs:**
    ```bash
    fly logs --app discord-raffle-bot
    ```

  * **SSH into the VM:**
    ```bash
    fly ssh console --app discord-raffle-bot
    ```

  * **Check app status:**
    ```bash
    fly status --app discord-raffle-bot
    ```

  * **Inspect database:**
    ```bash
    fly ssh console --app discord-raffle-bot
    # Inside the VM:
    sqlite3 /data/raffle.db
    ```

---

## 6. Architecture Notes

### 6.1 Why Parameterized Dockerfile?

This approach provides:
- **Single source of truth** - One Dockerfile for all apps
- **Easier maintenance** - Changes apply to all bots
- **Faster builds** - Docker layer caching works across apps
- **Consistency** - All bots use the same runtime configuration

### 6.2 App Isolation

Each bot app is isolated:
- **Code**: Separate directories in `apps/`
- **Database**: Separate SQLite databases
- **Deployment**: Separate Fly.io instances
- **Configuration**: Separate environment variables

This allows independent development, testing, and deployment of each bot.

<!-- end list -->
