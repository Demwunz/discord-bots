# Raffle Bot UI Migration Plan

## Overview
Transition raffle_bot from slash command-based admin workflow to persistent, component-based UI:
- **Priority 1**: Per-spot claim buttons (improves user experience)
- **Priority 2**: Admin control panel in #raffle-admin (improves admin workflow)

Channel-based security: Admin panel only posted in `#raffle-admin` (prevents users from seeing admin controls).

---

## Channel Architecture

### Admin Channel: `#raffle-admin` (Forum Channel)
- **Forum-based organization**: Each raffle gets its own forum thread
- **Admin controls**: Posted in each raffle's admin forum thread (no separate control panel)
- **Notifications**: Payment notifications, status updates posted as replies in raffle thread
- **Security**: Only users with channel access can see admin threads
- Primary security layer: Discord channel permissions
- Secondary security: Bot Boss role checks on all admin actions

### User Channel: `raffles-v2` (Forum Channel)
- Each raffle is a forum thread/post
- Raffle embed + per-spot claim buttons in thread starter message
- For raffles >25 spots: Additional messages with more buttons posted as thread replies
- Public access for all server members

---

## Priority 1: Per-Spot Claim Buttons (User Experience)

### Current vs New User Flow

**Current Flow** (Complex):
1. Click "Claim Spots" button
2. Ephemeral select menu appears with available spots
3. Select spot(s) from dropdown
4. Submit

**New Flow** (Simple):
1. See all spots as buttons on raffle message
2. Click desired spot button
3. Ephemeral confirmation dialog appears
4. Click "Confirm" button
5. Spot claimed

### Button Layout Design

**Button Grid** (5 rows × 5 buttons per message):
```
Raffle Embed
┌─────────────────────────┐
│ Amazing Item Raffle     │
│ $10 per spot | 50 spots │
│ Description...          │
└─────────────────────────┘

Spots 1-25:
[ 1 ] [ 2 ] [ 3 ] [ 4 ] [ 5 ]
[@West] [ 7 ] [ 8 ] [@Joe] [ 10 ]
[ 11 ] [@Kim✅] [ 13 ] [ 14 ] [ 15 ]
[ 16 ] [ 17 ] [ 18 ] [ 19 ] [ 20 ]
[ 21 ] [ 22 ] [ 23 ] [ 24 ] [ 25 ]

(If >25 spots, additional message posted as thread reply)

Spots 26-50:
[ 26 ] [ 27 ] [ 28 ] [ 29 ] [ 30 ]
...
```

### Button States

1. **Available**: Blue primary button with ➡️ and spot number
   ```elixir
   %{type: 2, style: 1, label: "➡️ 5", custom_id: "claim_spot_{raffle_id}_5"}
   ```

2. **Claimed (no payment yet)**: Gray disabled button with @username
   ```elixir
   %{type: 2, style: 2, label: "@West", custom_id: "claimed_{raffle_id}_7", disabled: true}
   ```

3. **User marked as paid** (pending admin confirmation): Yellow/orange disabled button with ✅ @username
   ```elixir
   %{type: 2, style: 2, label: "✅ @West", custom_id: "user_paid_{raffle_id}_7", disabled: true}
   ```
   Note: Needs admin to verify and confirm

4. **Admin confirmed paid**: Green disabled button with ✅ @username
   ```elixir
   %{type: 2, style: 3, label: "✅ @West", custom_id: "confirmed_paid_{raffle_id}_12", disabled: true}
   ```

### Custom ID Convention
`claim_spot_{raffle_id}_{spot_number}`

Examples:
- `claim_spot_abc123_5` - Spot 5 in raffle abc123
- `claim_spot_abc123_42` - Spot 42 in raffle abc123

### Confirmation Dialog

When user clicks available spot button, show ephemeral message:
```
🎟️ Confirm Claim

Spot: #5
Raffle: Amazing Item
Price: $10

[✅ Confirm Claim] [❌ Cancel]
```

Custom IDs:
- Confirm: `confirm_claim_{raffle_id}_{spot_number}`
- Cancel: `cancel_claim`

### Payment Flow

**Trigger**: When ALL spots in a raffle are claimed

**User Experience**:
1. "Pay for your spots" button appears for all claimants (in raffle thread or via DM)
2. User clicks → Ephemeral message shows payment details + "Mark as Paid" button
3. User marks as paid → Their spot buttons update to ✅ @username (yellow/orange)
4. Notification sent to admin forum thread: "@User marked spots #5, #12 as paid"
5. Admin manually verifies payment
6. Admin clicks confirm → Spot buttons turn green ✅ @username

