# Product Context

## Overview

Discord Bots is an Elixir umbrella project hosting multiple Discord bot applications. The umbrella architecture enables shared infrastructure while keeping each bot independent.

## Applications

### Raffle Bot

A Discord bot that automates paid community raffles from creation through winner selection and shipping management.

#### Core User Flows

**1. Guild Setup (Admin)**
- Admin runs `/configure_raffle_admin` in admin channel
- Sets admin channel, user channel, and bot boss role
- Configuration persists per Discord server (guild)

**2. Raffle Creation (Admin)**
- Admin runs `/setup_raffle` or `/setup_raffle_admin`
- Fills modal: title, description, price, spots, shipping costs
- Bot posts raffle embed in user channel
- Creates admin thread for management
- Schedules auto-close based on duration (1-30 days)

**3. Spot Claiming (User)**
- User clicks "Claim Spot" button on raffle
- Selects spot number from paginated dropdown
- Confirms claim
- Can claim multiple spots per raffle

**4. Payment Flow**
- User marks themselves as paid (self-service)
- Selects payment platform (Venmo, PayPal, etc.)
- Admin reviews and confirms payment in admin thread
- Real-time status updates on raffle embed

**5. Winner Selection (Admin)**
- Admin runs `/pick_winner` after raffle closes
- Weighted random selection from paid claims
- Winner notified via DM
- Can reroll with reason if winner doesn't respond

**6. Shipping (Winner)**
- Winner clicks "Submit Shipping" button
- Fills shipping details modal
- Admin receives shipping info in admin thread
- Marks as shipped when complete

#### Key Features

- **Multi-Guild Support**: Each Discord server has independent configuration
- **Persistent Data**: SQLite database survives bot restarts
- **Auto-Close**: Raffles automatically close after specified duration
- **Photo Management**: Admins can upload product photos to admin threads
- **Audit Trail**: Winner rerolls are logged with reasons
- **Paginated UI**: Handles raffles with many spots gracefully

#### User Roles

| Role | Permissions |
|------|-------------|
| Bot Boss | Create/manage raffles, mark payments, pick winners |
| Regular User | Claim spots, mark self as paid, submit shipping |

## Future Applications

The umbrella structure is designed to host additional Discord bots. Each new bot:
- Lives in `apps/<bot_name>/`
- Has its own database and configuration
- Shares common dependencies (Nostrum, Ecto)
- Can be deployed independently
