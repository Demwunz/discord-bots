# Raffle Bot UI Migration - Implementation Progress

## ⚠️ IMPORTANT NOTES FOR CONTINUATION

### What Was Just Completed (Claude Session)
1. ✅ All database migrations created (3 files in `apps/raffle_bot/priv/repo/migrations/`)
2. ✅ All schema updates (Raffle and Claim schemas)
3. ✅ Button builder functions in `embeds/raffle.ex`
4. ✅ All three button handlers (ClaimSpotButton, ConfirmClaim, CancelClaim)
5. ✅ Consumer routing for button interactions
6. ✅ **NEW:** Added `start_forum_thread/3` method to:
   - `apps/raffle_bot/lib/raffle_bot/discord/api.ex` (behaviour)
   - `apps/raffle_bot/lib/raffle_bot/discord/nostrum_api.ex` (implementation)
   - `apps/raffle_bot/test/support/mock_api.ex` (mock for testing)
7. ✅ **NEW:** Updated `raffle_setup.ex` to create forum threads with spot buttons

### Critical Context for Gemini
- **Plan File**: `/Users/fazal/.claude/plans/goofy-crafting-boole.md` - READ THIS FIRST
- **Channel Architecture**:
  - `#raffle-admin` (admin_channel_id): Forum channel for admin threads
  - `raffles-v2` (user_channel_id): Forum channel for raffle posts
  - Each raffle = its own forum thread/post
- **Button States**:
  - Available: ➡️ spot_number (blue primary)
  - Claimed unpaid: @username (gray secondary)
  - User marked paid: ✅ @username (gray - pending admin confirm)
  - Admin confirmed: ✅ @username (green success)
- **Multi-page Support**: Raffles >25 spots use multiple messages (Discord 25-button limit)

### What Was Completed (Gemini Session)
**Bugs Fixed:**
1. ✅ **Bug #1** (raffle_setup.ex line 60): Fixed create_message signature to use keyword list
2. ✅ **Bug #2** (nostrum_api.ex line 43): Replaced `Api.post/2` with `Nostrum.Api.request(:post, ...)`
3. ✅ **Bug #3** (raffle_setup.ex): Added pattern matching for response structure validation

### What Was Completed (Claude Session 2 - Current)
**Priority 1 Completion:**
1. ✅ Created shared `ButtonRefresher` helper module (`apps/raffle_bot/lib/raffle_bot/discord/helpers/button_refresher.ex`)
2. ✅ Updated `ConfirmClaim` to use ButtonRefresher
3. ✅ Updated `MarkPaidUser` to use ButtonRefresher (now refreshes spot buttons when admin marks paid)

**Priority 2 Completion:**
4. ✅ Created `AdminThread` component module (`apps/raffle_bot/lib/raffle_bot/discord/components/admin_thread.ex`)
   - Builds admin embeds showing raffle status and stats
   - Builds admin action buttons (Mark Paid, Extend, Close, Pick Winner)
5. ✅ Updated `raffle_setup.ex` to create admin forum threads
   - Creates admin thread in `admin_channel_id` after user thread
   - Stores `admin_thread_id` and `admin_thread_message_id`
   - Handles admin thread creation failures gracefully
6. ✅ Implemented complete payment flow:
   - `PaymentInfo` button handler - shows payment details to users
   - `MarkSelfPaid` button handler - allows users to mark spots as paid
   - `AdminConfirmPayment` button handler - admin confirms payment (turns buttons green)
   - `AdminRejectPayment` button handler - admin rejects payment claim
   - Added `Claims.get_user_claims_for_raffle/2` function
7. ✅ Updated `ConfirmClaim` to post payment button when raffle sells out
8. ✅ Updated Consumer routing for all new payment buttons

### Remaining Issues
1. **Migrations not run**: User needs to run `mix ecto.migrate` before testing (requires Elixir environment or Docker setup)

## Priority 1: Per-Spot Claim Buttons

### Database Migrations
- [x] Create database migration for spot_button_message_ids
- [x] Create database migration for payment details and admin thread tracking
- [x] Create database migration for user_marked_paid flag on claims
- [ ] **FIRST STEP**: Run migrations (run `mix ecto.migrate` from project root)

### Schema Updates
- [x] Update Raffle schema with new fields
- [x] Update Claim schema with user_marked_paid fields

### Button Display & Logic
- [x] Add button builder functions to raffle embed module
- [x] Update raffle setup modal to create spot buttons (⚠️ HAS BUGS - see Known Issues)
- [x] Add start_forum_thread to Api behaviour and implementations

### Button Handlers
- [x] Create ClaimSpotButton handler
- [x] Create ConfirmClaim handler
- [x] Create CancelClaim handler

### Integration
- [x] Add consumer routing for claim button interactions
- [ ] **NEXT STEP**: Update mark paid flow to refresh spot buttons
  - **File**: `apps/raffle_bot/lib/raffle_bot/discord/selects/mark_paid_user.ex`
  - **Action**: After updating claims to `is_paid: true`, call the refresh function:
    ```elixir
    # Add this after successful claim update:
    refresh_raffle_buttons(raffle_id)
    ```
  - **Helper**: Import or copy `refresh_raffle_buttons/1` from `confirm_claim.ex` (lines 59-79)
  - **Alternative**: Extract to shared module: `apps/raffle_bot/lib/raffle_bot/discord/helpers/button_refresher.ex`

## Priority 2: Admin Forum Threads & Payment Flow

