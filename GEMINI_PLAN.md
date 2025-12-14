# Gemini's Execution Plan

This document outlines the step-by-step plan for completing the raffle bot UI migration. It incorporates findings from the initial handoff, codebase analysis, and existing project documentation.

## 1. Codebase Analysis & Key Conventions

My analysis confirms the project follows standard Elixir and Phoenix best practices. All new code will adhere strictly to these patterns:

*   **Project Structure:** Standard Elixir umbrella project. All work will be contained within the `raffle_bot` app.
*   **Context Boundaries:** Business logic is cleanly isolated in Context modules (`RaffleBot.Raffles`, `RaffleBot.Claims`, `RaffleBot.GuildConfig`). These modules are the single source of truth for their respective domains and must not contain any Discord-specific code.
*   **Discord Interaction Flow:** The `RaffleBot.Discord.Consumer` acts as the central router for all incoming Discord events. It pattern matches on interactions and delegates them to dedicated handler modules in the `apps/raffle_bot/lib/raffle_bot/discord/{commands,buttons,modals,selects}` directories.
*   **API Abstraction:** All external calls to the Discord API are funneled through the `RaffleBot.Discord.Api` behaviour. This is critical for testing. All new Discord API calls will be added to this behaviour and implemented in `NostrumApi` for production and `MockApi` for tests.
*   **Authorization Strategy:** Admin-level commands are secured by the `handle_admin_command/2` helper in the `Consumer`. This helper uses `RaffleBot.Discord.Authorization.authorize_admin/1` to verify the user has the configured `bot_boss_role_id`. This pattern will be used for all new admin-only functionality.
*   **Testing Conventions:** The suite uses `Mox` to mock the `Api` behaviour, ensuring tests don't hit the live Discord API. Database tests use `Ecto.Adapters.SQL.Sandbox` for transactional, isolated tests, configured via a `DataCase` module in `test/support`.

## 2. Execution Plan (TODO List)

This plan is broken into phases to ensure stability and methodical progress.

### Phase 1: Stabilization & Setup

The goal of this phase is to fix all known bugs, apply the pending database changes, and ensure the project is in a stable state before building new features.

- [ ] **1.1.** Confirm repository state by running `git status`.
- [ ] **1.2.** **Fix Bug #1:** Correct the `create_message/3` function signature in `apps/raffle_bot/lib/raffle_bot/discord/modals/raffle_setup.ex`.
- [ ] **1.3.** **Fix Bug #2:** Investigate and correct the `start_forum_thread` API call in `apps/raffle_bot/lib/raffle_bot/discord/nostrum_api.ex`.
- [ ] **1.4.** **Fix Bug #3:** Add robust pattern matching for the thread creation API response in `raffle_setup.ex`.
- [ ] **1.5.** Run pending database migrations using `mix ecto.migrate`.
- [ ] **1.6.** Run the full test suite (`mix test`) to verify stability after fixes.

### Phase 2: Priority 1 Feature Completion (User Flow)

With a stable base, this phase focuses on completing the user-facing spot claiming functionality.

- [ ] **2.1.** Refactor the `refresh_raffle_buttons/1` logic into a shared helper module (e.g., `RaffleBot.Discord.Helpers.ButtonRefresher`) to avoid code duplication.
- [ ] **2.2.** Implement the "mark paid" flow update in `mark_paid_user.ex` to call the new refresh helper, ensuring buttons update when an admin confirms payment.
- [ ] **2.3.** Conduct manual testing of the complete user flow:
    - [ ] Test creating a small raffle (e.g., 5 spots).
    - [ ] Test claiming a spot and seeing the button state change.
    - [ ] Test an admin marking the spot as paid and seeing the button change to green.
    - [ ] Test a large, multi-page raffle (e.g., 30 spots) to ensure pagination works correctly.

### Phase 3: Priority 2 Feature Implementation (Admin Flow & Payments)

This phase builds out the new admin workflow and the self-service payment system for users.

- [ ] **3.1.** Implement the user payment flow:
    - [ ] When all spots are claimed, add a "Pay for Your Spots" button to the raffle message.
    - [ ] Create a handler for this button that shows the user an ephemeral message with payment details and a "Mark as Paid" button.
    - [ ] Implement the handler for "Mark as Paid" to set `claim.user_marked_paid = true` and refresh the spot buttons to the "pending confirmation" state.
- [ ] **3.2.** Update raffle creation (`raffle_setup.ex`) to also create a dedicated admin thread in the configured `admin_channel_id`.
- [ ] **3.3.** Create a new module (`RaffleBot.Discord.Components.AdminThread`) to build the embeds and action buttons for the admin thread.
- [ ] **3.4.** Implement the notification system that posts a message to the admin thread when a user marks their spots as paid. This message should include "Confirm Payment" buttons.
- [ ] **3.5.** Implement the handlers for the admin "Confirm Payment" and "Reject Payment" buttons.

### Phase 4: Documentation & Finalization

The final phase is to update project documentation and prepare the work for review.

- [ ] **4.1.** Update `specs/raffle_bot/product_requirements.md` to reflect the new button-based UI and forum-based admin flow.
- [ ] **4.2.** Update `specs/raffle_bot/technical_requirements.md` to document the new database fields and architectural patterns.
- [ ] **4.3.** Review all changes and prepare a commit that follows the project's contribution guidelines.