**Payment Details Storage**:
- Collected during raffle setup (new field in modal)
- Stored in `raffles.payment_details` (text field)
- Example: "Venmo: @username" or "PayPal: email@example.com"

**Button Logic**:
```
🎟️ Pay for Your Spots

You claimed: Spot #5, Spot #12
Total: $20 ($10 per spot)

Payment Details:
Venmo: @raffle_admin
PayPal: admin@example.com

Once paid, click "Mark as Paid" below.

[✅ Mark as Paid]
```

### Multi-Message Support for Large Raffles

**Discord Limits**: 25 buttons max per message (5 rows × 5 buttons)

**Strategy**:
- Raffle with ≤25 spots: Single message (forum thread starter)
- Raffle with >25 spots: Multiple messages
  - Message 1 (starter): Embed + Spots 1-25
  - Message 2 (reply): Spots 26-50
  - Message 3 (reply): Spots 51-75
  - etc.

**Database Storage**: Store all message IDs in `spot_button_message_ids` array field

### Implementation Steps - Priority 1

#### Step 1.1: Database Migration
```elixir
# Migration: Add spot_button_message_ids to raffles table
alter table(:raffles) do
  add :spot_button_message_ids, {:array, :text}, default: []
end
```

**Files**:
- `apps/raffle_bot/priv/repo/migrations/[timestamp]_add_spot_button_message_ids.exs` (NEW)
- `apps/raffle_bot/lib/raffle_bot/raffles/raffle.ex` (MODIFY - add field to schema)

#### Step 1.2: Button Builder Functions

**File**: `apps/raffle_bot/lib/raffle_bot/discord/embeds/raffle.ex`

**New Functions**:
```elixir
def build_spot_buttons(raffle, claims, page \\ 1) do
  # Calculate spot range for this page (25 spots per page)
  start_spot = (page - 1) * 25 + 1
  end_spot = min(page * 25, raffle.total_spots)

  # Build button grid (5 rows × 5 buttons)
  start_spot..end_spot
  |> Enum.chunk_every(5)  # 5 buttons per row
  |> Enum.map(fn spot_numbers ->
    %{
      type: 1,  # Action row
      components: Enum.map(spot_numbers, &build_spot_button(raffle, claims, &1))
    }
  end)
end

defp build_spot_button(raffle, claims, spot_number) do
  case find_claim(claims, spot_number) do
    nil ->
      # Available spot
      %{
        type: 2,
        style: 1,  # Primary (blue)
        label: "#{spot_number}",
        custom_id: "claim_spot_#{raffle.id}_#{spot_number}"
      }

    %{is_paid: true, user_id: user_id} ->
      # Paid spot
      %{
        type: 2,
        style: 3,  # Success (green)
        label: truncate_username(format_username(user_id), 72) <> " ✅",
        custom_id: "claimed_#{raffle.id}_#{spot_number}",
        disabled: true
      }

    %{user_id: user_id} ->
      # Claimed but unpaid
      %{
        type: 2,
        style: 2,  # Secondary (gray)
        label: truncate_username(format_username(user_id), 80),
        custom_id: "claimed_#{raffle.id}_#{spot_number}",
        disabled: true
      }
  end
end

defp format_username(user_id) do
  # Format as "@username" or fetch from Discord API/cache
  "@#{user_id}"
end

defp truncate_username(username, max_length) do
  if String.length(username) > max_length do
    String.slice(username, 0, max_length - 3) <> "..."
  else
    username
  end
end

defp find_claim(claims, spot_number) do
  Enum.find(claims, fn claim -> claim.spot_number == spot_number end)
end
```

#### Step 1.3: Update Raffle Creation to Use Buttons

**File**: `apps/raffle_bot/lib/raffle_bot/discord/modals/raffle_setup.ex`

