# Product Requirements Document (PRD)
**Project Name:** Discord Raffle Bot (Elixir/Phoenix)
**App Location:** `apps/raffle_bot`
**Version:** 2.0 (Elixir Pivot)

## 1. Executive Summary
The Discord Raffle Bot is a persistent, fault-tolerant application designed to automate the management of paid community raffles. It replaces manual spreadsheet tracking with a real-time, database-backed system that handles spot claiming, payment verification, and transparent winner selection.

## 2. Functional Requirements

### 2.1 Raffle Creation (`/setup_raffle`)
* **Trigger:** Slash Command.
* **Inputs:** `Title`, `Price`, `Total Spots`, `Photo URL`.
* **Interaction Flow:**
    1.  Admin runs command.
    2.  Bot opens a **Modal Form** requesting text-heavy details:
        * `Description` (Paragraph)
        * `Grading Link` (Text)
        * `Duration` (Number of days)
        * `International Shipping` (Text, e.g., "No" or "Yes +$15")
    3.  **Output:**
        * Generates a Discord Embed using the standard "Raffle Time!" text template.
        * Pins the message to the channel.
        * Attaches a **Persistent View** with a button labeled `[ 🎟️ Claim Spots ]`.

### 2.2 Spot Claiming (User Interaction)
* **Trigger:** User clicks the `[ 🎟️ Claim Spots ]` button.
* **Interaction Flow:**
    1.  Bot fetches currently available spots from the database (Ecto).
    2.  Bot sends an **Ephemeral Message** (Private) with a **Multi-Select Dropdown Menu**.
    3.  **Pagination Logic:**
        * Discord dropdowns support max 25 items.
        * **Constraint:** If open spots > 25, the bot must generate multiple dropdowns in the same message (e.g., "Select 1-25", "Select 26-50").
* **Post-Action:**
    1.  **Validation:** Ensure spots weren't taken milliseconds ago.
    2.  **Database:** Insert claim record (User ID, Spot ID).
    3.  **Visual Update:** Edit the Pinned Embed to update the grid (e.g., `1. @Username`).
    4.  **Sold Out Check:** If `Total Claims` == `Total Spots`, immediately DM the configured Admin Channel: *"🚨 SOLD OUT: [Raffle Title]"*.

### 2.3 Payment Tracking (`/mark_paid`)
* **Trigger:** Admin Slash Command.
* **Interaction Flow:**
    1.  Bot presents a dropdown of **Active Raffles**.
    2.  Admin selects a raffle.
    3.  Bot presents a Multi-Select Dropdown of users who have **Unpaid** claims in that raffle.
    4.  Admin selects users and clicks Confirm.
* **Post-Action:**
    1.  Update database: Set `is_paid = true`.
    2.  Update Pinned Embed: Append checkmark to user entry (`1. @Username ✅`).

### 2.4 Winner Selection (`/pick_winner`)
* **Trigger:** Admin Slash Command.
* **Interaction Flow:**
    1.  Admin selects a **Closed** raffle.
    2.  Bot calculates a **Weighted Random Winner** (1 spot = 1 entry ticket).
    3.  **Review Phase:** Bot posts the potential winner **only** to the Admin Channel.
        * Controls: `[ ✅ Confirm & Announce ]` and `[ 🔄 Re-Roll ]`.
* **Confirmation Action:**
    1.  Edit Pinned Embed: Add a `🏆 WINNER: @Username` field.
    2.  Post Announcement: Send a congratulatory message to the `#general` channel.

### 2.5 Administration
* **Manual Close (`/end_raffle`):**
    * Admin selects an active raffle.
    * Bot sets status to `active: false`, updates title to `[CLOSED]`, and disables the "Claim" button.
* **Daily Reporting:**
    * **Mechanism:** A GenServer process runs every 24 hours.
    * **Action:** Query new claims from the last 24h and post a summary to the Admin Channel.

### 2.6 Guild Configuration (`/setup_raffle_admin`)
* **Trigger:** Admin Slash Command (First-time setup).
* **Authorization:** Requires Discord "Manage Server" permission.
* **Inputs:**
    * `bot_boss_role` - Discord role that will have admin access to raffle commands
    * `user_channel` - Public channel where raffle posts will appear
* **Interaction Flow:**
    1. Admin runs command from the desired admin channel.
    2. Bot automatically detects admin channel from command invocation location.
    3. Bot stores guild configuration in database.
    4. Bot confirms configuration with ephemeral success message.
* **Post-Action:**
    1. Guild configuration created/updated in database.
    2. Authorization enabled for all admin commands.
    3. Channel validation activated (soft warnings).

### 2.7 Guild Reconfiguration (`/configure_raffle_admin`)
* **Trigger:** Admin Slash Command.
* **Authorization:** Requires Bot Boss role (from guild configuration).
* **Inputs:** Same as `/setup_raffle_admin`.
* **Interaction Flow:** Identical to setup, but requires existing Bot Boss role.
* **Purpose:** Allows changing channels or Bot Boss role after initial setup.

### 2.8 Authorization & Channel Validation
* **Role-Based Authorization:**
    * All admin commands require Bot Boss role (configured per-guild).
    * Users without Bot Boss role receive ephemeral error message.
    * Authorization checked before command execution.
* **Channel Validation (Soft Enforcement):**
    * Admin commands should be used in admin channel.
    * User commands should be used in user channel.
    * Wrong channel usage logs warning but allows execution.
    * Provides helpful tip to users about designated channels.
* **Unconfigured Guilds:**
    * Before `/setup_raffle_admin` is run, commands work without restrictions.
    * After configuration, authorization and validation are enforced.

## 3. UI/UX Specifications
* **Embed Colors:** Green (`0x57F287`) for Active, Red (`0xED4245`) for Closed.
* **Grid Format:** The list of spots must be displayed in the Embed Description or Fields as text.
    * *Unclaimed:* `1. [OPEN]`
    * *Claimed (Unpaid):* `1. @Username`
    * *Claimed (Paid):* `1. @Username ✅`
