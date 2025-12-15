# Product Requirements Document (PRD)
**Project Name:** Discord Raffle Bot (Elixir/Phoenix)
**App Location:** `apps/raffle_bot`
**Version:** 2.2 (Winner Selection & Shipping)

## 1. Executive Summary
The Discord Raffle Bot is a persistent, fault-tolerant application designed to automate the management of paid community raffles. It replaces manual spreadsheet tracking with a real-time, database-backed system that handles spot claiming, payment verification, and transparent winner selection.

**Version 2.1 adds the Admin Control Panel** - a pinned forum post in the admin channel that provides a centralized, discoverable interface for creating and managing raffles without needing to remember slash commands.

**Version 2.2 adds Complete Winner Selection** - transparent winner picking with weighted random selection, re-roll audit trail with required reasons, winner announcement with shipping details collection, and full admin thread logging for accountability.

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

### 2.3 Self-Service Payment Flow (Updated in v2.1)

**Version 2.1 Update:** Payment details hidden from main embed; users see them only when paying. Payment platform info collected.

* **Trigger:** User clicks "💰 Pay for Your Spots" button (shown via My Spots).
* **Interaction Flow:**
    1.  Bot shows **Ephemeral Payment Details**:
        * User's claimed spots (aggregated total, not per-spot)
        * Total amount ($price × spot count)
        * Payment instructions (Venmo, PayPal, etc.) - **only shown here, not in main embed**
        * "✅ Mark as Paid" button
    2.  User completes payment externally
    3.  User clicks "Mark as Paid"
    4.  **NEW:** Bot shows **Payment Confirmation Modal** asking:
        * Payment platform selection (Venmo/PayPal/Zelle)
        * Username/email used for payment
    5.  User submits modal
* **Post-Action:**
    1.  **Database:** Set `user_marked_paid = true`, `user_marked_paid_at = DateTime.utc_now()` for ALL user's claims at once
    2.  **Visual Update:** All user's spot buttons update from `[#. @user 💵]` to `[#. @user 💸]` (user marked paid)
    3.  **Admin Thread Notification:** Message posted to raffle's admin thread:
        ```
        💸 Spots #2, #3, #4 claimed by @user marked paid
        Venmo: `@username` • $30
        [Confirmed] [Unconfirmed]
        ```

**Button States (5 states, always show spot number first):**
| # | State | Button Format | Style |
|---|-------|---------------|-------|
| 1 | Available | `[1. Claim]` | Blue (Primary) |
| 2 | Claimed (raffle not full) | `[1. @user]` | Gray (Secondary) |
| 3 | Payment pending (raffle full) | `[1. @user 💵]` | Gray (Secondary) |
| 4 | User marked paid | `[1. @user 💸]` | Gray (Secondary) |
| 5 | Admin confirmed | `[1. @user ✅]` | Green (Success) |

**Note:** The 💵 emoji only appears when the raffle is sold out (all spots claimed), indicating it's time to pay.

### 2.4 Admin Payment Confirmation (New in v2.0)

**Version 2.0 Update:** Admins verify payments directly from admin forum threads.

* **Trigger:** Admin clicks **"Confirmed"** button in admin thread notification.
* **Post-Action:**
    1.  **Database:** Set `is_paid = true`
    2.  **Visual Update:** Spot buttons turn green `[#. @user ✅]`
    3.  **Admin Thread:** Buttons disabled after action

* **Unconfirmed Flow:** Admin clicks **"Unconfirmed"** button
    1.  **Database:** Reset `user_marked_paid = false`
    2.  **Visual Update:** Spot buttons return to `[#. @user 💵]`
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

### 2.6 Winner Selection (Updated in v2.2)

**Version 2.2 Update:** Complete winner workflow with re-roll transparency, shipping collection, and audit trail.

#### 2.6.1 Initiating Winner Selection

* **Triggers:**
    * Admin Slash Command: `/pick_winner`
    * Admin Thread Button: "🏆 Pick Winner" (shown when raffle is closed)

* **Preconditions:**
    * Raffle must be **closed** (`active: false`)
    * At least one **paid** claim exists

#### 2.6.2 Winner Selection Logic

* **Algorithm:** Weighted Random Selection
    * Each paid spot = 1 entry ticket
    * User with 3 paid spots has 3× chance of winning
    * Only `is_paid = true` claims are eligible
* **Database Query:**
    ```
    SELECT user_id, spot_number FROM claims
    WHERE raffle_id = ? AND is_paid = true
    ```
