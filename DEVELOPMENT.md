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

### 4. Deployment (Fly.io)

Deployment is handled via the `flyctl` CLI.

### 4.1 Prerequisites

  * You must have `flyctl` installed.
  * You must be logged in: `fly auth login`.

### 4.2 Deploying Updates

1.  Ensure all tests pass locally (`mix test`).
2.  Deploy from the root directory:
    ```bash
    fly deploy
    ```
    *This will build the Docker image, push it to Fly, and migrate the database if configured.*

### 4.3 Troubleshooting Production

  * **View Logs:**
    ```bash
    fly logs
    ```
  * **SSH into the VM:**
    ```bash
    fly ssh console
    ```
    *Useful for inspecting the production SQLite database manually.*

<!-- end list -->
