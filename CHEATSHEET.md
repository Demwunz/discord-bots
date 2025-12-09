# AGENT CHEAT SHEET (Elixir Edition)

## 1. Git Worktrees
* **New:** `git worktree add ../feat-[ID]-[NAME] -b feat/[ID]-[NAME]`
* **Remove:** `git worktree remove ../feat-[ID]-[NAME]`

## 2. Elixir / Mix
* **Start App:** `iex -S mix`
* **Run Tests:** `mix test`
* **Get Deps:** `mix deps.get`
* **Format Code:** `mix format`

## 3. Database (Ecto)
* **Create Migration:** `mix ecto.gen.migration [name]` (run inside app folder)
* **Run Migrations:** `mix ecto.migrate`
* **Inspect Data (IEx):**
    ```elixir
    alias RaffleBot.Repo
    alias RaffleBot.Raffles.Claim
    Repo.all(Claim)
    ```

## 4. Fly.io
* **Deploy:** `fly deploy`
* **Logs:** `fly logs`
* **SSH into VM:** `fly ssh console`