### Next Implementation Tasks (In Order)
1. [ ] **Implement payment flow and Pay button**
   - When all spots claimed, show "Pay for your spots" button to claimants
   - Button shows payment details (from `raffle.payment_details`)
   - User clicks "Mark as Paid" → sets `claim.user_marked_paid = true`
   - Updates button to show ✅ @username (yellow/gray)
   - Sends notification to admin thread

2. [ ] **Create admin forum thread on raffle creation**
   - **File**: `apps/raffle_bot/lib/raffle_bot/discord/modals/raffle_setup.ex`
   - **Action**: After creating user forum thread, create admin thread:
     ```elixir
     # After user thread creation:
     {:ok, admin_thread} = discord_api().start_forum_thread(
       config.admin_channel_id,
       "🎯 #{raffle.title}",
       %{embeds: [build_admin_embed(raffle)], components: build_admin_buttons(raffle)}
     )
     # Store: admin_thread_id, admin_thread_message_id
     ```

3. [ ] **Create admin thread component builders**
   - **File**: `apps/raffle_bot/lib/raffle_bot/discord/components/admin_thread.ex` (NEW)
   - **Functions**:
     - `build_admin_embed/1` - Show raffle status, payment info
     - `build_admin_buttons/1` - Admin action buttons

4. [ ] **Implement payment notification to admin thread**
   - When user marks as paid, post message to `raffle.admin_thread_id`
   - Include user mention, spots claimed, amount
   - Add "Confirm Payment" and "Reject" buttons

5. [ ] **Create admin payment confirmation buttons**
   - Confirm button: Sets `claim.is_paid = true`, refreshes all buttons to green
   - Reject button: Sets `claim.user_marked_paid = false`, refreshes to gray

## Testing & Finalization

- [ ] Fix bugs in raffle_setup.ex (see Known Issues above)
- [ ] Run `mix ecto.migrate` to apply database changes
- [ ] Test raffle creation with spot buttons
- [ ] Test claim flow (click → confirm → refresh)
- [ ] Test multi-page raffles (>25 spots)
- [ ] Test payment flow (when implemented)
- [ ] Test admin thread creation (when implemented)

## Files Modified So Far

### Created Files (Session 1 - Claude)
1. `apps/raffle_bot/priv/repo/migrations/20251214105658_add_spot_button_message_ids_to_raffles.exs`
2. `apps/raffle_bot/priv/repo/migrations/20251214105730_add_payment_and_admin_thread_to_raffles.exs`
3. `apps/raffle_bot/priv/repo/migrations/20251214105827_add_user_marked_paid_to_claims.exs`
4. `apps/raffle_bot/lib/raffle_bot/discord/buttons/claim_spot_button.ex`
5. `apps/raffle_bot/lib/raffle_bot/discord/buttons/confirm_claim.ex`
6. `apps/raffle_bot/lib/raffle_bot/discord/buttons/cancel_claim.ex`

### Created Files (Session 3 - Claude)
7. `apps/raffle_bot/lib/raffle_bot/discord/helpers/button_refresher.ex` - Shared button refresh helper
8. `apps/raffle_bot/lib/raffle_bot/discord/components/admin_thread.ex` - Admin thread embeds and buttons
9. `apps/raffle_bot/lib/raffle_bot/discord/buttons/payment_info.ex` - Payment details display
10. `apps/raffle_bot/lib/raffle_bot/discord/buttons/mark_self_paid.ex` - User payment marking
11. `apps/raffle_bot/lib/raffle_bot/discord/buttons/admin_confirm_payment.ex` - Admin payment confirmation
12. `apps/raffle_bot/lib/raffle_bot/discord/buttons/admin_reject_payment.ex` - Admin payment rejection

### Modified Files (Session 1 - Claude)
1. `apps/raffle_bot/lib/raffle_bot/raffles/raffle.ex` - Added 4 new fields
2. `apps/raffle_bot/lib/raffle_bot/claims/claim.ex` - Added 2 new fields
3. `apps/raffle_bot/lib/raffle_bot/discord/embeds/raffle.ex` - Added spot button builders
4. `apps/raffle_bot/lib/raffle_bot/discord/consumer.ex` - Added button routing
5. `apps/raffle_bot/lib/raffle_bot/discord/api.ex` - Added start_forum_thread callback
6. `apps/raffle_bot/test/support/mock_api.ex` - Added mock start_forum_thread

### Modified Files (Session 2 - Gemini)
7. `apps/raffle_bot/lib/raffle_bot/discord/modals/raffle_setup.ex` - Fixed bugs, added response validation
8. `apps/raffle_bot/lib/raffle_bot/discord/nostrum_api.ex` - Fixed API call with proper request method

### Modified Files (Session 3 - Claude)
9. `apps/raffle_bot/lib/raffle_bot/discord/buttons/confirm_claim.ex` - Uses ButtonRefresher, posts payment button
10. `apps/raffle_bot/lib/raffle_bot/discord/selects/mark_paid_user.ex` - Added button refresh call
11. `apps/raffle_bot/lib/raffle_bot/discord/modals/raffle_setup.ex` - Added admin thread creation
12. `apps/raffle_bot/lib/raffle_bot/claims/claims.ex` - Added get_user_claims_for_raffle/2
13. `apps/raffle_bot/lib/raffle_bot/discord/consumer.ex` - Added payment button routing

---

**Last Updated**: 2025-12-14 (Session 3 - Claude)
**Session Summary**: Completed Priority 1 & Priority 2 implementation. All features implemented except testing which requires running migrations and live bot.
