# Server Setup Guide

How to configure the Raffle Bot for your Discord server.

---

## Prerequisites

Before using the bot, your server needs:

### 1. Two Forum Channels

| Channel | Purpose | Visibility |
|---------|---------|------------|
| `#raffle-admin` | Admin controls and notifications | Private (admins only) |
| `#raffles-v2` | Public raffle posts | Public |

### 2. Bot Boss Role

- Create a role named `Bot Boss` (or any name you prefer)
- Assign to users who should manage raffles
- This role grants access to all admin commands

### 3. Bot Invitation

Add the bot to your server with these permissions:
- Send Messages
- Use Slash Commands
- Manage Threads
- Embed Links
- Attach Files

---

## Initial Setup (One Time)

A server administrator must configure the bot once.

### Step 1: Go to Admin Channel

Navigate to your `#raffle-admin` forum channel.

### Step 2: Run Setup Command

```
/setup_raffle_admin bot_boss_role:@BotBoss user_channel:#raffles-v2
```

### What This Configures

| Setting | Source |
|---------|--------|
| Admin channel | Detected from where you run the command |
| User channel | The `user_channel` parameter |
| Admin role | The `bot_boss_role` parameter |
| Control Panel | Created automatically |

### Step 3: Verify Setup

You should see:
- A success message confirming configuration
- A new pinned thread: "🎰 Raffle Control Panel"

---

## Updating Configuration

To change settings after initial setup:

```
/configure_raffle_admin bot_boss_role:@NewRole user_channel:#new-channel
```

This requires the existing Bot Boss role to run.

---

## Channel Structure After Setup

```
#raffle-admin (Forum Channel - Private)
├── 📌 🎰 Raffle Control Panel (Pinned Thread)
│   └── Control Panel embed + buttons
│
├── 🎯 [Raffle Title] (Admin Thread - auto-created per raffle)
│   └── Admin controls for this specific raffle
│
└── ...more raffle admin threads

#raffles-v2 (Forum Channel - Public)
├── 🎟️ [Raffle Title] (Raffle Thread - auto-created)
│   └── Raffle embed + spot buttons
│
└── ...more raffle threads
```

---

## Troubleshooting

### "Bot Boss role not found"
- Ensure the role exists and is spelled correctly
- The bot must be able to see the role

### "Channel must be a forum channel"
- Both admin and user channels must be Forum type channels
- Regular text channels won't work

### Control Panel not appearing
- Check the bot has permission to create threads
- Look for pinned threads in the admin channel
- Run `/setup_raffle_admin` again if needed

---

[← Back to Guide Index](../GUIDE.md)