* **Selection:** Random pick from the pool of paid spot entries

#### 2.6.3 Winner Preview (Admin Thread Only)

Bot posts preview message to the raffle's **admin thread**:

```
┌─────────────────────────────────────────┐
│ 🎲 Winner Preview                       │
│                                         │
│ 🏆 @username                            │
│ Spots: #3, #7, #12 (3 entries)          │
│ Winning Entry: Spot #7                  │
│                                         │
│ [✅ Confirm & Announce] [🔄 Re-Roll]    │
└─────────────────────────────────────────┘
```

**Components:**
| Button | Style | Custom ID |
|--------|-------|-----------|
| ✅ Confirm & Announce | Green (Success) | `confirm_winner_{raffle_id}_{user_id}` |
| 🔄 Re-Roll | Gray (Secondary) | `reroll_winner_{raffle_id}` |

#### 2.6.4 Re-Roll Flow (Transparency & Audit)

When admin clicks **"🔄 Re-Roll"**:

1. **Modal Prompt:** Bot shows modal requesting reason
    ```
    ┌─────────────────────────────────────┐
    │ Re-Roll Reason                      │
    │                                     │
    │ Why are you re-rolling this winner? │
    │ ┌─────────────────────────────────┐ │
    │ │                                 │ │
    │ │ (Required - for transparency)   │ │
    │ └─────────────────────────────────┘ │
    │                                     │
    │              [Submit]               │
    └─────────────────────────────────────┘
    ```

2. **Audit Log:** Bot posts to admin thread:
    ```
    ⚠️ Re-Roll Record

    Previous Winner: @username (Spots #3, #7, #12)
    Re-rolled by: @admin
    Reason: [admin's reason]
    Timestamp: 2025-12-15 10:30 UTC
    ```

3. **New Selection:** Bot picks new winner and shows new preview
    * Previous winner remains in the eligible pool (unless manually excluded)

#### 2.6.5 Confirm & Announce Flow

When admin clicks **"✅ Confirm & Announce"**:

1. **Database Update:**
    * Set `winner_user_id` on raffle record
    * Set `winner_announced_at` timestamp

2. **User Thread Announcement:**
    Bot posts to the **user raffle thread**:
    ```
    ┌─────────────────────────────────────────┐
    │ 🎉 We Have a Winner!                    │
    │                                         │
    │ Congratulations @username! 🏆           │
    │                                         │
    │ You won with spot #7!                   │
    │ (3 total entries)                       │
    │                                         │
    │ [📦 Submit Shipping Details]            │
    └─────────────────────────────────────────┘
    ```

    **Important:** The "📦 Submit Shipping Details" button is **only visible to the winner** (ephemeral-style visibility not possible for persistent messages, so button validates user on click).

3. **Raffle Embed Update:**
    * Add field: `🏆 Winner: @username`
    * Change embed color to Gold (`0xFFD700`)

4. **Admin Thread Confirmation:**
    ```
    ✅ Winner Confirmed & Announced

    Winner: @username
    Winning Spot: #7
    Announced at: 2025-12-15 10:35 UTC

    Awaiting shipping details from winner...
    ```

#### 2.6.6 Winner Shipping Details Collection

When winner clicks **"📦 Submit Shipping Details"**:

1. **User Validation:** Bot checks if clicker is the winner
    * If not winner: Ephemeral message "This button is only for the winner."

2. **Shipping Modal:**
    ```
    ┌─────────────────────────────────────────┐
    │ 📦 Shipping Details                     │
    │                                         │
    │ Full Name *                             │
    │ ┌─────────────────────────────────────┐ │
    │ │                                     │ │
    │ └─────────────────────────────────────┘ │
    │                                         │
    │ Street Address *                        │
    │ ┌─────────────────────────────────────┐ │
    │ │                                     │ │
    │ └─────────────────────────────────────┘ │
    │                                         │
    │ City, State, ZIP *                      │
    │ ┌─────────────────────────────────────┐ │
    │ │                                     │ │
    │ └─────────────────────────────────────┘ │
    │                                         │
    │ Country *                               │
    │ ┌─────────────────────────────────────┐ │
    │ │                                     │ │
    │ └─────────────────────────────────────┘ │
    │                                         │
    │ Phone Number                            │
    │ ┌─────────────────────────────────────┐ │
    │ │ (Optional - for delivery updates)   │ │
    │ └─────────────────────────────────────┘ │
    │                                         │
    │              [Submit]                   │
    └─────────────────────────────────────────┘
    ```