**Changes**:
```elixir
case Raffles.create_raffle(attrs) do
  {:ok, raffle} ->
    # Build embed
    embed = RaffleEmbed.build(raffle, [])

    # Build first page of buttons (spots 1-25)
    buttons_page_1 = RaffleEmbed.build_spot_buttons(raffle, [], 1)

    # Create forum thread in raffles-v2
    # TODO: Use Nostrum API to create forum thread
    # Thread name: raffle.title
    # First message: embed + buttons
    {:ok, message} = discord_api().create_forum_thread(
      config.user_channel_id,  # raffles-v2 forum channel ID
      %{
        name: raffle.title,
        message: %{
          embeds: [embed],
          components: buttons_page_1
        }
      }
    )

    # Store message IDs
    message_ids = [message.id]

    # If > 25 spots, create additional messages as thread replies
    if raffle.total_spots > 25 do
      num_pages = ceil(raffle.total_spots / 25)

      additional_ids = for page <- 2..num_pages do
        buttons = RaffleEmbed.build_spot_buttons(raffle, [], page)
        start_spot = (page - 1) * 25 + 1
        end_spot = min(page * 25, raffle.total_spots)

        {:ok, msg} = discord_api().create_message(
          message.channel_id,  # Thread ID
          %{
            content: "**Spots #{start_spot} - #{end_spot}**",
            components: buttons
          }
        )
        msg.id
      end

      message_ids = message_ids ++ additional_ids
    end

    # Update raffle with message IDs
    Raffles.update_raffle(raffle, %{
      message_id: hd(message_ids),
      channel_id: message.channel_id,
      spot_button_message_ids: tl(message_ids)  # All except first
    })

    # Send success response
    discord_api().create_interaction_response(
      interaction,
      4,
      %{
        content: "✅ Raffle created! View it in <##{config.user_channel_id}>",
        flags: 64  # Ephemeral
      }
    )
end
```

#### Step 1.4: Claim Spot Button Handler

**File**: `apps/raffle_bot/lib/raffle_bot/discord/buttons/claim_spot_button.ex` (NEW)

```elixir
defmodule RaffleBot.Discord.Buttons.ClaimSpotButton do
  use RaffleBot.Discord.ApiConsumer
  alias RaffleBot.Raffles
  alias RaffleBot.Discord.Embeds.Raffle, as: RaffleEmbed

  def handle(%{data: %{"custom_id" => "claim_spot_" <> rest}} = interaction) do
    [raffle_id, spot_number_str] = String.split(rest, "_", parts: 2)
    spot_number = String.to_integer(spot_number_str)

    raffle = Raffles.get_raffle!(raffle_id)

    # Show confirmation dialog (ephemeral)
    discord_api().create_interaction_response(
      interaction,
      4,
      %{
        content: """
        🎟️ **Confirm Claim**

        Spot: **##{spot_number}**
        Raffle: **#{raffle.title}**
        Price: **$#{raffle.price}**

        Click "Confirm" to claim this spot.
        """,
        components: [
          %{
            type: 1,
            components: [
              %{
                type: 2,
                style: 3,  # Green
                label: "✅ Confirm Claim",
                custom_id: "confirm_claim_#{raffle_id}_#{spot_number}"
              },
              %{
                type: 2,
                style: 4,  # Red
                label: "❌ Cancel",
                custom_id: "cancel_claim"
              }
            ]
          }
        ],
        flags: 64  # Ephemeral
      }
    )
  end
end
```

#### Step 1.5: Confirm Claim Button Handler

**File**: `apps/raffle_bot/lib/raffle_bot/discord/buttons/confirm_claim.ex` (NEW)

```elixir
defmodule RaffleBot.Discord.Buttons.ConfirmClaim do
  use RaffleBot.Discord.ApiConsumer
  alias RaffleBot.Raffles
  alias RaffleBot.Claims
  alias RaffleBot.Discord.Embeds.Raffle, as: RaffleEmbed

  def handle(%{data: %{"custom_id" => "confirm_claim_" <> rest}} = interaction) do
    [raffle_id, spot_number_str] = String.split(rest, "_", parts: 2)
    spot_number = String.to_integer(spot_number_str)
    user_id = interaction.user.id

    case Claims.create_claim(raffle_id, user_id, spot_number) do
      {:ok, _claim} ->
        # Refresh all button messages for this raffle
        refresh_raffle_buttons(raffle_id)

        # Update ephemeral response
        discord_api().edit_interaction_response(
          interaction,
          %{
            content: "✅ **Spot Claimed!**\n\nYou've claimed spot ##{spot_number}.",
            components: []
          }
        )

      {:error, :spot_taken} ->
        discord_api().edit_interaction_response(
          interaction,
          %{
            content: "❌ **Spot Unavailable**\n\nSpot ##{spot_number} was just claimed. Try another spot.",
            components: []
          }
        )

      {:error, reason} ->
        discord_api().edit_interaction_response(
          interaction,
          %{
            content: "❌ **Error**: #{inspect(reason)}",
            components: []
          }
        )
    end
  end

  defp refresh_raffle_buttons(raffle_id) do
    raffle = Raffles.get_raffle!(raffle_id)
    claims = Claims.get_claims_by_raffle(raffle_id)

    # Update starter message (page 1)
    buttons_page_1 = RaffleEmbed.build_spot_buttons(raffle, claims, 1)
    discord_api().edit_message(
      raffle.channel_id,
      raffle.message_id,
      %{components: buttons_page_1}
    )

    # Update additional messages (pages 2+)
    raffle.spot_button_message_ids
    |> Enum.with_index(2)
    |> Enum.each(fn {message_id, page} ->
      buttons = RaffleEmbed.build_spot_buttons(raffle, claims, page)
      discord_api().edit_message(raffle.channel_id, message_id, %{components: buttons})
    end)
  end
end
```

