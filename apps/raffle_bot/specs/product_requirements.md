# Product Requirements Document (PRD)
**Project Name:** Discord Raffle Bot (Elixir/Phoenix)
**App Location:** `apps/raffle_bot`
**Version:** 2.0 (Elixir Pivot)

## 1. Executive Summary
The Discord Raffle Bot is a persistent, fault-tolerant application designed to automate the management of paid community raffles. It replaces manual spreadsheet tracking with a real-time, database-backed system that handles spot claiming, payment verification, and transparent winner selection.

## 2. Functional Requirements

### 2.1 Raffle Creation (`/setup_raffle`)

**Version 2.0 Update:** Raffles now create forum threads instead of simple messages.

* **Trigger:** Slash Command.
* **Inputs:** `Title`, `Price`, `Total Spots`, `Photo URL`.
* **Interaction Flow:**
    1.  Admin runs command.
    2.  Bot opens a **Modal Form** requesting text-heavy details:
        * `Description` (Paragraph)
        * `Grading Link` (Text)
        * `Duration` (Number of days)
        * `International Shipping` (Text, e.g., "No" or "Yes +$15")
        * `Payment Details` (Text, e.g., "Venmo: @username")
    3.  **Output:**
        * Creates **User Forum Thread** in configured `user_channel_id`:
          - Thread starter: Raffle embed + spot buttons (page 1: spots 1-25)
          - Additional messages: More spot buttons if >25 spots
        * Creates **Admin Forum Thread** in configured `admin_channel_id`:
          - Thread starter: Admin embed + admin control buttons
          - Used for payment notifications and admin actions

### 2.2 Spot Claiming (User Interaction) - Button-Based UI

**Version 2.0 Update:** Spot claiming now uses direct button interactions instead of dropdown menus.

* **Trigger:** User clicks a spot button (e.g., `➡️ 5`) on the raffle message.
* **Interaction Flow:**
    1.  Bot shows an **Ephemeral Confirmation Dialog** with spot details
    2.  User clicks "✅ Confirm Claim" or "❌ Cancel"
    3.  **Multi-Page Support:**
        * Discord limit: 25 buttons per message (5 rows × 5 buttons)
        * Raffles >25 spots: Additional messages posted in thread for spots 26-50, 51-75, etc.
* **Post-Action:**
    1.  **Validation:** Unique constraint ensures no double-booking
    2.  **Database:** Insert claim record (`raffle_id`, `user_id`, `spot_number`)
    3.  **Visual Update:** All spot button messages refresh simultaneously
        * Claimed spot: Gray button with @username
        * Remaining spots: Stay blue with ➡️ and number
    4.  **Sold Out Flow:** If `Total Claims` == `Total Spots`:
        * "Pay for your spots" button posted to thread
        * Admins notified in admin forum thread

### 2.3 Self-Service Payment Flow (New in v2.0)

**Version 2.0 Update:** Users can now mark their own spots as paid for admin verification.

* **Trigger:** User clicks "💰 Pay for Your Spots" button (posted when raffle sells out).
* **Interaction Flow:**
    1.  Bot shows **Ephemeral Payment Details**:
        * User's claimed spots
        * Total amount ($price × spot count)
        * Payment instructions (Venmo, PayPal, etc.)
        * "✅ Mark as Paid" button
    2.  User completes payment externally
    3.  User clicks "Mark as Paid"
* **Post-Action:**
    1.  **Database:** Set `user_marked_paid = true`, `user_marked_paid_at = DateTime.utc_now()`
    2.  **Visual Update:** Spot buttons update to yellow/gray ✅ @username (pending admin verification)
    3.  **Admin Notification:** Message posted to admin forum thread:
        * User mention
        * Spots and amount
        * "✅ Confirm Payment" and "❌ Reject" buttons

### 2.4 Admin Payment Confirmation (New in v2.0)

**Version 2.0 Update:** Admins verify payments directly from admin forum threads.

* **Trigger:** Admin clicks "✅ Confirm Payment" in admin thread notification.
* **Post-Action:**
    1.  **Database:** Set `is_paid = true`
    2.  **Visual Update:** Spot buttons turn green ✅ @username
    3.  **Admin Thread:** Confirmation message updated to show completed

* **Reject Flow:** Admin clicks "❌ Reject"
    1.  **Database:** Reset `user_marked_paid = false`
    2.  **Visual Update:** Spot buttons return to gray @username
    3.  User can mark as paid again after actual payment

### 2.5 Legacy Payment Tracking (`/mark_paid`)

**Note:** This command still works for backward compatibility.

* **Trigger:** Admin Slash Command.
* **Interaction Flow:**
    1.  Bot presents a dropdown of **Active Raffles**.
    2.  Admin selects a raffle.
    3.  Bot presents a Multi-Select Dropdown of users who have **Unpaid** claims in that raffle.
    4.  Admin selects users and clicks Confirm.
* **Post-Action:**
    1.  Update database: Set `is_paid = true`.
    2.  Update spot buttons: Turn green ✅ @username.

### 2.6 Winner Selection (`/pick_winner`)
* **Trigger:** Admin Slash Command.
* **Interaction Flow:**
    1.  Admin selects a **Closed** raffle.
    2.  Bot calculates a **Weighted Random Winner** (1 spot = 1 entry ticket).
    3.  **Review Phase:** Bot posts the potential winner **only** to the Admin Channel/Thread.
        * Controls: `[ ✅ Confirm & Announce ]` and `[ 🔄 Re-Roll ]`.
* **Confirmation Action:**
    1.  Edit raffle message: Add a `🏆 WINNER: @Username` field.
    2.  Post Announcement: Send a congratulatory message to the raffle thread.

### 2.7 Administration
* **Manual Close (`/end_raffle`):**
    * Admin selects an active raffle.
    * Bot sets status to `active: false`, updates title to `[CLOSED]`, and disables spot buttons.
* **Daily Reporting:**
    * **Mechanism:** A GenServer process runs every 24 hours.
    * **Action:** Query new claims from the last 24h and post a summary to the Admin Channel.

### 2.8 Guild Configuration (`/setup_raffle_admin`)
* **Trigger:** Admin Slash Command (First-time setup).
* **Authorization:** Requires Discord "Manage Server" permission.
* **Note:** Both user and admin channels must be **Forum Channels** (Discord channel type 15).
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
