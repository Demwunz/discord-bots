# HUMAN SETUP GUIDE
**Objective:** Perform the manual one-time setup steps required before the bot can run.

## Phase 1: Create the Bot (Discord Developer Portal)
1.  Go to the [Discord Developer Portal](https://discord.com/developers/applications).
2.  Click **New Application** (Top Right) -> Name it (e.g., "RaffleManager") -> Create.
3.  **Get the Token:**
    * Click **Bot** on the left sidebar.
    * Click **Reset Token** -> Copy this long string.
    * *Action:* Paste this into your `.env` file or keep it safe. You will need it for the Fly.io secrets step.
4.  **Enable Intents (Crucial):**
    * Scroll down on the **Bot** page to "Privileged Gateway Intents".
    * Toggle ON: **Server Members Intent**.
    * Toggle ON: **Message Content Intent**.
    * Click **Save Changes**.

## Phase 2: Invite the Bot to Your Server
1.  On the left sidebar, click **OAuth2** -> **URL Generator**.
2.  **Scopes:** Check the box `bot` and `applications.commands`.
3.  **Bot Permissions:** Check the following boxes (or just `Administrator` for simplicity):
    * `Send Messages`
    * `Embed Links`
    * `Attach Files`
    * `Manage Messages` (To pin/unpin)
    * `Read Message History`
    * `Mention Everyone` (To tag winners)
4.  **Invite:**
    * Copy the URL generated at the bottom.
    * Paste it into your browser.
    * Select your server and click **Authorize**.

## Phase 3: Get Admin Channel ID
1.  Open Discord settings -> **Advanced** -> Turn ON **Developer Mode**.
2.  Right-click the channel where you want Admin Reports (e.g., `#admin-logs`).
3.  Click **Copy Channel ID**.
4.  *Action:* Save this ID for the Fly.io secrets step.

## Phase 4: Fly.io Setup (Terminal)
*Prerequisite: Install the `flyctl` command line tool.*

1.  **Login:**
    ```bash
    fly auth login
    ```
2.  **Initialize App:**
    Run this from the root of your project:
    ```bash
    fly launch --no-deploy
    # Prompts:
    # App Name: discord-raffle-bot-umbrella (or similar unique name)
    # Region: Choose closest to you
    # Database: No (We are using SQLite)
    # Upstash Redis: No
    ```
    *This creates a `fly.toml` file in your root directory.*

3.  **Create Volume (The Hard Drive):**
    This is required for the SQLite database to survive restarts.
    ```bash
    fly volumes create raffle_data --size 1
    ```

4.  **Set Secrets (Upload your keys):**
    You need to generate a `SECRET_KEY_BASE` for Phoenix. You can run `mix phx.gen.secret` locally if you have Elixir installed, or generate a random string.
    ```bash
    fly secrets set DISCORD_TOKEN="your_token_from_phase_1"
    fly secrets set ADMIN_CHANNEL_ID="your_id_from_phase_3"
    fly secrets set SECRET_KEY_BASE="generated_random_string_here"
    ```

5.  **Deploy:**
    ```bash
    fly deploy
    ```
