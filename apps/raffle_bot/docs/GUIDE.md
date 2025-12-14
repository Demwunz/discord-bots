# Raffle Bot User Guide

A Discord bot for managing community raffles with real-time spot claiming, payment tracking, and automated winner selection.

---

## Table of Contents

1. [Overview](#overview)
2. [Getting Started](#getting-started)
3. [For Users](#for-users)
4. [For Administrators](#for-administrators)
5. [Visual Reference](#visual-reference)
6. [FAQ](#faq)

---

## Overview

The Raffle Bot automates the entire raffle process within Discord:

- **Create raffles** with customizable spots, pricing, and descriptions
- **Claim spots** directly by clicking buttons (no complex menus)
- **Track payments** with visual status indicators
- **Pick winners** randomly with fair spot-based weighting

### Key Features

| Feature | Description |
|---------|-------------|
| Per-Spot Buttons | Click directly on the spot you want |
| Real-Time Updates | All users see changes instantly |
| Payment Tracking | Visual indicators for paid/unpaid status |
| Admin Controls | Dedicated admin thread per raffle |
| Forum Organization | Each raffle gets its own thread |

---

## Getting Started

### Prerequisites

Before using the bot, your server needs:

1. **Two Forum Channels:**
   - `#raffle-admin` - Private channel for admin controls
   - `#raffles-v2` - Public channel for raffle posts

2. **Bot Boss Role:**
   - Create a role named `Bot Boss`
   - Assign to users who should manage raffles

3. **Bot Invitation:**
   - Add the bot to your server with appropriate permissions

### Initial Setup (One Time)

A server administrator must configure the bot once:

**In `#raffle-admin`, run:**
```
/setup_raffle_admin bot_boss_role:@BotBoss user_channel:#raffles-v2
```

This configures:
- Which channel receives raffle posts
- Which role has admin permissions
- The admin channel (detected automatically)

**Updating Configuration Later:**
```
/configure_raffle_admin bot_boss_role:@NewRole user_channel:#new-channel
```

---

## For Users

### How to Join a Raffle

#### Step 1: Find a Raffle

Browse the `#raffles-v2` forum channel. Each raffle is a separate thread with:
- Raffle description and price
- Grid of numbered spot buttons

#### Step 2: Claim a Spot

1. Find an available spot (blue button with arrow)
2. Click the spot number you want
3. Confirm in the popup dialog
4. Your name appears on the button

```
Before: [ -> 5 ]      (blue, available)
After:  [ @YourName ] (gray, claimed)
```

#### Step 3: Pay for Your Spots

When all spots are claimed:
1. A payment button appears in the thread
2. Click "Pay for Your Spots"
3. View payment details (Venmo, PayPal, etc.)
4. Send payment to the admin
5. Click "Mark as Paid"

Your button changes to show pending status:
```
[ checkmark @YourName ] (gray with checkmark, waiting admin confirmation)
```

#### Step 4: Wait for Confirmation

The admin will verify your payment and confirm it. Your button turns green:
```
[ @YourName checkmark ] (green, payment confirmed)
```

### Button States Reference

| Appearance | Meaning |
|------------|---------|
| Blue with arrow | Available - click to claim |
| Gray with @name | Claimed, payment pending |
| Gray with checkmark @name | User marked as paid (waiting admin) |
| Green with @name checkmark | Admin confirmed payment |

### Check Your Spots

**Command:** `/my_spots`

Shows all spots you've claimed across all raffles with payment status.

---

## For Administrators

### Creating a Raffle

**Command:** `/setup_raffle`

Opens a form with these fields:

| Field | Required | Description |
|-------|----------|-------------|
| Title | Yes | Name of the raffle |
| Price | Yes | Cost per spot (numbers only) |
| Total Spots | Yes | Number of available spots |
| Description | Yes | Details about the item |
| Photo URL | No | Image URL for the embed |
| Grading Link | No | CGC/PSA verification link |
| Duration | No | Days until auto-close (default: 7) |
| International Shipping | No | Shipping terms |
| Payment Details | No | How to pay (Venmo, PayPal, etc.) |

**What Happens:**
1. A forum thread is created in `#raffles-v2`
2. An admin thread is created in `#raffle-admin`
3. Spot buttons appear for users to claim

### Admin Thread

Each raffle gets a dedicated admin thread showing:

- Raffle status (Active/Closed)
- Claim statistics (total, paid, pending)
- Payment details
- Admin action buttons

**Admin Actions:**

| Button | Action |
|--------|--------|
| Mark Paid | Mark users' spots as paid |
| Extend Duration | Add 7 days to raffle |
| Close Raffle | End the raffle early |
| Pick Winner | Randomly select winner (closed raffles only) |

### Payment Verification Flow

When a user marks their spots as paid:

1. **Notification appears** in the raffle's admin thread
2. Shows user, spots claimed, and total amount
3. **Verify payment** in your payment app
4. Click **"Confirm Payment"** or **"Reject"**

Confirming payment:
- Updates spot buttons to green
- User receives confirmation

Rejecting payment:
- Resets user's paid status
- User can try again

### Managing Payments (Legacy Command)

**Command:** `/mark_paid`

1. Select a raffle from dropdown
2. Select users who have paid
3. Confirm selection

This is an alternative to the button-based confirmation.

### Ending Raffles

**Command:** `/end_raffle`

Select an active raffle to close it. This:
- Disables all claim buttons
- Marks raffle as closed
- Enables "Pick Winner" button

### Extending Raffles

**Command:** `/extend_raffle`

Adds 7 days to the selected raffle's duration.

### Picking Winners

**Command:** `/pick_winner`

1. Select a **closed** raffle
2. Bot randomly selects a winner (each spot = one entry)
3. Preview shown privately in admin thread
4. Click **"Confirm & Announce"** or **"Re-Roll"**

On confirmation:
- Winner announced in raffle thread
- Raffle embed updated with winner

### Daily Reporting

The bot automatically posts a summary of new claims from the last 24 hours to the admin channel every day.

---

## Visual Reference

### Raffle Embed

```
+----------------------------------+
|  Raffle Time!                    |
+----------------------------------+
|  [Image if provided]             |
|                                  |
|  Title: Amazing Item             |
|  Price: $10                      |
|  Total Spots: 25                 |
|  Spots Claimed: 15               |
|  Spots Remaining: 10             |
|  Participants: @User1, @User2... |
+----------------------------------+
```

### Spot Button Grid

```
Spots 1-25:
[ -> 1 ] [ -> 2 ] [ @Kim ] [ -> 4 ] [ -> 5 ]
[ @Joe ] [ -> 7 ] [ -> 8 ] [ @Amy ] [ -> 10 ]
[ -> 11] [@Sam v] [ -> 13] [ -> 14] [ -> 15]
[ -> 16] [ -> 17] [ -> 18] [ -> 19] [ -> 20]
[ -> 21] [ -> 22] [ -> 23] [ -> 24] [ -> 25]

Legend:
[ -> # ]   = Available (blue)
[ @Name ]  = Claimed, unpaid (gray)
[ @Name v] = Admin confirmed paid (green)
```

### Large Raffles (>25 spots)

For raffles with more than 25 spots:
- First message shows spots 1-25
- Reply messages show spots 26-50, 51-75, etc.

### Admin Thread View

```
+----------------------------------+
|  Raffle: Amazing Item            |
+----------------------------------+
|  Status: Active                  |
|  Price: $10 per spot             |
|  Total Spots: 25                 |
|  Claimed: 15/25                  |
|  Paid: 8                         |
|  Pending Payment: 7              |
+----------------------------------+
| [Mark Paid] [Extend] [Close]     |
+----------------------------------+
```

---

## FAQ

### For Users

**Q: Can I claim multiple spots?**
A: Yes! Click each spot you want individually and confirm each one.

**Q: Can I unclaim a spot?**
A: No. Contact an admin if you need to release a spot.

**Q: What if I marked as paid but admin rejected it?**
A: Check your payment went through, then mark as paid again.

**Q: How is the winner chosen?**
A: Random selection where each spot = one entry. More spots = better odds.

### For Admins

**Q: Can I change raffle settings after creation?**
A: You can extend duration. Other changes require creating a new raffle.

**Q: What if someone claims without paying?**
A: Track unpaid claims in the admin thread. You can close the raffle and pick winner from paid spots.

**Q: Can I have multiple raffles at once?**
A: Yes! Each raffle is independent with its own thread.

**Q: What permissions does the bot need?**
A: Send Messages, Use Slash Commands, Manage Threads, Embed Links in both forum channels.

---

## Related Documentation

- [Technical Requirements](../specs/technical_requirements.md) - Implementation details
- [Product Requirements](../specs/product_requirements.md) - Feature specifications
- [Migration Plan](PLAN.md) - UI migration details

---

*Last Updated: December 2025*