#### Step 1.6: Cancel Claim Button Handler

**File**: `apps/raffle_bot/lib/raffle_bot/discord/buttons/cancel_claim.ex` (NEW)

```elixir
defmodule RaffleBot.Discord.Buttons.CancelClaim do
  use RaffleBot.Discord.ApiConsumer

  def handle(interaction) do
    discord_api().edit_interaction_response(
      interaction,
      %{
        content: "Claim cancelled.",
        components: []
      }
    )
  end
end
```

#### Step 1.7: Consumer Routing

**File**: `apps/raffle_bot/lib/raffle_bot/discord/consumer.ex`

Add to type 3 (button) handlers:
```elixir
%{"custom_id" => "claim_spot_" <> _rest} ->
  Buttons.ClaimSpotButton.handle(interaction)

%{"custom_id" => "confirm_claim_" <> _rest} ->
  Buttons.ConfirmClaim.handle(interaction)

%{"custom_id" => "cancel_claim"} ->
  Buttons.CancelClaim.handle(interaction)
```

#### Step 1.8: Update Mark Paid Flow

When admin marks spots as paid, refresh button states to show green checkmark.

**File**: `apps/raffle_bot/lib/raffle_bot/discord/selects/mark_paid_user.ex`

After updating claims to `is_paid: true`, add:
```elixir
# Import refresh function from ConfirmClaim or create shared helper
refresh_raffle_buttons(raffle_id)
```

---

## Priority 2: Admin Forum Thread per Raffle

### Architecture Change

**OLD APPROACH** (Single pinned admin panel):
- One control panel message with all admin controls
- Select raffle from dropdown → Show actions

**NEW APPROACH** (Forum-based per raffle):
- Each raffle gets its own forum thread in `#raffle-admin`
- Admin controls posted as first message in thread
- Notifications (payment marked, all spots claimed) posted as replies in thread
- Keeps admin channel organized and searchable

### Admin Thread Layout (per Raffle)

**Thread Starter Message**:
```
┌─────────────────────────────────────────┐
│  🎯 Raffle: Amazing Item                │
├─────────────────────────────────────────┤
│  Status: Active ● | 25/25 spots claimed │
│  Price: $10 per spot                    │
│  Created: Dec 14, 2025                  │
│  Closes: Dec 21, 2025                   │
├─────────────────────────────────────────┤
│  Payment Details:                       │
│  Venmo: @admin | PayPal: admin@...      │
├─────────────────────────────────────────┤
│  Claimed: 25 | Paid: 12 | Pending: 13   │
└─────────────────────────────────────────┘

Admin Actions:
[📋 View All Claims] [💰 Confirm Payments]
[⏰ Extend Duration] [🔒 Close Raffle]
[🏆 Pick Winner] (if closed)
```

**Thread Replies** (notifications):
```
🔔 All spots claimed! Claimants can now see payment button.

💵 @West marked spots #5, #12 as paid ($20 total)
   [✅ Confirm Payment] [❌ Reject]

✅ Payment confirmed for @West (spots #5, #12)

🏆 Winner selected: @Lucky (spot #17)
```

### Custom ID Convention
`admin_{action}_{raffle_id}[_{data}]`

Examples:
- `admin_view_claims_{raffle_id}` - View all claims for raffle
- `admin_confirm_payment_{raffle_id}_{user_id}` - Confirm user's payment
- `admin_reject_payment_{raffle_id}_{user_id}` - Reject payment claim
- `admin_extend_{raffle_id}` - Extend raffle by 7 days
- `admin_close_{raffle_id}` - Close raffle
- `admin_pick_winner_{raffle_id}` - Pick winner