3. **Admin Thread Notification:**
    ```
    📦 Shipping Details Received

    Winner: @username

    Name: John Doe
    Address: 123 Main Street
             Apt 4B
    City/State/ZIP: New York, NY 10001
    Country: United States
    Phone: +1 (555) 123-4567

    ✅ Ready to ship!
    ```

4. **Winner Confirmation:**
    Ephemeral message to winner:
    ```
    ✅ Shipping details submitted!

    The raffle admin has been notified and will
    ship your prize soon. Congratulations again!
    ```

5. **Button Update:**
    * Original announcement button changes to disabled: "✅ Shipping Details Submitted"

#### 2.6.7 Data Storage

**Raffle Schema Updates:**
| Field | Type | Description |
|-------|------|-------------|
| `winner_user_id` | string | Discord user ID of winner |
| `winner_announced_at` | utc_datetime | When winner was announced |
| `winner_spot_number` | integer | The specific spot that won |
| `shipping_details` | map | Winner's shipping information (JSON) |
| `shipping_submitted_at` | utc_datetime | When shipping was submitted |

**Re-Roll Audit (New Table: `winner_rerolls`):**
| Field | Type | Description |
|-------|------|-------------|
| `id` | binary_id | Primary key |
| `raffle_id` | binary_id | FK to raffles |
| `previous_winner_id` | string | User ID who was re-rolled |
| `previous_winner_spots` | array | Spot numbers they had |
| `rerolled_by_id` | string | Admin who re-rolled |
| `reason` | string | Reason for re-roll |
| `rerolled_at` | utc_datetime | Timestamp |

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
    4. **Bot creates a pinned Control Panel post in the admin forum channel.**
    5. Bot confirms configuration with ephemeral success message including link to Control Panel.
* **Post-Action:**
    1. Guild configuration created/updated in database.
    2. **Control Panel forum thread created in admin channel** (see Section 2.10).
    3. Control Panel thread/message IDs stored in guild configuration.
    4. Authorization enabled for all admin commands.
    5. Channel validation activated (soft warnings).

### 2.10 Admin Control Panel (New in v2.1)

**Purpose:** Provides a centralized, discoverable location for raffle management within the admin forum channel.

* **Creation:** Automatically created when `/setup_raffle_admin` is run.
* **Location:** Pinned forum thread in the configured admin channel.
* **Thread Name:** "🎰 Raffle Control Panel"

#### Control Panel Components

**Embed:**
* Title: "🎰 Raffle Control Panel"
* Description: Welcome message with quick action instructions
* Fields:
    * Active Raffles count (updates dynamically)
* Color: Discord Blurple (`0x5865F2`)
* Footer: "Raffle Bot | Admin Panel"

**Buttons:**
| Button | Style | Action |
|--------|-------|--------|
| 🎟️ Create New Raffle | Green (Success) | Opens raffle setup modal |
| 📋 List Active Raffles | Blue (Primary) | Shows ephemeral list of active raffles |

#### Button Interactions

**Create New Raffle (`control_panel_create_raffle`):**
* Opens the same modal form as `/setup_raffle` command
* Modal fields: Title, Price, Total Spots, Grading Link, Description
* On submit: Creates user thread + admin thread (existing flow)
* Authorization: Requires Bot Boss role

**List Active Raffles (`control_panel_list_raffles`):**
* Returns ephemeral embed with all active raffles
* Each raffle shows: Title, Price, Thread link
* If no active raffles: Helpful message to create one
* Authorization: Requires Bot Boss role

#### Channel Structure (After Setup)

```
#raffle-admin (Forum Channel)
├── 📌 🎰 Raffle Control Panel (Pinned Thread)
│   └── Control Panel embed + buttons
│   └── [Create New Raffle] → Opens modal
│   └── [List Active Raffles] → Shows active raffles
│
├── 🎯 Spawn #1 CGC 9.8 (Admin Thread - auto-created)
│   └── Admin controls for this specific raffle
│
└── 🎯 Amazing Spider-Man #300 (Admin Thread - auto-created)
    └── Admin controls for this specific raffle
```

#### Data Storage

**GuildConfiguration Schema Updates:**
* `control_panel_thread_id` - Forum thread ID for the control panel
* `control_panel_message_id` - Message ID of the control panel embed

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
