# Raffle Bot Documentation

A Discord bot for managing community raffles with real-time spot claiming, payment tracking, and automated winner selection.

---

## Quick Links

| Guide | Description |
|-------|-------------|
| [Server Setup](guides/SETUP.md) | Configure the bot for your Discord server |
| [User Guide](guides/USER_GUIDE.md) | How to join raffles and claim spots |
| [Admin Guide](guides/ADMIN_GUIDE.md) | Managing raffles, payments, and winners |
| [Visual Reference](guides/VISUAL_REFERENCE.md) | Screenshots and interface examples |

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
| Control Panel | Centralized button-based raffle management |
| Per-Spot Buttons | Click directly on the spot you want |
| Real-Time Updates | All users see changes instantly |
| Payment Tracking | Visual indicators for paid/unpaid status |
| Admin Controls | Dedicated admin thread per raffle |
| Forum Organization | Each raffle gets its own thread |

---

## Quick Start

### For Server Admins

1. Create two forum channels: `#raffle-admin` (private) and `#raffles-v2` (public)
2. Create a `Bot Boss` role for raffle managers
3. Run `/setup_raffle_admin` in the admin channel
4. Use the Control Panel to create your first raffle

→ [Full Setup Guide](guides/SETUP.md)

### For Users

1. Browse `#raffles-v2` for active raffles
2. Click a numbered button to claim a spot
3. When the raffle fills, click "My Spots" to pay
4. Wait for admin to confirm your payment

→ [Full User Guide](guides/USER_GUIDE.md)

### For Raffle Admins

1. Open the Control Panel in `#raffle-admin`
2. Click "Create New Raffle"
3. Verify payments in each raffle's admin thread
4. Pick winners when ready

→ [Full Admin Guide](guides/ADMIN_GUIDE.md)

---

## Button States (5 States)

| Appearance | Meaning |
|------------|---------|
| `[ 1. Claim ]` (blue) | Available - click to claim |
| `[ 1. @user ]` (gray) | Claimed (raffle still has open spots) |
| `[ 1. @user 💵 ]` (gray) | Payment pending (raffle is full) |
| `[ 1. @user 💸 ]` (gray) | User marked as paid (waiting admin) |
| `[ 1. @user ✅ ]` (green) | Admin confirmed payment |

**Note:** The 💵 emoji only appears when all spots are claimed.

---

## Slash Commands Reference

| Command | Who | Description |
|---------|-----|-------------|
| `/setup_raffle_admin` | Server Admin | Initial bot configuration |
| `/configure_raffle_admin` | Bot Boss | Update bot configuration |
| `/setup_raffle` | Bot Boss | Create a new raffle |
| `/mark_paid` | Bot Boss | Mark users as paid (legacy) |
| `/end_raffle` | Bot Boss | Close a raffle early |
| `/extend_raffle` | Bot Boss | Add 7 days to a raffle |
| `/pick_winner` | Bot Boss | Select random winner |

---

## Related Documentation

- [Product Requirements](../specs/product_requirements.md) - Feature specifications
- [Technical Requirements](../specs/technical_requirements.md) - Implementation details

---

*Last Updated: December 2025 (v2.1 - Control Panel)*
