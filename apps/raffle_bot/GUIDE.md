# Discord Raffle Bot Guide

Welcome to the Raffle Bot! This guide explains everything you need to know to manage paid community raffles directly within your Discord server.

## 🌟 Overview

The Raffle Bot automates the entire raffle process, from creation to winner selection. It replaces clunky spreadsheets with a real-time, persistent system, making raffles fair, transparent, and easy to manage.

---

## 🚀 For Administrators: Managing Raffles

As an admin, you have access to a suite of slash commands to create and manage raffles.

### 1. Creating a Raffle

The first step is to create a new raffle.

*   **Command:** `/setup_raffle`
*   **Action:** This opens a form (a Discord Modal) where you can enter the raffle details.

#### Raffle Details:
*   **Title:** The name of your raffle (e.g., "Spawn #1").
*   **Price:** The cost for a single spot.
*   **Total Spots:** The total number of spots available.
*   **Photo URL:** A link to an image that will be displayed in the raffle embed.
*   **Description:** A detailed description of the item being raffled.
*   **Grading Link:** (Optional) A link to CGC/PSA etc or additional details.
*   **Duration:** The number of days the raffle will run before automatically closing (defaults to 7).
*   **International Shipping:** Information about international shipping (e.g., "Yes, buyer pays shipping" or "No").

Once submitted, the bot will post a beautiful embed in the channel, pin it, and add a **[ 🎟️ Claim Spots ]** button for users to join.

### 2. Tracking Payments

Keep track of who has paid for their spots.

*   **Command:** `/mark_paid`
*   **Action:**
    1.  A dropdown will appear, listing all active raffles.
    2.  Select the raffle you want to update.
    3.  A new multi-select dropdown will appear, showing only the users who have **unpaid** claims.
    4.  Select the users who have paid and confirm.
*   **Result:** The raffle embed will update, adding a `✅` next to the names of paid users.

### 3. Ending a Raffle

You can end a raffle manually at any time.

*   **Command:** `/end_raffle`
*   **Action:** Select an active raffle from the dropdown menu.
*   **Result:** The raffle will be marked as **[CLOSED]**, and the "Claim Spots" button will be disabled.

### 4. Extending a Raffle

Need more time? You can extend a raffle's duration.

*   **Command:** `/extend_raffle`
*   **Action:** Select an active raffle from the dropdown menu.
*   **Result:** The raffle's duration will be extended by 7 days.

### 5. Picking a Winner

Once a raffle is closed and all payments are collected, it's time to pick a winner!

*   **Command:** `/pick_winner`
*   **Action:**
    1.  Select a **closed** raffle from the dropdown menu.
    2.  The bot will randomly select a winner, with each spot counting as one entry.
    3.  The potential winner is posted **privately** to the admin channel for review.
    4.  You can then **[ ✅ Confirm & Announce ]** or **[ 🔄 Re-Roll ]**.
*   **Result:**
    *   **On confirmation:** The winner is announced in the main channel, and the raffle embed is updated with a `🏆 WINNER` field.

### 6. Daily Reporting

The bot will automatically post a summary of new claims from the last 24 hours to the admin channel every day.

---

## 🙋 For Users: Participating in Raffles

### 1. Claiming Your Spots

Joining a raffle is simple.

*   **Action:** Click the **[ 🎟️ Claim Spots ]** button on any active raffle.
*   **Interaction:**
    1.  The bot will send you a **private message** (ephemeral) with one or more dropdown menus.
    2.  If there are more than 25 spots available, you'll see multiple dropdowns (e.g., "Spots 1-25", "Spots 26-50").
    3.  Select the spots you want to claim.
*   **Result:** The raffle embed will instantly update to show your name next to your claimed spots.

### 2. Checking Your Spots

You can view all the spots you've claimed across all raffles.

*   **Command:** `/my_spots`
*   **Result:** The bot will send you a private message listing all your claimed spots and their payment status.

## Local Development with Docker

If you prefer to use Docker for local development, you can use the provided `docker-compose.yml` file to build and run the application.

### Prerequisites

*   [Docker](https://docs.docker.com/get-docker/)
*   [Docker Compose](https://docs.docker.com/compose/install/)

### Setup

1.  **Create a `.env` file:**

    Create a copy of the `.env.example` file and name it `.env`.

    ```bash
    cp .env.example .env
    ```

2.  **Fill in the environment variables:**

    Open the `.env` file and fill in the required environment variables:

    *   `SECRET_KEY_BASE`: You can generate a new secret by running `mix phx.gen.secret`.
    *   `DISCORD_TOKEN`: Your Discord bot token.
    *   `ADMIN_CHANNEL_ID`: The ID of the channel where you want to receive admin reports.

### Running the Application

Once you have configured your `.env` file, you can start the application using Docker Compose:

```bash
docker-compose up --build
```

This will build the Docker image and start the application. The bot will be running and connected to Discord.

Any changes you make to the local application code will be automatically reflected in the running container.
---

## 🎨 Visual Guide

The raffle embed provides a clear, at-a-glance view of the raffle's status.

*   **Color:**
    *   **Green (`0x57F287`):** The raffle is active and open for claims.
    *   **Red (`0xED4245`):** The raffle is closed.
*   **Spot Status:**
    *   `1. [OPEN]` - The spot is available.
    *   `1. @Username` - The spot is claimed but not yet paid for.
    *   `1. @Username ✅` - The spot is claimed and paid for.
    *   `🏆 WINNER: @Username` - The winner of the raffle.