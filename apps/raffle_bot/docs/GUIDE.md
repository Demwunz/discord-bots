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

1. Find an available spot (blue button with number)
2. Click the spot you want (e.g., "5. Claim")
3. Confirm in the popup dialog
4. Your name appears on the button

```
Before: [ 5. Claim ]  (blue, available)
After:  [ @YourName ] (gray, claimed)
```

#### Step 3: Check Your Spots

Click the **"My Spots"** button at the bottom of the raffle to see:
- Which spots you've claimed
- Total amount owed
- Payment status for each spot

#### Step 4: Pay for Your Spots

When all spots are claimed:
1. A payment button appears in the thread
2. Click "Pay for Your Spots"
3. View payment details (Venmo, PayPal, etc.)
4. Send payment to the admin
5. Click "Mark as Paid"

Your button changes to show pending status:
```
[ 💵 @YourName ] (gray with money emoji, waiting admin confirmation)
```

#### Step 5: Wait for Confirmation

The admin will verify your payment and confirm it. Your button turns green:
```
[ @YourName ✅ ] (green, payment confirmed)
```

### Button States Reference

| Appearance | Meaning |
|------------|---------|
| `[ 5. Claim ]` (blue) | Available - click to claim |
| `[ @YourName ]` (gray) | Claimed, payment pending |
| `[ 💵 @YourName ]` (gray) | User marked as paid (waiting admin) |
| `[ @YourName ✅ ]` (green) | Admin confirmed payment |

### Check Your Spots

Click the **🎟️ My Spots** button on any raffle to see your claimed spots and payment status.

---

## For Administrators

### Creating a Raffle

**Command:** `/setup_raffle`

Opens a form with these fields:

| Field | Required | Description |
|-------|----------|-------------|
| Title | Yes | Name of the raffle (e.g., "Spawn #1 CGC 9.8") |
| Price per Spot | Yes | Cost per spot (numbers only, e.g., "10") |
| Total Spots | Yes | Number of available spots |
| Grading Link | No | Link to CGC/CBCS certificate (optional) |
| Description | Yes | Details about the item |

**Default Settings:**
- **Duration:** 7 days (raffle closes if not filled)
- **US Shipping:** Free USPS Ground Advantage
- **International Shipping:** Not available by default
- **Payment:** Venmo, Zelle, or PayPal accepted

**What Happens:**
1. A forum thread is created in `#raffles-v2`
2. An admin thread is created in `#raffle-admin`
3. Spot buttons appear for users to claim

### Adding Photos

Photos are added separately after creating the raffle:

1. Go to the raffle's admin thread in `#raffle-admin`
2. Click the **📸 Add Photos** button
3. Reply to the prompt message with your photo attachments
4. The bot will add the photos to the raffle embed

**Tips:**
- Attach up to 10 images per message
- Send multiple replies to add more photos
- New photos replace existing photos

### Admin Thread

Each raffle gets a dedicated admin thread showing:

- Raffle status (Active/Closed)
- Claim statistics (total, paid, pending)
- Payment details
- Admin action buttons

**Admin Actions:**

| Button | Action |
|--------|--------|
| 📸 Add Photos | Upload photos for the raffle |
| 💰 Mark Paid | Mark users' spots as paid |
| ⏰ Extend Duration | Add 7 days to raffle |
| 🔒 Close Raffle | End the raffle early |
| 🏆 Pick Winner | Randomly select winner (closed raffles only) |

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
+------------------------------------------+
| 🎟️ Raffle Time! — Amazing Item            |
+------------------------------------------+
| [Image if photos added]                  |
|                                          |
| A beautiful CGC 9.8 graded comic...      |
|                                          |
| 🔗 Grading: View Certificate (if link)   |
|                                          |
| 💵 Spots are $10 each — grab as many     |
|    as you want!                          |
| 🎯 25 total spots — pick your spot by    |
|    clicking the buttons below!           |
|                                          |
| Raffles will run as soon as all spots    |
| are filled.                              |
| If we don't fill it up within 7 days,    |
| this one will close.                     |
|                                          |
| 📦 Shipping Info:                        |
| 🇺🇸 US: Free USPS Ground Advantage        |
| 🌍 No international shipping             |
|                                          |
| 💳 Payment:                              |
| Only collected once all spots are full   |
| — Venmo, Zelle or PayPal is good to go.  |
+------------------------------------------+
```

### Spot Button Grid

```
Spots 1-20:
[1. Claim] [2. Claim] [ @Kim  ] [4. Claim] [5. Claim]
[ @Joe  ] [7. Claim] [8. Claim] [ @Amy  ] [10.Claim]
[11.Claim] [@Sam ✅] [13.Claim] [14.Claim] [15.Claim]
[16.Claim] [17.Claim] [18.Claim] [19.Claim] [20.Claim]

[🎟️ My Spots]

Legend:
[#. Claim] = Available (blue)
[ @Name ] = Claimed, unpaid (gray)
[ 💵 @Name ] = User marked paid (gray)
[ @Name ✅] = Admin confirmed paid (green)
```

### Large Raffles (>20 spots)

For raffles with more than 20 spots:
- First message shows spots 1-20 plus the My Spots button
- Reply messages show spots 21-40, 41-60, etc.

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
