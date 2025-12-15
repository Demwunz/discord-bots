# Administrator Guide

How to manage raffles as a Discord server administrator.

---

## Table of Contents

- [Control Panel](#control-panel)
- [Creating a Raffle](#creating-a-raffle)
- [Adding Photos](#adding-photos)
- [Admin Thread](#admin-thread)
- [Payment Verification](#payment-verification)
- [Managing Raffles](#managing-raffles)
- [FAQ](#faq)

---

## Control Panel

The Control Panel is the easiest way to manage raffles. It's automatically created when you run `/setup_raffle_admin`.

**Location:** Pinned thread in `#raffle-admin` named "🎰 Raffle Control Panel"

**Buttons:**

| Button | Action |
|--------|--------|
| 🎟️ **Create New Raffle** | Opens the raffle setup form |
| 📋 **List Active Raffles** | Shows all ongoing raffles with links |

**Benefits:**
- No need to remember slash commands
- Easy to find in the admin channel
- Quick access to active raffle list

---

## Creating a Raffle

### Option 1: Control Panel (Recommended)

1. Go to the "🎰 Raffle Control Panel" thread in `#raffle-admin`
2. Click **"Create New Raffle"** button
3. Fill out the form

### Option 2: Slash Command

Run `/setup_raffle` anywhere in the server

### Form Fields

| Field | Required | Description |
|-------|----------|-------------|
| Title | Yes | Name of the raffle (e.g., "Spawn #1 CGC 9.8") |
| Price per Spot | Yes | Cost per spot (numbers only, e.g., "10") |
| Total Spots | Yes | Number of available spots |
| Grading Link | No | Link to CGC/CBCS certificate (optional) |
| Description | Yes | Details about the item |

### Default Settings

- **Duration:** 7 days (raffle closes if not filled)
- **US Shipping:** Free USPS Ground Advantage
- **International Shipping:** Not available by default
- **Payment:** Venmo, Zelle, or PayPal accepted

### What Happens

1. A forum thread is created in `#raffles-v2`
2. An admin thread is created in `#raffle-admin`
3. Spot buttons appear for users to claim

---

## Adding Photos

Photos are added separately after creating the raffle:

1. Go to the raffle's admin thread in `#raffle-admin`
2. Click the **📸 Add Photos** button
3. Reply to the prompt message with your photo attachments
4. The bot will add the photos to the raffle embed

**Tips:**
- Attach up to 10 images per message
- Send multiple replies to add more photos
- New photos replace existing photos

---

## Admin Thread

Each raffle gets a dedicated admin thread showing:

- Raffle status (Active/Closed)
- Claim statistics (total, paid, pending)
- Payment details
- Admin action buttons

### Admin Actions

| Button | Action |
|--------|--------|
| 📸 Add Photos | Upload photos for the raffle |
| 💰 Mark Paid | Mark users' spots as paid |
| ⏰ Extend Duration | Add 7 days to raffle |
| 🔒 Close Raffle | End the raffle early |
| 🏆 Pick Winner | Randomly select winner (closed raffles only) |

---

## Payment Verification

When a user marks their spots as paid:

1. **Button update** - User's spot buttons change from `💵` to `💸` (visible to all)

2. **Admin notification** appears in the raffle's admin thread:
   ```
   💸 Spots #2, #3, #4 claimed by @user marked paid
   Venmo: `@username` • $30
   [Confirmed] [Unconfirmed]
   ```

3. **Verify payment** in your payment app using the username provided

4. Click **"Confirmed"** or **"Unconfirmed"**

### Confirming Payment
- Updates all user's spot buttons to green with `✅`

### Rejecting (Unconfirmed)
- Resets user's paid status back to `💵`
- User can mark as paid again

### Legacy Command: `/mark_paid`

1. Select a raffle from dropdown
2. Select users who have paid
3. Confirm selection

This is an alternative to the button-based confirmation.

---

## Managing Raffles

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

## FAQ

**Q: Where is the Control Panel?**
A: It's automatically created in `#raffle-admin` when you run `/setup_raffle_admin`. Look for the "🎰 Raffle Control Panel" thread.

**Q: Can I change raffle settings after creation?**
A: You can extend duration. Other changes require creating a new raffle.

**Q: What if someone claims without paying?**
A: Track unpaid claims in the admin thread. You can close the raffle and pick winner from paid spots.

**Q: Can I have multiple raffles at once?**
A: Yes! Each raffle is independent with its own thread.

**Q: What permissions does the bot need?**
A: Send Messages, Use Slash Commands, Manage Threads, Embed Links in both forum channels.

---

[← Back to Guide Index](../GUIDE.md)