### Implementation Steps - Priority 2

#### Step 2.1: Database Migrations

**Add payment details to raffles**:
```elixir
# Migration: Add payment_details and admin_thread_id to raffles
alter table(:raffles) do
  add :payment_details, :text  # Venmo, PayPal, etc.
  add :admin_thread_id, :text  # Forum thread ID in #raffle-admin
  add :admin_thread_message_id, :text  # First message ID in admin thread
end
```

**Add user_marked_paid flag to claims**:
```elixir
# Migration: Track when user self-marks as paid
alter table(:claims) do
  add :user_marked_paid, :boolean, default: false
  add :user_marked_paid_at, :utc_datetime
end
```

**Files**:
- `apps/raffle_bot/priv/repo/migrations/[timestamp]_add_payment_and_admin_thread_to_raffles.exs` (NEW)
- `apps/raffle_bot/priv/repo/migrations/[timestamp]_add_user_marked_paid_to_claims.exs` (NEW)
- `apps/raffle_bot/lib/raffle_bot/raffles/raffle.ex` (MODIFY)
- `apps/raffle_bot/lib/raffle_bot/claims/claim.ex` (MODIFY)

#### Step 2.2: Update Raffle Setup Modal

**File**: `apps/raffle_bot/lib/raffle_bot/discord/modals/raffle_setup.ex`

**Changes**:
1. Add `payment_details` field to modal (textarea, optional)
2. When creating raffle:
   - Create user forum thread in `raffles-v2` (existing)
   - Create admin forum thread in `#raffle-admin` (NEW)
   - Store both thread IDs in raffle record

**Admin Thread Creation**:
```elixir
# Create admin forum thread
{:ok, admin_thread} = discord_api().create_forum_thread(
  config.admin_channel_id,  # #raffle-admin
  %{
    name: "🎯 #{raffle.title}",
    message: %{
      embeds: [build_admin_embed(raffle, claims)],
      components: build_admin_buttons(raffle)
    }
  }
)

# Store admin thread info
Raffles.update_raffle(raffle, %{
  admin_thread_id: admin_thread.id,
  admin_thread_message_id: admin_thread.first_message_id
})
```

#### Step 2.3: Admin Thread Components

**File**: `apps/raffle_bot/lib/raffle_bot/discord/components/admin_thread.ex` (NEW)

