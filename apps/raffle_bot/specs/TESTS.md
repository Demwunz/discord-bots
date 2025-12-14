# TESTING GUIDELINES
**Framework:** `ExUnit`
**Mocking Library:** `Mox`
**Location:** `apps/raffle_bot/test/`

## 1. Testing Strategy
We strictly separate **Business Logic** (Contexts) from **External Effects** (Discord/Database).

### 1.1 Database Tests (Async & Sandboxed)
* **Tool:** `Ecto.Adapters.SQL.Sandbox`
* **Behavior:** Tests run in a database transaction that rolls back automatically after the test finishes. This keeps the DB clean.
* **Location:** `apps/raffle_bot/test/raffle_bot/`

### 1.2 Discord Interaction Tests (Mocked)
* **Tool:** `Mox`
* **Rule:** Tests MUST NOT make real HTTP requests to Discord.
* **Implementation:**
    1.  Define a Behaviour `@callback` in `RaffleBot.Discord.Api`.
    2.  In `config/test.exs`, swap the real adapter for a Mock.
    3.  In tests, use `expect` to verify that `create_message` or `edit_message` was called.

---

## 2. Required Test Cases
The Agent must implement tests covering these specific scenarios:

### 2.1 Context: Raffles (`RaffleBot.Raffles`)
* **`create_raffle/1`:**
    * Success: Inserts a raffle with `active: true`.
    * Validation: Fails if `price` is negative or `title` is missing.
* **`close_raffle/1`:**
    * Updates `active` to `false`.

### 2.2 Context: Claims (`RaffleBot.Claims`)
* **`claim_spot/2`:**
    * Success: User A claims Spot 5 -> DB record created.
    * Error: User B tries to claim Spot 5 -> Returns `{:error, :spot_taken}`.
    * Error: User A tries to claim Spot 99 (outside total spots) -> Returns error.
* **`mark_paid/2`:**
    * Updates `is_paid` from `false` to `true`.
* **`get_open_spots/1`:**
    * Returns a list of integers that are NOT in the `claims` table.

### 2.3 Business Logic: Winner Selection
* **`pick_winner/1`:**
    * Given a raffle with 3 claims (User A: 2 spots, User B: 1 spot), verify that the selection function returns a valid User ID from the pool.
    * *Tip:* You do not need to test randomness, just that the result is valid.

### 2.4 Pagination Logic
* **Scenario:** A raffle has 50 spots.
* **Test:** Verify the helper function splits the list `1..50` into two lists: `1..25` and `26..50` (for the Discord Select Menu limit).

---

## 3. How to Run Tests
From the root of the umbrella project:

```bash
# Run all tests
mix test

# Run tests for specific app
mix test apps/raffle_bot

# Run a specific file
mix test apps/raffle_bot/test/raffle_bot/raffles_test.exs
