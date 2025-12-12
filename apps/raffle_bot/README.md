# Raffle Bot

The Raffle Bot is a powerful Discord bot designed to streamline and automate the management of paid community raffles. It handles the entire raffle process, from initial setup and spot claiming to payment tracking and transparent winner selection.

## ✨ Key Features

*   **Automated Raffle Creation**: Admins can easily set up raffles via a slash command and modal form.
*   **Spot Claiming**: Users can claim spots through an interactive, paginated select menu.
*   **Payment Tracking**: Admin commands to mark claimed spots as paid, updating the raffle status in real-time.
*   **Winner Selection**: Automated weighted random winner selection with an admin review process.
*   **Persistent Data**: Utilizes a SQLite database to ensure all raffle data is stored persistently.
*   **Discord Integration**: Seamless interaction with Discord UI elements like slash commands, buttons, modals, and select menus.

## 🚀 Getting Started

For a detailed guide on how to set up, configure, and use the Raffle Bot, please refer to the [Raffle Bot Guide](./docs/GUIDE.md).

## 📚 Documentation

*   **Raffle Bot Guide**: [Detailed usage guide for the Raffle Bot](./docs/GUIDE.md)
*   **Product Requirements**: [Overview of the bot's functional requirements](../../specs/raffle_bot/product_requirements.md)
*   **Technical Requirements**: [Details on the bot's architecture and technical implementation](../../specs/raffle_bot/technical_requirements.md)
*   **Overall Project Documentation**: For information about the entire umbrella project, deployment, and development practices, see the main [Documentation Index](../../docs/INDEX.md).

## 🛠️ Development

This application is built with:
*   Elixir / OTP
*   Phoenix (headless)
*   Nostrum (Discord library)
*   Ecto with SQLite3 for persistence

---

Last Updated: December 2025