```elixir
defmodule RaffleBot.Discord.Components.AdminPanel do
  alias RaffleBot.Raffles

  def build_main_view(guild_id) do
    active_raffles = Raffles.list_active_raffles()
    closed_raffles = Raffles.list_closed_raffles()

    %{
      embeds: [build_main_embed(active_raffles, closed_raffles)],
      components: build_main_components(active_raffles, closed_raffles)
    }
  end

  def build_raffle_view(raffle_id) do
    raffle = Raffles.get_raffle!(raffle_id)
    claims = RaffleBot.Claims.get_claims_by_raffle(raffle_id)

    %{
      embeds: [build_raffle_embed(raffle, claims)],
      components: build_raffle_components(raffle)
    }
  end

  defp build_main_embed(active_raffles, closed_raffles) do
    %{
      title: "🎯 Raffle Admin Control Panel",
      description: "Select a raffle from the dropdown or create a new one.",
      color: 0x5865F2,  # Blurple
      fields: [
        %{name: "Active Raffles", value: "#{length(active_raffles)}", inline: true},
        %{name: "Closed Raffles", value: "#{length(closed_raffles)}", inline: true}
      ],
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  defp build_main_components(active_raffles, closed_raffles) do
    [
      # Row 1: Create button
      %{
        type: 1,
        components: [
          %{
            type: 2,
            style: 3,  # Green
            label: "🎲 Create New Raffle",
            custom_id: "admin_panel_create"
          }
        ]
      },
      # Row 2: Active raffles dropdown (if any)
      if length(active_raffles) > 0 do
        %{
          type: 1,
          components: [
            %{
              type: 3,  # Select menu
              custom_id: "admin_panel_select_active",
              placeholder: "Select an active raffle...",
              options: Enum.map(active_raffles, fn r ->
                %{
                  label: truncate(r.title, 100),
                  value: r.id,
                  description: "#{r.total_spots} spots | $#{r.price}"
                }
              end)
            }
          ]
        }
      end,
      # Row 3: Closed raffles dropdown (if any)
      if length(closed_raffles) > 0 do
        %{
          type: 1,
          components: [
            %{
              type: 3,  # Select menu
              custom_id: "admin_panel_select_closed",
              placeholder: "Select a closed raffle...",
              options: Enum.map(closed_raffles, fn r ->
                %{
                  label: truncate(r.title, 100),
                  value: r.id,
                  description: "Closed on #{format_date(r.closed_at)}"
                }
              end)
            }
          ]
        }
      end,
      # Row 4: Refresh button
      %{
        type: 1,
        components: [
          %{
            type: 2,
            style: 2,  # Gray
            label: "🔄 Refresh",
            custom_id: "admin_panel_refresh"
          }
        ]
      }
    ]
    |> Enum.reject(&is_nil/1)  # Remove nil components
  end

  defp build_raffle_components(raffle) do
    [
      # Management stage (if active)
      if raffle.active do
        %{
          type: 1,
          components: [
            %{
              type: 2,
              style: 1,  # Blurple
              label: "💰 Mark Paid",
              custom_id: "admin_panel_mark_paid_#{raffle.id}"
            },
            %{
              type: 2,
              style: 1,
              label: "⏰ Extend Duration",
              custom_id: "admin_panel_extend_#{raffle.id}"
            }
          ]
        }
      end,
      # Completion stage
      %{
        type: 1,
        components: [
          if raffle.active do
            %{
              type: 2,
              style: 4,  # Red
              label: "🔒 Close Raffle",
              custom_id: "admin_panel_close_#{raffle.id}"
            }
          else
            %{
              type: 2,
              style: 3,  # Green
              label: "🏆 Pick Winner",
              custom_id: "admin_panel_pick_winner_#{raffle.id}"
            }
          end
        ]
      },
      # Back button
      %{
        type: 1,
        components: [
          %{
            type: 2,
            style: 2,  # Gray
            label: "⬅️ Back to Main",
            custom_id: "admin_panel_back"
          }
        ]
      }
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp truncate(str, max) do
    if String.length(str) > max, do: String.slice(str, 0, max - 3) <> "...", else: str
  end

  defp format_date(nil), do: "N/A"
  defp format_date(datetime), do: Calendar.strftime(datetime, "%b %d, %Y")
end
```

#### Step 2.3: Panel Manager

**File**: `apps/raffle_bot/lib/raffle_bot/discord/panel_manager.ex` (NEW)

```elixir
defmodule RaffleBot.Discord.PanelManager do
  use RaffleBot.Discord.ApiConsumer
  alias RaffleBot.GuildConfig
  alias RaffleBot.Discord.Components.AdminPanel

  def refresh_panel(guild_id) do
    case GuildConfig.get_guild_config_by_guild_id(guild_id) do
      %{admin_panel_message_id: message_id, admin_panel_channel_id: channel_id}
      when not is_nil(message_id) and not is_nil(channel_id) ->
        content = AdminPanel.build_main_view(guild_id)

        case discord_api().edit_message(channel_id, message_id, content) do
          {:ok, _message} -> :ok
          {:error, _reason} ->
            # Panel deleted, clear from database
            GuildConfig.update_guild_config_by_guild_id(guild_id, %{
              admin_panel_message_id: nil
            })
            :error
        end

      _ ->
        # No panel configured
        :noop
    end
  end

  def show_raffle_view(interaction, raffle_id) do
    content = AdminPanel.build_raffle_view(raffle_id)

    discord_api().create_interaction_response(
      interaction,
      7,  # Update message
      content
    )
  end

  def show_main_view(interaction) do
    guild_id = interaction.guild_id
    content = AdminPanel.build_main_view(guild_id)

    discord_api().create_interaction_response(
      interaction,
      7,  # Update message
      content
    )
  end
end
```

#### Step 2.4: Create Admin Panel Command

**File**: `apps/raffle_bot/lib/raffle_bot/discord/commands/create_admin_panel.ex` (NEW)

