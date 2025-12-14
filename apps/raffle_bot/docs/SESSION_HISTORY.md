# Session History - December 14, 2025

This document captures the conversation history and changes made during the Claude Code session for future reference.

---

## Session Summary

### Date: December 14, 2025
### Project: Raffle Bot (Discord Bots Umbrella)
### Branch: main

---

## Changes Made This Session

### 1. Raffle Embed Format Update

**Commit:** `b920de1` - feat(raffle): Update embed format with shipping and payment info

The raffle embed was completely redesigned with a new format:

**New Format:**
```
🎟️ Raffle Time! — [TITLE]

[DESCRIPTION]

🔗 Grading: View Certificate (only if link provided)

💵 Spots are $[PRICE] each — grab as many as you want!
🎯 [TOTAL] total spots — pick your spot by clicking the buttons below!

Raffles will run as soon as all spots are filled.
If we don't fill it up within [DURATION] days, this one will close and we'll kick off a fresh raffle.

📦 Shipping Info:
🇺🇸 US: [US_SHIPPING or default: "Free USPS Ground Advantage"]
🌍 [INTL_SHIPPING or "No international shipping for this raffle."]

💳 Payment:
Only collected once all spots are full — [PAYMENT_DETAILS or "Venmo, Zelle or PayPal is good to go."]
```

**Conditional Logic:**
- Grading link: Only shown if provided
- International shipping: Shows "No international shipping" if null/empty
- Payment details: Uses default if not provided

### 2. Schema Changes

**New Field Added:**
- `us_shipping` (string, default: "Free USPS Ground Advantage")

**Existing Fields Used:**
- `grading_link` (string, optional)
- `duration_days` (integer, default: 7)
- `international_shipping` (string, optional)
- `payment_details` (string, optional)

### 3. Setup Modal Changes

The `/setup_raffle` modal was updated:

| Field | Required | Description |
|-------|----------|-------------|
| Title | Yes | Name of the raffle |
| Price per Spot | Yes | Cost per spot (numbers only) |
| Total Spots | Yes | Number of available spots |
| Grading Link | No | Link to CGC/CBCS certificate |
| Description | Yes | Details about the item |

**Removed:** Payment Details field (now uses default)

### 4. Migration Created

**File:** `apps/raffle_bot/priv/repo/migrations/20251214230001_add_us_shipping_to_raffles.exs`

```elixir
defmodule RaffleBot.Repo.Migrations.AddUsShippingToRaffles do
  use Ecto.Migration

  def change do
    alter table(:raffles) do
      add :us_shipping, :text, default: "Free USPS Ground Advantage"
    end
  end
end
```

---

## Files Modified

1. **apps/raffle_bot/lib/raffle_bot/discord/embeds/raffle.ex**
   - Complete rewrite of `build/2` function
   - New helper functions: `build_description/1`, `build_grading_link/1`, `build_international_shipping/1`, `build_payment_details/1`, `add_image_to_embed/2`

2. **apps/raffle_bot/lib/raffle_bot/discord/commands/setup_raffle.ex**
   - Replaced `payment_details` field with `grading_link` field in modal

3. **apps/raffle_bot/lib/raffle_bot/raffles/raffle.ex**
   - Added `us_shipping` field to schema
   - Removed default from `international_shipping` (now nil by default)
   - Added `us_shipping` to changeset cast list

4. **apps/raffle_bot/docs/GUIDE.md**
   - Updated "Creating a Raffle" section with new fields
   - Added "Default Settings" section
   - Updated "Visual Reference" with new embed format

5. **apps/raffle_bot/priv/repo/migrations/20251214230001_add_us_shipping_to_raffles.exs** (NEW)
   - Migration to add `us_shipping` column

---

## Previous Session Changes (Context)

From the previous session, these changes were already made:

### UI/UX Improvements (Commit: `bceca25`)
1. **Button Labels:** Changed from `"➡️ 5"` to `"5. Claim"`
2. **Payment Pending:** Changed from `"✅ @name"` to `"💵 @name"`
3. **My Spots Button:** Added persistent button on raffle (20 spots per page + utility row)
4. **Photo Upload Flow:** Admin can upload photos via reply in admin thread

### File Reorganization (Commit: `0830462`)
- Moved PLAN.md → apps/raffle_bot/docs/PLAN.md
- Moved TODO.md → apps/raffle_bot/docs/TODO.md
- Moved specs/raffle_bot/ → apps/raffle_bot/specs/