```elixir
defmodule RaffleBot.Discord.Commands.CreateAdminPanel do
  use RaffleBot.Discord.ApiConsumer
  alias RaffleBot.GuildConfig
  alias RaffleBot.Discord.Components.AdminPanel

  def handle(interaction) do
    guild_id = interaction.guild_id
    channel_id = interaction.channel_id

    # Validate channel is #raffle-admin
    config = GuildConfig.get_guild_config_by_guild_id(guild_id)

    unless to_string(channel_id) == config.admin_channel_id do
      return discord_api().create_interaction_response(
        interaction,
        4,
        %{
          content: "❌ This command must be run in <##{config.admin_channel_id}>",
          flags: 64
        }
      )
    end

    # Send creating message (ephemeral)
    discord_api().create_interaction_response(
      interaction,
      4,
      %{
        content: "Creating admin panel...",
        flags: 64
      }
    )

    # Build and post panel
    content = AdminPanel.build_main_view(guild_id)

    {:ok, message} = discord_api().create_message(channel_id, content)

    # Pin the message
    discord_api().pin_message(channel_id, message.id)

    # Save to database
    GuildConfig.update_guild_config_by_guild_id(guild_id, %{
      admin_panel_message_id: to_string(message.id),
      admin_panel_channel_id: to_string(channel_id)
    })

    # Update ephemeral response
    discord_api().edit_original_interaction_response(
      interaction,
      %{
        content: "✅ Admin panel created and pinned!"
      }
    )
  end
end
```

#### Step 2.5: Button Handlers

Create these handler modules (NEW):

**Admin Panel Navigation**:
- `apps/raffle_bot/lib/raffle_bot/discord/buttons/admin_panel_create.ex` - Opens raffle setup modal
- `apps/raffle_bot/lib/raffle_bot/discord/buttons/admin_panel_refresh.ex` - Shows main view
- `apps/raffle_bot/lib/raffle_bot/discord/buttons/admin_panel_back.ex` - Shows main view

**Raffle Actions**:
- `apps/raffle_bot/lib/raffle_bot/discord/buttons/admin_panel_mark_paid.ex` - Shows user selection
- `apps/raffle_bot/lib/raffle_bot/discord/buttons/admin_panel_extend.ex` - Extends by 7 days
- `apps/raffle_bot/lib/raffle_bot/discord/buttons/admin_panel_close.ex` - Closes raffle
- `apps/raffle_bot/lib/raffle_bot/discord/buttons/admin_panel_pick_winner.ex` - Winner flow

**Select Handlers**:
- `apps/raffle_bot/lib/raffle_bot/discord/selects/admin_panel_select.ex` - Handles raffle selection
- `apps/raffle_bot/lib/raffle_bot/discord/selects/admin_panel_mark_paid_user.ex` - Handles user selection

#### Step 2.6: Consumer Routing

**File**: `apps/raffle_bot/lib/raffle_bot/discord/consumer.ex`

Add slash command:
```elixir
%{"name" => "create_admin_panel"} ->
  handle_admin_command(interaction, &Commands.CreateAdminPanel.handle/1)
```

Add button handlers:
```elixir
%{"custom_id" => "admin_panel_create"} ->
  handle_admin_command(interaction, &Buttons.AdminPanelCreate.handle/1)

%{"custom_id" => "admin_panel_refresh"} ->
  handle_admin_command(interaction, &Buttons.AdminPanelRefresh.handle/1)

%{"custom_id" => "admin_panel_back"} ->
  handle_admin_command(interaction, &Buttons.AdminPanelBack.handle/1)

%{"custom_id" => "admin_panel_select_active"} ->
  handle_admin_command(interaction, &Selects.AdminPanelSelect.handle/1)

%{"custom_id" => "admin_panel_select_closed"} ->
  handle_admin_command(interaction, &Selects.AdminPanelSelect.handle/1)

%{"custom_id" => "admin_panel_mark_paid_" <> _raffle_id} ->
  handle_admin_command(interaction, &Buttons.AdminPanelMarkPaid.handle/1)

%{"custom_id" => "admin_panel_extend_" <> _raffle_id} ->
  handle_admin_command(interaction, &Buttons.AdminPanelExtend.handle/1)

%{"custom_id" => "admin_panel_close_" <> _raffle_id} ->
  handle_admin_command(interaction, &Buttons.AdminPanelClose.handle/1)

%{"custom_id" => "admin_panel_pick_winner_" <> _raffle_id} ->
  handle_admin_command(interaction, &Buttons.AdminPanelPickWinner.handle/1)
```

#### Step 2.7: Integration - Auto-Refresh Panel

After raffle creation/modification, refresh panel:

**File**: `apps/raffle_bot/lib/raffle_bot/discord/modals/raffle_setup.ex`