---

## Pending Migrations

The following migrations need to be run:

1. `20251214230001_add_us_shipping_to_raffles.exs` - Adds us_shipping field

**Run with:**
```bash
docker-compose up -d --build && docker-compose exec raffle_bot /app/bin/raffle_bot eval 'RaffleBot.Release.migrate()'
```

Or for Fly.io:
```bash
fly ssh console -C "/app/bin/raffle_bot eval 'RaffleBot.Release.migrate()'"
```

---

## Current Schema State

**Raffle Schema (`apps/raffle_bot/lib/raffle_bot/raffles/raffle.ex`):**
```elixir
schema "raffles" do
  field :message_id, :integer
  field :spot_button_message_ids, {:array, :string}, default: []
  field :channel_id, :integer
  field :title, :string
  field :price, :decimal
  field :total_spots, :integer
  field :description, :string
  field :photo_url, :string
  field :photo_urls, {:array, :string}, default: []
  field :grading_link, :string
  field :duration_days, :integer, default: 7
  field :us_shipping, :string, default: "Free USPS Ground Advantage"
  field :international_shipping, :string
  field :active, :boolean, default: true
  field :closed_at, :utc_datetime
  field :auto_close_at, :utc_datetime
  field :payment_details, :string
  field :admin_thread_id, :string
  field :admin_thread_message_id, :string

  has_many :claims, Claim

  timestamps()
end
```

---

## Git Log (Recent Commits)

```
b920de1 feat(raffle): Update embed format with shipping and payment info
bceca25 feat(raffle): Improve UI/UX with button changes and photo uploads
0830462 refactor(docs): Reorganize raffle_bot documentation structure
d10706f feat(raffle): Add guild-specific authorization and channel validation
b611fad chore: ignore MacOS DS_Store files
```

---

## User's Original Request (This Session)

The user wanted to update the Raffle Embed to this format:
```
🎟️ Raffle Time! — [TITLE]
[DESCRIPTION]
[GRADING LINK] ? [LINK]: null [/GRADING-LINK]
💵 Spots are [PRICE PER SPOT] each — grab as many as you want!
🎯 [TOTAL SPOTS] total spots — pick your spot by clicking the buttons below!
Raffles will run as soon as all spots are filled.
If we don't fill it up within [DURATION] days, this one will close and we'll kick off a fresh raffle.

📦 Shipping Info:
🇺🇸 US: [SHIPPING(Default:Free USPS Ground Advantage)]
[INTERNATIONAL SHIPPING]? No international shipping for this raffle : [/INTERNATIONAL SHIPPING]
💳 Payment:
Only collected once all spots are full — [PAYMENT DETAILS](Default:) Venmo, Zelle or PayPal is good to go [/PAYMENT DETAILS]
```

**Notation explained:**
- `[PLACEHOLDER]` = field value
- `[FIELD]? value_if_true : value_if_false` = conditional logic
- `(Default: value)` = default value if not provided

---

## Next Steps / TODO

1. Run the new migration (`20251214230001_add_us_shipping_to_raffles.exs`)
2. Test the new embed format in Discord
3. Consider adding admin ability to edit shipping/payment details after raffle creation
4. Consider adding duration_days to the setup modal (currently uses default of 7)

---

## Important File Paths

- **Embed Builder:** `apps/raffle_bot/lib/raffle_bot/discord/embeds/raffle.ex`
- **Setup Modal:** `apps/raffle_bot/lib/raffle_bot/discord/commands/setup_raffle.ex`
- **Modal Handler:** `apps/raffle_bot/lib/raffle_bot/discord/modals/raffle_setup.ex`
- **Schema:** `apps/raffle_bot/lib/raffle_bot/raffles/raffle.ex`
- **Consumer:** `apps/raffle_bot/lib/raffle_bot/discord/consumer.ex`
- **Admin Thread:** `apps/raffle_bot/lib/raffle_bot/discord/components/admin_thread.ex`
- **Button Handlers:** `apps/raffle_bot/lib/raffle_bot/discord/buttons/`
- **User Guide:** `apps/raffle_bot/docs/GUIDE.md`
- **Plan:** `apps/raffle_bot/docs/PLAN.md`

---

*Last Updated: December 14, 2025*