After successful raffle creation:
```elixir
RaffleBot.Discord.PanelManager.refresh_panel(interaction.guild_id)
```

Also add refresh calls to:
- Mark paid handlers
- Extend raffle handlers
- Close raffle handlers
- Pick winner handlers

---

## Critical Files Summary

### Priority 1: Per-Spot Claim Buttons

**Database**:
- `apps/raffle_bot/priv/repo/migrations/[timestamp]_add_spot_button_message_ids.exs` (NEW)
- `apps/raffle_bot/lib/raffle_bot/raffles/raffle.ex` (MODIFY)

**Button Display**:
- `apps/raffle_bot/lib/raffle_bot/discord/embeds/raffle.ex` (MODIFY)
- `apps/raffle_bot/lib/raffle_bot/discord/modals/raffle_setup.ex` (MODIFY)

**Button Handlers** (NEW):
- `apps/raffle_bot/lib/raffle_bot/discord/buttons/claim_spot_button.ex`
- `apps/raffle_bot/lib/raffle_bot/discord/buttons/confirm_claim.ex`
- `apps/raffle_bot/lib/raffle_bot/discord/buttons/cancel_claim.ex`

**Consumer**:
- `apps/raffle_bot/lib/raffle_bot/discord/consumer.ex` (MODIFY)

### Priority 2: Admin Control Panel

**Database**:
- `apps/raffle_bot/priv/repo/migrations/[timestamp]_add_admin_panel_to_guild_configurations.exs` (NEW)
- `apps/raffle_bot/lib/raffle_bot/guild_config/guild_configuration.ex` (MODIFY)
- `apps/raffle_bot/lib/raffle_bot/guild_config/guild_config.ex` (MODIFY)

**Core Logic** (NEW):
- `apps/raffle_bot/lib/raffle_bot/discord/components/admin_panel.ex`
- `apps/raffle_bot/lib/raffle_bot/discord/panel_manager.ex`

**Command** (NEW):
- `apps/raffle_bot/lib/raffle_bot/discord/commands/create_admin_panel.ex`

**Handlers** (NEW):
- `apps/raffle_bot/lib/raffle_bot/discord/buttons/admin_panel_*.ex` (7 files)
- `apps/raffle_bot/lib/raffle_bot/discord/selects/admin_panel_*.ex` (2 files)

**Consumer**:
- `apps/raffle_bot/lib/raffle_bot/discord/consumer.ex` (MODIFY)

---

## Key Changes Summary

### NEW Features:
1. **Per-spot claim buttons** with emoji states (➡️ → @user → ✅)
2. **Self-service payment flow** - users mark their own spots as paid
3. **Payment details field** in raffle setup modal
4. **Admin forum threads** - each raffle gets own thread in #raffle-admin (NO central panel)
5. **Payment notifications** sent to admin thread when user marks paid
6. **Admin payment confirmation** buttons in admin thread

### Database Changes:
- `raffles.payment_details` (text) - Payment info from raffle setup
- `raffles.admin_thread_id` (text) - Forum thread ID in #raffle-admin
- `raffles.admin_thread_message_id` (text) - First message in admin thread
- `claims.user_marked_paid` (boolean) - User self-marked as paid
- `claims.user_marked_paid_at` (datetime) - When user marked paid

### Button States:
1. Available: ➡️ 5 (blue)
2. Claimed: @West (gray)
3. User marked paid: ✅ @West (yellow/orange) - waiting admin confirmation
4. Admin confirmed: ✅ @West (green)

### Architecture:
- **#raffle-admin**: Forum channel, each raffle = separate thread
- **No admin control panel**: Controls live in each raffle's admin thread
- **Payment flow**: All spots claimed → "Pay" button → User marks paid → Admin confirms

## Success Criteria

- [ ] Users can claim spots by clicking buttons directly on raffle message
- [ ] Button states update in real-time with correct emojis
- [ ] Multi-message support works for raffles >25 spots
- [ ] Payment details collected in raffle setup modal
- [ ] "Pay for your spots" button appears when all spots claimed
- [ ] Users can mark their spots as paid
- [ ] Admin receives notification in raffle's admin thread
- [ ] Admin can confirm/reject payment from admin thread
- [ ] Admin thread created in #raffle-admin for each raffle
- [ ] Admin actions (extend, close, pick winner) work in admin thread
- [ ] Channel-based security enforced
- [ ] Bot Boss role authorization enforced
- [ ] All tests passing
- [ ] Documentation updated
